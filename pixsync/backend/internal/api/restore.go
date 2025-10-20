package api

import (
	"context"
	"io"
	"net/http"
	"strconv"
	"time"

	"backend/internal/db"
	"backend/internal/storage"
)

// RestoreHandler
func RestoreHandler(pg *db.Postgres, store storage.Storage) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userID := r.Context().Value(CtxUserID).(int64)

		// Asset-ID
		assetIDStr := r.URL.Query().Get("id")
		if assetIDStr == "" {
			http.Error(w, "missing asset id", http.StatusBadRequest)
			return
		}
		assetID, err := strconv.ParseInt(assetIDStr, 10, 64)
		if err != nil {
			http.Error(w, "invalid asset id", http.StatusBadRequest)
			return
		}

		// load asset from db
		asset, err := pg.GetAsset(userID, assetID)
		if err != nil {
			http.Error(w, "asset not found", http.StatusNotFound)
			return
		}

		// open file from storage
		ctx := context.Background()
		reader, err := store.Get(ctx, asset.StorageKey)
		if err != nil {
			if err == storage.ErrNotFound {
				http.Error(w, "file missing", http.StatusNotFound)
				return
			}
			http.Error(w, "storage error", http.StatusInternalServerError)
			return
		}
		defer reader.Close()

		// set header
		w.Header().Set("Content-Disposition", "attachment; filename=\""+asset.Filename+"\"")
		w.Header().Set("Content-Type", asset.Mime)
		if asset.TakenAt != nil {
			w.Header().Set("X-Taken-At", asset.TakenAt.Format(time.RFC3339))
		}

		// stream direct to client
		_, err = io.Copy(w, reader)
		if err != nil {
			http.Error(w, "failed to send file", http.StatusInternalServerError)
			return
		}
	}
}