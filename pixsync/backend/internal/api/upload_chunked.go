package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"backend/internal/db"
	"backend/internal/storage"
	"github.com/google/uuid"
)

// POST /upload/init
func UploadInitHandler(pg *db.Postgres) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userID := r.Context().Value(CtxUserID).(int64)

		var req struct {
			Filename string    `json:"filename"`
			Size     int64     `json:"size"`
			Mime     string    `json:"mime"`
			TakenAt  time.Time `json:"taken_at"`
		}

		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "invalid request", http.StatusBadRequest)
			return
		}

		uploadID := uuid.New().String()
		tempPath := filepath.Join("/tmp", "pixsync_upload_"+uploadID)

		// DB insert
		err := pg.CreateUpload(uploadID, userID, req.Filename, req.Size, tempPath)
		if err != nil {
			http.Error(w, "db error", http.StatusInternalServerError)
			return
		}

		resp := map[string]interface{}{
			"upload_id": uploadID,
			"offset":    0,
		}
		json.NewEncoder(w).Encode(resp)
	}
}

// POST /upload/chunk
func UploadChunkHandler(pg *db.Postgres) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		uploadID := r.URL.Query().Get("id")
		if uploadID == "" {
			http.Error(w, "missing upload id", http.StatusBadRequest)
			return
		}

		up, err := pg.GetUpload(uploadID)
		if err != nil {
			http.Error(w, "upload not found", http.StatusNotFound)
			return
		}

		f, err := os.OpenFile(up.TempPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			http.Error(w, "failed to write temp file", http.StatusInternalServerError)
			return
		}
		defer f.Close()

		n, err := io.Copy(f, r.Body)
		if err != nil {
			http.Error(w, "failed to read chunk", http.StatusInternalServerError)
			return
		}

		// Update offset in DB
		err = pg.UpdateUploadOffset(uploadID, up.UploadedOffset+n)
		if err != nil {
			http.Error(w, "db update error", http.StatusInternalServerError)
			return
		}

		// Response
		resp := map[string]interface{}{
			"received": n,
			"offset":   up.UploadedOffset + n,
		}
		json.NewEncoder(w).Encode(resp)
	}
}

// POST /upload/complete
func UploadCompleteHandler(pg *db.Postgres, store storage.Storage) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userID := r.Context().Value(CtxUserID).(int64)
		uploadID := r.URL.Query().Get("id")
		if uploadID == "" {
			http.Error(w, "missing upload id", http.StatusBadRequest)
			return
		}

		up, err := pg.GetUpload(uploadID)
		if err != nil {
			http.Error(w, "upload not found", http.StatusNotFound)
			return
		}

		// proof upload complete
		info, err := os.Stat(up.TempPath)
		if err != nil || info.Size() != up.TotalSize {
			http.Error(w, "upload incomplete", http.StatusBadRequest)
			return
		}

		// move file
		storageKey := fmt.Sprintf("%d/%s/original", userID, uuid.New().String())

		f, err := os.Open(up.TempPath)
		if err != nil {
			http.Error(w, "failed to open temp file", http.StatusInternalServerError)
			return
		}
		defer f.Close()

		fileInfo, _ := f.Stat()
		err = store.Put(r.Context(), storageKey, f, fileInfo.Size())

		if err != nil {
			http.Error(w, "failed to store file", http.StatusInternalServerError)
			return
		}

	_, err = pg.CreateAsset(userID, up.Filename, "", up.TotalSize, up.Mime, "", &up.TakenAt, storageKey)
	if err != nil {
		http.Error(w, "failed to save asset", http.StatusInternalServerError)
		return
	}

		// mark upload as finished
		pg.CompleteUpload(uploadID)

		// delete temp-file
		os.Remove(up.TempPath)

		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "completed"})
	}
}