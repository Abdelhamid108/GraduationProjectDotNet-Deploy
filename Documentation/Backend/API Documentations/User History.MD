# User History — API Documentation

**Base URL:** `https://ema2a.mooo.com`  
**Controller prefix:** `/api/UserHistory`

---

## Overview

The User History API allows authenticated users to retrieve and manage their sign language translation history. Each record represents a sentence that was formed during a previous translation session. All endpoints in this controller require authentication.

**Full base path:** `https://ema2a.mooo.com/api/UserHistory`

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

All endpoints in this controller require a valid Bearer token:

```
Authorization: Bearer <AccessToken>
```

Requests without a valid token will be rejected by the server before reaching the endpoint.

---

## Endpoint Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/UserHistory/get-user-history` | Retrieve all history records for the authenticated user |
| `DELETE` | `/api/UserHistory/delete-user-history-record` | Delete a single history record by ID |
| `DELETE` | `/api/UserHistory/delete-all-user-history` | Delete all history records for the authenticated user |

---

## Endpoint 1 — Get User History 🔒

### Description

Returns a list of all translation history records belonging to the authenticated user, ordered as stored. Each record includes the formed sentence and the timestamp of when it was created.

### Request

```
GET https://ema2a.mooo.com/api/UserHistory/get-user-history
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

---

### Response

#### Success — `200 OK`

Returns a `List<UserRecordDTO>` containing all records for the authenticated user. Returns an empty list `[]` if the user has no history.

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "formedSentence": "مرحبا كيف حالك",
      "formedAt": "2026-02-26T14:30:00Z"
    },
    {
      "id": 2,
      "formedSentence": "أنا بخير شكرا",
      "formedAt": "2026-02-26T15:10:00Z"
    }
  ],
  "errorMessage": "",
  "statusCode": 200
}
```

#### `UserRecordDTO` Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | The unique identifier of the history record. Used to delete a specific record. |
| `formedSentence` | string | The Arabic sentence that was formed during the translation session. |
| `formedAt` | DateTime | UTC timestamp of when the sentence was formed. |

#### Error — `500 Internal Server Error`

```json
{
  "success": false,
  "data": null,
  "errorMessage": "An unexpected error occurred",
  "statusCode": 500
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | `data` contains a `List<UserRecordDTO>`. Returns an empty list if the user has no history. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 2 — Delete User History Record 🔒

### Description

Deletes a single translation history record by its ID. The record must exist in the database — the endpoint does not verify ownership against the authenticated user, so the correct `Id` must be provided.

### Request

```
DELETE https://ema2a.mooo.com/api/UserHistory/delete-user-history-record
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

#### Request Body — `DeleteUserRecordDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Id` | integer | ✅ | The ID of the history record to delete. Must be a non-zero integer. |

#### Example Request Body

```json
{
  "Id": 1
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

Returned when the request body is null, the `Id` is `0`, or no record with the given `Id` exists.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Null Record",
  "statusCode": 400
}
```

```json
{
  "success": false,
  "data": null,
  "errorMessage": "No Such Record",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | Record deleted — `data` is `true`. |
| `400` | Bad Request | Request body is null, `Id` is `0`, or no record with that `Id` exists. |
| `500` | Internal Server Error | An unexpected server error occurred. |

---

## Endpoint 3 — Delete All User History 🔒

### Description

Permanently deletes all translation history records belonging to the authenticated user. This action is irreversible.

### Request

```
DELETE https://ema2a.mooo.com/api/UserHistory/delete-all-user-history
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Authorization` | string | ✅ | `Bearer <AccessToken>` |

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

Returned when the authenticated user has no history records to delete.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "No Records",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | All records deleted — `data` is `true`. |
| `400` | Bad Request | The authenticated user has no history records. |
| `500` | Internal Server Error | An unexpected server error occurred. |

> **Warning:** This operation is irreversible. All history records for the authenticated user will be permanently removed.