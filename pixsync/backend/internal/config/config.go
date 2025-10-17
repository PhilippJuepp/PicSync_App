package config

import (
	"fmt"
	"os"
	"strings"
	"time"
)

func init() {
	// Versuche, .env aus dem Projektroot zu laden (eine Ebene höher)
	if _, err := os.Stat("../.env"); err == nil {
		data, _ := os.ReadFile("../.env")
		lines := strings.Split(string(data), "\n")
		for _, line := range lines {
			if line == "" || strings.HasPrefix(line, "#") {
				continue
			}
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				os.Setenv(strings.TrimSpace(parts[0]), strings.TrimSpace(parts[1]))
			}
		}
	}
}

// Config holds all runtime configuration values for the PixSync backend.
type Config struct {
	AppHost          string
	AppPort          string
	DatabaseHost     string
	DatabasePort     string
	DatabaseUser     string
	DatabasePassword string
	DatabaseName     string
	DatabaseSSLMode  string
	StorageDriver    string // "local" or "minio"
	LocalStoragePath string
	MinioEndpoint    string
	MinioAccessKey   string
	MinioSecretKey   string
	MinioBucket      string
	JWTSecret        string
	Timezone         string
}

// Load reads all configuration values from environment variables.
// Each field has a sensible default, allowing a simple local Docker setup.
func Load() *Config {
	cfg := &Config{
		AppHost:          getEnv("APP_HOST", "0.0.0.0"),
		AppPort:          getEnv("APP_PORT", "8080"),
		DatabaseHost:     getEnv("DB_HOST", "postgres"),
		DatabasePort:     getEnv("DB_PORT", "5432"),
		DatabaseUser:     getEnv("DB_USER", "pixsync"),
		DatabasePassword: getEnv("DB_PASSWORD", "pixsync"),
		DatabaseName:     getEnv("DB_NAME", "pixsync"),
		DatabaseSSLMode:  getEnv("DB_SSLMODE", "disable"),
		StorageDriver:    getEnv("STORAGE_DRIVER", "local"),
		LocalStoragePath: getEnv("LOCAL_STORAGE_PATH", "/data/pixsync"),
		MinioEndpoint:    getEnv("MINIO_ENDPOINT", "minio:9000"),
		MinioAccessKey:   getEnv("MINIO_ACCESS_KEY", "minioadmin"),
		MinioSecretKey:   getEnv("MINIO_SECRET_KEY", "minioadmin"),
		MinioBucket:      getEnv("MINIO_BUCKET", "pixsync"),
		JWTSecret:        getEnv("JWT_SECRET", "changeme"),
		Timezone:         getEnv("TZ", "Europe/Berlin"),
	}
	return cfg
}

// GetDatabaseURL builds a full Postgres connection string.
func (c *Config) GetDatabaseURL() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=%s",
		c.DatabaseUser,
		c.DatabasePassword,
		c.DatabaseHost,
		c.DatabasePort,
		c.DatabaseName,
		c.DatabaseSSLMode,
	)
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

// Utility: returns parsed duration if you ever need it later.
func getEnvDuration(key string, fallback time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return fallback
}