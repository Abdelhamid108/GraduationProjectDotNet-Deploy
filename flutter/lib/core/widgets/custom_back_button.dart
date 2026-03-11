import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CustomBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50.w,
      height: 50.h,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed ?? () => Navigator.pop(context),
        icon: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(3.1416),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 50,
          ),
        ),
      ),
    );
  }
}
