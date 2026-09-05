import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/components/CustomButton.dart';

import 'package:mobile/components/CustomLogo.dart';
import 'package:mobile/components/CustomTextForm.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool loading = false;

  // ============================================================
  // تسجيل الدخول باستخدام Google
  // ============================================================
  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });

      // الحصول على نسخة GoogleSignIn
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

      // تسجيل الدخول في Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      // الانتقال إلى الصفحة الرئيسية
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("homepage", (route) => false);
    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ في Google",
        desc: "حدث خطأ أثناء تسجيل الدخول باستخدام Google\n${e.description}",
        btnOkOnPress: () {},
      ).show();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ في Firebase",
        desc: e.message ?? "حدث خطأ أثناء تسجيل الدخول",
        btnOkOnPress: () {},
      ).show();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ",
        desc: "حدث خطأ أثناء تسجيل الدخول\n$e",
        btnOkOnPress: () {},
      ).show();
    }
  }

  // ============================================================
  // التخلص من Controllers
  // ============================================================
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // ============================================================
  // واجهة تسجيل الدخول
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 50),

                    // Logo
                    const CustomLogo(),

                    const SizedBox(height: 30),

                    // Login
                    const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "login To Continue Using The App",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 10),

                    // Email
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    CustomTextForm(
                      hinttext: "Enter Your Email",
                      mycontroller: email,
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

                    const SizedBox(height: 10),

                    // Password
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    CustomTextForm(
                      hinttext: "Enter Your Password",
                      mycontroller: password,
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

                    // Forgot Password
                    InkWell(
                      onTap: () async {
                        if (email.text.trim().isEmpty) {
                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.error,
                            title: "خطأ",
                            desc: "الرجاء كتابة البريد الإلكتروني",
                            btnOkOnPress: () {},
                          ).show();

                          return;
                        }

                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: email.text.trim(),
                          );

                          if (!mounted) return;

                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.success,
                            title: "تم بنجاح",
                            desc:
                                "تم إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني",
                            btnOkOnPress: () {},
                          ).show();
                        } on FirebaseAuthException catch (e) {
                          if (!mounted) return;

                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.error,
                            title: "خطأ",
                            desc: e.message ?? "حدث خطأ",
                            btnOkOnPress: () {},
                          ).show();
                        }
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

                    // Login Button
                    CustomButton(
                      title: " Login ",
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        try {
                          setState(() {
                            loading = true;
                          });

                          final UserCredential credential = await FirebaseAuth
                              .instance
                              .signInWithEmailAndPassword(
                                email: email.text.trim(),
                                password: password.text.trim(),
                              );

                          if (!mounted) return;

                          setState(() {
                            loading = false;
                          });

                          final User? user = credential.user;

                          if (user == null) {
                            return;
                          }

                          if (user.emailVerified) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              "homepage",
                              (route) => false,
                            );
                          } else {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.warning,
                              title: "تنبيه",
                              desc:
                                  "الرجاء التوجه إلى بريدك الإلكتروني للتحقق من الحساب",
                              btnOkOnPress: () {},
                            ).show();
                          }
                        } on FirebaseAuthException catch (e) {
                          if (!mounted) return;

                          setState(() {
                            loading = false;
                          });

                          if (e.code == "invalid-credential") {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.error,
                              title: "خطأ",
                              desc:
                                  "البريد الإلكتروني أو كلمة المرور غير صحيحة",
                              btnOkOnPress: () {},
                            ).show();
                          } else {
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.error,
                              title: "خطأ",
                              desc: e.message ?? "حدث خطأ",
                              btnOkOnPress: () {},
                            ).show();
                          }
                        } catch (e) {
                          if (!mounted) return;

                          setState(() {
                            loading = false;
                          });

                          AwesomeDialog(
                            context: context,
                            dialogType: DialogType.error,
                            title: "خطأ",
                            desc: "حدث خطأ غير متوقع: $e",
                            btnOkOnPress: () {},
                          ).show();
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // Google Button
                    MaterialButton(
                      onPressed: () async {
                        await signInWithGoogle();
                      },
                      color: Colors.red,
                      textColor: Colors.white,
                      height: 50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        "Login With Google",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign Up
                    InkWell(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed("signup");
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
