# Sign Language Translator — API Documentation

**Base URL:** `https://ema2a.mooo.com`  
**Controller prefix:** `/api/SignLanguageTranslator`

---

## Overview

The Sign Language Translator API provides a set of endpoints to support real-time Arabic sign language translation. It exposes functionality for: detecting and translating sign gestures from image frames, correcting and finalizing recognized letter sequences into coherent Arabic sentences, and converting text to speech audio.

All endpoints are prefixed with `/api/SignLanguageTranslator` and accept/return JSON unless otherwise noted.

**Full base path:** `https://ema2a.mooo.com/api/SignLanguageTranslator`

---

## Common Response Envelope

All endpoints return a standard `APIResponseDTO<T>` wrapper object:

```json
{
  "success": true | false,
  "data": <generic object (depends on the endpoint)>,
  "errorMessage": "string (empty on success)",
  "statusCode": <HTTP status code>
}
```

On success, `data` carries the endpoint-specific payload. On failure, `data` is `null` and `errorMessage` contains a human-readable description of the error.

---

## Endpoint Summary

| Method | Endpoint                                              | Rate Limited | Purpose                                                         |
| ------ | ----------------------------------------------------- | :----------: | --------------------------------------------------------------- |
| `POST` | `/api/SignLanguageTranslator/finalize-sentence`       |     Yes      | Correct and space concatenated Arabic letters into a sentence   |
| `POST` | `/api/SignLanguageTranslator/generate-audio`          |     Yes      | Convert Arabic text to speech audio via Gemini TTS (Kore voice) |
| `POST` | `/api/SignLanguageTranslator/text-to-speech/hardware` |     Yes      | Convert Arabic text to speech via Azure TTS (ar-EG-SalmaNeural) |

---

## Endpoint 1 — Finalize Sentence

### Description

Takes a raw string of concatenated Arabic letters and uses the Gemini AI model to insert spaces and correct minor spelling errors, returning a properly formed Arabic sentence. This endpoint is rate-limited and supports two client modes: `frontend` and `hardware`.

### Request

```
POST https://ema2a.mooo.com/api/SignLanguageTranslator/finalize-sentence?client={client}
```

#### Query Parameters

|Parameter|Type|Required|Description|
|---|---|:-:|---|
|`client`|string|Optional|Identifies the caller. Allowed values: `frontend` _(default)_ or `hardware`. Controls which API key set is used internally.|

#### Headers

|Field|Type|Required|Description|
|---|---|:-:|---|
|`Content-Type`|string|✅|Must be `application/json`|

#### Request Body — `SentenceData`

|Field|Type|Required|Description|
|---|---|:-:|---|
|`Sentence`|string|✅|The concatenated Arabic letters/text to be corrected and spaced.|

#### Example Request

```
POST https://ema2a.mooo.com/api/SignLanguageTranslator/finalize-sentence?client=frontend
```

```json
{
  "Sentence": "مرحبكيفحالك"
}
```

---

### Response

#### Success — `200 OK`

```json
{
  "success": true,
  "data": "مرحبا كيف حالك",
  "errorMessage": "",
  "statusCode": 200
}
```

#### Success — `200 OK` (fallback)

If the AI model returns an empty or unparseable result, `data` will be the string `"None"`:

```json
{
  "success": true,
  "data": "None",
  "errorMessage": "",
  "statusCode": 200
}
```

#### Error — `400 Bad Request`

```json
{
  "success": false,
  "data": null,
  "errorMessage": "No sentence data provided.",
  "statusCode": 400
}
```

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Invalid format. Allowed values are 'frontend' or 'hardware'.",
  "statusCode": 400
}
```

#### All Possible Responses

|HTTP Code|Status|Description|
|:-:|---|---|
|`200`|Success|Corrected sentence returned as a plain string in `data`.|
|`200`|Success (fallback)|AI returned empty/unparseable content — `data` is the string `"None"`.|
|`400`|Bad Request|`Sentence` field is empty, `client` parameter is missing, or `client` value is not `frontend` or `hardware`.|
|`500`|Internal Server Error|HTTP request to the Gemini API failed, or an unexpected server error occurred.|

> **Note:** This endpoint is rate-limited (GeminiLimiter policy). If the primary API key is rate-limited (HTTP 429), the server automatically retries with a backup key. The client does not need to handle this — if both keys are exhausted, a `500` error is returned.

---

## Endpoint 2 — Generate Audio

### Description

Converts a plain text string to speech audio using the Gemini TTS model. Returns the generated audio as a base64-encoded string along with the sample rate, suitable for playback in a browser or native application. The voice used is **Kore** with a clear, friendly tone.

### Request

```
POST https://ema2a.mooo.com/api/SignLanguageTranslator/generate-audio
```

#### Headers

|Field|Type|Required|Description|
|---|---|:-:|---|
|`Content-Type`|string|✅|Must be `application/json`|

#### Request Body — `TTSRequest`

|Field|Type|Required|Description|
|---|---|:-:|---|
|`text`|string|✅|The text to be converted to speech audio.|

#### Example Request Body

```json
{
  "text": "مرحبا كيف حالك"
}
```

---

### Response

#### Success — `200 OK`

Returns a `TTSResponse` object wrapped in the standard envelope:

```json
{
  "success": true,
  "data": {
    "audioData": "<base64-encoded audio string>",
    "sampleRate": 24000
  },
  "errorMessage": "",
  "statusCode": 200
}
```

#### `TTSResponse` Fields

|Field|Type|Description|
|---|---|---|
|`audioData`|string|Base64-encoded raw audio data returned by the Gemini TTS model.|
|`sampleRate`|integer|Sample rate in Hz. Parsed from the Gemini response MIME type (e.g. `24000`). Defaults to `24000` if not present in the MIME type.|

#### Error — `400 Bad Request`

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Missing 'text' field. Please provide the text to convert to audio.",
  "statusCode": 400
}
```

