package db

import (
	"database/sql"
	"errors"
)

type User struct {
	ID int64
	Email string
	PasswordHash string
	CreatedAt string
}

func (p *Postgres) CreateUser(email, passwordHash string) (int64, error) {
	var id int64
	err := p.DB.QueryRow(
		"INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id",
		email, passwordHash,
	).Scan(&id)
	if err != nil {
		return 0, err
	}
	return id, nil
}

func (p *Postgres) GetUserByEmail(email string) (*User, error) {
	u := &User{}
	row := p.DB.QueryRow("SELECT id, email, password_hash, created_at FROM users WHERE email=$1", email)
	if err := row.Scan(&u.ID, &u.Email, &u.PasswordHash, &u.CreatedAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return u, nil
}