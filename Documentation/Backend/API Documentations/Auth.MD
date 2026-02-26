# Auth — API Documentation

**Base URL:** `https://ema2a.mooo.com`  
**Controller prefix:** `/api/Auth`

---

## Overview

The Auth API handles all user identity operations: registration, login, token management, password management, Google OAuth, and profile management. It uses **JWT access tokens** and **refresh tokens** for authentication. Endpoints marked as 🔒 **Authorized** require a valid Bearer token in the request header.

**Full base path:** `https://ema2a.mooo.com/api/Auth`

---

## Common Response Envelope

All endpoints return a standard `APIResponseDTO<T>` wrapper object:

```json
{
  "success": true | false,
  "data": <T>,
  "errorMessage": "string (empty on success)",
  "statusCode": <HTTP status code>
}
```

On success, `data` carries the endpoint-specific payload. On failure, `data` is `null` and `errorMessage` contains a human-readable description of the error.

---

## Authentication

Endpoints marked with 🔒 require the following header:

```
Authorization: Bearer <AccessToken>
```

The `AccessToken` is obtained from the `login-user`, `refresh-tokens`, or `google-callback` endpoints.

---

## Endpoint Summary

| Method | Endpoint | Auth Required | Description |
|--------|----------|:---:|---------|
| `POST` | `/api/Auth/register-user` | No | Register a new user account |
| `POST` | `/api/Auth/login-user` | No | Log in and receive access and refresh tokens |
| `POST` | `/api/Auth/refresh-tokens` | No | Exchange a refresh token for a new token pair |
| `POST` | `/api/Auth/get-reset-password-token` | No | Request a password reset OTP sent via email |
| `POST` | `/api/Auth/reset-password` | No | Reset password using the OTP received by email |
| `POST` | `/api/Auth/change-password` | 🔒 Yes | Change password while authenticated |
| `GET` | `/api/Auth/login-google` | No | Initiate Google OAuth login flow |
| `GET` | `/api/Auth/google-callback` | No | OAuth callback — returns tokens after Google authentication |
| `POST` | `/api/Auth/update-user-image` | 🔒 Yes | Replace the authenticated user's profile image |
| `POST` | `/api/Auth/logout` | 🔒 Yes | Invalidate the current refresh token |
| `GET` | `/api/Auth/user-profile` | 🔒 Yes | Retrieve the authenticated user's profile |
| `POST` | `/api/Auth/update-user-profile` | 🔒 Yes | Update the authenticated user's profile fields |

---

## Endpoint 1 — Register User

### Description

Creates a new user account. Accepts `multipart/form-data` to allow an optional profile image to be uploaded alongside the registration fields.

### Request

```
POST https://ema2a.mooo.com/api/Auth/register-user
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `multipart/form-data` |

#### Request Body — `RegisterDTO` (form-data)

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Email` | string | ✅ | The user's email address. |
| `FullName` | string | ✅ | The user's full name. |
| `UserName` | string | ✅ | The user's chosen username. |
| `Password` | string | ✅ | The user's password. |
| `PhoneNumber` | string | ✅ | The user's phone number. |
| `UserImage` | file | Optional | Profile image file to upload. |

---

### Response

#### Success — `200 OK`

Returns an `ApplicationUserDTO` with the created user's details.

```json
{
  "success": true,
  "data": {
    "email": "user@example.com",
    "fullName": "John Doe",
    "userName": "johndoe",
    "phoneNumber": "01012345678",
    "base64UserImage": "data:image/png;base64,iVBORw0KGgo..."
  },
  "errorMessage": "",
  "statusCode": 200
}
```

> **Note:** `base64UserImage` will be `null` or empty if no image was uploaded.

#### Error — `400 Bad Request`

Returned when the request body is null or the service layer reports a validation/business logic failure (e.g. username or email already taken).

```json
{
  "success": false,
  "data": null,
  "errorMessage": "<service error message>",
  "statusCode": 400
}
```

#### Error — `500 Internal Server Error`

