import 'package:awesome_dialog/awesome_dialog.dart';
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
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController Username = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    Username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Container(height: 10),
              const Text(
                "Sign Up To Continue Using The App",
                style: TextStyle(color: Colors.grey),
              ),
              Container(height: 10),
              const Text(
                "Username",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              CustomTextForm(
                hinttext: "Enter Your Username",
                mycontroller: Username,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your username";
                  }

                  if (value.length < 3) {
                    return "Username must be at least 3 characters";
                  }

                  return null;
                },
              ),
              Container(height: 10),
              const Text(
                "Email",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              CustomTextForm(
                hinttext: "Enter Your Email",
                mycontroller: email,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }

                  if (!value.contains("@")) {
                    return "Enter a valid email";
                  }

                  return null;
                },
              ),
              Container(height: 10),
              const Text(
                "Password",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                alignment: Alignment.centerRight,
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              Container(height: 10),
              CustomButton(
                title: "Sign Up",
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: email.text,
                            password: password.text,
                          );
                      FirebaseAuth.instance.currentUser!
                          .sendEmailVerification();
                      Navigator.of(context).pushReplacementNamed("login");
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'weak-password') {
                        print('The password provided is too weak.');
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.info,
                          animType: AnimType.rightSlide,
                          title: 'Dialog Title',
                          desc: 'The password provided is too weak.',
                          btnCancelOnPress: () {},
                          btnOkOnPress: () {},
                        ).show();
                      } else if (e.code == 'email-already-in-use') {
                        print('The account already exists for that email.');
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.info,
                          animType: AnimType.rightSlide,
                          title: 'Dialog Title',
                          desc: 'The account already exists for that email.',
                          btnCancelOnPress: () {},
                          btnOkOnPress: () {},
                        ).show();
                      }
                    } catch (e) {
                      print(e);
                    }
                  }
                },
              ),
              Container(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed("login");
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
