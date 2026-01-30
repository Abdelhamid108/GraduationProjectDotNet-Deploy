# Sign Language Translation API Documentation

Complete API documentation for the Graduation Project Sign Language Translation System.

## 📚 Documentation Files

This package includes comprehensive API documentation in multiple formats:

### 1. **API_DOCUMENTATION.md** (Main Documentation)
- **Description:** Complete, detailed API documentation
- **Contents:**
  - Overview and authentication
  - All endpoint specifications with examples
  - Request/response formats
  - Error handling
  - Integration examples
  - Best practices
- **Best for:** Developers who need comprehensive understanding

### 2. **QUICK_REFERENCE.md** (Quick Reference Guide)
- **Description:** Quick lookup reference for common operations
- **Contents:**
  - Quick start guide
  - Common endpoints table
  - Code snippets and cURL examples
  - Troubleshooting guide
- **Best for:** Quick lookups and common operations

### 3. **openapi.yaml** (OpenAPI Specification)
- **Description:** Machine-readable API specification in OpenAPI 3.0 format
- **Contents:**
  - Complete API schema
  - All endpoints with parameters
  - Request/response schemas
  - Security definitions
- **Best for:** 
  - Generating client SDKs
  - API testing tools (Swagger UI, Postman)
  - Automated documentation generation
  - API validation

### 4. **Postman_Collection.json** (Postman Collection)
- **Description:** Ready-to-use Postman collection
- **Contents:**
  - All API endpoints pre-configured
  - Example requests
  - Auto-saving authentication tokens
  - Test scripts
- **Best for:** 
  - Testing API endpoints
  - Debugging
  - Quick API exploration

## 🚀 Quick Start

### For Developers

1. **Read the main documentation:**
   ```
   Start with API_DOCUMENTATION.md for complete understanding
   ```

2. **Import Postman collection:**
   - Open Postman
   - Import `Postman_Collection.json`
   - Set `baseUrl` variable to your API URL
   - Start testing endpoints

3. **Use the OpenAPI spec:**
   ```bash
   # View in Swagger UI
   docker run -p 8080:8080 -e SWAGGER_JSON=/docs/openapi.yaml \
     -v $(pwd):/docs swaggerapi/swagger-ui
   
   # Or use online editor
   # Visit: https://editor.swagger.io
   # Upload openapi.yaml
   ```

### For Quick Lookups

Use `QUICK_REFERENCE.md` for:
- Finding endpoint URLs
- Checking request formats
- Getting code examples
- Troubleshooting common issues

## 📋 API Overview

### Base URL
```
Production: https://api.example.com/api
Development: http://localhost:5000/api
```

### Authentication
Most endpoints require JWT Bearer authentication:
```
Authorization: Bearer {your_access_token}
```

### Main Features
- ✅ User authentication (JWT + Google OAuth)
- ✅ Real-time sign language detection
- ✅ Text-to-sign conversion
- ✅ Arabic speech transcription
- ✅ Text-to-speech generation
- ✅ Translation history management

## 🔗 API Endpoints Summary

| Category | Endpoints Count | Authentication Required |
|----------|----------------|-------------------------|
| Authentication | 11 | Mixed (some public) |
| Sign Language Translation | 4 | Public |
| Arabic Translation | 3 | Public |
| User History | 3 | Required |

## 📖 Key Endpoints

### Authentication
- `POST /auth/register-user` - Register new user
- `POST /auth/login-user` - Login and get tokens
- `POST /auth/refresh-tokens` - Refresh access token
- `GET /auth/user-profile` - Get user profile

### Sign Language
- `POST /signlanguagetranslator` - Detect sign from image
- `POST /signlanguagetranslator/finalize-sentence` - Process detected letters
- `POST /signlanguagetranslator/text-to-audio` - Generate speech

### Arabic Translation
- `POST /arabiclanguagetranslator/text-to-sign` - Convert text to sign images
- `POST /arabiclanguagetranslator/audio-to-text` - Transcribe speech
- `GET /arabiclanguagetranslator/letters-keyboard` - Get letter sign image

### History
- `GET /userhistory/get-user-history` - Get translation history
- `DELETE /userhistory/delete-all-user-history` - Clear history

## 🛠️ Using the Documentation

### Option 1: Read Markdown Files
Simply open any `.md` file in a Markdown viewer or text editor.

### Option 2: Use Swagger UI
View interactive API documentation:
```bash
# Using Docker
docker run -p 8080:8080 -e SWAGGER_JSON=/docs/openapi.yaml \
  -v $(pwd):/docs swaggerapi/swagger-ui

# Access at: http://localhost:8080
```

