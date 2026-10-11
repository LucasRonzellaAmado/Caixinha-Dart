package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

const token = "token-de-teste-123456"

func newTestServer(t *testing.T) http.Handler {
	t.Helper()
	return (&server{dataDir: t.TempDir(), tokens: []string{token}}).routes()
}

func do(t *testing.T, h http.Handler, method, auth, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, "/v1/backup", strings.NewReader(body))
	if auth != "" {
		req.Header.Set("Authorization", "Bearer "+auth)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestBackupRoundTrip(t *testing.T) {
	h := newTestServer(t)
	if rec := do(t, h, http.MethodGet, token, ""); rec.Code != http.StatusNotFound {
		t.Fatalf("esperava 404, veio %d", rec.Code)
	}
	payload := `{"format":"caixinha-backup","version":1}`
	if rec := do(t, h, http.MethodPut, token, payload); rec.Code != http.StatusNoContent {
		t.Fatalf("esperava 204, veio %d", rec.Code)
	}
	rec := do(t, h, http.MethodGet, token, "")
	if rec.Code != http.StatusOK || rec.Body.String() != payload {
		t.Fatalf("backup não confere: %d %q", rec.Code, rec.Body.String())
	}
}

func TestRejectsInvalidRequests(t *testing.T) {
	h := newTestServer(t)
	if rec := do(t, h, http.MethodGet, "", ""); rec.Code != http.StatusUnauthorized {
		t.Fatalf("sem token deveria ser 401, veio %d", rec.Code)
	}
	if rec := do(t, h, http.MethodGet, "outro-token-qualquer-xyz", ""); rec.Code != http.StatusUnauthorized {
		t.Fatalf("token errado deveria ser 401, veio %d", rec.Code)
	}
	if rec := do(t, h, http.MethodPut, token, `{"format":"outro"}`); rec.Code != http.StatusBadRequest {
		t.Fatalf("formato errado deveria ser 400, veio %d", rec.Code)
	}
}
