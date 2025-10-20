package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"

	"backend/internal/api"
	"backend/internal/config"
	"backend/internal/db"
	"backend/internal/storage"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	// === Load configuration ===
	cfg := config.Load()

	// === Connect to PostgreSQL ===
	dbURL := cfg.GetDatabaseURL()
	pg, err := db.NewPostgres(dbURL)
	if err != nil {
		log.Fatalf("failed to connect to postgres: %v", err)
	}
	defer pg.Close()

	// === Run migrations ===
	if err := pg.Migrate(); err != nil {
		log.Fatalf("migration failed: %v", err)
	}

	// === Initialize storage backend (local or minio) ===
	store, err := storage.New(cfg)
	if err != nil {
		log.Fatalf("failed to initialize storage: %v", err)
	}

	// === Setup router ===
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	// === Register all API routes ===
	api.RegisterRoutes(r, pg, store, cfg)

	// === Start HTTP server ===
	addr := fmt.Sprintf("%s:%s", cfg.AppHost, cfg.AppPort)
	srv := &http.Server{
		Addr:         addr,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// === Run server in background ===
	go func() {
		fmt.Printf("PixSync server running on %s\n", addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	// === Graceful shutdown ===
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)
	<-stop
	log.Println("Shutdown signal received, stopping server...")

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("server shutdown failed: %v", err)
	}
	log.Println("Server stopped gracefully.")
}