package main

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const maxBackupBytes = 20 << 20

type server struct {
	dataDir string
	tokens  []string
}

func main() {
	srv := &server{
		dataDir: env("CAIXINHA_DATA_DIR", "./data"),
		tokens:  splitTokens(os.Getenv("CAIXINHA_TOKENS")),
	}
	if len(srv.tokens) == 0 {
		log.Fatal("defina CAIXINHA_TOKENS com pelo menos um token (separados por vírgula)")
	}
	if err := os.MkdirAll(srv.dataDir, 0o700); err != nil {
		log.Fatalf("não foi possível criar %s: %v", srv.dataDir, err)
	}

	addr := env("CAIXINHA_ADDR", ":8080")
	httpServer := &http.Server{
		Addr:              addr,
		Handler:           srv.routes(),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       60 * time.Second,
		WriteTimeout:      60 * time.Second,
	}
	log.Printf("caixinha-server ouvindo em %s", addr)
	log.Fatal(httpServer.ListenAndServe())
}

func (s *server) routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	mux.HandleFunc("GET /v1/backup", s.authorized(s.getBackup))
	mux.HandleFunc("PUT /v1/backup", s.authorized(s.putBackup))
	return mux
}

func (s *server) authorized(next func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok || !s.validToken(token) {
			http.Error(w, "token inválido", http.StatusUnauthorized)
			return
		}
		next(w, r, token)
	}
}

func (s *server) validToken(token string) bool {
	valid := false
	for _, allowed := range s.tokens {
		if subtle.ConstantTimeCompare([]byte(token), []byte(allowed)) == 1 {
			valid = true
		}
	}
	return valid
}

func (s *server) backupPath(token string) string {
	sum := sha256.Sum256([]byte(token))
	return filepath.Join(s.dataDir, hex.EncodeToString(sum[:])+".json")
}

func (s *server) getBackup(w http.ResponseWriter, _ *http.Request, token string) {
	file, err := os.Open(s.backupPath(token))
	if errors.Is(err, os.ErrNotExist) {
		http.Error(w, "nenhum backup", http.StatusNotFound)
		return
	}
	if err != nil {
		log.Printf("erro ao abrir backup: %v", err)
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}
	defer file.Close()
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	if _, err := io.Copy(w, file); err != nil {
		log.Printf("erro ao enviar backup: %v", err)
	}
}

func (s *server) putBackup(w http.ResponseWriter, r *http.Request, token string) {
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxBackupBytes))
	if err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			http.Error(w, "backup grande demais", http.StatusRequestEntityTooLarge)
			return
		}
		http.Error(w, "corpo inválido", http.StatusBadRequest)
		return
	}
	var envelope struct {
		Format  string `json:"format"`
		Version int    `json:"version"`
	}
	if err := json.Unmarshal(body, &envelope); err != nil || envelope.Format != "caixinha-backup" {
		http.Error(w, "não é um backup do Caixinha", http.StatusBadRequest)
		return
	}

	target := s.backupPath(token)
	tmp, err := os.CreateTemp(s.dataDir, "upload-*.tmp")
	if err != nil {
		log.Printf("erro ao criar temporário: %v", err)
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(body); err != nil {
		tmp.Close()
		log.Printf("erro ao gravar backup: %v", err)
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}
	if err := tmp.Close(); err != nil {
		log.Printf("erro ao fechar backup: %v", err)
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}
	if err := os.Rename(tmp.Name(), target); err != nil {
		log.Printf("erro ao salvar backup: %v", err)
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func env(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func splitTokens(raw string) []string {
	var tokens []string
	for _, token := range strings.Split(raw, ",") {
		if token = strings.TrimSpace(token); len(token) >= 16 {
			tokens = append(tokens, token)
		}
	}
	return tokens
}
