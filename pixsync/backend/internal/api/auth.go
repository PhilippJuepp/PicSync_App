package api

import (
	"encoding/json"
	"net/http"
	"time"
  "strings"

	"backend/internal/db"
	"backend/internal/auth"
)

type registerReq struct {
    Name     string `json:"name"`
    Email    string `json:"email"`
    Password string `json:"password"`
}

type loginReq struct {
    Identifier string `json:"identifier"`
    Password   string `json:"password"`
}

func RegisterHandler(pg *db.Postgres) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        var rq registerReq
        if err := json.NewDecoder(r.Body).Decode(&rq); err != nil {
            http.Error(w, "bad request", http.StatusBadRequest)
            return
        }

        rq.Name = strings.TrimSpace(rq.Name)
        rq.Email = strings.TrimSpace(strings.ToLower(rq.Email))
        rq.Password = strings.TrimSpace(rq.Password)

        if rq.Email == "" || rq.Password == "" || rq.Name == "" {
            http.Error(w, "missing fields", http.StatusBadRequest)
            return
        }

        if u, _ := pg.GetUserByEmail(rq.Email); u != nil {
            http.Error(w, "email already used", http.StatusConflict)
            return
        }
        if u, _ := pg.GetUserByName(rq.Name); u != nil {
            http.Error(w, "name already used", http.StatusConflict)
            return
        }

        pwHash, _ := auth.HashPassword(rq.Password)
        id, err := pg.CreateUser(rq.Name, rq.Email, pwHash)
        if err != nil {
            http.Error(w, "server error", http.StatusInternalServerError)
            return
        }

        json.NewEncoder(w).Encode(map[string]any{"id": id})
    }
}

func LoginHandler(pg *db.Postgres) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        var rq loginReq
        if err := json.NewDecoder(r.Body).Decode(&rq); err != nil {
            http.Error(w, "bad request", http.StatusBadRequest)
            return
        }

        rq.Identifier = strings.TrimSpace(strings.ToLower(rq.Identifier))
        rq.Password = strings.TrimSpace(rq.Password)

        identifier := rq.Identifier
        
 		    var u *db.User
        var err error

        if strings.Contains(identifier, "@") {
            u, err = pg.GetUserByEmail(identifier)
        } else {
            u, err = pg.GetUserByName(identifier)
        }

        if err != nil || u == nil {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }

        if !auth.CheckPasswordHash(u.PasswordHash, rq.Password) {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }

		// access token
		accessToken, err := auth.NewToken(u.ID, 15*time.Minute)
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError)
			return
		}

		// refresh token
		refreshPlain, err := auth.GenRefreshToken()
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError)
			return
		}

		// save session (Logout/Rotation)
		sessionID, err := auth.CreateSession(
			pg,
			u.ID,
			refreshPlain,
			30*24*time.Hour,
			r.Header.Get("X-Device-Name"),
			"",
			r.RemoteAddr,
			r.UserAgent(),
		)
		if err != nil {
			http.Error(w, "server error", http.StatusInternalServerError)
			return
		}

		// send to client
		json.NewEncoder(w).Encode(map[string]any{
			"access_token":       accessToken,
			"access_expires_in":  15 * 60,
			"refresh_token":      refreshPlain,
			"refresh_expires_in": 30 * 24 * 60 * 60,
			"session_id":         sessionID,
          "user": map[string]any{
          "id": u.ID,
          "email": u.Email,
          "name": u.Name,
      },
		})
	}
}

func RefreshHandler(pg *db.Postgres) http.HandlerFunc {
  return func(w http.ResponseWriter, r *http.Request) {
    var body struct { RefreshToken string `json:"refresh_token"` }
    if err := json.NewDecoder(r.Body).Decode(&body); err != nil { http.Error(w,"bad request",400); return }

    hash := auth.Sha256Hex(body.RefreshToken)
    sessionID, userID, revoked, expiresAt, err := auth.FindSessionByRefreshHash(pg, hash)
    if err != nil { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
    if revoked || time.Now().After(expiresAt) { http.Error(w, "unauthorized", http.StatusUnauthorized); return }

    // rotate
    newRefresh, err := auth.GenRefreshToken()
    if err != nil { http.Error(w,"server error",500); return }
    newHash := auth.Sha256Hex(newRefresh)
    if err := auth.RotateSessionRefresh(pg, sessionID, newHash, 30*24*time.Hour); err != nil {
      http.Error(w,"server error",500); return
    }

    // new access token
    accessToken, err := auth.NewToken(userID, 15*time.Minute)
    if err != nil { http.Error(w,"server error",500); return }

    json.NewEncoder(w).Encode(map[string]any{
		"access_token": accessToken,
		"access_expires_in": 15*60,
		"refresh_token": newRefresh,
		"refresh_expires_in": 30*24*60*60,
		"session_id": sessionID,
		"user_id": userID,
    })
  }
}

func LogoutHandler(pg *db.Postgres) http.HandlerFunc {
  return func(w http.ResponseWriter, r *http.Request) {
    var body struct { SessionID string `json:"session_id"`; RefreshToken string `json:"refresh_token"` }
    _ = json.NewDecoder(r.Body).Decode(&body)

    if body.SessionID != "" {
      if err := auth.RevokeSessionByID(pg, body.SessionID); err != nil { http.Error(w,"server error",500); return }
      w.WriteHeader(200); return
    }
    if body.RefreshToken != "" {
      hash := auth.Sha256Hex(body.RefreshToken)
      // find session id then revoke (reuse FindSessionByRefreshHash)
      sid, _, _, _, err := auth.FindSessionByRefreshHash(pg, hash)
      if err != nil { http.Error(w,"ok",200); return } // already gone
      _ = auth.RevokeSessionByID(pg, sid)
      w.WriteHeader(200); return
    }
    w.WriteHeader(400)
  }
}