### Option 3: Import to Postman
1. Open Postman
2. Click "Import"
3. Select `Postman_Collection.json`
4. Configure environment variables
5. Start testing!

### Option 4: Generate Client SDK
Use OpenAPI Generator with `openapi.yaml`:
```bash
# Install OpenAPI Generator
npm install @openapitools/openapi-generator-cli -g

# Generate TypeScript client
openapi-generator-cli generate -i openapi.yaml \
  -g typescript-axios -o ./client

# Generate C# client
openapi-generator-cli generate -i openapi.yaml \
  -g csharp -o ./client

# Generate Python client
openapi-generator-cli generate -i openapi.yaml \
  -g python -o ./client
```

## 🔐 Authentication Flow

```
1. Register → POST /auth/register-user
   ↓
2. Login → POST /auth/login-user
   ↓ (receive access token & refresh token)
3. Use access token in Authorization header
   ↓ (when token expires)
4. Refresh → POST /auth/refresh-tokens
   ↓
5. Logout → POST /auth/logout
```

## 📝 Example Usage

### JavaScript/TypeScript
```javascript
// Login
const response = await fetch('https://api.example.com/api/auth/login-user', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    userName: 'user',
    password: 'pass'
  })
});

const data = await response.json();
const token = data.data.accessToken;

// Use token
fetch('https://api.example.com/api/auth/user-profile', {
  headers: { 'Authorization': `Bearer ${token}` }
});
```

### cURL
```bash
# Login
curl -X POST https://api.example.com/api/auth/login-user \
  -H "Content-Type: application/json" \
  -d '{"userName":"user","password":"pass"}'

# Get profile
curl -X GET https://api.example.com/api/auth/user-profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Python
```python
import requests

# Login
response = requests.post(
    'https://api.example.com/api/auth/login-user',
    json={'userName': 'user', 'password': 'pass'}
)
token = response.json()['data']['accessToken']

# Get profile
headers = {'Authorization': f'Bearer {token}'}
response = requests.get(
    'https://api.example.com/api/auth/user-profile',
    headers=headers
)
```

## 🎯 Common Use Cases

### 1. Real-time Sign Language Detection
```
Capture video frame → Convert to base64 
→ POST /signlanguagetranslator 
→ Accumulate letters → Finalize sentence
```

### 2. Text-to-Sign Learning
```
Enter Arabic text → POST /arabiclanguagetranslator/text-to-sign 
→ Display sign images → Learn signs
```

### 3. Speech-to-Text Translation
```
Record audio → Convert to base64 
→ POST /arabiclanguagetranslator/audio-to-text 
→ Get transcription
```

## ⚠️ Important Notes

### Rate Limiting
- API implements rate limiting on most endpoints
- Implement exponential backoff for retries
- Status code 429 indicates rate limit exceeded

### Image Requirements
- Format: JPEG (base64-encoded with data URI)
- Good lighting and clear hand visibility
- Confidence threshold: 0.71 for detection

### Audio Requirements
- Supported formats: WAV, MP3, MPEG, OGG
- Base64-encoded
- Clear speech without background noise

### Token Management
- Access tokens expire periodically
- Use refresh tokens to get new access tokens
- Store tokens securely (not in localStorage for production)

## 🐛 Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check if token is valid
   - Verify Authorization header format
   - Try refreshing token

2. **429 Rate Limited**
   - Implement request throttling
   - Use exponential backoff
   - Cache responses when possible

3. **400 Bad Request**
   - Validate request body structure
   - Check required fields
   - Ensure correct data types

4. **Sign detection not working**
   - Verify image is base64 JPEG
   - Check lighting and hand visibility
   - Ensure proper gesture formation

## 📞 Support

- **GitHub Repository:** [GraduationProjectDotNet-Deploy](https://github.com/Abdelhamid108/GraduationProjectDotNet-Deploy)
- **Issues:** Report bugs and request features on GitHub
- **Email:** ema2ateam@gmail.com


## 📄 License

This documentation is part of the Graduation Project. Refer to the repository license for terms.

## 🔄 Changelog

### Version 1.0.0 (Current)
- Initial API release
- Complete authentication system
- Sign language detection
- Arabic text processing
- Audio transcription and generation
- User history management

---

## 📚 Additional Resources

- **Main Documentation:** `API_DOCUMENTATION.md` - Start here for comprehensive docs
- **Quick Reference:** `QUICK_REFERENCE.md` - For quick lookups
- **OpenAPI Spec:** `openapi.yaml` - For tools and SDK generation
- **Postman Collection:** `Postman_Collection.json` - For testing

---

**Last Updated:** January 30, 2026  
**Documentation Version:** 1.0.0  
**API Version:** 1.0.0

**Generated by:** Claude API Documentation Generator