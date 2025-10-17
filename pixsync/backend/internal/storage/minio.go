package storage

import (
	"context"
	"fmt"
	"io"
	"net/url"
	"strings"
	"time"

	"backend/internal/config"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// MinioStorage implements Storage using MinIO / S3-compatible backend.
type MinioStorage struct {
	client *minio.Client
	bucket string
	// optional base prefix inside bucket (not used now)
	prefix string
}

// NewMinio creates a MinIO-backed Storage. Expects cfg.MinioEndpoint, MinioAccessKey, MinioSecretKey, MinioBucket.
func NewMinio(cfg *config.Config) (*MinioStorage, error) {
	if cfg.MinioEndpoint == "" {
		return nil, fmt.Errorf("minio endpoint not set")
	}
	// parse endpoint for secure scheme detection
	endpoint := cfg.MinioEndpoint
	secure := false
	// if user provided URL-like (http:// or https://), parse and extract host
	if strings.HasPrefix(endpoint, "http://") || strings.HasPrefix(endpoint, "https://") {
		u, err := url.Parse(endpoint)
		if err != nil {
			return nil, fmt.Errorf("invalid minio endpoint url: %w", err)
		}
		secure = u.Scheme == "https"
		endpoint = u.Host
	}

	// create client
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.MinioAccessKey, cfg.MinioSecretKey, ""),
		Secure: secure,
	})
	if err != nil {
		return nil, fmt.Errorf("minio.New: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// ensure bucket exists (create if missing)
	exists, err := minioClient.BucketExists(ctx, cfg.MinioBucket)
	if err != nil {
		return nil, fmt.Errorf("bucket exists check: %w", err)
	}
	if !exists {
		if err := minioClient.MakeBucket(ctx, cfg.MinioBucket, minio.MakeBucketOptions{}); err != nil {
			return nil, fmt.Errorf("create bucket: %w", err)
		}
	}

	return &MinioStorage{client: minioClient, bucket: cfg.MinioBucket}, nil
}

func (m *MinioStorage) Put(ctx context.Context, objectKey string, src io.Reader, size int64) error {
	opts := minio.PutObjectOptions{
		ContentType: "application/octet-stream",
	}
	// Use PutObject which supports streaming
	_, err := m.client.PutObject(ctx, m.bucket, objectKey, src, size, opts)
	if err != nil {
		return fmt.Errorf("minio put object: %w", err)
	}
	return nil
}

func (m *MinioStorage) Get(ctx context.Context, objectKey string) (io.ReadCloser, error) {
	obj, err := m.client.GetObject(ctx, m.bucket, objectKey, minio.GetObjectOptions{})
	if err != nil {
		return nil, fmt.Errorf("minio get object: %w", err)
	}
	// stat to detect 404
	if _, err := obj.Stat(); err != nil {
		if minio.ToErrorResponse(err).StatusCode == 404 {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("minio stat object: %w", err)
	}
	return obj, nil
}

func (m *MinioStorage) Exists(ctx context.Context, objectKey string) (bool, error) {
	_, err := m.client.StatObject(ctx, m.bucket, objectKey, minio.StatObjectOptions{})
	if err != nil {
		if minio.ToErrorResponse(err).StatusCode == 404 {
			return false, nil
		}
		return false, fmt.Errorf("minio stat object: %w", err)
	}
	return true, nil
}

func (m *MinioStorage) Remove(ctx context.Context, objectKey string) error {
	if err := m.client.RemoveObject(ctx, m.bucket, objectKey, minio.RemoveObjectOptions{}); err != nil {
		// if object doesn't exist, MinIO returns error; map to ErrNotFound for consistency
		if minio.ToErrorResponse(err).StatusCode == 404 {
			return ErrNotFound
		}
		return fmt.Errorf("minio remove object: %w", err)
	}
	return nil
}