```json
{
  "success": false,
  "data": null,
  "errorMessage": "An unexpected error occurred: <details>",
  "statusCode": 500
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | User registered — `data` contains the new user's `ApplicationUserDTO`. |
| `400` | Bad Request | Request body is null, or a validation/business logic error occurred (e.g. duplicate username). |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 2 — Login User

### Description

Authenticates a user with a username and password. On success, returns a JWT access token and a refresh token.

### Request

```
POST https://ema2a.mooo.com/api/Auth/login-user
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |

#### Request Body — `LoginDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `UserName` | string | ✅ | The user's username. |
| `Password` | string | ✅ | The user's password. |

#### Example Request Body

```json
{
  "UserName": "johndoe",
  "Password": "P@ssw0rd!"
}
```

---

### Response

#### Success — `200 OK`

Returns a `TokenResponseDTO` with the access and refresh tokens.

```json
{
  "success": true,
  "data": {
    "accessToken": "<JWT access token>",
    "refreshToken": "<refresh token>",
    "accessTokenExpires": "2026-02-26T15:00:00Z",
    "refreshTokenExpires": "2026-03-26T15:00:00Z"
  },
  "errorMessage": "",
  "statusCode": 200
}
```

#### `TokenResponseDTO` Fields

| Field | Type | Description |
|-------|------|-------------|
| `accessToken` | string | JWT token to be sent as a Bearer token in the `Authorization` header for protected endpoints. |
| `refreshToken` | string | Long-lived token used to obtain a new token pair via `refresh-tokens`. |
| `accessTokenExpires` | DateTime | UTC expiry timestamp of the access token. |
| `refreshTokenExpires` | DateTime | UTC expiry timestamp of the refresh token. |

#### Error — `400 Bad Request`

Returned when the request body is null or credentials are invalid.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "<service error message>",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Login successful — `data` contains `TokenResponseDTO`. |
| `400` | Bad Request | Request body is null or credentials are invalid. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 3 — Refresh Tokens

### Description

Exchanges a valid, non-expired refresh token for a new access token and refresh token pair. Use this endpoint to silently re-authenticate users when their access token has expired.

### Request

```
POST https://ema2a.mooo.com/api/Auth/refresh-tokens
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |

#### Request Body — `TokenRequestDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `RefreshToken` | string | ✅ | The refresh token previously issued by `login-user`, `google-callback`, or a previous `refresh-tokens` call. |

#### Example Request Body

```json
{
  "RefreshToken": "<refresh token>"
}
```

---

### Response

#### Success — `200 OK`

Returns a new `TokenResponseDTO` with a fresh access token and refresh token.

```json
{
  "success": true,
  "data": {
    "accessToken": "<new JWT access token>",
    "refreshToken": "<new refresh token>",
    "accessTokenExpires": "2026-02-26T16:00:00Z",
    "refreshTokenExpires": "2026-03-26T16:00:00Z"
  },
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `401 Unauthorized`

Returned when the refresh token is invalid, expired, or not found.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Invaild Refresh Token !",
  "statusCode": 401
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | New token pair issued — `data` contains `TokenResponseDTO`. |
| `401` | Unauthorized | Refresh token is invalid, expired, or missing. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 4 — Get Reset Password Token

### Description

Triggers a password reset flow for the given email address. If the email belongs to a registered user, a one-time OTP is generated and sent to that email. The OTP expires after **10 minutes** and can only be used once.

### Request

```
POST https://ema2a.mooo.com/api/Auth/get-reset-password-token
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |

#### Request Body — `GetResetPasswordTokenByEmailDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Email` | string | ✅ | The email address associated with the account to reset. |

#### Example Request Body

```json
{
  "Email": "user@example.com"
}
```

---

### Response

#### Success — `200 OK`

Indicates the OTP email was sent successfully. The `data` field will be `true`.

