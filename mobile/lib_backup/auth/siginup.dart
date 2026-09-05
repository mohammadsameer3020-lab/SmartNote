// import 'dart:math';

// import 'package:awesome_dialog/awesome_dialog.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:kids_learning_app/components/costombutten.dart';
// import 'package:kids_learning_app/components/costomlogoath.dart';
// import 'package:kids_learning_app/components/textformfield.dart';

// class siginup extends StatefulWidget {
//   const siginup({super.key});

//   @override
//   State<siginup> createState() => _siginupState();
// }

// class _siginupState extends State<siginup> {
//   TextEditingController email = TextEditingController();
//   TextEditingController password = TextEditingController();
//   TextEditingController Username = TextEditingController();
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();
//   @override
//   @override
//   void dispose() {
//     email.dispose();
//     password.dispose();
//     Username.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: formKey,
//           child: ListView(
//             children: [
//               const SizedBox(height: 50),
//               const CustomLogo(),
//               const SizedBox(height: 30),
//               const Text(
//                 "Sign Up",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Container(height: 10),
//               const Text(
//                 "Sign Up To Continue Using The App",
//                 style: TextStyle(color: Colors.grey),
//               ),
//               Container(height: 10),
//               const Text(
//                 "Username",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               CustomTextForm(
//                 hinttext: "Enter Your Username",
//                 mycontroller: Username,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return "Please enter your username";
//                   }

//                   if (value.length < 3) {
//                     return "Username must be at least 3 characters";
//                   }

//                   return null;
//                 },
//               ),
//               Container(height: 10),
//               const Text(
//                 "Email",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               CustomTextForm(
//                 hinttext: "Enter Your Email",
//                 mycontroller: email,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return "Please enter your email";
//                   }

//                   if (!value.contains("@")) {
//                     return "Enter a valid email";
//                   }

//                   return null;
//                 },
//               ),
//               Container(height: 10),
//               const Text(
//                 "Password",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               CustomTextForm(
//                 hinttext: "Enter Your Password",
//                 mycontroller: password,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return "Please enter your password";
//                   }

//                   if (value.length < 6) {
//                     return "Password must be at least 6 characters";
//                   }

//                   return null;
//                 },
//               ),
//               Container(
//                 margin: const EdgeInsets.only(top: 10, bottom: 20),
//                 alignment: Alignment.centerRight,
//                 child: const Text(
//                   "Forgot Password?",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Container(height: 10),
//               CustomButton(
//                 title: "Sign Up",
//                 onPressed: () async {
//                   if (formKey.currentState!.validate()) {
//                     try {
//                       await FirebaseAuth.instance
//                           .createUserWithEmailAndPassword(
//                         email: email.text,
//                         password: password.text,
//                       );
//                       FirebaseAuth.instance.currentUser!
//                           .sendEmailVerification();
//                       Navigator.of(context).pushReplacementNamed("login");
//                     } on FirebaseAuthException catch (e) {
//                       if (e.code == 'weak-password') {
//                         print('The password provided is too weak.');
//                         AwesomeDialog(
//                           context: context,
//                           dialogType: DialogType.info,
//                           animType: AnimType.rightSlide,
//                           title: 'Dialog Title',
//                           desc: 'The password provided is too weak.',
//                           btnCancelOnPress: () {},
//                           btnOkOnPress: () {},
//                         ).show();
//                       } else if (e.code == 'email-already-in-use') {
//                         print('The account already exists for that email.');
//                         AwesomeDialog(
//                           context: context,
//                           dialogType: DialogType.info,
//                           animType: AnimType.rightSlide,
//                           title: 'Dialog Title',
//                           desc: 'The account already exists for that email.',
//                           btnCancelOnPress: () {},
//                           btnOkOnPress: () {},
//                         ).show();
//                       }
//                     } catch (e) {
//                       print(e);
//                     }
//                   }
//                 },
//               ),
//               Container(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text("Already have an account?"),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pushNamed("login");
//                     },
//                     child: const Text(
//                       "Login",
//                       style: TextStyle(
//                         color: Colors.orange,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:mobile/components/CustomButton.dart';
import 'package:mobile/components/CustomLogo.dart';
import 'package:mobile/components/CustomTextForm.dart';

class siginup extends StatefulWidget {
  const siginup({super.key});

  @override
  State<siginup> createState() => _siginupState();
}

class _siginupState extends State<siginup> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController username = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    username.dispose();

    super.dispose();
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      // إنشاء الحساب في Firebase Authentication
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      final User? user = credential.user;

      if (user == null) {
        throw Exception("User creation failed");
      }

      // تحديث اسم المستخدم في Firebase Auth
      await user.updateDisplayName(username.text.trim());

      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "uid": user.uid,
        "name": username.text.trim(),
        "email": email.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      // إرسال رسالة التحقق
      await user.sendEmailVerification();

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: "تم إنشاء الحساب",
        desc:
            "تم إنشاء حسابك بنجاح.\nتم إرسال رابط التحقق إلى بريدك الإلكتروني.",
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
        case "weak-password":
          message = "كلمة المرور ضعيفة.";
          break;

        case "email-already-in-use":
          message = "هذا البريد الإلكتروني مستخدم بالفعل.";
          break;

        case "invalid-email":
          message = "البريد الإلكتروني غير صحيح.";
          break;

        case "network-request-failed":
          message = "تأكد من اتصالك بالإنترنت.";
          break;

        default:
          message = e.message ?? "حدث خطأ أثناء إنشاء الحساب.";
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

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: "خطأ",
        desc: "حدث خطأ غير متوقع.",
        btnOkText: "موافق",
        btnOkOnPress: () {},
      ).show();

      debugPrint(e.toString());
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 50),

                    const CustomLogo(),

                    const SizedBox(height: 30),

                    const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Sign Up To Continue Using The App",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // USERNAME
                    // ==================================================
                    const Text(
                      "Username",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    CustomTextForm(
                      hinttext: "Enter Your Username",
                      mycontroller: username,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your username";
                        }

                        if (value.trim().length < 3) {
                          return "Username must be at least 3 characters";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // EMAIL
                    // ==================================================
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 24,
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

                    const SizedBox(height: 15),

                    // ==================================================
                    // PASSWORD
                    // ==================================================
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 24,
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

                    const SizedBox(height: 25),

                    // ==================================================
                    // SIGN UP BUTTON
                    // ==================================================
                    CustomButton(title: "Sign Up", onPressed: signUp),

                    const SizedBox(height: 20),

                    // ==================================================
                    // LOGIN
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed("login");
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
