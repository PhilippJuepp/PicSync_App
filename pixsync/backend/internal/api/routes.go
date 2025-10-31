package api

import (
	"net/http"

	"backend/internal/config"
	"backend/internal/db"
	"backend/internal/storage"

	"github.com/go-chi/chi/v5"
)

func RegisterRoutes(r chi.Router, pg *db.Postgres, store storage.Storage, cfg *config.Config) {
	// Health-Check
	r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

	// Auth
	r.Post("/auth/register", RegisterHandler(pg))
	r.Post("/auth/login", LoginHandler(pg))
	r.Post("/auth/refresh", RefreshHandler(pg))
	r.Post("/auth/logout", LogoutHandler(pg))

	// protected routes
	r.Group(func(protected chi.Router) {
		protected.Use(JWTMiddleware)
		protected.Post("/upload", UploadHandler(pg, store))
		protected.Get("/restore", RestoreHandler(pg, store))
		protected.Post("/upload/init", UploadInitHandler(pg))
		protected.Post("/upload/chunk", UploadChunkHandler(pg))
		protected.Post("/upload/complete", UploadCompleteHandler(pg, store))
	})
}