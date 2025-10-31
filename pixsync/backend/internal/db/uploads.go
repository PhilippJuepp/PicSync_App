package db

import (
    "time"
)

type Upload struct {
    ID             string
    UserID         int64
    Filename       string
    TempPath       string
    TotalSize      int64
    UploadedOffset int64
    Mime           string
    TakenAt        time.Time
    CreatedAt      time.Time
    Completed      bool
}

func (pg *Postgres) CreateUpload(id string, userID int64, filename string, totalSize int64, tempPath string) error {
    _, err := pg.DB.Exec(`
        INSERT INTO uploads (id, user_id, filename, total_size, temp_path, uploaded_offset, completed, created_at)
        VALUES ($1, $2, $3, $4, $5, 0, false, NOW())
    `, id, userID, filename, totalSize, tempPath)
    return err
}

func (pg *Postgres) GetUpload(id string) (*Upload, error) {
    row := pg.DB.QueryRow(`
        SELECT id, user_id, filename, temp_path, total_size, uploaded_offset, completed, mime, taken_at
        FROM uploads WHERE id = $1
    `, id)

    var u Upload
    err := row.Scan(&u.ID, &u.UserID, &u.Filename, &u.TempPath, &u.TotalSize, &u.UploadedOffset, &u.Completed, &u.Mime, &u.TakenAt)
    if err != nil {
        return nil, err
    }
    return &u, nil
}

func (pg *Postgres) UpdateUploadOffset(id string, offset int64) error {
    _, err := pg.DB.Exec(`UPDATE uploads SET uploaded_offset = $1 WHERE id = $2`, offset, id)
    return err
}

func (pg *Postgres) CompleteUpload(id string) error {
    _, err := pg.DB.Exec(`UPDATE uploads SET completed = true WHERE id = $1`, id)
    return err
}