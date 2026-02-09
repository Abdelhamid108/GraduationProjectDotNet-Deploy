# Failure Analysis Guide

This document provides detailed diagnosis and resolution steps for common test failures.

---

## How to Read Failure Reports

Each failure in the test report includes:

```json
{
  "id": "endpoint_id",
  "name": "Human-readable test name",
  "endpoint": "METHOD /api/path",
  "status": "FAILED",
  "error": "Error description",
  "diagnosis": "Most likely cause",
  "suggested_fix": "Steps to resolve"
}
```

---

## Failure Categories

### 1. Authentication Failures

#### 401 Unauthorized

| Symptom | Cause | Solution |
|---------|-------|----------|
| `401` on protected endpoint | Token expired | Re-run tests to get fresh token |
| `401` on login | Wrong credentials | Check `config/env.sh` credentials |
| `401` with valid token | Token invalidated | User logged out elsewhere |

**Debug Steps:**
```bash
# Test if credentials are correct
curl -X POST "$BASE_URL/api/Auth/login-user" \
  -H "Content-Type: application/json" \
  -d '{"userName":"your-user","password":"your-pass"}'
```

#### 403 Forbidden

| Symptom | Cause | Solution |
|---------|-------|----------|
| `403` on any endpoint | Role-based access denied | Use user with correct role |
| `403` on admin endpoint | User is not admin | Test with admin account |

---

### 2. Request Failures

#### 400 Bad Request

| Symptom | Cause | Solution |
|---------|-------|----------|
| `400` with validation error | Invalid payload | Check request body format |
| `400` "Null DTO" | Missing request body | Ensure payload is present |
| `400` field error | Missing required field | Add required fields |

**Common Payload Issues:**

```json
// ❌ Wrong
{ "username": "test" }

// ✅ Correct (note: userName with capital N)
{ "userName": "test" }
```

#### 404 Not Found

| Symptom | Cause | Solution |
|---------|-------|----------|
| `404` on all endpoints | Wrong base URL | Verify `--base-url` |
| `404` on specific endpoint | Endpoint removed/renamed | Check API documentation |
| `404` with ID param | Resource doesn't exist | Use valid resource ID |

---

### 3. Server Errors

#### 500 Internal Server Error

| Symptom | Cause | Solution |
|---------|-------|----------|
| `500` on register | File upload issue | Check test image path |
| `500` on any endpoint | Backend exception | Check backend logs |
| `500` intermittent | Database issue | Check DB connection |

**Debug Steps:**
```bash
# Check if backend is healthy
curl "$BASE_URL/api/Auth/TestAuthentication" \
  -H "Authorization: Bearer $TOKEN"
```

#### 502 Bad Gateway

| Symptom | Cause | Solution |
|---------|-------|----------|
| `502` on audio/text endpoints | Gemini API unavailable | External service issue |
| `502` on TTS endpoints | TTS service down | Check TTS container |
| `502` intermittent | Nginx/proxy issue | Check nginx logs |

---

### 4. Rate Limiting

#### 429 Too Many Requests

| Symptom | Cause | Solution |
|---------|-------|----------|
| `429` on login | LoginLimiter (5 req/10s) | Wait 10 seconds |
| `429` on register | RegisterLimiter (5 req/10min) | Wait 10 minutes |
| `429` on any endpoint | Rate limit exceeded | Reduce test frequency |

**Rate Limits Reference:**

| Endpoint | Limit | Window |
|----------|-------|--------|
| Login | 5 requests | 10 seconds |
| Register | 5 requests | 10 minutes |
| Refresh Token | 10 requests | 1 minute |
| Password Reset | 3 requests | 1 hour |
| Gemini (AI) | 10 requests | 1 minute |
| Arabic Translator | 30 requests | 1 minute |

---

### 5. Connection Errors

#### Connection Refused

| Symptom | Cause | Solution |
|---------|-------|----------|
| Cannot connect | Service not running | Start backend |
| Cannot connect | Wrong port | Verify URL port |
| Cannot connect | Firewall blocking | Check firewall rules |

**Debug Steps:**
```bash
# Test basic connectivity
curl -v "$BASE_URL/tts/health"

# Check if port is open (Linux)
nc -zv ema2a.ddns.net 443

# Check DNS resolution
nslookup ema2a.ddns.net
```

#### SSL/TLS Errors

| Symptom | Cause | Solution |
|---------|-------|----------|
| Certificate error | Self-signed cert | Use `curl -k` flag |
| SSL handshake fail | TLS version mismatch | Update curl |
| Certificate expired | Let's Encrypt expired | Renew certificate |

---

### 6. WebSocket Failures

#### SignalR Connection Failed

| Symptom | Cause | Solution |
|---------|-------|----------|
| Negotiation failed | /signHub/negotiate error | Check endpoint path |
| Upgrade failed | Proxy blocking WebSocket | Check nginx config |
| Connection dropped | Server timeout | Increase timeout |

**Debug Steps:**
```bash
# Test SignalR negotiation
curl -X POST "$BASE_URL/signHub/negotiate" \
  -H "Content-Type: application/json"

# Test WebSocket upgrade
websocat -v "wss://ema2a.ddns.net/signHub"
```

#### ProcessFrame Errors

| Symptom | Cause | Solution |
|---------|-------|----------|
| "Invalid image" | Bad base64 data | Check image encoding |
| "No sign detected" | Low confidence | Use clearer image |
| Timeout | Processing too slow | Increase timeout |

---

## Endpoint-Specific Issues

### Audio to Text (Gemini API)

**Common Error:** `502 Bad Gateway`

**Causes:**
1. Gemini API key expired or invalid
2. Rate limit on Gemini API (external)
3. Network connectivity to Google

**Resolution:**
1. Verify `GENERATE_TEXT_FROM_AUDIO_KEY` in backend `.env`
2. Wait and retry (Gemini has strict rate limits)
3. Check https://status.cloud.google.com

---

### Text to Sign

**Common Error:** `500 File not found`

**Causes:**
1. Letter images missing from `/app/Letters/`
2. Dictionary mapping incorrect

**Resolution:**
1. Verify letter images exist in container
2. Check `lettersDictionary` in `StaticDetails`

---

### TTS Service

**Common Error:** `503 Service Unavailable`

**Causes:**
1. TTS container not running
2. Model loading failed (memory issue)

**Resolution:**
```bash
# Check TTS container status
docker ps | grep tts-service

# Check TTS health endpoint
curl "$BASE_URL/tts/health"

# View TTS container logs
docker logs tts-service
```

---

## Quick Diagnostic Commands

```bash
# Full health check
echo "=== Backend Health ==="
curl -s "$BASE_URL/api/Auth/TestAuthentication" || echo "Backend down"

echo "=== TTS Health ==="
curl -s "$BASE_URL/tts/health" | jq . || echo "TTS down"

echo "=== SignalR ==="
curl -s -X POST "$BASE_URL/signHub/negotiate" | jq . || echo "SignalR down"
```

---

## Escalation Path

If you cannot resolve an issue:

1. **Check backend logs**
   ```bash
   docker logs backend
   ```

2. **Check nginx logs**
   ```bash
   docker logs nginx
   ```

3. **Verify environment variables**
   ```bash
   docker exec backend env | grep -E "(KEY|SECRET)"
   ```

4. **Test in isolation**
   - Use Postman/Insomnia for manual testing
   - Compare with test framework results
