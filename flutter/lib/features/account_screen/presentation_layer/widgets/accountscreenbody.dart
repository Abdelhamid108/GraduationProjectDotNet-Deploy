import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:graduationproject/core/style/app_assets.dart';
import 'package:graduationproject/core/style/app_fonts.dart';
import 'package:graduationproject/core/widgets/TextField_button.dart';
import 'package:graduationproject/features/auth/controller/auth_controller.dart';
import 'package:graduationproject/features/profile_screen/presentation_layer/profilescreenview.dart';

class AccountBody extends StatefulWidget {
  const AccountBody({super.key});

  @override
  State<AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends State<AccountBody> {

  final AuthController _authController = Get.find<AuthController>();

  String _userName = '';
  String? _base64Image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    /// الحل للمشكلة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final data = await _authController.getUserProfile();

    if (data != null) {
      setState(() {
        _userName = data['fullName'] ?? data['userName'] ?? '';
        _base64Image = data['userBase64Image'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xffD9D9D9),
                  borderRadius: BorderRadius.circular(15.r),
                ),
              ),

              SizedBox(height: 20.h),

              CustomTextField(
                label: 'كلمة المرور القديمة',
                hintText: 'ادخل كلمة المرور',
               isPassword:true,
                controller: oldPasswordController,
              ),

              SizedBox(height: 20.h),

              CustomTextField(
                label: 'كلمة المرور الجديدة',
                hintText: 'ادخل كلمة المرور',
                isPassword:true,
                controller: newPasswordController,
              ),

              SizedBox(height: 20.h),

              CustomTextField(
                label: 'تأكيد كلمة المرور',
                hintText: 'تأكيد كلمة المرور',
                isPassword:true,
                controller: confirmPasswordController,
              ),

              SizedBox(height: 30.h),

              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  onPressed: () {

                    if (newPasswordController.text !=
                        confirmPasswordController.text) {

                      Get.snackbar(
                        'خطأ',
                        'كلمتا المرور غير متطابقتين',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );

                    } else {

                      _authController.changePasswordProfile(
                        currentPassword: oldPasswordController.text,
                        newPassword: newPasswordController.text,
                      );

                    }

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF30BBF9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35.r),
                    ),
                  ),
                  child: Text(
                    'تحديث كلمة المرور',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontFamily: AppFonts.mainfontName,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(
        children: [

          /// الخلفية المتدرجة
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 300.h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8B86D),
                    Color(0xFF30BBF9),
                  ],
                ),
              ),
            ),
          ),

          /// كلمة مرحباً
          Positioned(
            top: 32.h,
            left: 187.w,
            right: 0,
            child: Center(
              child: Text(
                'مرحباً',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          /// صورة المستخدم والاسم
          Positioned(
            top: 118.h,
            left: 130.w,
            right: 10.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                _isLoading
                    ? CircleAvatar(
                        radius: 49.5.r,
                        backgroundColor: const Color(0xFFC4C4C4),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Container(
                        width: 99.w,
                        height: 99.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFC4C4C4),
                          image: (_base64Image != null &&
                                  _base64Image!.isNotEmpty)
                              ? DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(_base64Image!),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (_base64Image == null ||
                                _base64Image!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 50.sp,
                                color: Colors.white,
                              )
                            : null,
                      ),

                SizedBox(width: 16.w),

                if (!_isLoading)
                  Text(
                    _userName.isNotEmpty ? _userName : 'مستخدم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          /// الملف الشخصي
          Positioned(
            top: 334.h,
            left: 161.w,
            child: _buildMenuItem(
              context: context,
              icon: AppAssets.profileIcon,
              title: 'الملف الشخصي',
              onTap: () async {

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreenView(),
                  ),
                );

                _loadProfile();

              },
            ),
          ),

          /// تغيير كلمة المرور
          Positioned(
            top: 411.h,
            left: 164.w,
            child: _buildMenuItem(
              context: context,
              icon: AppAssets.passwordIcon,
              title: 'تغيير كلمة المرور',
              onTap: () => _showChangePasswordSheet(context),
            ),
          ),

          /// الوضع الليلي
          Positioned(
            top: 484.h,
            left: 103.w,
            right: 0.w,
            child: _buildDarkModeToggle(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 40.w,
            height: 40.h,
            colorFilter: const ColorFilter.mode(
              Color(0xFF248DBC),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF1C6E93),
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return Row(
      children: [

        SvgPicture.asset(
          AppAssets.darkModeIcon,
          width: 40.w,
          height: 40.h,
        ),

        SizedBox(width: 13.w),

        Text(
          'الوضع الليلي',
          style: TextStyle(
            color: const Color(0xFF1C6E93),
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
        ),

        const Spacer(),

        Switch(
          value: false,
          onChanged: (value) {},
          activeColor: const Color(0xFF30BBF9),
        ),
      ],
    );
  }
}