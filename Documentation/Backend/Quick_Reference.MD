# API Quick Reference Guide

## Base URL
```
**Base URL:** `https://ema2a.ddnsgeek.com/`
```

## Authentication
```
Authorization: Bearer {access_token}
```

---

## Quick Start

### 1. Register & Login
```bash
# Register
curl -X POST https://api.example.com/api/auth/register-user \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "johndoe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "phoneNumber": "01234567890"
  }'

# Login
curl -X POST https://api.example.com/api/auth/login-user \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "johndoe",
    "password": "SecurePass123!"
  }'
```

### 2. Translate Sign Language
```bash
curl -X POST https://api.example.com/api/signlanguagetranslator \
  -H "Content-Type: application/json" \
  -d '{
    "imageData": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  }'
```

### 3. Text to Sign
```bash
curl -X POST https://api.example.com/api/arabiclanguagetranslator/text-to-sign \
  -H "Content-Type: application/json" \
  -d '{
    "text": "مرحبا بك"
  }'
```

---

## Common Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/auth/register-user` | POST | ❌ | Register new user |
| `/auth/login-user` | POST | ❌ | Login user |
| `/auth/refresh-tokens` | POST | ❌ | Refresh access token |
| `/auth/user-profile` | GET | ✅ | Get user profile |
| `/auth/logout` | POST | ✅ | Logout user |
| `/signlanguagetranslator` | POST | ❌ | Detect sign language |
| `/signlanguagetranslator/finalize-sentence` | POST | ❌ | Finalize Arabic sentence |
| `/signlanguagetranslator/text-to-audio` | POST | ❌ | Convert text to audio |
| `/arabiclanguagetranslator/text-to-sign` | POST | ❌ | Convert text to sign images |
| `/arabiclanguagetranslator/audio-to-text` | POST | ❌ | Transcribe Arabic audio |
| `/userhistory/get-user-history` | GET | ✅ | Get translation history |
| `/userhistory/delete-all-user-history` | DELETE | ✅ | Clear history |

---

## Response Structure

### Success
```json
{
  "success": true,
  "data": { /* result */ },
  "statusCode": 200,
  "errorMessage": null
}
```

### Error
```json
{
  "success": false,
  "data": null,
  "statusCode": 400,
  "errorMessage": "Error description"
}
```

---

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad Request |
| 401 | Unauthorized |
| 429 | Rate Limited |
| 500 | Server Error |
| 502 | External API Error |

---

## Rate Limits

Most endpoints have rate limiting. When exceeded, you'll receive:
```json
{
  "success": false,
  "statusCode": 429,
  "errorMessage": "Rate limit exceeded"
}
```

**Recommended:** Implement exponential backoff for retries.

---

## Authentication Flow

```
1. Register → POST /auth/register-user
2. Login → POST /auth/login-user → Get tokens
3. Use access token in Authorization header
4. When token expires → POST /auth/refresh-tokens
5. Logout → POST /auth/logout
```

---

## Sign Language Translation Flow

```
1. Capture video frame
2. Convert to base64 JPEG
3. POST /signlanguagetranslator
4. Accumulate detected letters
5. POST /signlanguagetranslator/finalize-sentence
6. Optional: POST /signlanguagetranslator/generate-audio
```

---

## Text-to-Sign Flow

```
1. Enter Arabic text
2. POST /arabiclanguagetranslator/text-to-sign
3. Receive array of letter images (base64 PNG)
4. Display images sequentially
```

---

## Audio Transcription Flow

```
1. Record audio
2. Convert to base64
3. POST /arabiclanguagetranslator/audio-to-text
4. Receive transcribed text
```

---

## Common Patterns

### Making Authenticated Requests
```javascript
const token = localStorage.getItem('accessToken');

fetch('https://api.example.com/api/auth/user-profile', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});
```

### Handling Token Expiration
```javascript
async function apiCall(url, options) {
  let response = await fetch(url, options);
  
  if (response.status === 401) {
    // Refresh token
    await refreshTokens();
    // Retry request
    response = await fetch(url, options);
  }
  
  return response;
}
```

### Processing Sign Language Frames
```javascript
// Capture from video
const canvas = document.createElement('canvas');
canvas.width = video.videoWidth;
canvas.height = video.videoHeight;
canvas.getContext('2d').drawImage(video, 0, 0);

const imageData = canvas.toDataURL('image/jpeg');

// Send to API
const response = await fetch('/api/signlanguagetranslator', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ imageData })
});
```

---

## Error Handling

### Always Check Success Flag
```javascript
const response = await fetch(url, options);
const data = await response.json();

if (data.success) {
  // Handle success
  console.log(data.data);
} else {
  // Handle error
  console.error(data.errorMessage);
}
```

### Handle Network Errors
```javascript
try {
  const response = await fetch(url, options);
  const data = await response.json();
  // Process data
} catch (error) {
  console.error('Network error:', error);
  // Show user-friendly message
}
```

---

## Best Practices

1. **Token Management**
   - Store tokens securely
   - Refresh before expiration
   - Clear on logout

2. **Rate Limiting**
   - Implement client-side throttling
   - Cache responses when possible
   - Use exponential backoff

3. **Image Processing**
   - Compress images before sending
   - Use appropriate quality settings
   - Handle base64 encoding efficiently

4. **Error Handling**
   - Always check response.success
   - Display user-friendly messages
   - Log errors for debugging

5. **Performance**
   - Minimize API calls
   - Implement request cancellation
   - Use appropriate timeouts

---

## Testing with cURL

### Register User
```bash
curl -X POST http://localhost:5000/api/auth/register-user \
  -H "Content-Type: application/json" \
  -d '{"userName":"testuser","email":"test@example.com","password":"Test123!","phoneNumber":"01234567890"}'
```

### Login
```bash
curl -X POST http://localhost:5000/api/auth/login-user \
  -H "Content-Type: application/json" \
  -d '{"userName":"testuser","password":"Test123!"}'
```

### Get Profile (with token)
```bash
curl -X GET http://localhost:5000/api/auth/user-profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Finalize Sentence
```bash
curl -X POST http://localhost:5000/api/signlanguagetranslator/finalize-sentence \
  -H "Content-Type: application/json" \
  -d '{"sentence":"مرحبابك"}'
```

---

## Troubleshooting

### Issue: 401 Unauthorized
**Solution:** Check if token is valid and included in Authorization header

### Issue: 429 Rate Limited
**Solution:** Implement exponential backoff and reduce request frequency

### Issue: 400 Bad Request
**Solution:** Validate request body matches expected DTOs

### Issue: 500 Internal Server Error
**Solution:** Check server logs, verify all required services are running

### Issue: Image detection not working
**Solution:** 
- Ensure image is base64-encoded JPEG
- Check image quality and lighting
- Verify hand is clearly visible
- Confidence threshold is 0.71

---

## Support Resources

- **Full Documentation:** [API_DOCUMENTATION.md](./API_DOCUMENTATION.md)
- **OpenAPI Spec:** [openapi.yaml](./openapi.yaml)
- **GitHub Issues:** https://github.com/Abdelhamid108/GraduationProjectDotNet-Deploy/issues

---

## Code Examples Repository

For complete working examples in various languages, visit:
- JavaScript/TypeScript examples
- C# examples
- Python examples
- Mobile (React Native) examples

---

**Last Updated:** January 30, 2026