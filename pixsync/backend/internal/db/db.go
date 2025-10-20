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

type Asset struct {
    ID         int64
    UserID     int64
    Filename   string
    Path       string
    Size       int64
    Mime       string
    Hash       string
    TakenAt    *time.Time
    StorageKey string
    CreatedAt  time.Time
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

func (p *Postgres) GetAsset(userID, assetID int64) (*Asset, error) {
	a := &Asset{}
	query := `SELECT id, filename, path, size, mime, hash, taken_at, storage_key, created_at
	          FROM assets WHERE id=$1 AND user_id=$2`
	row := p.DB.QueryRow(query, assetID, userID)
	err := row.Scan(&a.ID, &a.Filename, &a.Path, &a.Size, &a.Mime, &a.Hash, &a.TakenAt, &a.StorageKey, &a.CreatedAt)
	if err != nil {
		return nil, err
	}
	return a, nil
}