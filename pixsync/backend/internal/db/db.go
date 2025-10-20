package db

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/lib/pq"
)

type Postgres struct {
	DB *sql.DB
}

// NewPostgres creates and opens a PostgreSQL connection
func NewPostgres(url string) (*Postgres, error) {
	var err error
	db, err := sql.Open("postgres", url)
	if err != nil {
		return nil, fmt.Errorf("failed to open db connection: %w", err)
	}

	// Retry ping for up to ~20s total
	for i := 0; i < 10; i++ {
		err = db.Ping()
		if err == nil {
			log.Println("Connected to PostgreSQL")
			return &Postgres{DB: db}, nil
		}
		log.Printf("Waiting for database... (%d/10)\n", i+1)
		time.Sleep(2 * time.Second)
	}
	return nil, fmt.Errorf("could not connect to database: %w", err)
}

// Close closes the connection
func (p *Postgres) Close() {
	if p.DB != nil {
		p.DB.Close()
	}
}

func (p *Postgres) CreateAsset(userID int64, filename string, path string, size int64, mime, hash string, takenAt *time.Time, storageKey string) (int64, error) {
    var id int64
    query := `
        INSERT INTO assets (user_id, filename, path, size, mime, hash, taken_at, storage_key)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        RETURNING id
    `
    err := p.DB.QueryRow(query, userID, filename, path, size, mime, hash, takenAt, storageKey).Scan(&id)
    return id, err
}