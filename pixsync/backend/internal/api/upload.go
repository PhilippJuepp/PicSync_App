package api

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"backend/internal/db"
	"backend/internal/storage"
)

func UploadHandler(pg *db.Postgres, store storage.Storage) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        userID := r.Context().Value(CtxUserID).(int64)

        if err := r.ParseMultipartForm(100 << 20); err != nil {
            http.Error(w, "file too large", http.StatusBadRequest)
            return
        }

        file, header, err := r.FormFile("file")
        if err != nil {
            http.Error(w, "file missing", http.StatusBadRequest)
            return
        }
        defer file.Close()

        filename := header.Filename
        mime := header.Header.Get("Content-Type")

        takenAtStr := r.FormValue("taken_at")
        var takenAt *time.Time
        if takenAtStr != "" {
            if t, err := time.Parse(time.RFC3339, takenAtStr); err == nil {
                takenAt = &t
            }
        }

        hashBytes := sha256.New()
        tmpFilePath := filepath.Join(os.TempDir(), strconv.FormatInt(time.Now().UnixNano(), 10))
        tmpFile, _ := os.Create(tmpFilePath)
        defer tmpFile.Close()
        defer os.Remove(tmpFilePath)

        sizeWritten, err := io.Copy(io.MultiWriter(hashBytes, tmpFile), file)
        if err != nil {
            http.Error(w, "file save failed", http.StatusInternalServerError)
            return
        }

        hash := hex.EncodeToString(hashBytes.Sum(nil))
        storageKey := strconv.FormatInt(time.Now().UnixNano(), 10) + "_" + filename

        tmpFile.Seek(0, io.SeekStart) // Reader auf Anfang zurücksetzen
		if err := store.Put(r.Context(), storageKey, tmpFile, sizeWritten); err != nil {
			http.Error(w, "storage failed", http.StatusInternalServerError)
			return
		}

        assetID, err := pg.CreateAsset(userID, filename, tmpFilePath, sizeWritten, mime, hash, takenAt, storageKey)
        if err != nil {
            http.Error(w, "db insert failed", http.StatusInternalServerError)
            return
        }

        json.NewEncoder(w).Encode(map[string]any{
            "id":       assetID,
            "filename": filename,
            "url":      "/assets/" + storageKey,
        })
    }
}