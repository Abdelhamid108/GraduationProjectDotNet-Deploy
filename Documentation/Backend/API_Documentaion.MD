# Graduation Project Web API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Base Response Structure](#base-response-structure)
4. [Rate Limiting](#rate-limiting)
5. [API Endpoints](#api-endpoints)
   - [Authentication Controller](#authentication-controller)
   - [Sign Language Translator Controller](#sign-language-translator-controller)
   - [Arabic Language Translator Controller](#arabic-language-translator-controller)
   - [User History Controller](#user-history-controller)
6. [Data Transfer Objects (DTOs)](#data-transfer-objects-dtos)
7. [Error Handling](#error-handling)

---

## Overview

This API provides comprehensive sign language translation services, including real-time sign-to-text translation, text-to-sign conversion, and Arabic language processing capabilities. The API is built using ASP.NET Core and follows RESTful conventions.

**Base URL:** `https://ema2a.ddnsgeek.com/`

**API Version:** 1.0

**Content-Type:** `application/json` (except for file uploads)

---

## Authentication

The API uses JWT (JSON Web Token) bearer authentication. Most endpoints require a valid access token.

### Authentication Flow
1. Register a new user or login with existing credentials
2. Receive an access token and refresh token
3. Include the access token in the `Authorization` header for protected endpoints
4. Use the refresh token to obtain new access tokens when they expire

**Header Format:**
```
Authorization: Bearer {your_access_token}
```

### Token Refresh
Access tokens expire after a certain period. Use the refresh token endpoint to obtain new tokens without re-authenticating.

---

## Base Response Structure

All API responses follow a standardized structure:

### Success Response
```json
{
  "success": true,
  "data": { /* response data */ },
  "statusCode": 200,
  "errorMessage": null
}
```

### Error Response
```json
{
  "success": false,
  "data": null,
  "statusCode": 400,
  "errorMessage": "Error description"
}
```

### HTTP Status Codes
- **200 OK**: Request succeeded
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Authentication required or invalid token
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server-side error

---

## Rate Limiting

The API implements rate limiting on various endpoints to ensure fair usage:

| Limiter | Endpoints | Purpose |
|---------|-----------|---------|
| RegisterLimiter | `/api/auth/register-user` | User registration |
| LoginLimiter | `/api/auth/login-user` | User login |
| RefreshTokenLimiter | `/api/auth/refresh-tokens` | Token refresh |
| GetResetPasswordLimiter | `/api/auth/get-reset-password-token` | Password reset request |
| ResetPasswordLimiter | `/api/auth/reset-password` | Password reset |
| GoogleLoginLimiter | `/api/auth/login-google` | Google OAuth login |
| GoogleCallbackLimiter | `/api/auth/google-callback` | Google OAuth callback |
| UpdateImageLimiter | `/api/auth/update-user-image` | Profile image update |
| LogoutLimiter | `/api/auth/logout` | User logout |
| UserProfileReadLimiter | `/api/auth/user-profile` | Profile retrieval |
| UserProfileUpdateLimiter | `/api/auth/update-user-profile` | Profile update |
| GeminiLimiter | Sign translation & audio endpoints | AI model operations |
| ArabicLimiter | Arabic translation endpoints | Arabic text processing |

When rate limited, you'll receive a `429 Too Many Requests` status code.

---

## API Endpoints

### Authentication Controller
**Base Route:** `/api/auth`

#### 1. Register User
Create a new user account.

**Endpoint:** `POST /api/auth/register-user`

**Rate Limit:** RegisterLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "userName": "string",
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "phoneNumber": "01234567890"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "user-guid",
    "userName": "string",
    "email": "user@example.com",
    "phoneNumber": "01234567890",
    "profilePictureUrl": "https://..."
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: Validation error or user already exists
- `500 Internal Server Error`: Server error

---

#### 2. Login User
Authenticate and receive access tokens.

**Endpoint:** `POST /api/auth/login-user`

**Rate Limit:** LoginLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "userName": "string",
  "password": "SecurePassword123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "refresh-token-string",
    "expiresAt": "2024-01-30T12:00:00Z"
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: Invalid credentials
- `500 Internal Server Error`: Server error

---

#### 3. Refresh Tokens
Obtain new access tokens using a refresh token.

**Endpoint:** `POST /api/auth/refresh-tokens`

**Rate Limit:** RefreshTokenLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "accessToken": "expired-access-token",
  "refreshToken": "valid-refresh-token"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "new-access-token",
    "refreshToken": "new-refresh-token",
    "expiresAt": "2024-01-30T12:00:00Z"
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid refresh token
- `500 Internal Server Error`: Server error

---

#### 4. Get Reset Password Token
Request a password reset OTP via email.

**Endpoint:** `POST /api/auth/get-reset-password-token`

**Rate Limit:** GetResetPasswordLimiter

**Authentication:** Not required

**Query Parameters:**
- `Email` (string, required): User's email address

**Request:**
```
POST /api/auth/get-reset-password-token?Email=user@example.com
```

**Success Response (200):**
```json
{
  "success": true,
  "data": true,
  "statusCode": 200,
  "errorMessage": null
}
```

**Note:** An email containing a 6-digit OTP will be sent to the user. The OTP expires in 10 minutes.

**Error Responses:**
- `400 Bad Request`: Invalid email or user not found
- `500 Internal Server Error`: Email service error or server error

---

#### 5. Reset Password
Reset password using the OTP received via email.

**Endpoint:** `POST /api/auth/reset-password`

**Rate Limit:** ResetPasswordLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456",
  "newPassword": "NewSecurePassword123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": true,
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: Invalid OTP, expired OTP, or validation error
- `500 Internal Server Error`: Server error

---

#### 6. Login with Google
Initiate Google OAuth authentication.

**Endpoint:** `GET /api/auth/login-google`

**Rate Limit:** GoogleLoginLimiter

**Authentication:** Not required

**Response:** Redirects to Google authentication page

**Usage:** Navigate user to this endpoint in a browser to start Google OAuth flow.

---

#### 7. Google OAuth Callback
Handle Google OAuth callback and create/login user.

**Endpoint:** `GET /api/auth/google-callback`

**Rate Limit:** GoogleCallbackLimiter

**Authentication:** Not required (handled by OAuth)

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "userId": "user-guid",
    "accessToken": "jwt-access-token",
    "refreshToken": "refresh-token-string",
    "isNewUser": true
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `401 Unauthorized`: External authentication failed
- `400 Bad Request`: JWT token not issued
- `500 Internal Server Error`: Server error

---

#### 8. Update User Image
Update user profile picture.

**Endpoint:** `POST /api/auth/update-user-image`

**Rate Limit:** UpdateImageLimiter

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Request Body:**
- `newImge` (file, required): Image file to upload

**Success Response (200):**
```json
{
  "success": true,
  "data": "https://path-to-uploaded-image.jpg",
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: No image provided or invalid image
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Upload or server error

---

#### 9. Logout
Invalidate the current refresh token.

**Endpoint:** `POST /api/auth/logout`

**Rate Limit:** LogoutLimiter

**Authentication:** Required

**Request Body:**
```json
{
  "accessToken": "current-access-token",
  "refreshToken": "current-refresh-token"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": true,
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: Invalid token
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Server error

---

#### 10. Get User Profile
Retrieve the authenticated user's profile information.

**Endpoint:** `GET /api/auth/user-profile`

**Rate Limit:** UserProfileReadLimiter

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "user-guid",
    "userName": "username",
    "email": "user@example.com",
    "phoneNumber": "01234567890",
    "profilePictureUrl": "https://...",
    "createdAt": "2024-01-01T00:00:00Z"
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: User not found
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Server error

---

#### 11. Update User Profile
Update user profile information.

**Endpoint:** `POST /api/auth/update-user-profile`

**Rate Limit:** UserProfileUpdateLimiter

**Authentication:** Required

**Request Body:**
```json
{
  "userName": "newUsername",
  "email": "newemail@example.com",
  "phoneNumber": "01234567890"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "user-guid",
    "userName": "newUsername",
    "email": "newemail@example.com",
    "phoneNumber": "01234567890",
    "profilePictureUrl": "https://...",
    "createdAt": "2024-01-01T00:00:00Z"
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: Validation error or duplicate username/email
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Server error

---

#### 12. Test Authentication
Test endpoint to verify authentication is working.

**Endpoint:** `GET /api/auth/TestAuthentication`

**Authentication:** Required

**Success Response (200):**
```
"You Are Authenticated"
```

**Error Responses:**
- `401 Unauthorized`: Not authenticated

---

### Sign Language Translator Controller
**Base Route:** `/api/signlanguagetranslator`

This controller handles real-time sign language detection, sentence finalization, and audio generation.

#### 1. Translate Sign
Detect and translate sign language from an image frame.

**Endpoint:** `POST /api/signlanguagetranslator`

**Rate Limit:** None specified (may have server-side limits)

**Authentication:** Not required

**Request Body:**
```json
{
  "imageData": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "translation": "ا"
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Detection Response Examples:**
- High confidence detection: `{"translation": "ا"}`
- Low confidence: `{"translation": "No sign detected (try adjusting your gesture)."}`
- No detection: `{"translation": "No sign detected."}`

**Notes:**
- Image must be base64-encoded JPEG
- Minimum confidence threshold: 0.71
- Returns the Arabic letter with highest confidence
- Processes images using ML model for sign detection

**Error Responses:**
- `400 Bad Request`: No image data, invalid base64, or model detection failed
- `500 Internal Server Error`: Processing error

---

#### 2. Finalize Sentence
Process concatenated Arabic letters into a coherent sentence with proper spacing and corrections.

**Endpoint:** `POST /api/signlanguagetranslator/finalize-sentence`

**Rate Limit:** GeminiLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "sentence": "مرحبابكفيتطبيقنا"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": "مرحبا بك في تطبيقنا",
  "statusCode": 200,
  "errorMessage": null
}
```

**Notes:**
- Uses Gemini AI to intelligently add spaces and correct spelling
- Optimized for sign language translator output
- Processes Arabic text only

**Error Responses:**
- `400 Bad Request`: No sentence data provided
- `500 Internal Server Error`: Gemini API error or processing error

---

#### 3. Generate Audio
Convert finalized sentence to speech audio.

**Endpoint:** `POST /api/signlanguagetranslator/generate-audio`

**Rate Limit:** GeminiLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "sentence": "مرحبا بك في تطبيقنا"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "audioData": "base64-encoded-audio-data...",
    "sampleRate": 24000
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Audio Format:**
- Encoding: Base64
- Format: PCM/WAV
- Sample Rate: Typically 24000 Hz
- Voice: Kore (Gemini TTS voice)

**Notes:**
- Requires finalized sentence (with proper spacing)
- Uses Gemini Text-to-Speech API
- Returns base64-encoded audio data

**Error Responses:**
- `400 Bad Request`: Missing sentence field or empty sentence
- `500 Internal Server Error`: Gemini API error or processing error

---

#### 4. Text to Audio (Combined)
Finalize a concatenated sentence and generate audio in a single request.

**Endpoint:** `POST /api/signlanguagetranslator/text-to-audio`

**Rate Limit:** GeminiLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "sentence": "مرحبابكفيتطبيقنا"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "audioData": "base64-encoded-audio-data...",
    "sampleRate": 24000
  },
  "statusCode": 200,
  "errorMessage": null
}
```

**Process:**
1. Receives concatenated Arabic letters
2. Finalizes sentence using Gemini (adds spaces, corrects spelling)
3. Generates audio from finalized sentence
4. Returns audio data

**Notes:**
- Combines finalize-sentence and generate-audio operations
- More efficient for end-to-end conversion
- Two sequential Gemini API calls

**Error Responses:**
- `400 Bad Request`: Missing sentence field
- `500 Internal Server Error`: API communication error or processing error

---

### Arabic Language Translator Controller
**Base Route:** `/api/arabiclanguagetranslator`

This controller provides Arabic text-to-sign conversion and audio transcription services.

#### 1. Text to Sign
Convert Arabic text to sign language letter images.

**Endpoint:** `POST /api/arabiclanguagetranslator/text-to-sign`

**Rate Limit:** ArabicLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "text": "مرحبا بك"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    [
      "data:image/png;base64,iVBORw0KGgoAAAANS...",
      "data:image/png;base64,iVBORw0KGgoAAAANS...",
      "data:image/png;base64,iVBORw0KGgoAAAANS...",
      "data:image/png;base64,iVBORw0KGgoAAAANS...",
      "data:image/png;base64,iVBORw0KGgoAAAANS..."
    ],
    [
      "data:image/png;base64,iVBORw0KGgoAAAANS...",
      "data:image/png;base64,iVBORw0KGgoAAAANS..."
    ]
  ],
  "statusCode": 200,
  "errorMessage": null
}
```

**Response Structure:**
- Outer array: Contains arrays for each word
- Inner arrays: Contains base64 PNG images for each letter in the word
- Images are sign language representations of Arabic letters

**Notes:**
- Splits text by spaces to separate words
- Each letter is mapped to a corresponding sign language image
- Letters not in dictionary are skipped (logged on server)
- Returns base64-encoded PNG images

**Error Responses:**
- `400 Bad Request`: No text provided or empty text
- `500 Internal Server Error`: File reading error or processing error

---

#### 2. Audio to Text
Transcribe Arabic speech from audio to text.

**Endpoint:** `POST /api/arabiclanguagetranslator/audio-to-text`

**Rate Limit:** GeminiLimiter

**Authentication:** Not required

**Request Body:**
```json
{
  "audioData": "base64-encoded-audio-data",
  "mimeType": "audio/wav"
}
```

**Supported Audio Formats:**
- `audio/wav`
- `audio/mp3`
- `audio/mpeg`
- `audio/ogg`
- Other formats supported by Gemini API

**Success Response (200):**
```json
{
  "success": true,
  "data": "مرحبا بك في تطبيقنا",
  "statusCode": 200,
  "errorMessage": null
}
```

**Notes:**
- Uses Gemini 2.5 Flash Preview model for transcription
- Optimized for Arabic speech recognition
- Filters out non-speech sounds and background noise
- Audio should be base64-encoded

**Error Responses:**
- `400 Bad Request`: Audio data or MIME type not provided
- `502 Bad Gateway`: Error calling Gemini API (network issues)
- `500 Internal Server Error`: JSON parsing error or unexpected error

---

#### 3. Letters Keyboard
Get sign language image for a specific Arabic letter.

**Endpoint:** `GET /api/arabiclanguagetranslator/letters-keyboard`

**Rate Limit:** ArabicLimiter

**Authentication:** Not required

**Query Parameters:**
- `letter` (char, required): Single Arabic letter

**Request:**
```
GET /api/arabiclanguagetranslator/letters-keyboard?letter=ا
```

**Success Response (200):**
```json
{
  "success": true,
  "data": "data:image/png;base64,iVBORw0KGgoAAAANS...",
  "statusCode": 200,
  "errorMessage": null
}
```

**Notes:**
- Returns a single base64-encoded PNG image
- Useful for keyboard/input interfaces showing sign language letters
- Letter must exist in the sign language dictionary

**Error Responses:**
- `400 Bad Request`: Letter parameter missing or letter not found in dictionary
- `500 Internal Server Error`: File reading error or processing error

---

### User History Controller
**Base Route:** `/api/userhistory`

This controller manages user's translation history records.

#### 1. Get User History
Retrieve all history records for the authenticated user.

**Endpoint:** `GET /api/userhistory/get-user-history`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "formedSentence": "مرحبا بك في تطبيقنا",
      "formedAt": "2024-01-30T10:30:00Z"
    },
    {
      "id": 2,
      "formedSentence": "كيف حالك",
      "formedAt": "2024-01-30T11:45:00Z"
    }
  ],
  "statusCode": 200,
  "errorMessage": null
}
```

**Notes:**
- Returns all history records for the authenticated user
- Ordered by creation time
- Each record includes sentence and timestamp

**Error Responses:**
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Database or server error

---

#### 2. Delete User History Record
Delete a specific history record by ID.

**Endpoint:** `DELETE /api/userhistory/delete-user-history-record`

**Authentication:** Required

**Request Body:**
```json
{
  "id": 1
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": true,
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: Null record or ID is 0, or record not found
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Database or server error

---

#### 3. Delete All User History
Delete all history records for the authenticated user.

**Endpoint:** `DELETE /api/userhistory/delete-all-user-history`

**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": true,
  "statusCode": 200,
  "errorMessage": null
}
```

**Error Responses:**
- `400 Bad Request`: No records found to delete
- `401 Unauthorized`: Not authenticated
- `500 Internal Server Error`: Database or server error

---

## Data Transfer Objects (DTOs)

### Authentication DTOs

#### RegisterDTO
```json
{
  "userName": "string",
  "email": "string",
  "password": "string",
  "phoneNumber": "string"
}
```

#### LoginDTO
```json
{
  "userName": "string",
  "password": "string"
}
```

#### TokenRequestDTO
```json
{
  "accessToken": "string",
  "refreshToken": "string"
}
```

#### TokenResponseDTO
```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "expiresAt": "datetime"
}
```

#### ApplicationUserDTO
```json
{
  "id": "string",
  "userName": "string",
  "email": "string",
  "phoneNumber": "string",
  "profilePictureUrl": "string"
}
```

#### ResetPasswordDTO
```json
{
  "email": "string",
  "otp": "string",
  "newPassword": "string"
}
```

#### ResetPasswordTokenDTO
```json
{
  "userName": "string",
  "otp": "string"
}
```

#### ExternalLoginDTO
```json
{
  "provider": "string",
  "providerUserId": "string",
  "email": "string",
  "name": "string",
  "phoneNumber": "string"
}
```

#### ExternalLoginResponseDTO
```json
{
  "userId": "string",
  "accessToken": "string",
  "refreshToken": "string",
  "isNewUser": "boolean"
}
```

#### UserProfileDTO
```json
{
  "id": "string",
  "userName": "string",
  "email": "string",
  "phoneNumber": "string",
  "profilePictureUrl": "string",
  "createdAt": "datetime"
}
```

#### UpdateUserProfileDTO
```json
{
  "userName": "string",
  "email": "string",
  "phoneNumber": "string"
}
```

### Translation DTOs

#### FrameData
```json
{
  "imageData": "string (base64)"
}
```

#### SentenceData
```json
{
  "sentence": "string"
}
```

#### TextToSignDTO
```json
{
  "text": "string"
}
```

#### TranscriptionRequest
```json
{
  "audioData": "string (base64)",
  "mimeType": "string"
}
```

#### TTSResponse
```json
{
  "audioData": "string (base64)",
  "sampleRate": "integer"
}
```

### History DTOs

#### UserRecordDTO
```json
{
  "id": "integer",
  "formedSentence": "string",
  "formedAt": "datetime"
}
```

#### DeleteUserRecordDTO
```json
{
  "id": "integer"
}
```

### Base Response DTO

#### APIResponseDTO<T>
```json
{
  "success": "boolean",
  "data": "T (generic type)",
  "statusCode": "HttpStatusCode (integer)",
  "errorMessage": "string | null"
}
```

---

## Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "data": null,
  "statusCode": 400,
  "errorMessage": "Descriptive error message"
}
```

### Common Error Scenarios

#### 1. Authentication Errors
**Status Code:** 401 Unauthorized
```json
{
  "success": false,
  "data": null,
  "statusCode": 401,
  "errorMessage": "Invalid credentials" 
}
```

#### 2. Validation Errors
**Status Code:** 400 Bad Request
```json
{
  "success": false,
  "data": null,
  "statusCode": 400,
  "errorMessage": "Null DTO"
}
```

#### 3. Rate Limit Errors
**Status Code:** 429 Too Many Requests
- Server responds with rate limit exceeded message
- Client should implement exponential backoff

#### 4. Server Errors
**Status Code:** 500 Internal Server Error
```json
{
  "success": false,
  "data": null,
  "statusCode": 500,
  "errorMessage": "An unexpected error occurred"
}
```

#### 5. External API Errors
**Status Code:** 502 Bad Gateway
```json
{
  "success": false,
  "data": null,
  "statusCode": 502,
  "errorMessage": "Error calling Gemini API: [details]"
}
```

### Error Logging
- All errors are logged on the server with detailed information
- Client receives sanitized error messages
- Sensitive information is never exposed in error responses

---

## Best Practices

### 1. Authentication
- Store tokens securely (never in localStorage for production apps)
- Implement automatic token refresh before expiration
- Handle 401 errors by redirecting to login
- Clear tokens on logout

### 2. Rate Limiting
- Implement client-side rate limiting to avoid hitting API limits
- Cache responses where appropriate
- Use exponential backoff for retries

### 3. Image Processing
- Compress images before sending to reduce payload size
- Use appropriate image quality for sign language detection
- Handle base64 encoding/decoding efficiently

### 4. Error Handling
- Always check the `success` field in responses
- Display user-friendly error messages
- Implement proper error logging on client side
- Handle network errors gracefully

### 5. Performance
- Use pagination for large datasets (when available)
- Implement request cancellation for long-running operations
- Cache frequently accessed data
- Minimize redundant API calls

---

## Integration Examples

### Example 1: User Registration and Login Flow

```javascript
// 1. Register
const registerResponse = await fetch('https://api.example.com/api/auth/register-user', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    userName: 'johndoe',
    email: 'john@example.com',
    password: 'SecurePass123!',
    phoneNumber: '01234567890'
  })
});

const registerData = await registerResponse.json();

if (registerData.success) {
  console.log('User registered:', registerData.data);
  
  // 2. Login
  const loginResponse = await fetch('https://api.example.com/api/auth/login-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userName: 'johndoe',
      password: 'SecurePass123!'
    })
  });
  
  const loginData = await loginResponse.json();
  
  if (loginData.success) {
    // Store tokens
    localStorage.setItem('accessToken', loginData.data.accessToken);
    localStorage.setItem('refreshToken', loginData.data.refreshToken);
  }
}
```

### Example 2: Real-time Sign Language Translation

```javascript
// Capture frame from video
const canvas = document.createElement('canvas');
const context = canvas.getContext('2d');
canvas.width = video.videoWidth;
canvas.height = video.videoHeight;
context.drawImage(video, 0, 0);

