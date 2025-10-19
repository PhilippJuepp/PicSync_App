package api

import (
	"encoding/json"
	"net/http"
	"time"

	"backend/internal/db"
	"backend/internal/auth"
)

type registerReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type loginReq struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func RegisterHandler(pg *db.Postgres) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var rq registerReq
		if err := json.NewDecoder(r.Body).Decode(&rq); err != nil {
			http.Error(w, "bad request", http.StatusBadRequest); return
		}
		if rq.Email == "" || rq.Password == "" {
			http.Error(w, "missing fields", http.StatusBadRequest); return
		}
		// check exists
		existing, _ := pg.GetUserByEmail(rq.Email)
		if existing != nil {
			http.Error(w, "email already used", http.StatusConflict); return
		}
		pwHash, _ := auth.HashPassword(rq.Password)
		id, err := pg.CreateUser(rq.Email, pwHash)
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError); return
		}
		json.NewEncoder(w).Encode(map[string]any{"id": id})
	}
}

func LoginHandler(pg *db.Postgres) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var rq loginReq
		if err := json.NewDecoder(r.Body).Decode(&rq); err != nil {
			http.Error(w, "bad request", http.StatusBadRequest); return
		}
		u, err := pg.GetUserByEmail(rq.Email)
		if err != nil || u == nil {
			http.Error(w, "unauthorized", http.StatusUnauthorized); return
		}
		if !auth.CheckPasswordHash(u.PasswordHash, rq.Password) {
			http.Error(w, "unauthorized", http.StatusUnauthorized); return
		}
		token, err := auth.NewToken(u.ID, 24*time.Hour)
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError); return
		}
		json.NewEncoder(w).Encode(map[string]any{"token": token})
	}
}