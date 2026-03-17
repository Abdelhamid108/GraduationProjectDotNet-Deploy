
This document provides a comprehensive guide to the API, detailing the available endpoints, required parameters, and response formats to help you integrate our service into your applications.

### API Response Structure

All API endpoints return a standardized `APIResponseDTO` object, which provides a consistent way to handle both successful responses and errors.

```
{
  "errorMessage": "string",
  "data": {},
  "success": true,
  "statusCode": 200
}



```

- `errorMessage`: A string containing a detailed error message if the request was not successful. It is an empty string on success.
    
- `data`: The payload of the response. The type of this data varies depending on the endpoint. It can be a single object, an array, or `null`.
    
- `success`: A boolean indicating if the request was successful.
    
- `statusCode`: The HTTP status code of the response.
    

### Base URL

https://34.18.112.76/


### Authentication

Most endpoints require authentication. Once a user has logged in, an access token is provided in the `TokenResponseDTO`. This token should be included in the `Authorization` header of all subsequent protected requests using the Bearer scheme.

**Header:** `Authorization: Bearer YOUR_ACCESS_TOKEN`

### Data Transfer Objects (DTOs)

The following DTOs are used throughout the API to structure data for requests and responses.

### **1. Authentication Controller**

#### `LoginDTO`

Used for user login.

- `UserName` (string)
    
- `Password` (string)
    

#### `TokenResponseDTO`

Returned after a successful login or token refresh.

- `AccessToken` (string)
    
- `RefreshToken` (string)
    
- `AccessTokenExpires` (DateTime)
    
- `RefreshTokenExpires` (DateTime)
    

#### `RegisterDTO`

Used for user registration.

- `Email` (string)
    
- `FullName` (string)
    
