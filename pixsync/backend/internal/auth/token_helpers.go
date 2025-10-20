package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/base64"
	"fmt"
	"time"
	"database/sql"
	"backend/internal/db"
)

// genRefreshToken: erzeugt sicheren zufälligen Refresh-Token (plaintext)
func GenRefreshToken() (string, error) {
	b := make([]byte, 48) // 48 bytes -> base64 ~64 chars
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// sha256hex: Hash für Speicherung
func Sha256Hex(s string) string {
	h := sha256.Sum256([]byte(s))
	return hex.EncodeToString(h[:])
}

// CreateSession: speichert session row und gibt session id + expiry
func CreateSession(pg *db.Postgres, userID int64, refreshTokenPlain string, ttl time.Duration, deviceName, deviceID, ip, ua string) (string, error) {
	hash := Sha256Hex(refreshTokenPlain)
	expiresAt := time.Now().Add(ttl)
	var id string
	err := pg.DB.QueryRow(
		`INSERT INTO sessions (user_id, refresh_token_hash, device_name, device_id, ip, user_agent, expires_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id`,
		userID, hash, deviceName, deviceID, ip, ua, expiresAt,
	).Scan(&id)
	if err != nil {
		return "", err
	}
	return id, nil
}

// FindSessionByRefreshHash: returns session id + revoked + expires
func FindSessionByRefreshHash(pg *db.Postgres, hash string) (id string, userID int64, revoked bool, expiresAt time.Time, err error) {
	row := pg.DB.QueryRow(`SELECT id, user_id, revoked, expires_at FROM sessions WHERE refresh_token_hash=$1`, hash)
	if err = row.Scan(&id, &userID, &revoked, &expiresAt); err != nil {
		if err == sql.ErrNoRows { return "", 0, false, time.Time{}, fmt.Errorf("not found") }
		return "", 0, false, time.Time{}, err
	}
	return
}

// RotateSessionRefresh: set new hash + expires + last_used
func RotateSessionRefresh(pg *db.Postgres, sessionID string, newHash string, ttl time.Duration) error {
	_, err := pg.DB.Exec(`UPDATE sessions SET refresh_token_hash=$1, expires_at=$2, last_used_at=now() WHERE id=$3 AND revoked=false`,
		newHash, time.Now().Add(ttl), sessionID)
	return err
}

// RevokeSessionByID
func RevokeSessionByID(pg *db.Postgres, sessionID string) error {
	_, err := pg.DB.Exec(`UPDATE sessions SET revoked=true WHERE id=$1`, sessionID)
	return err
}