// Convert to base64
const imageData = canvas.toDataURL('image/jpeg');

// Send to API
const response = await fetch('https://api.example.com/api/signlanguagetranslator', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ imageData })
});

const result = await response.json();

if (result.success) {
  console.log('Detected sign:', result.data.translation);
  // Append to sentence
  currentSentence += result.data.translation;
}
```

### Example 3: Text to Sign Conversion

```javascript
const response = await fetch('https://api.example.com/api/arabiclanguagetranslator/text-to-sign', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: 'مرحبا بك'
  })
});

const result = await response.json();

if (result.success) {
  // result.data is array of arrays
  // Each inner array represents a word
  result.data.forEach((word, wordIndex) => {
    console.log(`Word ${wordIndex + 1}:`);
    word.forEach((letterImage, letterIndex) => {
      // Display letterImage (base64 PNG)
      const img = document.createElement('img');
      img.src = letterImage;
      document.body.appendChild(img);
    });
  });
}
```

### Example 4: Audio Transcription

```javascript
// Record audio and convert to base64
const audioBlob = await recordAudio();
const reader = new FileReader();

reader.onloadend = async () => {
  const base64Audio = reader.result.split(',')[1];
  
  const response = await fetch('https://api.example.com/api/arabiclanguagetranslator/audio-to-text', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      audioData: base64Audio,
      mimeType: 'audio/wav'
    })
  });
  
  const result = await response.json();
  
  if (result.success) {
    console.log('Transcribed text:', result.data);
  }
};

