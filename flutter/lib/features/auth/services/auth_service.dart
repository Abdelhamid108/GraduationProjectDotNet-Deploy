import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  late final dio.Dio _dio;

  AuthService() {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: "https://ema2a.mooo.com/api",
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  dio.Options _authOptions(String token) {
    return dio.Options(
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      validateStatus: (status) => status != null && status < 500,
    );
  }

  Future<dio.Response> login({
    required String userName,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        "/Auth/login-user",
        data: {"userName": userName, "password": password},
        options: dio.Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print("Login Response: ${response.data}");
      return response;
    } on dio.DioException catch (e) {
      print("Login Error: ${e.response?.data}");
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> register({
    required String email,
    required String fullName,
    required String userName,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        "Email": email,
        "FullName": fullName,
        "UserName": userName,
        "Password": password,
        "PhoneNumber": phoneNumber,
      });
      final response = await _dio.post("/Auth/register-user", data: formData);
      print("Register Response: ${response.data}");
      return response;
    } on dio.DioException catch (e) {
      print("Register Error: ${e.response?.data}");
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> getUserProfile(String token) async {
    try {
      return await _dio.get(
        "/Auth/user-profile",
        options: _authOptions(token),
      );
    } on dio.DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> updateUserProfile({
    required String token,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String userName,
  }) async {
    try {
      return await _dio.post(
        "/Auth/update-user-profile",
        data: {
          "fullName": fullName,
          "email": email,
          "phoneNumber": phoneNumber,
          "userName": userName,
        },
        options: _authOptions(token),
      );
    } on dio.DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> updateUserImage({
    required String token,
    required String imagePath,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        "NewImge": await dio.MultipartFile.fromFile(imagePath),
      });
      return await _dio.post(
        "/Auth/update-user-image",
        data: formData,
        options: dio.Options(
          headers: {"Authorization": "Bearer $token"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } on dio.DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> updateUserImageBytes({
    required String token,
    required Uint8List imageBytes,
    String fileName = 'profile.jpg',
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        "NewImge": dio.MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
      });
      return await _dio.post(
        "/Auth/update-user-image",
        data: formData,
        options: dio.Options(
          headers: {"Authorization": "Bearer $token"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } on dio.DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await _dio.post(
        "/Auth/change-password",
        data: {
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        },
        options: _authOptions(token),
      );
    } on dio.DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> sendResetEmail(String email) async {
    try {
      final response = await _dio.post(
        "/Auth/get-reset-password-token",
        data: {"email": email},
        options: dio.Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print("Reset Email Response: ${response.data}");
      return response;
    } on dio.DioException catch (e) {
      print("Reset Email Error: ${e.response?.data}");
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> verifyOtp(String email, String code) async {
    try {
      final response = await _dio.post(
        "/Auth/verify-otp",
        data: {"email": email, "code": code},
        options: dio.Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print("Verify OTP Response: ${response.data}");
      return response;
    } on dio.DioException catch (e) {
      print("Verify OTP Error: ${e.response?.data}");
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> setNewPassword(String otp, String newPassword) async {
    try {
      final response = await _dio.post(
        "/Auth/reset-password",
        data: {"otp": otp, "newPassword": newPassword},
        options: dio.Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      print("New Password Response: ${response.data}");
      return response;
    } on dio.DioException catch (e) {
      print("New Password Error: ${e.response?.data}");
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<dio.Response> logout(String refreshToken) async {
    try {
      return await _dio.post(
        "/Auth/logout",
        data: {"refreshToken": refreshToken},
        options: dio.Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } on dio.DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<void> loginWithGoogle() async {
    const url = "https://ema2a.mooo.com/api/Auth/login-google";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("لا يمكن فتح الرابط");
    }
  }
}