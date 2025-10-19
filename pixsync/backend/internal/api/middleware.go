package api

import (
	"context"
	"net/http"
	"strings"

	"backend/internal/auth"
)

type ctxKey string

const CtxUserID ctxKey = "user_id"

func JWTMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := r.Header.Get("Authorization")
		if h == "" || !strings.HasPrefix(h, "Bearer ") {
			http.Error(w, "unauthorized", http.StatusUnauthorized); return
		}
		tokenStr := strings.TrimPrefix(h, "Bearer ")
		claims, err := auth.ParseToken(tokenStr)
		if err != nil {
			http.Error(w, "unauthorized", http.StatusUnauthorized); return
		}
		if uid, ok := claims["user_id"].(float64); ok {
			ctx := context.WithValue(r.Context(), CtxUserID, int64(uid))
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}
		http.Error(w, "unauthorized", http.StatusUnauthorized)
	})
}