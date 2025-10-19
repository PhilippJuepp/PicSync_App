package api

import (
	"net/http"

	"backend/internal/config"
	"backend/internal/db"
	"backend/internal/storage"

	"github.com/go-chi/chi/v5"
)

func RegisterRoutes(r chi.Router, pg *db.Postgres, store storage.Storage, cfg *config.Config) {
	// === Health Check ===
	r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	// - /auth (Login/Register)
	// - /upload
	// - /assets
	// - /restore
}