import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _service = AuthService();
  final _box = GetStorage();

  var isLoading = false.obs;
  var userEmail = ''.obs;
  var userOtp = ''.obs;
  var accessToken = ''.obs;
  var refreshToken = ''.obs;

  // ── Resend OTP Timer ──
  RxInt resendSeconds = 60.obs;
  RxBool canResend = false.obs;
  Timer? _resendTimer;

  @override
  void onInit() {
    super.onInit();
    accessToken.value = _box.read('accessToken') ?? '';
    refreshToken.value = _box.read('refreshToken') ?? '';
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
  }

  // ── LOGIN ──
  Future<void> login(String userName, String password) async {
    final cleanUserName = userName.trim();
    final cleanPassword = password.trim();

    if (cleanUserName.isEmpty || cleanPassword.isEmpty) {
      Get.snackbar('خطأ', 'ادخل اسم المستخدم وكلمة المرور',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    try {
      isLoading.value = true;
      final response = await _service.login(
        userName: cleanUserName,
        password: cleanPassword,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        accessToken.value = data['accessToken'];
        refreshToken.value = data['refreshToken'];
        _box.write('accessToken', accessToken.value);
        _box.write('refreshToken', refreshToken.value);
        Get.offAllNamed('/mainscreen');
      } else {
        Get.snackbar('خطأ',
            response.data['errorMessage'] ?? 'فشل تسجيل الدخول',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'اسم المستخدم أو كلمة المرور غير صحيح',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── REGISTER ──
  Future<void> register({
    required String email,
    required String fullName,
    required String userName,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
  }) async {
    if (email.isEmpty || fullName.isEmpty || userName.isEmpty ||
        password.isEmpty || phoneNumber.isEmpty) {
      Get.snackbar('خطأ', 'ادخل كل البيانات',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar('خطأ', 'كلمتا المرور غير متطابقتين',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    try {
      isLoading.value = true;
      final response = await _service.register(
        email: email,
        fullName: fullName,
        userName: userName,
        password: password,
        phoneNumber: phoneNumber,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar('نجاح', 'تم إنشاء الحساب بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('خطأ',
            response.data['errorMessage'] ?? 'فشل إنشاء الحساب',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إنشاء الحساب',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── GET USER PROFILE ──
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      isLoading.value = true;
      final response = await _service.getUserProfile(accessToken.value);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ── UPDATE USER PROFILE ──
  Future<void> updateUserProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String userName,
  }) async {
    try {
      isLoading.value = true;
      final response = await _service.updateUserProfile(
        token: accessToken.value,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        userName: userName,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar('نجاح', 'تم تحديث البيانات بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ',
            response.data['errorMessage'] ?? 'فشل تحديث البيانات',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث البيانات',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── UPDATE USER IMAGE (Mobile) ──
  Future<void> updateUserImage(String imagePath) async {
    try {
      isLoading.value = true;
      final response = await _service.updateUserImage(
        token: accessToken.value,
        imagePath: imagePath,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar('نجاح', 'تم تحديث الصورة بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ',
            response.data['errorMessage'] ?? 'فشل تحديث الصورة',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث الصورة',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── UPDATE USER IMAGE (Web) ──
  Future<void> updateUserImageBytes(Uint8List imageBytes) async {
    try {
      isLoading.value = true;
      final response = await _service.updateUserImageBytes(
        token: accessToken.value,
        imageBytes: imageBytes,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar('نجاح', 'تم تحديث الصورة بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ',
            response.data['errorMessage'] ?? 'فشل تحديث الصورة',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث الصورة',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── CHANGE PASSWORD (Profile) ──
  Future<void> changePasswordProfile({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      final response = await _service.changePassword(
        token: accessToken.value,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar('نجاح', 'تم تغيير كلمة المرور بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
        Get.back();
      } else {
        Get.snackbar('خطأ',
            response.data['errorMessage'] ?? 'فشل تغيير كلمة المرور',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تغيير كلمة المرور',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── SEND RESET EMAIL ──
  Future<void> sendEmail(String email) async {
    if (email.isEmpty) {
      Get.snackbar('خطأ', 'ادخل البريد الإلكتروني',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    try {
      isLoading.value = true;
      userEmail.value = email.trim();

      final response = await http.post(
        Uri.parse("https://ema2a.mooo.com/api/Auth/get-reset-password-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim()}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        startResendTimer();
        Get.toNamed('/otp');
      } else {
        Get.snackbar('خطأ',
            data["errorMessage"] ?? "هذا البريد غير مسجل",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الكود',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── RESEND TIMER ──
  void startResendTimer() {
    canResend.value = false;
    resendSeconds.value = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds.value == 0) {
        canResend.value = true;
        timer.cancel();
      } else {
        resendSeconds.value--;
      }
    });
  }

  // ── RESEND OTP ──
  Future<void> resendOtp() async {
    if (!canResend.value) return;
    try {
      isLoading.value = true;
      final response = await http.post(
        Uri.parse("https://ema2a.mooo.com/api/Auth/get-reset-password-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": userEmail.value}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        startResendTimer();
        Get.snackbar('تم الإرسال', 'تم إرسال رمز تحقق جديد',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ',
            data["errorMessage"] ?? "فشل إعادة الإرسال",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إعادة الإرسال',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── VERIFY OTP ──
  Future<void> verifyOtp(String code) async {
    if (code.length < 6) {
      Get.snackbar('خطأ', 'ادخل كود التحقق كامل',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    try {
      isLoading.value = true;
      userOtp.value = code;
      Get.toNamed('/new-password');
    } catch (e) {
      Get.snackbar('خطأ', 'الكود غير صحيح',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── RESET PASSWORD ──
  Future<void> changePassword(String newPassword) async {
    try {
      isLoading.value = true;
      print("OTP: ${userOtp.value}");
      print("Email: ${userEmail.value}");
      print("New Password: $newPassword");

      final response = await http.post(
        Uri.parse("https://ema2a.mooo.com/api/Auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "OTP": userOtp.value,
          "Email": userEmail.value,
          "newPassword": newPassword,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        Get.snackbar('نجاح', 'تم تغيير كلمة المرور بنجاح',
            backgroundColor: Colors.blue[400], colorText: Colors.white);
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('خطأ',
            data["errorMessage"] ?? "فشل تغيير كلمة المرور",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تغيير كلمة المرور',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // ── LOGOUT ──
  Future<void> logout() async {
    try {
      await _service.logout(refreshToken.value);
      _box.remove('accessToken');
      _box.remove('refreshToken');
      accessToken.value = '';
      refreshToken.value = '';
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تسجيل الخروج',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ── GOOGLE LOGIN ──
  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      await _service.loginWithGoogle();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تسجيل الدخول بجوجل',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}