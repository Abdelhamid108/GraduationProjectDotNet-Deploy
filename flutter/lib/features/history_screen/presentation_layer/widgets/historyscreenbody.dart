import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HistoryBody extends StatelessWidget {
  const HistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100.sp,
            color: const Color(0xFF30BBF9),
          ),
          SizedBox(height: 20.h),
          Text(
            'صفحة History',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '(سيتم العمل عليها لاحقاً)',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}