reader.readAsDataURL(audioBlob);
```

### Example 5: Token Refresh

```javascript
async function refreshTokens() {
  const accessToken = localStorage.getItem('accessToken');
  const refreshToken = localStorage.getItem('refreshToken');
  
  const response = await fetch('https://api.example.com/api/auth/refresh-tokens', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      accessToken,
      refreshToken
    })
  });
  
  const result = await response.json();
  
  if (result.success) {
    localStorage.setItem('accessToken', result.data.accessToken);
    localStorage.setItem('refreshToken', result.data.refreshToken);
    return result.data.accessToken;
  } else {
    // Redirect to login
    window.location.href = '/login';
  }
}

// Use in API calls
async function makeAuthenticatedRequest(url, options = {}) {
  let token = localStorage.getItem('accessToken');
  
  const response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (response.status === 401) {
    // Token expired, refresh and retry
    token = await refreshTokens();
    return fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${token}`
      }
    });
  }
  
  return response;
}
```

---

## Changelog

### Version 1.0 (Current)
- Initial API release
- User authentication with JWT
- Google OAuth integration
- Real-time sign language detection
- Arabic text-to-sign conversion
- Audio transcription and generation
- User history management
- Comprehensive rate limiting

---

## Support

For API support and questions:
- **Email:** ema2ateam@gmail.com
- **Documentation:** https://docs.example.com
- **GitHub Issues:** https://github.com/Abdelhamid108/GraduationProjectDotNet-Deploy/issues

---

## License

This API documentation is part of a graduation project. Please refer to the repository license for usage terms.

---

**Last Updated:** January 30, 2026
**API Version:** 1.0