#### All Possible Responses

|HTTP Code|Status|Description|
|:-:|---|---|
|`200`|Success|Audio generated successfully. `data` contains `audioData` and `sampleRate`.|
|`400`|Bad Request|The `text` field is missing or empty.|
|`500`|Internal Server Error|Gemini API call failed, or an unexpected server error occurred.|

> **Note:** This endpoint is rate-limited (GeminiLimiter policy). If the primary Gemini TTS key is rate-limited, the server automatically retries with a backup key before returning an error.

---

## Endpoint 3 — Text-to-Speech (Hardware)

### Description

Converts Arabic text to speech using Microsoft Azure Cognitive Services TTS, specifically the **ar-EG-SalmaNeural** voice at 16kHz mono MP3 quality. This endpoint is intended for hardware clients. The response can be returned either as a raw MP3 file download or as a base64-encoded string, controlled by the `format` query parameter.

### Request

```
POST https://ema2a.mooo.com/api/SignLanguageTranslator/text-to-speech/hardware?format={format}
```

#### Query Parameters

|Parameter|Type|Required|Description|
|---|---|:-:|---|
|`format`|string|Optional|Output format. Allowed values: `mp3` _(default)_ — returns a raw `audio/mpeg` file download. `base64` — returns a JSON response with base64-encoded audio and sample rate.|

#### Headers

|Field|Type|Required|Description|
|---|---|:-:|---|
|`Content-Type`|string|✅|Must be `application/json`|

#### Request Body — `TTSRequest`

|Field|Type|Required|Description|
|---|---|:-:|---|
|`text`|string|✅|The Arabic text to be converted to speech.|

#### Example Requests

Return as MP3 file (default):

```
POST https://ema2a.mooo.com/api/SignLanguageTranslator/text-to-speech/hardware?format=mp3
```

Return as base64 JSON:

```
POST https://ema2a.mooo.com/api/SignLanguageTranslator/text-to-speech/hardware?format=base64
```

Request body (both formats):

```json
{
  "text": "مرحبا"
}
```

---

### Response

#### `format=mp3` — `200 OK`

Returns the audio as a raw file download:

|Header|Value|
|---|---|
|`Content-Type`|`audio/mpeg`|
|`Content-Disposition`|`attachment; filename=speech.mp3`|
|Body|Raw MP3 audio bytes — 16kHz, 32kbps, mono.|

#### `format=base64` — `200 OK`

Returns a JSON envelope with a `TTSResponse` payload:

```json
{
  "success": true,
  "data": {
    "audioData": "<base64-encoded MP3 string>",
    "sampleRate": 16000
  },
  "errorMessage": "",
  "statusCode": 200
}
```

> `sampleRate` is always `16000` for this endpoint, as Azure is configured to output 16kHz audio.

#### Error — `400 Bad Request`

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Missing 'text' field. Please provide the text to convert to audio.",
  "statusCode": 400
}
```

```json
{
  "success": false,
  "data": null,
  "errorMessage": "Invalid format. Allowed values are 'mp3' or 'base64'.",
  "statusCode": 400
}
```

#### All Possible Responses

| HTTP Code | Status                | Description                                                                                       |
| :-------: | --------------------- | ------------------------------------------------------------------------------------------------- |
|   `200`   | Success (mp3)         | Raw MP3 binary stream returned as file download.                                                  |
|   `200`   | Success (base64)      | Base64-encoded MP3 audio returned in standard JSON envelope.                                      |
|   `400`   | Bad Request           | `text` field is empty, `format` parameter is missing, or `format` value is not `mp3` or `base64`. |
|   `500`   | Internal Server Error | Azure TTS API call failed or an unexpected server error occurred.                                 |

> **Note:** This endpoint is rate-limited (GeminiLimiter policy). Unlike the other TTS endpoint, this one does **not** have a backup key fallback — if the Azure API fails, a `500` error is returned directly.