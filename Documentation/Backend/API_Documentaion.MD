# Ema2a API Documentation

**Version:** v1  
**Base URL:** `/api`

## Table of Contents

1. [Authentication](#authentication)
2. [API Response Format](#api-response-format)
3. [Endpoints](#endpoints)
   - [Authentication & User Management](#authentication--user-management)
   - [Sign Language Translation](#sign-language-translation)
   - [Arabic Language Translation](#arabic-language-translation)
   - [User History](#user-history)

---

## Authentication

This API uses **Bearer Token** authentication with JWT (JSON Web Tokens).

### How to Authenticate

Include the JWT token in the `Authorization` header of your requests:

```
Authorization: Bearer {your_jwt_token}
```

### Obtaining Tokens

- Register a new user via `/api/Auth/register-user`
- Login via `/api/Auth/login-user` to receive access and refresh tokens
- Use `/api/Auth/refresh-tokens` to obtain new tokens when the access token expires

---

## API Response Format

All API responses follow a standardized format:

```json
{
  "success": true,
  "data": {},
  "errorMessage": null,
  "statusCode": 200
}
```

**Fields:**
- `success` (boolean): Indicates if the request was successful
- `data` (varies): The response payload (type varies by endpoint)
- `errorMessage` (string|null): Error description if `success` is false
- `statusCode` (integer): HTTP status code

---

## Endpoints

### Authentication & User Management

---

#### 1. Register User

**Endpoint:** `/api/Auth/register-user`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not required  
**Content-Type:** `multipart/form-data`

**Description:** Register a new user account with optional profile image.

**Request Parameters (Form Data):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Email | string | Yes | User's email address |
| FullName | string | Yes | User's full name |
| UserName | string | Yes | Unique username |
| Password | string | Yes | User's password |
| PhoneNumber | string | Yes | User's phone number |
| UserImage | file (binary) | No | Profile image file |

**Example Request (cURL):**

```bash
curl -X POST "https://api.example.com/api/Auth/register-user" \
  -H "Content-Type: multipart/form-data" \
  -F "Email=user@example.com" \
  -F "FullName=John Doe" \
  -F "UserName=johndoe" \
  -F "Password=SecurePass123!" \
  -F "PhoneNumber=+1234567890" \
  -F "UserImage=@profile.jpg"
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "email": "string",
    "fullName": "string",
    "userName": "string",
    "phoneNumber": "string",
    "userBase64Image": "string"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "email": "user@example.com",
    "fullName": "John Doe",
    "userName": "johndoe",
    "phoneNumber": "+1234567890",
    "userBase64Image": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 2. Login User

**Endpoint:** `/api/Auth/login-user`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Authenticate user and receive JWT tokens.

**Request Body Schema:**

```json
{
  "userName": "string",
  "password": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/Auth/login-user" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "johndoe",
    "password": "SecurePass123!"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "accessTokenExpires": "2024-01-01T12:00:00Z",
    "refreshTokenExpires": "2024-01-08T12:00:00Z"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "a1b2c3d4e5f6...",
    "accessTokenExpires": "2024-01-01T13:00:00Z",
    "refreshTokenExpires": "2024-01-08T12:00:00Z"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 3. Refresh Tokens

**Endpoint:** `/api/Auth/refresh-tokens`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Obtain new access and refresh tokens using a valid refresh token.

**Request Body Schema:**

```json
{
  "refreshToken": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/Auth/refresh-tokens" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "a1b2c3d4e5f6..."
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "accessTokenExpires": "2024-01-01T12:00:00Z",
    "refreshTokenExpires": "2024-01-08T12:00:00Z"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 4. Get Reset Password Token

**Endpoint:** `/api/Auth/get-reset-password-token`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Request a password reset OTP to be sent to the user's email.

**Request Body Schema:**

```json
{
  "email": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/Auth/get-reset-password-token" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": true,
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": true,
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 5. Reset Password

**Endpoint:** `/api/Auth/reset-password`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Reset user password using the OTP sent via email.

**Request Body Schema:**

```json
{
  "email": "string",
  "otp": "string",
  "newPassword": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/Auth/reset-password" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "otp": "123456",
    "newPassword": "NewSecurePass123!"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": true,
  "errorMessage": null,
  "statusCode": 200
}
```


#### 6. Change Password

**Endpoint:** `/api/Auth/change-password`
**Method:** `POST`
**Tag:** Auth
**Authentication:** Required (Bearer Token)
**Content-Type:** `application/json`

**Description:** Change the authenticated user's password.

**Request Body Schema:**

```json
{
  "currentPassword": "string",
  "newPassword": "string"
}

---

#### 7. Login with Google

**Endpoint:** `/api/Auth/login-google`  
**Method:** `GET`  
**Tag:** Auth  
**Authentication:** Not required

**Description:** Initiate Google OAuth authentication flow.

**Example Request:**

```bash
curl -X GET "https://api.example.com/api/Auth/login-google"
```

**Response:** Redirects to Google OAuth consent screen.

---

#### 8. Google Callback

**Endpoint:** `/api/Auth/google-callback`  
**Method:** `GET`  
**Tag:** Auth  
**Authentication:** Not required

**Description:** Callback endpoint for Google OAuth. Returns JWT tokens after successful authentication.

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "accessTokenExpires": "2024-01-01T12:00:00Z",
    "refreshTokenExpires": "2024-01-08T12:00:00Z",
    "isNewUser": true
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 9. Update User Image

**Endpoint:** `/api/Auth/update-user-image`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Required (Bearer Token)  
**Content-Type:** `multipart/form-data`

**Description:** Update the authenticated user's profile image.

**Request Parameters (Form Data):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| NewImge | file (binary) | Yes | New profile image file |

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/Auth/update-user-image" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: multipart/form-data" \
  -F "NewImge=@new_profile.jpg"
```

**Response Schema:**

```json
{
  "success": true,
  "data": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 10. Logout

**Endpoint:** `/api/Auth/logout`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Required (Bearer Token)  
**Content-Type:** `application/json`

**Description:** Logout user and invalidate refresh token.

**Request Body Schema:**

```json
{
  "refreshToken": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/Auth/logout" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "a1b2c3d4e5f6..."
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": true,
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 11. Get User Profile

**Endpoint:** `/api/Auth/user-profile`  
**Method:** `GET`  
**Tag:** Auth  
**Authentication:** Required (Bearer Token)

**Description:** Retrieve the authenticated user's profile information.

**Example Request:**

```bash
curl -X GET "https://api.example.com/api/Auth/user-profile" \
  -H "Authorization: Bearer {token}"
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "fullName": "string",
    "email": "string",
    "userBase64Image": "string",
    "phoneNumber": "string",
    "userName": "string"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "fullName": "John Doe",
    "email": "user@example.com",
    "userBase64Image": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "phoneNumber": "+1234567890",
    "userName": "johndoe"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 12. Update User Profile

**Endpoint:** `/api/Auth/update-user-profile`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Required (Bearer Token)  
**Content-Type:** `application/json`

**Description:** Update the authenticated user's profile information.

**Request Body Schema:**

```json
{
  "fullName": "string",
  "email": "string",
  "phoneNumber": "string",
  "userName": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/Auth/update-user-profile" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Jane Doe",
    "email": "jane@example.com",
    "phoneNumber": "+1234567891",
    "userName": "janedoe"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "fullName": "string",
    "email": "string",
    "userBase64Image": "string",
    "phoneNumber": "string",
    "userName": "string"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

### Sign Language Translation

---

#### 13. Translate Sign Language to Text

**Endpoint:** `/api/SignLanguageTranslator`  
**Method:** `POST`  
**Tag:** SignLanguageTranslator  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Translate a sign language gesture from an image to Arabic text. The image is processed through a machine learning model to detect sign language letters.

**Request Body Schema:**

```json
{
  "imageData": "string"
}
```

**Fields:**
- `imageData` (string): Base64-encoded image data with MIME type prefix (e.g., `data:image/jpeg;base64,...`)

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/SignLanguageTranslator" \
  -H "Content-Type: application/json" \
  -d '{
    "imageData": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "translation": "string"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "translation": "ا"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Note:** If no sign is detected or confidence is below threshold (0.71), the response will indicate:
```json
{
  "success": true,
  "data": {
    "translation": "No sign detected."
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 14. Finalize Sentence

**Endpoint:** `/api/SignLanguageTranslator/finalize-sentence`  
**Method:** `POST`  
**Tag:** SignLanguageTranslator  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Takes concatenated Arabic letters from sign language translation and formats them into a coherent sentence with proper spacing and spelling corrections using AI.

**Request Body Schema:**

```json
{
  "sentence": "string",
}
```

**Fields:**
- `sentence` (string): Concatenated Arabic letters without spaces

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/SignLanguageTranslator/finalize-sentence" \
  -H "Content-Type: application/json" \
  -d '{
    "sentence": "مرحبابكم",
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": "string",
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": "مرحبا بكم",
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 15. Get Sentence Correction

**Endpoint:** `/api/SignLanguageTranslator/correct-sentence`  
**Method:** `POST`  
**Tag:** SignLanguageTranslator  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Get AI-powered suggestion to correct or improve an Arabic sentence.

**Request Body Schema:**

```json
{
  "sentence": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/SignLanguageTranslator/suggestions" \
  -H "Content-Type: application/json" \
  -d '{
    "sentence": "مرحبا بكم"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "correctedSentence": "string"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "correctedSentence": "مرحباً بكم"
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 16. Generate Audio from Sentence

**Endpoint:** `/api/SignLanguageTranslator/generate-audio`  
**Method:** `POST`  
**Tag:** SignLanguageTranslator  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Generate audio (Text-to-Speech) for a given Arabic sentence.

**Request Body Schema:**

```json
{
  "text": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/SignLanguageTranslator/generate-audio" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "مرحبا بكم"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "audioData": "string",
    "sampleRate": 24000
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Fields:**
- `audioData` (string): Base64-encoded audio data
- `sampleRate` (integer): Audio sample rate in Hz

**Example Response:**

```json
{
  "success": true,
  "data": {
    "audioData": "UklGRiQAAABXQVZFZm10IBAAAAABAAEA...",
    "sampleRate": 24000
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 17. Text to Audio (Combined)

**Endpoint:** `/api/SignLanguageTranslator/text-to-audio`  
**Method:** `POST`  
**Tag:** SignLanguageTranslator  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Combines sentence finalization and audio generation in a single request. Takes concatenated letters, formats them into a proper sentence, and generates audio.

**Request Body Schema:**

```json
{
  "sentence": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/SignLanguageTranslator/text-to-audio" \
  -H "Content-Type: application/json" \
  -d '{
    "sentence": "مرحبابكم"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": {
    "audioData": "string",
    "sampleRate": 24000
  },
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": {
    "audioData": "UklGRiQAAABXQVZFZm10IBAAAAABAAEA...",
    "sampleRate": 24000
  },
  "errorMessage": null,
  "statusCode": 200
}
```

---

### Arabic Language Translation

---

#### 18. Text to Sign Language

**Endpoint:** `/api/ArabicLanguageTranslator/text-to-sign`  
**Method:** `POST`  
**Tag:** ArabicLanguageTranslator  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Convert Arabic text to sign language images. Returns base64-encoded images for each letter, organized by words.

**Request Body Schema:**

```json
{
  "text": "string"
}
```

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/ArabicLanguageTranslator/text-to-sign" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "مرحبا بكم"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": [
    [
      "string"
    ]
  ],
  "errorMessage": null,
  "statusCode": 200
}
```

**Data Structure:**
- Outer array: Each element represents a word
- Inner array: Each element is a base64-encoded image representing a letter

**Example Response:**

```json
{
  "success": true,
  "data": [
    [
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
    ],
    [
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
    ]
  ],
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 19. Audio to Text

**Endpoint:** `/api/ArabicLanguageTranslator/audio-to-text`  
**Method:** `POST`  
**Tag:** ArabicLanguageTranslator  
**Authentication:** Not required  
**Content-Type:** `application/json`

**Description:** Transcribe Arabic speech from audio to text using AI speech recognition.

**Request Body Schema:**

```json
{
  "audioData": "string",
  "mimeType": "string"
}
```

**Fields:**
- `audioData` (string): Base64-encoded audio data
- `mimeType` (string): MIME type of the audio (e.g., "audio/wav", "audio/mp3")

**Example Request:**

```bash
curl -X POST "https://api.example.com/api/ArabicLanguageTranslator/audio-to-text" \
  -H "Content-Type: application/json" \
  -d '{
    "audioData": "UklGRiQAAABXQVZFZm10IBAAAAABAAEA...",
    "mimeType": "audio/wav"
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": "string",
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": "مرحبا بكم في تطبيقنا",
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 20. Get Letter Image (Keyboard)

**Endpoint:** `/api/ArabicLanguageTranslator/letters-keyboard`  
**Method:** `GET`  
**Tag:** ArabicLanguageTranslator  
**Authentication:** Not required

**Description:** Get the sign language image for a specific Arabic letter.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| letter | string | Yes | Single Arabic letter character |

**Example Request:**

```bash
curl -X GET "https://api.example.com/api/ArabicLanguageTranslator/letters-keyboard?letter=م" \
  -H "Content-Type: application/json"
```

**Response Schema:**

```json
{
  "success": true,
  "data": "string",
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "errorMessage": null,
  "statusCode": 200
}
```

---

### User History

---

#### 21. Get User History

**Endpoint:** `/api/UserHistory/get-user-history`  
**Method:** `GET`  
**Tag:** UserHistory  
**Authentication:** Required (Bearer Token)

**Description:** Retrieve all translation history records for the authenticated user.

**Example Request:**

```bash
curl -X GET "https://api.example.com/api/UserHistory/get-user-history" \
  -H "Authorization: Bearer {token}"
```

**Response Schema:**

```json
{
  "success": true,
  "data": [
    {
      "id": 0,
      "formedSentence": "string",
      "formedAt": "2024-01-01T12:00:00Z"
    }
  ],
  "errorMessage": null,
  "statusCode": 200
}
```

**Example Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "formedSentence": "مرحبا بكم",
      "formedAt": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "formedSentence": "كيف حالك",
      "formedAt": "2024-01-15T11:45:00Z"
    }
  ],
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 22. Delete User History Record

**Endpoint:** `/api/UserHistory/delete-user-history-record`  
**Method:** `DELETE`  
**Tag:** UserHistory  
**Authentication:** Required (Bearer Token)  
**Content-Type:** `application/json`

**Description:** Delete a specific history record by ID.

**Request Body Schema:**

```json
{
  "id": 0
}
```

**Example Request:**

```bash
curl -X DELETE "https://api.example.com/api/UserHistory/delete-user-history-record" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1
  }'
```

**Response Schema:**

```json
{
  "success": true,
  "data": true,
  "errorMessage": null,
  "statusCode": 200
}
```

---

#### 23. Delete All User History

**Endpoint:** `/api/UserHistory/delete-all-user-history`  
**Method:** `DELETE`  
**Tag:** UserHistory  
**Authentication:** Required (Bearer Token)

**Description:** Delete all history records for the authenticated user.

**Example Request:**

```bash
curl -X DELETE "https://api.example.com/api/UserHistory/delete-all-user-history" \
  -H "Authorization: Bearer {token}"
```

**Response Schema:**

```json
{
  "success": true,
  "data": true,
  "errorMessage": null,
  "statusCode": 200
}
```

---

## Error Handling

### Common Error Responses

**400 Bad Request:**
```json
{
  "success": false,
  "data": null,
  "errorMessage": "Invalid request data",
  "statusCode": 400
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "data": null,
  "errorMessage": "Unauthorized access",
  "statusCode": 401
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "data": null,
  "errorMessage": "An unexpected error occurred",
  "statusCode": 500
}
```

---

## Rate Limiting

The API implements strict rate limiting to ensure fair usage and system stability. If you exceed the limits below, you will receive a `429 Too Many Requests` response with the message:
`{ "message": "Rate limit exceeded. Try again later." }`

| Endpoint | Limiter Name | Quota / Policy |
|----------|--------------|----------------|
| `/api/Auth/register-user` | `RegisterLimiter` | 5 requests per 10 minutes |
| `/api/Auth/login-user` | `LoginLimiter` | Token Bucket: 5 tokens initially, replenishes 5 tokens every 10 seconds |
| `/api/Auth/refresh-tokens` | `RefreshTokenLimiter` | 10 requests per 1 minute |
| `/api/Auth/get-reset-password-token` | `GetResetPasswordLimiter` | 3 requests per 1 hour |
| `/api/Auth/reset-password` | `ResetPasswordLimiter` | 3 requests per 1 hour |
| `/api/Auth/change-password` | `ChangePasswordLimiter` | 10 requests per 1 hour |
| `/api/Auth/login-google` | `GoogleLoginLimiter` | 10 requests per 1 minute |
| `/api/Auth/google-callback` | `GoogleCallbackLimiter` | 10 requests per 1 minute |
| `/api/Auth/update-user-image` | `UpdateImageLimiter` | 10 requests per 10 minutes |
| `/api/Auth/logout` | `LogoutLimiter` | 20 requests per 1 minute |
| `/api/Auth/user-profile` (GET) | `UserProfileReadLimiter` | 100 requests per 10 minutes |
| `/api/Auth/update-user-profile` | `UserProfileUpdateLimiter` | 10 requests per 10 minutes |
| `/api/SignLanguageTranslator/finalize-sentence` | `GeminiLimiter` | 3 requests per 1 minute |
| `/api/SignLanguageTranslator/correct-sentence` | `GeminiLimiter` | 3 requests per 1 minute |
| `/api/SignLanguageTranslator/generate-audio` | `GeminiLimiter` | 3 requests per 1 minute |
| `/api/SignLanguageTranslator/text-to-audio` | `GeminiLimiter` | 3 requests per 1 minute |
| `/api/ArabicLanguageTranslator/text-to-sign` | `ArabicLimiter` | 30 requests per 1 minute |
| `/api/ArabicLanguageTranslator/audio-to-text` | `GeminiLimiter` | 3 requests per 1 minute |
| `/api/ArabicLanguageTranslator/letters-keyboard` | `ArabicLimiter` | 30 requests per 1 minute |


---

## HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | OK - Request successful |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Authentication required or failed |
| 404 | Not Found - Resource doesn't exist |
| 429 | Too Many Requests - Rate limit exceeded |
| 500 | Internal Server Error - Server-side error |
| 502 | Bad Gateway - External API error (e.g., Gemini API) |

---

## Data Models Reference

### ApplicationUserDTO
```json
{
  "email": "string",
  "fullName": "string",
  "userName": "string",
  "phoneNumber": "string",
  "userBase64Image": "string"
}
```

### TokenResponseDTO
```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "accessTokenExpires": "2024-01-01T12:00:00Z",
  "refreshTokenExpires": "2024-01-08T12:00:00Z"
}
```

### UserProfileDTO
```json
{
  "fullName": "string",
  "email": "string",
  "userBase64Image": "string",
  "phoneNumber": "string",
  "userName": "string"
}
```

### UserRecordDTO
```json
{
  "id": 0,
  "formedSentence": "string",
  "formedAt": "2024-01-01T12:00:00Z"
}
```

### TTSResponse
```json
{
  "audioData": "string",
  "sampleRate": 24000
}
```

### Suggestion
```json
{
  "correctedSentence": "string"
}
```

---

## Notes

1. **Base64 Image Format**: All images (profile pictures, sign language images) are returned as base64-encoded strings with MIME type prefix: `data:image/[type];base64,[data]`

2. **Date-Time Format**: All timestamps follow ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ`

3. **Authentication Flow**:
   - Register or Login to obtain tokens
   - Include access token in `Authorization` header for protected endpoints
   - Use refresh token to obtain new access tokens when they expire

4. **Sign Language Translation Workflow**:
   - Capture image → POST to `/api/SignLanguageTranslator` → Receive letter
   - Collect multiple letters → POST to `/api/SignLanguageTranslator/finalize-sentence` → Receive formatted sentence
   - Optional: POST to `/api/SignLanguageTranslator/generate-audio` → Receive audio

5. **Arabic to Sign Translation**:
   - Type Arabic text → POST to `/api/ArabicLanguageTranslator/text-to-sign` → Receive sign images
   - Or record audio → POST to `/api/ArabicLanguageTranslator/audio-to-text` → Convert to text → POST to text-to-sign

---

## Support

For issues or questions about the API, please contact the development team or refer to the application documentation.

**API Version:** v1  
**Last Updated:** 2026