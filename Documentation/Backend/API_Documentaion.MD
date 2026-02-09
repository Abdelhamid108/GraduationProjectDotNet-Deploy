# Ema2a API Documentation

**Version:** v1  
**Base URL:** `/api`

## Table of Contents

- [Authentication](#authentication)
- [ArabicLanguageTranslator Controller](#arabiclanguagetranslator-controller)
  - [Text to Sign](#text-to-sign)
  - [Audio to Text](#audio-to-text)
  - [Letters Keyboard](#letters-keyboard)
- [Auth Controller](#auth-controller)
  - [Register User](#register-user)
  - [Login User](#login-user)
  - [Refresh Tokens](#refresh-tokens)
  - [Forgot Password](#forgot-password)
  - [Reset Password](#reset-password)
  - [Resend OTP](#resend-otp)
  - [Verify OTP](#verify-otp)
- [Dictionary Controller](#dictionary-controller)
  - [Get All Dictionary Items](#get-all-dictionary-items)
- [NLPService Controller](#nlpservice-controller)
  - [Correct Sentence](#correct-sentence)
  - [Text to Speech](#text-to-speech)
  - [Sign to Text](#sign-to-text)
- [UserProfiles Controller](#userprofiles-controller)
  - [Get User Profile](#get-user-profile)
  - [Update User Profile](#update-user-profile)
  - [Update User Profile Picture](#update-user-profile-picture)
- [UserRecords Controller](#userrecords-controller)
  - [Get All User Records](#get-all-user-records)
  - [Create User Record](#create-user-record)
  - [Delete User Record](#delete-user-record)
- [Data Models](#data-models)

---

## Authentication

This API uses **Bearer Token Authentication** (JWT).

**Security Scheme:** `Bearer`  
**Type:** API Key  
**Header Name:** `Authorization`  
**Format:** `Bearer {your JWT token}`

To authenticate requests, include the Authorization header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## ArabicLanguageTranslator Controller

### Text to Sign

Converts Arabic text into sign language representations.

**Endpoint:** `/api/ArabicLanguageTranslator/text-to-sign`  
**Method:** `POST`  
**Tag:** ArabicLanguageTranslator  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `application/json`

**Schema:** [TextToSignDTO](#texttosigndto)

```json
{
  "text": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/ArabicLanguageTranslator/text-to-sign" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "مرحبا بك"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringListListAPIResponseDTO](#stringlistlistapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": [
    ["string", "string"],
    ["string"]
  ],
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": [
    ["sign_url_1", "sign_url_2"],
    ["sign_url_3"]
  ],
  "success": true,
  "statusCode": 200
}
```

---

### Audio to Text

Transcribes Arabic audio into text.

**Endpoint:** `/api/ArabicLanguageTranslator/audio-to-text`  
**Method:** `POST`  
**Tag:** ArabicLanguageTranslator  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `application/json`

**Schema:** [TranscriptionRequest](#transcriptionrequest)

```json
{
  "audioData": "string",
  "mimeType": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/ArabicLanguageTranslator/audio-to-text" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "audioData": "base64_encoded_audio_data",
    "mimeType": "audio/wav"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringAPIResponseDTO](#stringapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": "هذا نص مُحَوَّل من الصوت",
  "success": true,
  "statusCode": 200
}
```

---

### Letters Keyboard

Retrieves sign language representation for a specific letter.

**Endpoint:** `/api/ArabicLanguageTranslator/letters-keyboard`  
**Method:** `GET`  
**Tag:** ArabicLanguageTranslator  
**Authentication:** Required (Bearer Token)

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| letter | string | No | Arabic letter to get sign representation |

#### Example Request

```bash
curl -X GET "https://api.example.com/api/ArabicLanguageTranslator/letters-keyboard?letter=أ" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringAPIResponseDTO](#stringapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": "https://example.com/signs/alef.mp4",
  "success": true,
  "statusCode": 200
}
```

---

## Auth Controller

### Register User

Registers a new user account with profile information and optional profile image.

**Endpoint:** `/api/Auth/register-user`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not Required

#### Request Body

**Content-Type:** `multipart/form-data`

**Required Fields:**
- Email (string)
- FullName (string)
- UserName (string)
- Password (string)
- PhoneNumber (string)

**Optional Fields:**
- UserImage (binary file)

#### Example Request

```bash
curl -X POST "https://api.example.com/api/Auth/register-user" \
  -F "Email=user@example.com" \
  -F "FullName=John Doe" \
  -F "UserName=johndoe" \
  -F "Password=SecurePass123!" \
  -F "PhoneNumber=+201234567890" \
  -F "UserImage=@/path/to/image.jpg"
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [ApplicationUserDTOAPIResponseDTO](#applicationuserdtoapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": {
    "id": "string",
    "userName": "string",
    "email": "string",
    "fullName": "string",
    "phoneNumber": "string",
    "userBase64Image": "string"
  },
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "userName": "johndoe",
    "email": "user@example.com",
    "fullName": "John Doe",
    "phoneNumber": "+201234567890",
    "userBase64Image": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  },
  "success": true,
  "statusCode": 200
}
```

---

### Login User

Authenticates a user and returns JWT tokens.

**Endpoint:** `/api/Auth/login-user`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not Required

#### Request Body

**Content-Type:** `application/json`

**Schema:** [LoginDTO](#logindto)

```json
{
  "emailOrUsername": "string",
  "password": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/Auth/login-user" \
  -H "Content-Type: application/json" \
  -d '{
    "emailOrUsername": "johndoe",
    "password": "SecurePass123!"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [TokenResponseDTOAPIResponseDTO](#tokenresponsedtoapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "accessTokenExpires": "2026-02-09T12:00:00Z",
    "refreshTokenExpires": "2026-03-09T12:00:00Z"
  },
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
    "accessTokenExpires": "2026-02-09T13:00:00Z",
    "refreshTokenExpires": "2026-03-09T12:00:00Z"
  },
  "success": true,
  "statusCode": 200
}
```

---

### Refresh Tokens

Refreshes expired access tokens using a valid refresh token.

**Endpoint:** `/api/Auth/refresh-tokens`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not Required

#### Request Body

**Content-Type:** `application/json`

**Schema:** [TokenRequestDTO](#tokenrequestdto)

```json
{
  "refreshToken": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/Auth/refresh-tokens" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [TokenResponseDTOAPIResponseDTO](#tokenresponsedtoapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "accessTokenExpires": "2026-02-09T12:00:00Z",
    "refreshTokenExpires": "2026-03-09T12:00:00Z"
  },
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "bmV3IHJlZnJlc2ggdG9rZW4gaGVyZQ...",
    "accessTokenExpires": "2026-02-09T14:00:00Z",
    "refreshTokenExpires": "2026-03-09T13:00:00Z"
  },
  "success": true,
  "statusCode": 200
}
```

---

### Forgot Password

Initiates password reset process by sending OTP to user's email.

**Endpoint:** `/api/Auth/forgot-password`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not Required

#### Request Body

**Content-Type:** `application/json`

**Schema:** [ForgotPasswordDTO](#forgotpassworddto)

```json
{
  "email": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/Auth/forgot-password" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringAPIResponseDTO](#stringapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": "OTP has been sent to your email",
  "success": true,
  "statusCode": 200
}
```

---

### Reset Password

Resets user password using OTP verification.

**Endpoint:** `/api/Auth/reset-password`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not Required

#### Request Body

**Content-Type:** `application/json`

**Schema:** [ResetPasswordDTO](#resetpassworddto)

```json
{
  "email": "string",
  "otp": "string",
  "newPassword": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/Auth/reset-password" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "otp": "123456",
    "newPassword": "NewSecurePass123!"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringAPIResponseDTO](#stringapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": "Password has been reset successfully",
  "success": true,
  "statusCode": 200
}
```

---

### Resend OTP

Resends OTP to user's email for verification.

**Endpoint:** `/api/Auth/resend-otp`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not Required

#### Request Body

**Content-Type:** `application/json`

**Schema:** [ResendOtpDTO](#resendotpdto)

```json
{
  "email": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/Auth/resend-otp" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringAPIResponseDTO](#stringapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": "OTP has been resent to your email",
  "success": true,
  "statusCode": 200
}
```

---

### Verify OTP

Verifies OTP for email confirmation or password reset.

**Endpoint:** `/api/Auth/verify-otp`  
**Method:** `POST`  
**Tag:** Auth  
**Authentication:** Not Required

#### Request Body

**Content-Type:** `application/json`

**Schema:** [ConfirmOTPDTO](#confirmotpdto)

```json
{
  "email": "string",
  "otp": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/Auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "otp": "123456"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringAPIResponseDTO](#stringapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": "OTP verified successfully",
  "success": true,
  "statusCode": 200
}
```

---

## Dictionary Controller

### Get All Dictionary Items

Retrieves all dictionary items or filters by letter.

**Endpoint:** `/api/Dictionary`  
**Method:** `GET`  
**Tag:** Dictionary  
**Authentication:** Required (Bearer Token)

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| letter | string | No | Filter dictionary items by starting letter |

#### Example Request

```bash
curl -X GET "https://api.example.com/api/Dictionary?letter=أ" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [DictionaryItemDTOListAPIResponseDTO](#dictionaryitemdtolistapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": [
    {
      "id": 0,
      "arabicWord": "string",
      "videoUrl": "string"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": [
    {
      "id": 1,
      "arabicWord": "أسد",
      "videoUrl": "https://example.com/signs/asad.mp4"
    },
    {
      "id": 2,
      "arabicWord": "أرنب",
      "videoUrl": "https://example.com/signs/arnab.mp4"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

---

## NLPService Controller

### Correct Sentence

Provides grammar correction suggestions for Arabic text.

**Endpoint:** `/api/NLPService/correct-sentence`  
**Method:** `POST`  
**Tag:** NLPService  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `application/json`

**Schema:** [CorrectionRequest](#correctionrequest)

```json
{
  "sentence": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/NLPService/correct-sentence" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sentence": "هذا جمله بها أخطاء"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [SuggestionListAPIResponseDTO](#suggestionlistapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": [
    {
      "correctedSentence": "string"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": [
    {
      "correctedSentence": "هذه جملة بها أخطاء"
    },
    {
      "correctedSentence": "هذا جملة فيها أخطاء"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

---

### Text to Speech

Converts Arabic text to speech audio.

**Endpoint:** `/api/NLPService/text-to-speech`  
**Method:** `POST`  
**Tag:** NLPService  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `application/json`

**Schema:** [TTSRequest](#ttsrequest)

```json
{
  "text": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/NLPService/text-to-speech" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "مرحبا بك في التطبيق"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [TTSResponseAPIResponseDTO](#ttsresponseapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": {
    "audioData": "string",
    "sampleRate": 0
  },
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": {
    "audioData": "base64_encoded_audio_data_here...",
    "sampleRate": 22050
  },
  "success": true,
  "statusCode": 200
}
```

---

### Sign to Text

Converts sign language video to Arabic text.

**Endpoint:** `/api/NLPService/sign-to-text`  
**Method:** `POST`  
**Tag:** NLPService  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `application/json`

**Schema:** [SignToTextRequest](#signtotextrequest)

```json
{
  "videoData": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/NLPService/sign-to-text" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "videoData": "base64_encoded_video_data"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [StringAPIResponseDTO](#stringapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": "مرحبا كيف حالك",
  "success": true,
  "statusCode": 200
}
```

---

## UserProfiles Controller

### Get User Profile

Retrieves the authenticated user's profile information.

**Endpoint:** `/api/UserProfiles`  
**Method:** `GET`  
**Tag:** UserProfiles  
**Authentication:** Required (Bearer Token)

#### Example Request

```bash
curl -X GET "https://api.example.com/api/UserProfiles" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [UserProfileDTOAPIResponseDTO](#userprofiledtoapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": {
    "fullName": "string",
    "email": "string",
    "userBase64Image": "string",
    "phoneNumber": "string",
    "userName": "string"
  },
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": {
    "fullName": "John Doe",
    "email": "user@example.com",
    "userBase64Image": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "phoneNumber": "+201234567890",
    "userName": "johndoe"
  },
  "success": true,
  "statusCode": 200
}
```

---

### Update User Profile

Updates the authenticated user's profile information.

**Endpoint:** `/api/UserProfiles`  
**Method:** `PUT`  
**Tag:** UserProfiles  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `application/json`

**Schema:** [UpdateUserProfileDTO](#updateuserprofiledto)

```json
{
  "fullName": "string",
  "email": "string",
  "phoneNumber": "string",
  "userName": "string"
}
```

#### Example Request

```bash
curl -X PUT "https://api.example.com/api/UserProfiles" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "John Updated Doe",
    "email": "newemail@example.com",
    "phoneNumber": "+201234567890",
    "userName": "johndoe_new"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [UserProfileDTOAPIResponseDTO](#userprofiledtoapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": {
    "fullName": "string",
    "email": "string",
    "userBase64Image": "string",
    "phoneNumber": "string",
    "userName": "string"
  },
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": {
    "fullName": "John Updated Doe",
    "email": "newemail@example.com",
    "userBase64Image": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "phoneNumber": "+201234567890",
    "userName": "johndoe_new"
  },
  "success": true,
  "statusCode": 200
}
```

---

### Update User Profile Picture

Updates the authenticated user's profile picture.

**Endpoint:** `/api/UserProfiles/update-profile-picture`  
**Method:** `PUT`  
**Tag:** UserProfiles  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `multipart/form-data`

**Required Fields:**
- UserImage (binary file)

#### Example Request

```bash
curl -X PUT "https://api.example.com/api/UserProfiles/update-profile-picture" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "UserImage=@/path/to/new-image.jpg"
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [UserProfileDTOAPIResponseDTO](#userprofiledtoapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": {
    "fullName": "string",
    "email": "string",
    "userBase64Image": "string",
    "phoneNumber": "string",
    "userName": "string"
  },
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": {
    "fullName": "John Doe",
    "email": "user@example.com",
    "userBase64Image": "data:image/jpeg;base64,NEW_BASE64_IMAGE_DATA...",
    "phoneNumber": "+201234567890",
    "userName": "johndoe"
  },
  "success": true,
  "statusCode": 200
}
```

---

## UserRecords Controller

### Get All User Records

Retrieves all sentence formation records for the authenticated user.

**Endpoint:** `/api/UserRecords`  
**Method:** `GET`  
**Tag:** UserRecords  
**Authentication:** Required (Bearer Token)

#### Example Request

```bash
curl -X GET "https://api.example.com/api/UserRecords" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [UserRecordDTOListAPIResponseDTO](#userrecorddtolistapiresponsedto)

```json
{
  "errorMessage": "string",
  "data": [
    {
      "id": 0,
      "formedSentence": "string",
      "formedAt": "2026-02-09T12:00:00Z"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": [
    {
      "id": 1,
      "formedSentence": "مرحبا بك في التطبيق",
      "formedAt": "2026-02-09T10:30:00Z"
    },
    {
      "id": 2,
      "formedSentence": "كيف حالك اليوم",
      "formedAt": "2026-02-09T11:45:00Z"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

---

### Create User Record

Creates a new sentence formation record for the authenticated user.

**Endpoint:** `/api/UserRecords`  
**Method:** `POST`  
**Tag:** UserRecords  
**Authentication:** Required (Bearer Token)

#### Request Body

**Content-Type:** `application/json`

**Schema:** [CreateUserRecordDTO](#createuserrecorddto)

```json
{
  "formedSentence": "string"
}
```

#### Example Request

```bash
curl -X POST "https://api.example.com/api/UserRecords" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "formedSentence": "هذه جملة جديدة"
  }'
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [APIResponseDTO](#apiresponsedto)

```json
{
  "errorMessage": "string",
  "data": null,
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": null,
  "success": true,
  "statusCode": 200
}
```

---

### Delete User Record

Deletes a specific sentence formation record.

**Endpoint:** `/api/UserRecords/{id}`  
**Method:** `DELETE`  
**Tag:** UserRecords  
**Authentication:** Required (Bearer Token)

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Record ID to delete |

#### Example Request

```bash
curl -X DELETE "https://api.example.com/api/UserRecords/1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Response

**Status:** `200 OK`  
**Content-Type:** `application/json`

**Schema:** [APIResponseDTO](#apiresponsedto)

```json
{
  "errorMessage": "string",
  "data": null,
  "success": true,
  "statusCode": 200
}
```

#### Example Response

```json
{
  "errorMessage": null,
  "data": null,
  "success": true,
  "statusCode": 200
}
```

---

## Data Models

### APIResponseDTO

Base response wrapper for API responses without specific data.

```json
{
  "errorMessage": "string",
  "data": null,
  "success": true,
  "statusCode": 200
}
```

**Properties:**
- `errorMessage` (string, nullable): Error message if request failed
- `data` (null): No data payload
- `success` (boolean): Indicates if request was successful
- `statusCode` (HttpStatusCode): HTTP status code

---

### ApplicationUserDTO

User account information.

```json
{
  "id": "string",
  "userName": "string",
  "email": "string",
  "fullName": "string",
  "phoneNumber": "string",
  "userBase64Image": "string"
}
```

**Properties:**
- `id` (string, nullable): User unique identifier
- `userName` (string, nullable): Username
- `email` (string, nullable): Email address
- `fullName` (string, nullable): Full name
- `phoneNumber` (string, nullable): Phone number
- `userBase64Image` (string, nullable): Base64 encoded profile image

---

### ApplicationUserDTOAPIResponseDTO

API response wrapper for ApplicationUserDTO.

```json
{
  "errorMessage": "string",
  "data": {
    "id": "string",
    "userName": "string",
    "email": "string",
    "fullName": "string",
    "phoneNumber": "string",
    "userBase64Image": "string"
  },
  "success": true,
  "statusCode": 200
}
```

---

### ConfirmOTPDTO

OTP verification request.

```json
{
  "email": "string",
  "otp": "string"
}
```

**Properties:**
- `email` (string, nullable): User email address
- `otp` (string, nullable): One-time password

---

### CorrectionRequest

Sentence correction request.

```json
{
  "sentence": "string"
}
```

**Properties:**
- `sentence` (string, nullable): Arabic sentence to correct

---

### CreateUserRecordDTO

New user record creation request.

```json
{
  "formedSentence": "string"
}
```

**Properties:**
- `formedSentence` (string, nullable): The formed sentence to save

---

### DictionaryItemDTO

Dictionary item with Arabic word and sign video.

```json
{
  "id": 0,
  "arabicWord": "string",
  "videoUrl": "string"
}
```

**Properties:**
- `id` (integer): Dictionary item ID
- `arabicWord` (string, nullable): Arabic word
- `videoUrl` (string, nullable): URL to sign language video

---

### DictionaryItemDTOListAPIResponseDTO

API response wrapper for list of DictionaryItemDTO.

```json
{
  "errorMessage": "string",
  "data": [
    {
      "id": 0,
      "arabicWord": "string",
      "videoUrl": "string"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

---

### ForgotPasswordDTO

Password reset initiation request.

```json
{
  "email": "string"
}
```

**Properties:**
- `email` (string, nullable): User email address

---

### HttpStatusCode

HTTP status code enumeration.

**Possible Values:**
- 100 - Continue
- 101 - Switching Protocols
- 102 - Processing
- 103 - Early Hints
- 200 - OK
- 201 - Created
- 202 - Accepted
- 203 - Non-Authoritative Information
- 204 - No Content
- 205 - Reset Content
- 206 - Partial Content
- 207 - Multi-Status
- 208 - Already Reported
- 226 - IM Used
- 300 - Multiple Choices
- 301 - Moved Permanently
- 302 - Found
- 303 - See Other
- 304 - Not Modified
- 305 - Use Proxy
- 306 - Unused
- 307 - Temporary Redirect
- 308 - Permanent Redirect
- 400 - Bad Request
- 401 - Unauthorized
- 402 - Payment Required
- 403 - Forbidden
- 404 - Not Found
- 405 - Method Not Allowed
- 406 - Not Acceptable
- 407 - Proxy Authentication Required
- 408 - Request Timeout
- 409 - Conflict
- 410 - Gone
- 411 - Length Required
- 412 - Precondition Failed
- 413 - Request Entity Too Large
- 414 - Request-URI Too Long
- 415 - Unsupported Media Type
- 416 - Requested Range Not Satisfiable
- 417 - Expectation Failed
- 421 - Misdirected Request
- 422 - Unprocessable Entity
- 423 - Locked
- 424 - Failed Dependency
- 426 - Upgrade Required
- 428 - Precondition Required
- 429 - Too Many Requests
- 431 - Request Header Fields Too Large
- 451 - Unavailable For Legal Reasons
- 500 - Internal Server Error
- 501 - Not Implemented
- 502 - Bad Gateway
- 503 - Service Unavailable
- 504 - Gateway Timeout
- 505 - HTTP Version Not Supported
- 506 - Variant Also Negotiates
- 507 - Insufficient Storage
- 508 - Loop Detected
- 510 - Not Extended
- 511 - Network Authentication Required

---

### LoginDTO

User login credentials.

```json
{
  "emailOrUsername": "string",
  "password": "string"
}
```

**Properties:**
- `emailOrUsername` (string, nullable): Email or username
- `password` (string, nullable): User password

---

### ResendOtpDTO

OTP resend request.

```json
{
  "email": "string"
}
```

**Properties:**
- `email` (string, nullable): User email address

---

### ResetPasswordDTO

Password reset request with OTP.

```json
{
  "email": "string",
  "otp": "string",
  "newPassword": "string"
}
```

**Properties:**
- `email` (string, nullable): User email address
- `otp` (string, nullable): One-time password
- `newPassword` (string, nullable): New password

---

### SignToTextRequest

Sign language to text conversion request.

```json
{
  "videoData": "string"
}
```

**Properties:**
- `videoData` (string, nullable): Base64 encoded video data

---

### StringAPIResponseDTO

API response wrapper for string data.

```json
{
  "errorMessage": "string",
  "data": "string",
  "success": true,
  "statusCode": 200
}
```

**Properties:**
- `errorMessage` (string, nullable): Error message if request failed
- `data` (string, nullable): Response string data
- `success` (boolean): Indicates if request was successful
- `statusCode` (HttpStatusCode): HTTP status code

---

### StringListListAPIResponseDTO

API response wrapper for nested string arrays.

```json
{
  "errorMessage": "string",
  "data": [
    ["string", "string"],
    ["string"]
  ],
  "success": true,
  "statusCode": 200
}
```

**Properties:**
- `errorMessage` (string, nullable): Error message if request failed
- `data` (array of string arrays, nullable): Nested array of strings
- `success` (boolean): Indicates if request was successful
- `statusCode` (HttpStatusCode): HTTP status code

---

### Suggestion

Grammar correction suggestion.

```json
{
  "correctedSentence": "string"
}
```

**Properties:**
- `correctedSentence` (string, nullable): Corrected sentence suggestion

---

### SuggestionListAPIResponseDTO

API response wrapper for list of Suggestions.

```json
{
  "errorMessage": "string",
  "data": [
    {
      "correctedSentence": "string"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

---

### TextToSignDTO

Text to sign language conversion request.

```json
{
  "text": "string"
}
```

**Properties:**
- `text` (string, nullable): Arabic text to convert to sign language

---

### TokenRequestDTO

Token refresh request.

```json
{
  "refreshToken": "string"
}
```

**Properties:**
- `refreshToken` (string, nullable): Refresh token

---

### TokenResponseDTO

Authentication token response.

```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "accessTokenExpires": "2026-02-09T12:00:00Z",
  "refreshTokenExpires": "2026-03-09T12:00:00Z"
}
```

**Properties:**
- `accessToken` (string, nullable): JWT access token
- `refreshToken` (string, nullable): Refresh token
- `accessTokenExpires` (datetime): Access token expiration timestamp
- `refreshTokenExpires` (datetime): Refresh token expiration timestamp

---

### TokenResponseDTOAPIResponseDTO

API response wrapper for TokenResponseDTO.

```json
{
  "errorMessage": "string",
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "accessTokenExpires": "2026-02-09T12:00:00Z",
    "refreshTokenExpires": "2026-03-09T12:00:00Z"
  },
  "success": true,
  "statusCode": 200
}
```

---

### TranscriptionRequest

Audio transcription request.

```json
{
  "audioData": "string",
  "mimeType": "string"
}
```

**Properties:**
- `audioData` (string, nullable): Base64 encoded audio data
- `mimeType` (string, nullable): Audio MIME type (e.g., "audio/wav")

---

### TTSRequest

Text-to-speech conversion request.

```json
{
  "text": "string"
}
```

**Properties:**
- `text` (string, nullable): Arabic text to convert to speech

---

### TTSResponse

Text-to-speech conversion response.

```json
{
  "audioData": "string",
  "sampleRate": 0
}
```

**Properties:**
- `audioData` (string, nullable): Base64 encoded audio data
- `sampleRate` (integer): Audio sample rate in Hz

---

### TTSResponseAPIResponseDTO

API response wrapper for TTSResponse.

```json
{
  "errorMessage": "string",
  "data": {
    "audioData": "string",
    "sampleRate": 0
  },
  "success": true,
  "statusCode": 200
}
```

---

### UpdateUserProfileDTO

User profile update request.

```json
{
  "fullName": "string",
  "email": "string",
  "phoneNumber": "string",
  "userName": "string"
}
```

**Properties:**
- `fullName` (string, nullable): Full name
- `email` (string, nullable): Email address
- `phoneNumber` (string, nullable): Phone number
- `userName` (string, nullable): Username

---

### UserProfileDTO

User profile information.

```json
{
  "fullName": "string",
  "email": "string",
  "userBase64Image": "string",
  "phoneNumber": "string",
  "userName": "string"
}
```

**Properties:**
- `fullName` (string, nullable): Full name
- `email` (string, nullable): Email address
- `userBase64Image` (string, nullable): Base64 encoded profile image
- `phoneNumber` (string, nullable): Phone number
- `userName` (string, nullable): Username

---

### UserProfileDTOAPIResponseDTO

API response wrapper for UserProfileDTO.

```json
{
  "errorMessage": "string",
  "data": {
    "fullName": "string",
    "email": "string",
    "userBase64Image": "string",
    "phoneNumber": "string",
    "userName": "string"
  },
  "success": true,
  "statusCode": 200
}
```

---

### UserRecordDTO

User sentence formation record.

```json
{
  "id": 0,
  "formedSentence": "string",
  "formedAt": "2026-02-09T12:00:00Z"
}
```

**Properties:**
- `id` (integer): Record ID
- `formedSentence` (string, nullable): The formed sentence
- `formedAt` (datetime): Timestamp when sentence was created

---

### UserRecordDTOListAPIResponseDTO

API response wrapper for list of UserRecordDTO.

```json
{
  "errorMessage": "string",
  "data": [
    {
      "id": 0,
      "formedSentence": "string",
      "formedAt": "2026-02-09T12:00:00Z"
    }
  ],
  "success": true,
  "statusCode": 200
}
```

---

## Error Handling

All API endpoints return responses in a consistent format with the following structure:

```json
{
  "errorMessage": "Error description if failed",
  "data": "Response data or null",
  "success": true/false,
  "statusCode": 200
}
```

### Common Status Codes

- **200 OK**: Request succeeded
- **400 Bad Request**: Invalid request parameters or body
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: User doesn't have permission
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server-side error

### Error Response Example

```json
{
  "errorMessage": "Invalid credentials",
  "data": null,
  "success": false,
  "statusCode": 401
}
```

---

## Notes

- All timestamps are in ISO 8601 format (UTC)
- Base64 encoded data should be prefixed appropriately (e.g., `data:image/jpeg;base64,` for images)
- Phone numbers should include country code (e.g., +20 for Egypt)
- All text fields accept Arabic and English characters unless specified otherwise
- File uploads use multipart/form-data encoding
- Maximum file size limits may apply (check with API administrator)