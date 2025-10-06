package main

import (
	"bytes"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"testing"
)

const (
	headerContentType      = "Content-Type"
	errSetEnvFmt           = "set env: %v"
	pathUpload             = "/upload"
	fmtExpected200WithBody = "expected 200 got %d body=%s"
)

type storedObject struct {
	data []byte
	ct   string
}
type mockStorage struct {
	mu      sync.RWMutex
	buckets map[string]map[string]storedObject
}

func newMockStorage() *mockStorage {
	return &mockStorage{buckets: make(map[string]map[string]storedObject)}
}
func (m *mockStorage) bucketExists(bucket string) bool { _, ok := m.buckets[bucket]; return ok }
func (m *mockStorage) createBucket(bucket string) {
	if !m.bucketExists(bucket) {
		m.buckets[bucket] = make(map[string]storedObject)
	}
}
func (m *mockStorage) putObject(bucket, object string, data []byte, ct string) {
	m.buckets[bucket][object] = storedObject{data: data, ct: ct}
}
func (m *mockStorage) getObject(bucket, object string) (storedObject, bool) {
	o, ok := m.buckets[bucket][object]
	return o, ok
}
func (m *mockStorage) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/")
	parts := strings.Split(path, "/")
	if len(parts) == 0 || parts[0] == "" {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	bucket := parts[0]
	object := ""
	if len(parts) > 1 {
		object = strings.Join(parts[1:], "/")
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	switch r.Method {
	case http.MethodHead:
		if m.bucketExists(bucket) {
			w.WriteHeader(http.StatusOK)
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	case http.MethodPut:
		if object == "" {
			m.createBucket(bucket)
			w.WriteHeader(http.StatusOK)
		} else if m.bucketExists(bucket) {
			body, _ := io.ReadAll(r.Body)
			m.putObject(bucket, object, body, r.Header.Get(headerContentType))
			w.WriteHeader(http.StatusOK)
		} else {
			w.WriteHeader(http.StatusNotFound)
		}
	case http.MethodGet:
		if object == "" && r.URL.RawQuery == "location=" {
			if m.bucketExists(bucket) {
				w.WriteHeader(http.StatusOK)
				w.Write([]byte("<LocationConstraint>us-east-1</LocationConstraint>"))
			} else {
				w.WriteHeader(http.StatusNotFound)
			}
			return
		}
		if !m.bucketExists(bucket) {
			w.WriteHeader(http.StatusNotFound)
			return
		}
		obj, ok := m.getObject(bucket, object)
		if !ok {
			w.WriteHeader(http.StatusNotFound)
			return
		}
		if obj.ct != "" {
			w.Header().Set(headerContentType, obj.ct)
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(obj.data)
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

// helper to create multipart body
func createMultipartBody(t *testing.T, fieldName, filename string, content []byte, extraFields map[string]string) (string, *bytes.Buffer) {
	var b bytes.Buffer
	w := multipart.NewWriter(&b)
	fw, err := w.CreateFormFile(fieldName, filename)
	if err != nil {
		t.Fatalf("CreateFormFile error: %v", err)
	}
	if _, err := fw.Write(content); err != nil {
		t.Fatalf("writing file content failed: %v", err)
	}
	for k, v := range extraFields {
		if err := w.WriteField(k, v); err != nil {
			t.Fatalf("WriteField error: %v", err)
		}
	}
	_ = w.Close()
	return w.FormDataContentType(), &b
}

func setupEnv(t *testing.T, endpoint string) {
	if err := os.Setenv("LOCAL_IP", endpoint); err != nil {
		t.Fatalf("set env: %v", err)
	}
	if err := os.Setenv("ACCESS_KEY", "dummy"); err != nil {
		t.Fatalf("set env: %v", err)
	}
	if err := os.Setenv("SECRET_KEY", "dummy"); err != nil {
		t.Fatalf("set env: %v", err)
	}
}

func TestUploadFileSuccess(t *testing.T) {
	storage := newMockStorage()
	server := httptest.NewServer(storage)
	defer server.Close()

	setupEnv(t, strings.TrimPrefix(server.URL, "http://"))

	contentType, body := createMultipartBody(t, "file", "test.txt", []byte("hello world"), nil)
	req := httptest.NewRequest(http.MethodPost, "/upload", body)
	req.Header.Set("Content-Type", contentType)
	w := httptest.NewRecorder()

	uploadFile(w, req)
	res := w.Result()
	if res.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(res.Body)
		res.Body.Close()
		t.Fatalf("expected 200 got %d body=%s", res.StatusCode, string(b))
	}
	respBody, _ := io.ReadAll(res.Body)
	res.Body.Close()
	bodyStr := string(respBody)
	if !strings.Contains(bodyStr, "test.txt") || !strings.Contains(bodyStr, "File uploaded successfully") {
		t.Fatalf("unexpected response body: %s", bodyStr)
	}
	// verify object stored
	storage.mu.RLock()
	_, ok := storage.buckets["sarvesh"]["test.txt"]
	storage.mu.RUnlock()
	if !ok {
		t.Fatalf("file not stored in mock storage")
	}
}

func TestUploadFileWithMetadata(t *testing.T) {
	storage := newMockStorage()
	server := httptest.NewServer(storage)
	defer server.Close()

	setupEnv(t, strings.TrimPrefix(server.URL, "http://"))

	meta := map[string]any{"version": "1", "originalFilename": "orig.txt"}
	metaJSON, _ := json.Marshal(meta)
	contentType, body := createMultipartBody(t, "file", "encrypted.dat", []byte("encdata"), map[string]string{"metadata": string(metaJSON)})
	req := httptest.NewRequest(http.MethodPost, "/upload", body)
	req.Header.Set("Content-Type", contentType)
	w := httptest.NewRecorder()

	uploadFile(w, req)
	res := w.Result()
	if res.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(res.Body)
		res.Body.Close()
		t.Fatalf("expected 200 got %d body=%s", res.StatusCode, string(b))
	}
	res.Body.Close()
	storage.mu.RLock()
	_, okFile := storage.buckets["sarvesh"]["encrypted.dat"]
	_, okMeta := storage.buckets["sarvesh"]["encrypted.dat.metadata.json"]
	storage.mu.RUnlock()
	if !okFile || !okMeta {
		t.Fatalf("expected both file and metadata stored; got file=%v metadata=%v", okFile, okMeta)
	}
}

func TestUploadFileMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/upload", nil)
	w := httptest.NewRecorder()
	uploadFile(w, req)
	res := w.Result()
	if res.StatusCode != http.StatusMethodNotAllowed {
		res.Body.Close()
		t.Fatalf("expected 405 got %d", res.StatusCode)
	}
	res.Body.Close()
}

func TestDownloadFileSuccess(t *testing.T) {
	storage := newMockStorage()
	server := httptest.NewServer(storage)
	defer server.Close()
	setupEnv(t, strings.TrimPrefix(server.URL, "http://"))

	// Ensure bucket exists by creating it via bucket PUT request
	storage.mu.Lock()
	if _, ok := storage.buckets["sarvesh"]; !ok {
		storage.buckets["sarvesh"] = make(map[string]storedObject)
	}
	// seed object so presigned URL generation doesn't fail due to missing object
	storage.buckets["sarvesh"]["xyz.bin"] = storedObject{data: []byte("dummy"), ct: "application/octet-stream"}
	storage.mu.Unlock()

	req := httptest.NewRequest(http.MethodGet, "/download?filename=xyz.bin", nil)
	w := httptest.NewRecorder()
	downloadFile(w, req)
	res := w.Result()
	if res.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(res.Body)
		res.Body.Close()
		t.Fatalf("expected 200 got %d body=%s", res.StatusCode, string(b))
	}
	respBody, _ := io.ReadAll(res.Body)
	res.Body.Close()
	if !strings.Contains(string(respBody), "xyz.bin") {
		t.Fatalf("presigned URL does not contain filename: %s", string(respBody))
	}
}

func TestDownloadFileMissingFilename(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/download", nil)
	w := httptest.NewRecorder()
	downloadFile(w, req)
	res := w.Result()
	if res.StatusCode != http.StatusBadRequest {
		res.Body.Close()
		t.Fatalf("expected 400 got %d", res.StatusCode)
	}
	res.Body.Close()
}

func TestUploadFileSizeExceed(t *testing.T) {
	storage := newMockStorage()
	server := httptest.NewServer(storage)
	defer server.Close()

	setupEnv(t, strings.TrimPrefix(server.URL, "http://"))

	// Create a file larger than 1GB
	largeContent := make([]byte, (1<<30)+1) // 1GB + 1 byte
	contentType, body := createMultipartBody(t, "file", "largefile.dat", largeContent, nil)
	req := httptest.NewRequest(http.MethodPost, "/upload", body)
	req.Header.Set("Content-Type", contentType)
	w := httptest.NewRecorder()

	uploadFile(w, req)
	res := w.Result()
	if res.StatusCode != http.StatusBadRequest {
		b, _ := io.ReadAll(res.Body)
		res.Body.Close()
		t.Fatalf("expected 400 got %d body=%s", res.StatusCode, string(b))
	}
	res.Body.Close()
}

type mockMultipartFile struct {
	*bytes.Reader
}

func (m *mockMultipartFile) Close() error {
	return nil
}

func TestValidateFileSize(t *testing.T) {
	maxFileSize := int64(1 << 30) // 1 GB

	tests := []struct {
		contentSize int64
		wantErr     bool
	}{
		{100, false},
		{maxFileSize - 1, false},
		{maxFileSize, false},
		{maxFileSize + 1, true},
	}

	for _, tt := range tests {
		file := &mockMultipartFile{bytes.NewReader(make([]byte, tt.contentSize))}
		err := validateFileSize(file, maxFileSize)
		if (err != nil) != tt.wantErr {
			t.Errorf("validateFileSize(contentSize=%d, maxFileSize=%d) error = %v, wantErr %v", tt.contentSize, maxFileSize, err, tt.wantErr)
		}
	}
}

func TestValidateFileExtension(t *testing.T) {
	tests := []struct {
		contentType string
		wantErr     bool
	}{
		{".png", false},
		{".zip", false},
		{".xlsx", true},
		{".docx", false},
		{".doc", false},
		{".xls", true},
		{".ppt", true},
		{".mp4", true},
		{".mpeg", true},
		{".pdf", false},
		{".jpeg", false},
		{".jpg", false},
		{".txt", false},
		{".gif", false},
	}

	for _, tt := range tests {
		filename := "testfile" + tt.contentType
		err := validateFileExtension(filename)
		if (err != nil) != tt.wantErr {
			t.Errorf("validateFileExtension(contentType=%s) error = %v, wantErr %v", tt.contentType, err, tt.wantErr)
		}
	}
}
