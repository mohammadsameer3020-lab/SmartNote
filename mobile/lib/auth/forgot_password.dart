import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/CustomButton.dart';
import '../components/CustomLogo.dart';
import '../components/CustomTextForm.dart';
import '../core/constants/app_colors.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController email = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  // ============================================================
  // إرسال رابط إعادة تعيين كلمة المرور
  // ============================================================

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: "تم الإرسال",
        desc:
            "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.\n\n"
            "تحقق من البريد الوارد أو مجلد الرسائل غير المرغوب فيها.",
        btnOkText: "موافق",
        btnOkOnPress: () {
          Navigator.of(context).pushReplacementNamed("login");
        },
      ).show();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      String message;

      switch (e.code) {
        case "invalid-email":
          message = "البريد الإلكتروني غير صحيح.";
          break;

        case "user-not-found":
          message = "لا يوجد حساب مرتبط بهذا البريد الإلكتروني.";
          break;

        case "network-request-failed":
          message = "تأكد من اتصالك بالإنترنت.";
          break;

        default:
          message = e.message ?? "حدث خطأ أثناء إرسال رابط إعادة التعيين.";
      }

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: "خطأ",
        desc: message,
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      debugPrint("RESET PASSWORD ERROR: $e");

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ",
        desc: "حدث خطأ غير متوقع.",
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 30),

                      // Logo
                      const CustomLogo(),

                      const SizedBox(height: 30),

                      const Text(
                        "Forgot Password?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Enter your email and we will send you a link "
                        "to reset your password.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),

                      const SizedBox(height: 35),

                      const Text(
                        "Email",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CustomTextForm(
                        hinttext: "Enter Your Email",
                        mycontroller: email,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your email";
                          }

                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return "Enter a valid email";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      CustomButton(
                        title: "Send Reset Link",
                        onPressed: resetPassword,
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed("login");
                        },
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
