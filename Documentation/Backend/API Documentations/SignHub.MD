# SignHub — WebSocket API Documentation

**Base URL:** `https://ema2a.mooo.com`  
**Hub endpoint:** `/signHub`

---

## Overview

The Sign Language Translator WebSocket API provides a real-time, bidirectional communication channel for Arabic sign language detection. It is built on **SignalR** and is intended to be used alongside or as an alternative to the REST API for scenarios requiring continuous frame-by-frame translation with lower latency.

Clients connect to the hub, send image frames, and receive translation results pushed back by the server — all over a persistent connection.

**Full hub URL:** `https://ema2a.mooo.com/signHub`

---

## Connection

### Establishing a Connection

Connect to the hub using a SignalR client library. The hub URL is:

```
https://ema2a.mooo.com/signHub
```

#### JavaScript Example (SignalR Client)

```javascript
const connection = new signalR.HubConnectionBuilder()
  .withUrl("https://ema2a.mooo.com/signHub")
  .build();

// Start the connection
await connection.start();
```

#### Connection Lifecycle

| Event | Description |
|-------|-------------|
| Connected | A persistent connection to the hub is established. The client is ready to send frames and receive messages. |
| Disconnected | The connection has been closed, either by the client, server, or due to a network issue. |

---

## Hub Summary

| Direction | Method / Event | Description |
|-----------|---------------|-------------|
| Client → Server | `ProcessFrame` | Send a base64-encoded JPEG image frame for translation. |
| Server → Client | `ReceiveTranslation` | Receive a translation result or status message for each processed frame. |

---

## Client-to-Server — `ProcessFrame`

### Description

Invoked by the client to submit a single image frame for sign language detection. The server processes the frame through the detection model and pushes the result back to the caller via `ReceiveTranslation`. This method is designed to be called repeatedly in a real-time loop.

### Invocation

```
Hub Method: ProcessFrame
```

#### Parameters — `FrameData`

| Field | Type | Required | Description |
|-------|------|:--------:|-------------|
| `ImageData` | string | ✅ | Base64-encoded JPEG image. May include the data URI prefix `data:image/jpeg;base64,` which will be automatically stripped. |

#### Example Invocation (JavaScript)

```javascript
await connection.invoke("ProcessFrame", {
  ImageData: "data:image/jpeg;base64,/9j/4AAQSkZJRgAB..."
});
```

---

## Server-to-Client — `ReceiveTranslation`

### Description

The server pushes a response to the caller after every `ProcessFrame` invocation. The client must register a handler for this event before sending frames. The payload is always a single plain string.

### Handler Registration

```javascript
connection.on("ReceiveTranslation", (message) => {
  console.log("Translation:", message);
});
```

### Response Payload

| Type | Description |
|------|-------------|
| `string` | A plain string containing the translation result or a status/error message. |

---

### All Possible `ReceiveTranslation` Messages

#### Acknowledgement message

Sent immediately upon receiving any frame, before processing begins:

```
"Frame received at 14:23:05"
```

> **Note:** A timestamp acknowledgement is **always** sent first on every `ProcessFrame` call, before the translation result. Clients should expect two messages per invocation: the acknowledgement, followed by the result.

#### Gesture detected (confidence > 0.71)

The Arabic label of the detected sign:

```
"ب"
```

#### No confident match (confidence ≤ 0.71)

```
"No confident match"
```

#### No sign detected

Sent when the model finds no detections at all, or the detection pipeline reports failure:

```
"No sign detected"
```

#### Invalid image

Sent when `ImageData` is null or empty:

```
"Invalid image"
```

#### Server error

Sent when an unexpected exception occurs during processing:

```
"Error: <exception message>"
```

---

### Message Summary

| Message | Trigger |
|---------|---------|
| `"Frame received at {time}"` | Always sent immediately on every `ProcessFrame` call before processing. |
| `"{Arabic label}"` | Gesture detected with confidence **above 0.71** — returns the Arabic class label. |
| `"No confident match"` | Best detection found but confidence is **at or below 0.71**. |
| `"No sign detected"` | Model returned no detections, or detection pipeline was unsuccessful. |
| `"Invalid image"` | `ImageData` is null or empty. |
| `"Error: <details>"` | An unexpected server-side exception occurred. |

> **Note:** The confidence threshold is fixed at **0.71** on the server side. Clients do not need to perform any confidence filtering.

---

## Full Usage Example (JavaScript)

```javascript
const connection = new signalR.HubConnectionBuilder()
  .withUrl("https://ema2a.mooo.com/signHub")
  .build();

// Register handler BEFORE starting the connection
connection.on("ReceiveTranslation", (message) => {
  console.log("Received:", message);
});

// Start connection
await connection.start();

// Send a frame
await connection.invoke("ProcessFrame", {
  ImageData: "data:image/jpeg;base64,/9j/4AAQSkZJRgAB..."
});

// Stop connection when done
await connection.stop();
```