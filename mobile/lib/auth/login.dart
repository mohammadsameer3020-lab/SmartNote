import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:mobile/components/CustomButton.dart';
import 'package:mobile/components/CustomLogo.dart';
import 'package:mobile/components/CustomTextForm.dart';
import 'package:mobile/core/constants/app_colors.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool loading = false;

  // ============================================================
  // Google Sign In
  // ============================================================

  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });

      // إنشاء Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // تهيئة Google Sign In
      await googleSignIn.initialize();

      // فتح نافذة تسجيل الدخول
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // الحصول على بيانات المصادقة
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // إنشاء Firebase Credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول إلى Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      // الانتقال إلى Home
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("homepage", (route) => false);
    }
    // ==========================================================
    // Google Error
    // ==========================================================
    on GoogleSignInException catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      String message = "حدث خطأ أثناء تسجيل الدخول باستخدام Google.";

      if (e.description != null && e.description!.isNotEmpty) {
        message = e.description!;
      }

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ في Google",
        desc: message,
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();
    }
    // ==========================================================
    // Firebase Error
    // ==========================================================
    on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      String message;

      switch (e.code) {
        case "account-exists-with-different-credential":
          message =
              "يوجد حساب مرتبط بهذا البريد الإلكتروني بطريقة تسجيل دخول أخرى.";
          break;

        case "invalid-credential":
          message = "بيانات تسجيل الدخول غير صالحة.";
          break;

        case "network-request-failed":
          message = "تأكد من اتصالك بالإنترنت.";
          break;

        default:
          message = e.message ?? "حدث خطأ أثناء تسجيل الدخول.";
      }

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ في Firebase",
        desc: message,
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();
    }
    // ==========================================================
    // Other Error
    // ==========================================================
    catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      debugPrint("Google Sign In Error: $e");

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

  // ============================================================
  // Email Login
  // ============================================================

  Future<void> loginWithEmail() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      final User? user = credential.user;

      if (user == null) {
        return;
      }

      // التأكد من البريد الإلكتروني
      if (!user.emailVerified) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          title: "تنبيه",
          desc: "الرجاء التوجه إلى بريدك الإلكتروني والتحقق من الحساب أولاً.",
          btnOkText: "موافق",
          btnOkOnPress: () {},
        ).show();

        return;
      }

      // الانتقال إلى الصفحة الرئيسية
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("homepage", (route) => false);
    }
    // ==========================================================
    // Firebase Login Error
    // ==========================================================
    on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      String message;

      switch (e.code) {
        case "invalid-credential":
          message = "البريد الإلكتروني أو كلمة المرور غير صحيحة.";
          break;

        case "user-not-found":
          message = "لا يوجد حساب مرتبط بهذا البريد الإلكتروني.";
          break;

        case "wrong-password":
          message = "كلمة المرور غير صحيحة.";
          break;

        case "invalid-email":
          message = "البريد الإلكتروني غير صحيح.";
          break;

        case "user-disabled":
          message = "تم تعطيل هذا الحساب.";
          break;

        case "too-many-requests":
          message = "تمت محاولات تسجيل دخول كثيرة. حاول لاحقًا.";
          break;

        case "network-request-failed":
          message = "تأكد من اتصالك بالإنترنت.";
          break;

        default:
          message = e.message ?? "حدث خطأ أثناء تسجيل الدخول.";
      }

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ",
        desc: message,
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();
    }
    // ==========================================================
    // Other Error
    // ==========================================================
    catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      debugPrint("Login Error: $e");

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

  // ============================================================
  // Forgot Password
  // ============================================================

  Future<void> forgotPassword() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: "تنبيه",
        desc: "الرجاء كتابة البريد الإلكتروني أولاً.",
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();

      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: "تم بنجاح",
        desc: "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.",
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case "invalid-email":
          message = "البريد الإلكتروني غير صحيح.";
          break;

        case "user-not-found":
          message = "لا يوجد حساب بهذا البريد الإلكتروني.";
          break;

        case "network-request-failed":
          message = "تأكد من اتصالك بالإنترنت.";
          break;

        default:
          message = e.message ?? "حدث خطأ.";
      }

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ",
        desc: message,
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();
    }
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              )
            : Container(
                padding: const EdgeInsets.all(20),

                child: Form(
                  key: formKey,

                  child: ListView(
                    children: [
                      const SizedBox(height: 40),

                      // ==================================================
                      // Logo
                      // ==================================================
                      const CustomLogo(),

                      const SizedBox(height: 30),

                      // ==================================================
                      // Title
                      // ==================================================
                      Text(
                        "Welcome Back 👋",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Login to continue using SmartMind",
                        style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==================================================
                      // Email
                      // ==================================================
                      const Text(
                        "Email",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CustomTextForm(
                        hinttext: "Enter Your Email",
                        mycontroller: emailController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your email";
                          }

                          if (!value.contains("@")) {
                            return "Enter a valid email";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // Password
                      // ==================================================
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CustomTextForm(
                        hinttext: "Enter Your Password",
                        mycontroller: passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }

                          if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }

                          return null;
                        },
                      ),

                      // ==================================================
                      // Forgot Password
                      // ==================================================
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed("forgot_password");
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 20),
                          alignment: Alignment.centerRight,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // Login Button
                      // ==================================================
                      CustomButton(title: "Login", onPressed: loginWithEmail),

                      const SizedBox(height: 20),

                      // ==================================================
                      // OR
                      // ==================================================
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),

                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // Google Button
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: OutlinedButton.icon(
                          onPressed: signInWithGoogle,

                          icon: const Icon(Icons.login, color: Colors.red),

                          label: const Text(
                            "Continue with Google",
                            style: TextStyle(
                              color: AppColors.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,

                            side: BorderSide(color: Colors.grey.shade300),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ==================================================
                      // Sign Up
                      // ==================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed("signup");
                            },

                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