```json
{
  "success": true,
  "data": true,
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when the email field is empty, or the service layer reports a failure (e.g. email not registered).

```json
{
  "success": false,
  "data": null,
  "errorMessage": "<service error message>",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | OTP generated and email sent — `data` is `true`. |
| `400` | Bad Request | Email is empty, or the email is not associated with any account. |
| `500` | Internal Server Error | OTP generated but email sending failed, or an unexpected error occurred. |

> **Note:** The OTP is valid for **10 minutes** and is single-use. It must be submitted to the `reset-password` endpoint to complete the flow.

---

## Endpoint 5 — Reset Password

### Description

Completes the password reset flow. Accepts the OTP received by email and the desired new password. On success, the user's password is updated.

### Request

```
POST https://ema2a.mooo.com/api/Auth/reset-password
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |

#### Request Body — `ResetPasswordDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `OTP` | string | ✅ | The one-time password received via email from `get-reset-password-token`. |
| `NewPassword` | string | ✅ | The new password to set for the account. |

#### Example Request Body

```json
{
  "OTP": "847291",
  "NewPassword": "NewP@ssw0rd!"
}
```

---

### Response

#### Success — `200 OK`

```json
{
  "success": true,
  "data": true,
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when `NewPassword` is empty, `OTP` is null, or the service layer rejects the reset (e.g. invalid or expired OTP).

```json
{
  "success": false,
  "data": null,
  "errorMessage": "<service error message>",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Password reset successfully — `data` is `true`. |
| `400` | Bad Request | `NewPassword` is empty, `OTP` is null, or the OTP is invalid/expired. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 6 — Change Password 🔒

### Description

Allows an authenticated user to change their password by providing their current password and a new one. Requires a valid Bearer token.

### Request

```
POST https://ema2a.mooo.com/api/Auth/change-password
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

#### Request Body — `ChangePasswordDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `CurrentPassword` | string | ✅ | The user's current password. |
| `NewPassword` | string | ✅ | The new password to set. |

#### Example Request Body

```json
{
  "CurrentPassword": "OldP@ssw0rd!",
  "NewPassword": "NewP@ssw0rd!"
}
```

---

### Response

#### Success — `200 OK`

```json
{
  "success": true,
  "data": true,
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when the service layer rejects the change (e.g. current password is incorrect).

```json
{
  "success": false,
  "data": null,
  "errorMessage": "<service error message>",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Password changed successfully — `data` is `true`. |
| `400` | Bad Request | Current password is incorrect or other validation failure. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 7 — Login with Google

### Description

Initiates the Google OAuth 2.0 login flow by redirecting the client to Google's authentication page. This is a browser-redirect-based flow — it is not a JSON API call. After the user authenticates with Google, they are redirected to the `google-callback` endpoint automatically.

### Request

```
GET https://ema2a.mooo.com/api/Auth/login-google
```

> **Note:** This endpoint returns an HTTP redirect (`Challenge`) to Google's OAuth page. It is not intended to be called with `fetch`/`XMLHttpRequest`. Navigate the user's browser directly to this URL to begin the OAuth flow.

---

## Endpoint 8 — Google Callback

### Description

The OAuth 2.0 redirect target that Google returns the user to after successful authentication. This endpoint exchanges the external authentication result for an application token pair and optionally a user profile image. The external Google cookie is cleared after the token is issued.

> This endpoint is called automatically by Google's OAuth flow — it should not be invoked directly by clients.

### Request

```
GET https://ema2a.mooo.com/api/Auth/google-callback
```

---

### Response

#### Success — `200 OK`

Returns an `ExternalLoginResponseDTO` containing the token pair and the user's profile image.

```json
{
  "success": true,
  "data": {
    "tokenResponseDTO": {
      "accessToken": "<JWT access token>",
      "refreshToken": "<refresh token>",
      "accessTokenExpires": "2026-02-26T15:00:00Z",
      "refreshTokenExpires": "2026-03-26T15:00:00Z"
    },
    "base64Image": "data:image/png;base64,iVBORw0KGgo..."
  },
  "errorMessage": "",
  "statusCode": 200
}
```

#### `ExternalLoginResponseDTO` Fields

| Field | Type | Description |
|-------|------|-------------|
| `tokenResponseDTO` | object | Standard token pair — same structure as the `login-user` response. |
| `base64Image` | string | The user's profile image as a base64-encoded string, if available. May be empty. |

#### Error — `400 Bad Request`

Returned when the service layer fails to issue a JWT token.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "JWT token not issued",
  "statusCode": 400
}
```

#### Error — `401 Unauthorized`

Returned when Google's external authentication result is unsuccessful.

```
External authentication failed.
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Google login successful — `data` contains `ExternalLoginResponseDTO`. |
| `400` | Bad Request | Token could not be issued after successful Google authentication. |
| `401` | Unauthorized | Google external authentication failed. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 9 — Update User Image 🔒

### Description

Replaces the authenticated user's profile image. Accepts `multipart/form-data` with the new image file. Returns the new image as a base64-encoded string on success.

### Request

```
POST https://ema2a.mooo.com/api/Auth/update-user-image
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `multipart/form-data` |
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

#### Request Body — `ChangeUserImageDTO` (form-data)

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `NewImge` | file | ✅ | The new profile image file to upload. |

---

### Response

#### Success — `200 OK`

Returns the new profile image as a base64-encoded data URI string.

```json
{
  "success": true,
  "data": "data:image/png;base64,iVBORw0KGgo...",
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when no image file is provided, or the service layer reports a failure.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "No Image Provided",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Image updated — `data` is the new image as a base64 data URI string. |
| `400` | Bad Request | No image provided, or the service layer rejected the update. |
| `500` | Internal Server Error | Failed to extract user identity from token, or an unexpected error occurred. |

---

## Endpoint 10 — Logout 🔒

### Description

Invalidates the provided refresh token, effectively ending the user's session. The access token itself is not revoked (it will expire naturally), so clients should discard it locally after calling this endpoint.

### Request

```
POST https://ema2a.mooo.com/api/Auth/logout
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

#### Request Body — `TokenRequestDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `RefreshToken` | string | ✅ | The refresh token to invalidate. |

#### Example Request Body

```json
{
  "RefreshToken": "<refresh token>"
}
```

---

### Response

#### Success — `200 OK`

```json
{
  "success": true,
  "data": true,
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when the refresh token is not found or could not be invalidated.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Error",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Refresh token invalidated — `data` is `true`. |
| `400` | Bad Request | Refresh token not found or could not be invalidated. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 11 — User Profile 🔒

### Description

Returns the full profile of the currently authenticated user.

### Request

```
GET https://ema2a.mooo.com/api/Auth/user-profile
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

---

### Response

#### Success — `200 OK`

Returns a `UserProfileDTO` with the user's profile details.

```json
{
  "success": true,
  "data": {
    "fullName": "John Doe",
    "email": "user@example.com",
    "userBase64Image": "data:image/png;base64,iVBORw0KGgo...",
    "phoneNumber": "01012345678",
    "userName": "johndoe"
  },
  "errorMessage": "",
  "statusCode": 200
}
```

#### `UserProfileDTO` Fields

| Field | Type | Description |
|-------|------|-------------|
| `fullName` | string | The user's full name. |
| `email` | string | The user's email address. |
| `userBase64Image` | string | The user's profile image as a base64-encoded data URI string. |
| `phoneNumber` | string | The user's phone number. |
| `userName` | string | The user's username. |

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | `data` contains the user's `UserProfileDTO`. |
| `400` | Bad Request | Service layer failed to retrieve the profile. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 12 — Update User Profile 🔒

### Description

Updates one or more profile fields of the authenticated user. All fields are optional — only the fields provided will be updated.

### Request

```
POST https://ema2a.mooo.com/api/Auth/update-user-profile
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

#### Request Body — `UpdateUserProfileDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `FullName` | string | Optional | New full name to set. |
| `Email` | string | Optional | New email address to set. |
| `PhoneNumber` | string | Optional | New phone number to set. |
| `UserName` | string | Optional | New username to set. |

#### Example Request Body

```json
{
  "FullName": "Jane Doe",
  "Email": "jane@example.com",
  "PhoneNumber": "01098765432",
  "UserName": "janedoe"
}
```

---

### Response

#### Success — `200 OK`

Returns the updated `UserProfileDTO`.

```json
{
  "success": true,
  "data": {
    "fullName": "Jane Doe",
    "email": "jane@example.com",
    "userBase64Image": "data:image/png;base64,iVBORw0KGgo...",
    "phoneNumber": "01098765432",
    "userName": "janedoe"
  },
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when the service layer rejects the update (e.g. username or email already taken).

```json
{
  "success": false,
  "data": null,
  "errorMessage": "<service error message>",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Profile updated — `data` contains the updated `UserProfileDTO`. |
| `400` | Bad Request | Service layer rejected the update (e.g. duplicate username or email). |
| `500` | Internal Server Error | An unexpected server error occurred. |