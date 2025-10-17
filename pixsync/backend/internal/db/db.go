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