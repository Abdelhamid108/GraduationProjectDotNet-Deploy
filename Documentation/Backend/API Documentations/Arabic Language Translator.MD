# Arabic Language Translator — API Documentation

**Base URL:** `https://ema2a.mooo.com`  
**Controller prefix:** `/api/ArabicLanguageTranslator`

---

## Overview

The Arabic Language Translator API provides endpoints for bridging Arabic text, audio, and sign language. It exposes functionality for: converting Arabic text into sequences of sign language gesture images (letter by letter), transcribing Arabic speech audio into text, and retrieving the sign language gesture image for a single Arabic letter.

All endpoints are prefixed with `/api/ArabicLanguageTranslator` and accept/return JSON.

**Full base path:** `https://ema2a.mooo.com/api/ArabicLanguageTranslator`

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

## Rate Limiting

| Policy | Applies To | Limit |
|--------|-----------|-------|
| `ArabicLimiter` | `text-to-sign`, `letters-keyboard` | 30 requests per minute per client. No queuing — requests exceeding the limit are rejected immediately. |
| `GeminiLimiter` | `audio-to-text` | Governed by the GeminiLimiter policy (see the Sign Language Translator API docs for details). |

---

## Endpoint Summary

| Method | Endpoint | Rate Limited | Purpose |
|--------|----------|:---:|---------|
| `POST` | `/api/ArabicLanguageTranslator/text-to-sign` | Yes (ArabicLimiter) | Convert an Arabic text string into grouped sign language gesture images |
| `POST` | `/api/ArabicLanguageTranslator/audio-to-text` | Yes (GeminiLimiter) | Transcribe Arabic speech audio into text |
| `GET` | `/api/ArabicLanguageTranslator/letters-keyboard` | Yes (ArabicLimiter) | Retrieve the sign language gesture image for a single Arabic letter |

---

## Endpoint 1 — Text to Sign

### Description

Accepts an Arabic text string and returns a two-dimensional list of base64-encoded PNG images representing the sign language gestures for each letter. The outer list represents words (split by spaces), and the inner list represents the individual letter images within each word. Letters not found in the sign language dictionary are silently skipped.

### Request

```
POST https://ema2a.mooo.com/api/ArabicLanguageTranslator/text-to-sign
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |

#### Request Body — `TextToSignDTO`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Text` | string | ✅ | The Arabic text to convert into sign language gesture images. Words are split by spaces. |

#### Example Request Body

```json
{
  "Text": "مرحبا"
}
```

---

### Response

#### Success — `200 OK`

Returns a `List<List<string>>` where each inner list contains the base64-encoded PNG images for the letters of one word, in order.

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
    ]
  ],
  "errorMessage": "",
  "statusCode": 200
}
```

> **Note:** The response structure is always `List<List<string>>` — one inner list per word in the input. Letters not found in the sign language dictionary are silently omitted from the inner list. If a word contains no recognizable letters at all, an empty inner list `[]` is still included for that word.

#### Error — `400 Bad Request`

Returned when the `Text` field is missing or empty.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "No text provided.",
  "statusCode": 400
}
```

#### Error — `500 Internal Server Error`

Returned when an unexpected server-side error occurs during processing.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "An error occurred: <exception message>",
  "statusCode": 500
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | `data` contains a `List<List<string>>` of base64-encoded PNG images grouped by word. |
| `400` | Bad Request | `Text` field is missing or empty. |
| `500` | Internal Server Error | An unexpected error occurred while processing the request. |

---

## Endpoint 2 — Audio to Text

### Description

Accepts a base64-encoded audio clip and its MIME type, then uses the Gemini AI model to transcribe the Arabic speech content into text. Only human speech is transcribed — non-speech sounds and background noise are excluded from the output.

### Request

```
POST https://ema2a.mooo.com/api/ArabicLanguageTranslator/audio-to-text
```

#### Headers

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `Content-Type` | string | ✅ | Must be `application/json` |

#### Request Body — `TranscriptionRequest`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `AudioData` | string | ✅ | Base64-encoded audio data to be transcribed. |
| `MimeType` | string | ✅ | MIME type of the audio `audio/webm` 

#### Example Request Body

```json
{
  "AudioData": "/9j/4AAQSkZJRgAB...",
  "MimeType": "audio/webm"
}
```

---

### Response

#### Success — `200 OK`

Returns the transcribed Arabic text as a plain string in `data`.

```json
{
  "success": true,
  "data": "مرحبا كيف حالك",
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when `AudioData` or `MimeType` is missing or empty.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Audio data or MIME type not provided.",
  "statusCode": 400
}
```

#### Error — `500 Internal Server Error`

Returned when the Gemini API returns an empty transcription, or when a JSON parsing error or unexpected exception occurs.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Gemini API did not return a valid transcription.",
  "statusCode": 500
}
```

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Error parsing Gemini API response: <details>",
  "statusCode": 500
}
```

```json
{
  "success": false,
  "data": null,
  "errorMessage": "An unexpected error occurred: <details>",
  "statusCode": 500
}
```

#### Error — `502 Bad Gateway`

Returned when the HTTP request to the Gemini API fails entirely (e.g. network error or service unavailable).

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Error calling Gemini API: <details>",
  "statusCode": 502
}
```

#### All Possible Responses

| HTTP Code | Status | Description |
|:---------:|--------|-------------|
| `200` | Success | `data` contains the transcribed Arabic text as a plain string. |
| `400` | Bad Request | `AudioData` or `MimeType` is missing or empty. |
| `500` | Internal Server Error | Gemini returned an empty transcription, a JSON parsing error occurred, or an unexpected exception was thrown. |
| `502` | Bad Gateway | The HTTP request to the Gemini API failed (network or service error). |

> **Note:** This endpoint is rate-limited (GeminiLimiter policy). If the primary Gemini API key is rate-limited (HTTP 429), the server automatically retries with a backup key. The client does not need to handle this — if both keys are exhausted, a `500` error is returned.

---

## Endpoint 3 — Letters Keyboard

### Description

Accepts a single Arabic letter as a query parameter and returns its corresponding sign language gesture image as a base64-encoded PNG string. This is intended to support virtual keyboard UIs where users tap a letter to see its gesture.

### Request

```
GET https://ema2a.mooo.com/api/ArabicLanguageTranslator/letters-keyboard?letter={letter}
```

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `letter` | char | ✅ | A single Arabic letter character to look up (e.g. `ب`, `م`, `ر`). |

#### Example Request

```
GET https://ema2a.mooo.com/api/ArabicLanguageTranslator/letters-keyboard?letter=ب
```

---

### Response

#### Success — `200 OK`

Returns the gesture image as a base64-encoded PNG data URI string in `data`.

```json
{
  "success": true,
  "data": "data:image/png;base64,iVBORw0KGgoAAAANS...",
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

Returned when the `letter` parameter is missing, or the letter is not found in the sign language dictionary.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Letter parameter is required.",
  "statusCode": 400
}
```

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Letter 'X' not found in dictionary.",
  "statusCode": 400
}
```

#### Error — `500 Internal Server Error`

Returned when the letter exists in the dictionary but its image file is missing from the server, or when an unexpected exception occurs.

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Image file not found on server.",
  "statusCode": 500
}
```

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
| `200` | Success | `data` contains a `data:image/png;base64,...` string for the requested letter. |
| `400` | Bad Request | `letter` parameter is missing, or the letter is not in the sign language dictionary. |
| `500` | Internal Server Error | Image file is missing from the server, or an unexpected error occurred. |