- `UserName` (string) [💡 Note: can't contain \ / : ? * " <> |]
    
- `Password` (string)
    
- `PhoneNumber` (string)

- `UserImage` (IFormFile) [Not Required]
    

#### `ApplicationUserDTO`

Represents user data.

- `Email` (string)
    
- `FullName` (string)
    
- `UserName` (string)
    
- `PhoneNumber` (string)

- `ImagePath` (string)
    

#### `ChangePasswordDTO`

Used for changing a user's password.

- `CurrentPassword` (string)
    
- `NewPassword` (string)
    

#### `ResetPasswordDTO`

Used for resetting a password with a token.

- `TokenId` (Guid)
    
- `NewPassword` (string)
    

#### `TokenRequestDTO`

Used for refreshing an access token or logging out.

- `RefreshToken` (string)
    
#### `ExternalLoginResponseDTO`

Used for google login.

- `TokenResponseDTO` (object)
    
- `Base64Image` (string)

### **UpdateUserProfileDTO**

Used for updating user profile information.  
All fields are optional — only the fields that need to be updated should be sent.

- `FullName` (string?)
- `Email` (string?)
- `PhoneNumber` (string?)
- `UserName` (string?)

### **UserProfileDTO**

Represents a user's profile information.

- `FullName` (string)
- `Email` (string)
- `ImagePath` (string) — Base64-encoded image
- `PhoneNumber` (string)
- `UserName` (string)


### **2. Sign Language Translator Controller**


#### `FrameData`

Used to send image data for sign language translation.

- `ImageData` (string)
    

#### `SentenceData`

Used for the sentence correction request.

- `Sentence` (string)
    

#### `CorrectedResponse`

Represents the response from the sentence correction endpoint.

- `suggestion` (object)
    
    - `correctedSentence` (string)
        

#### `TTSRequest`

Used to request audio generation from text.

- `Text` (string)
    

#### `TTSResponse`

Represents the audio data from the TTS service.

- `AudioData` (string)
    
- `SampleRate` (integer)
    


### **3. Arabic Language Translator Controller**


#### `TextToSignDTO`

Used for the text-to-sign request.

- `Text` (string)
    


#### `TranscriptionRequest`

Used to send audio data for transcription.

- `AudioData` (string)
    
- `MimeType` (string)
    


### **3. User History Controller**

#### `UserRecordDTO`

Represents a single user history record.

- `Id` (integer)
    
- `FormedAt` (DateTime)
    
- `FormedSentence` (string)
    

#### `DeleteUserRecordDTO`

Used to delete a single user history record.

- `Id` (integer)
    


### Endpoints

#### Authentication Controller

This controller handles all user authentication, registration, and account management.

#### 1. Register a New User

- **Endpoint:** `/register-user`

- **Route:** `https://34.18.112.76/api/Auth/register-user`
    
- **Method:** `POST`
    
- **Description:** Creates a new user account.
    
- **Request Body (`RegisterDTO`):**
    
    ```
    {
      "email": "user@example.com",
      "fullName": "John Doe",
      "userName": "johndoe",
      "password": "SecurePassword123!",
      "phoneNumber": "123-456-7890",
      "UserImage": "file"
    }
    
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<ApplicationUserDTO>`
    
    ```
    {
      "errorMessage": "",
      "data": {
        "email": "user@example.com",
        "fullName": "John Doe",
        "userName": "johndoe",
        "phoneNumber": "123-456-7890",
        "ImagePath" "Base64Image"
      },
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<ApplicationUserDTO>`
    
    ```
    {
      "errorMessage": "Username already exists.",
      "data": null,
      "success": false,
      "statusCode": 400
    }
    
    
    
    ```
    

#### 2. User Login

- **Endpoint:** `/login-user`
    
- **Route:** `https://34.18.112.76/api/Auth/login-user`

- **Method:** `POST`
    
- **Description:** Authenticates a user and returns a new access and refresh token.
    
- **Request Body (`LoginDTO`):**
    
    ```
    {
      "userName": "johndoe",
      "password": "SecurePassword123!"
    }
    
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<TokenResponseDTO>`
    
    ```
    {
      "errorMessage": "",
      "data": {
        "accessToken": "ey...",
        "refreshToken": "ey...",
        "accessTokenExpires": "2023-10-27T16:00:00Z",
        "refreshTokenExpires": "2023-11-26T14:00:00Z"
      },
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<TokenResponseDTO>`
    
    ```
    {
      "errorMessage": "Invalid Credentials",
      "data": null,
      "success": false,
      "statusCode": 400
    }
    
    
    
    ```
    

#### 3. Refresh Access Token

- **Endpoint:** `/refresh-tokens`
    
- **Route:** `https://34.18.112.76/api/Auth/refresh-tokens`

- **Method:** `POST`
    
- **Description:** Renews the access and refresh tokens using an existing refresh token.
    
- **Request Body (`TokenRequestDTO`):**
    
    ```
    {
      "refreshToken": "ey..."
    }
    
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<TokenResponseDTO>`
    
    ```
    {
      "errorMessage": "",
      "data": {
        "accessToken": "ey...",
        "refreshToken": "ey...",
        "accessTokenExpires": "2023-10-27T16:00:00Z",
        "refreshTokenExpires": "2023-11-26T14:00:00Z"
      },
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```
    
- **Error Response (401 Unauthorized):** `APIResponseDTO<TokenResponseDTO>`
    
    ```
    {
      "errorMessage": "Invalid Refresh Token !",
      "data": null,
      "success": false,
      "statusCode": 401
    }
    
    
    
    ```
    

#### 4. Request Password Reset Token

- **Endpoint:** `/get-reset-password-token`
    
- **Route:** `https://34.18.112.76/api/Auth/get-reset-password-token`

- **Method:** `POST`
    
- **Description:** Sends a password reset token to the user's email address.
    
- **Query Parameter:** `email` (string)
    
- **Example Request:**
    
    ```
    POST /get-reset-password-token?Email=user@example.com
    
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "",
      "data": true,
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```
    

#### 5. Reset Password

- **Endpoint:** `/reset-password`

- **Route:** `https://34.18.112.76/api/Auth/reset-password`
    
- **Method:** `POST`
    
- **Description:** Resets a user's password using a token received via email.
    
- **Request Body (`ResetPasswordDTO`):**
    
    ```
    {
      "tokenId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "newPassword": "MyNewSecurePassword123!"
    }
    
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "",
      "data": true,
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```
    

#### 6. Change Password (Authorized)

- **Endpoint:** `/change-password`
    
- **Route:** `https://34.18.112.76/api/Auth/change-password`

- **Method:** `POST`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Allows an authenticated user to change their password.
    
- **Request Body (`ChangePasswordDTO`):**
    
    ```
    {
      "currentPassword": "SecurePassword123!",
      "newPassword": "MyNewSecurePassword123!"
    }
    
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "",
      "data": true,
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```
    

#### 7. Login with Google

- **Endpoint:** `/login-google`

- **Route:** `https://34.18.112.76/api/Auth/login-google`
    
- **Method:** `GET`
    
- **Description:** Initiates the Google external login flow. The user's browser will be redirected to the Google login page.
    

#### 8. Google Callback

- **Endpoint:** `/google-callback`
    
- **Route:** `https://34.18.112.76/api/Auth/google-callback`

- **Method:** `GET`
    
- **Description:** The callback URL that Google redirects to after a successful login. The API verifies Google authentication, extracts user details (email, name, Google ID, phone if available), processes them via the authentication service, and returns a new access and refresh token pair along with optional profile data (Base64 image). This endpoint should not be called directly.
    
- **Success Response (200 OK):** `APIResponseDTO<TokenResponseDTO>`
    
    ```
    {
    "errorMessage": "",
    "data": {
      "tokenResponseDTO": {
        "accessToken": "ey...",
        "refreshToken": "ey...",
        "accessTokenExpires": "2023-10-27T16:00:00Z",
        "refreshTokenExpires": "2023-11-26T14:00:00Z"
      },
      "base64Image": "iVBORw0KGgoAAAANSUhEUgAA..."
    },
    "success": true,
    "statusCode": 200
}

    
    
    
    ```
    

#### 9. Logout (Authorized)

- **Endpoint:** `/logout`
    
- **Route:** `https://34.18.112.76/api/Auth/logout`

- **Method:** `POST`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Invalidates the user's refresh token, forcing them to log in again to get a new one.
    
- **Request Body (`TokenRequestDTO`):**
    
    ```
    {
      "refreshToken": "ey..."
    }
    
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "",
      "data": true,
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```
    
#### 10. Change User Image (Authorized)

- **Endpoint:** `/update-user-image`
    
- **Route:** `https://34.18.112.76/api/Auth/update-user-image`

- **Method:** `POST`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** updates user's profile photo.
    
- **Request Body (`IFormFile`):**
    
- **Success Response (200 OK):** `APIResponseDTO<string>`
    
    ```
    {
      "errorMessage": "",
      "data": string, base64 encoded image,
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```

#### 11. Get User Profile (Authorized)

- **Endpoint:** `/user-profile`
    
- **Route:** `https://34.18.112.76/api/Auth/user-profile`

- **Method:** `GET`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Displays user's data.
        
- **Success Response (200 OK):** `APIResponseDTO<UserProfileDTO>`
    
    ```
    {
      "errorMessage": "",
      "data":  {
        "FullName": ,
        "Email": ,
        "ImagePath": string, base64 encoded image,
        "PhoneNumber": ,
        "UserName": ,
      },
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```

    #### 11. Update User Profile (Authorized)

- **Endpoint:** `/update-user-profile`
    
- **Route:** `https://34.18.112.76/api/Auth/update-user-profile`

- **Method:** `Post`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Updates user's data.
        
- **Request Body (`UpdateUserProfileDTO`):**

- **Success Response (200 OK):** `APIResponseDTO<UserProfileDTO>`
    
    ```
    {
      "errorMessage": "",
      "data":  {
        "FullName": ,
        "Email": ,
        "ImagePath": string, base64 encoded image,
        "PhoneNumber": ,
        "UserName": ,
      },
      "success": true,
      "statusCode": 200
    }
    
    
    
    ```


#### Sign Hub 

for realtime processing using web sockets

- **Route:** `https://34.18.112.76/api/signHub`

- **Request Body (`FrameData`):**

   ```
    {
      "imageData": "data:image/jpeg;base64,/9j/4AAQSkZJ..."
    }
     
  ```

  - **Success Response (200 OK):** string ClassLabelArabic (the arabic letter)



#### Sign Language Translator Controller

This controller handles the sign language translation, sentence correction, and text-to-speech services.

#### 1. Translate Sign

- **Endpoint:** `/`

- **Route:** `https://34.18.112.76`
    
- **Method:** `POST`
    
- **Description:** Translates a sign language gesture from a base64-encoded image into an Arabic letter.
    
- **Request Body (`FrameData`):**
    
    ```
    {
      "imageData": "data:image/jpeg;base64,/9j/4AAQSkZJ..."
    }
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<object>`
    
    ```
    {
      "errorMessage": "",
      "data": {
        "translation": "ا"
      },
      "success": true,
      "statusCode": 200
    }
    
    
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<string>`
    
    ```
    {
      "errorMessage": "No image data provided.",
      "data": null,
      "success": false,
      "statusCode": 400
    }
    
    
    ```
    

#### 2. Correct a Sentence

- **Endpoint:** `/CorrectSentence`
    
- **Route:** `https://34.18.112.76/api/SignLanguageTranslator/CorrectSentence`

- **Method:** `POST`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Corrects grammatical and spelling errors in an Arabic sentence using a language model.
    
- **Request Body (`SentenceData`):**
    
    ```
    {
      "sentence": "هذا  مزل كير."
    }
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<CorrectedResponse>`
    
    ```
    {
      "errorMessage": "",
      "data": {
        "suggestion": {
          "correctedSentence": "هذا منزلٌ كبيرٌ."
        }
      },
      "success": true,
      "statusCode": 200
    }
    
    
    ```
    

#### 3. Generate Audio from Text

- **Endpoint:** `/GenerateAudio`
    
- **Route:** `https://34.18.112.76/api/SignLanguageTranslator/GenerateAudio`

- **Method:** `POST`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Converts an Arabic sentence to an audio file.
    
- **Request Body (`TTSRequest`):**
    
    ```
    {
      "text": "مرحبا، كيف حالك؟"
    }
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<TTSResponse>`
    
    ```
    {
      "errorMessage": "",
      "data": {
        "audioData": "VGhlIGF1ZGlvIGRhdGEgYW4gYmFzZTY0IGZvcm1hdA==",
        "sampleRate": 24000
      },
      "success": true,
      "statusCode": 200
    }
    
    
    ```
    

#### 4. Separate Words in text

**Endpoint:** `/finalize-sentence`
    
- **Route:** `https://34.18.112.76/api/SignLanguageTranslator/finalize-sentence`

- **Method:** `POST`
        
- **Description:** but spaces in the correct places.
    
- **Request Body (`SentenceData`):**
    
    ```
    {
      "Sentence": "مرحباكيفحالك"
    }
    
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<TTSResponse>`
    
    ```
    {
      "errorMessage": "",
      "data": "مرحبا كيف حالك",
      "success": true,
      "statusCode": 200
    }
    
    
    ```

#### 5.Text to Audio (Finalize Sentence → Generate Speech)

- **Endpoint**: `/text-to-audio`

- **Route**: `https://YOUR_DOMAIN/api/SignLanguageTranslator/text-to-audio`

- **Method**: `POST`

- **Description:**

This endpoint performs a two–step processing pipeline:

Arabic Sentence Finalization

Takes a string of concatenated Arabic letters (from Sign Language recognition).

Uses Gemini to insert spaces, correct grammar, and form a readable sentence.

Text-to-Speech Generation

Converts the finalized Arabic sentence into a spoken audio file.

Returns audio as base64-encoded PCM/WAV data and sample rate.

- **Request Body (`SentenceData`):**

{
  "sentence": "مرحبابكفيك"
}


- **Success Response (200 OK):** `APIResponseDTO<TTSResponse>`

{
  "errorMessage": "",
  "data": {
    "audioData": "UklGRiQAAABXQVZFZm10IBAAAAABAAEA...",
    "sampleRate": 24000
  },
  "success": true,
  "statusCode": 200
}

- **Possible Error Responses:**

{
  "errorMessage": "Missing 'Sentence' field in request body.",
  "data": null,
  "success": false,
  "statusCode": 400
}


{
  "errorMessage": "Unexpected error occurred while processing the request.",
  "data": null,
  "success": false,
  "statusCode": 500
}


#### Arabic Language Translator Controller

This controller provides endpoints for text-to-sign translation, Gemini and Azure audio-to-text transcription, and retrieving sign images for the Arabic alphabet.

#### 1. Text-to-Sign Translation

- **Endpoint:** `/text-to-sign`
    
- **Route:** `https://34.18.112.76/api/ArabicLanguageTranslator/text-to-sign`

- **Method:** `POST`
    
- **Description:** Converts a given Arabic text into a list of base64-encoded sign images, grouped by word.
    
- **Request Body (`TextToSignDTO`):**
    
    ```
    {
      "text": "أهلا بك"
    }
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<List<List<string>>>`
    
    ```
    {
      "errorMessage": "",
      "data": [
        [
          "data:image/png;base64,...",
          "data:image/png;base64,...",
          "data:image/png;base64,..."
        ],
        [
          "data:image/png;base64,...",
          "data:image/png;base64,...",
          "data:image/png;base64,..."
        ]
      ],
      "success": true,
      "statusCode": 200
    }
    
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<List<List<string>>>`
    
    ```
    {
      "errorMessage": "No text provided.",
      "data": null,
      "success": false,
      "statusCode": 400
    }
    
    ```
    

#### 2. Audio-to-Text Transcription

- **Endpoint:** `/audio-to-text`
    

#### 3. Audio-to-Text Transcription (Azure Speech)

- **Endpoint:** `/audio-to-text-azure`

- **Route:** `https://34.18.112.76/api/ArabicLanguageTranslator/audio-to-text-azure`

- **Method:** `POST`

- **Description:** Transcribes base64-encoded PCM audio into Arabic text using Azure Speech SDK.

- **Required Environment Variables:**

    - `HARDWARE_TTS_KEY` (used as Azure Speech key)
    - `ENDPOINT` (Azure Speech endpoint URL)

- **Request Body (`TranscriptionRequest`):**

    ```
    {
      "audioData": "VGhlIGF1ZGlvIGRhdGEgYW4gYmFzZTY0IGZvcm1hdA==",
      "mimeType": "audio/l16;rate=16000"
    }

    ```

- **Success Response (200 OK):** `APIResponseDTO<string>`

    ```
    {
      "errorMessage": "",
      "data": "هذا هو النص المترجم من الصوت",
      "success": true,
      "statusCode": 200
    }

    ```

- **Possible Error Responses:** `APIResponseDTO<string>`

    ```
    {
      "errorMessage": "Audio data or MIME type not provided.",
      "data": null,
      "success": false,
      "statusCode": 400
    }
    ```

    ```
    {
      "errorMessage": "Missing Azure Speech configuration. Set HARDWARE_TTS_KEY and ENDPOINT.",
      "data": null,
      "success": false,
      "statusCode": 500
    }
    ```

    ```
    {
      "errorMessage": "Azure Speech could not recognize speech from the provided audio.",
      "data": null,
      "success": false,
      "statusCode": 422
    }
    ```
- **Route:** `https://34.18.112.76/api/ArabicLanguageTranslator/audio-to-text`
#### 4. Get Single Letter Sign Image
- **Method:** `POST`
    
- **Description:** Transcribes audio data into Arabic text using a language model.
    
- **Request Body (`TranscriptionRequest`):**
    
    ```
    {
      "audioData": "VGhlIGF1ZGlvIGRhdGEgYW4gYmFzZTY0IGZvcm1hdA==",
      "mimeType": "audio/l16;rate=16000"
    }
    
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<string>`
    
    ```
    {
      "errorMessage": "",
      "data": "هذا هو النص المترجم من الصوت",
      "success": true,
      "statusCode": 200
    }
    
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<string>`
    
    ```
    {
      "errorMessage": "Audio data or MIME type not provided.S",
      "data": null,
      "success": false,
      "statusCode": 400
    }
    
    ```
    

#### 3. Get Single Letter Sign Image

- **Endpoint:** `/letters-keyboard`
    
- **Route:** `https://34.18.112.76/api/ArabicLanguageTranslator/letters-keyboard`

- **Method:** `GET`
    
- **Description:** Retrieves the base64-encoded image for a single Arabic letter.
    
- **Query Parameter:** `letter` (char)
    
- **Example Request:** `GET /letters-keyboard?letter=أ`
    
- **Success Response (200 OK):** `APIResponseDTO<string>`
    
    ```
    {
      "errorMessage": "",
      "data": "data:image/png;base64,...",
      "success": true,
      "statusCode": 200
    }
    
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<string>`
    
    ```
    {
      "errorMessage": "Letter 'ث' not found in dictionary.",
      "data": null,
      "success": false,
      "statusCode": 400
    }
    
    ```
    

#### User History Controller

This controller manages user history records, including retrieving, deleting individual records, and clearing all history.

#### 1. Get User History

- **Endpoint:** `/get-user-history`
    
- **Route:** `https://34.18.112.76/api/UserHistory/get-user-history`


- **Method:** `GET`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Retrieves all history records for the authenticated user.
    
- **Success Response (200 OK):** `APIResponseDTO<List<UserRecordDTO>>`
    
    ```
    {
      "errorMessage": "",
      "data": [
        {
          "id": 1,
          "formedAt": "2023-10-27T16:00:00Z",
          "formedSentence": "مرحبا بك"
        },
        {
          "id": 2,
          "formedAt": "2023-10-28T10:30:00Z",
          "formedSentence": "كيف حالك؟"
        }
      ],
      "success": true,
      "statusCode": 200
    }
    ```
    
- **Error Response (500 Internal Server Error):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "An unexpected error occurred",
      "data": false,
      "success": false,
      "statusCode": 500
    }
    ```
    

#### 2. Delete User History Record

- **Endpoint:** `/delete-user-history-record`
    
- **Route:** `https://34.18.112.76/api/UserHistory/delete-user-history-record`

- **Method:** `DELETE`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Deletes a specific user history record by its ID.
    
- **Request Body (`DeleteUserRecordDTO`):**
    
    ```
    {
      "id": 1
    }
    ```
    
- **Success Response (200 OK):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "",
      "data": true,
      "success": true,
      "statusCode": 200
    }
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "No Such Record",
      "data": false,
      "success": false,
      "statusCode": 400
    }
    ```
    

#### 3. Delete All User History

- **Endpoint:** `/delete-all-user-history`
    
- **Route:** `https://34.18.112.76/api/UserHistory/delete-all-user-history`

- **Method:** `DELETE`
    
- **Authentication:** Requires a valid access token in the `Authorization` header.
    
- **Description:** Deletes all history records for the authenticated user.
    
- **Success Response (200 OK):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "",
      "data": true,
      "success": true,
      "statusCode": 200
    }
    ```
    
- **Error Response (400 Bad Request):** `APIResponseDTO<bool>`
    
    ```
    {
      "errorMessage": "No Records",
      "data": false,
      "success": false,
      "statusCode": 400
    }
    ```