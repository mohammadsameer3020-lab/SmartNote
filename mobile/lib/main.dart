// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import 'package:kids_learning_app/auth/siginup.dart';
// import 'package:kids_learning_app/auth/login.dart';

// import 'package:kids_learning_app/categories/AddCategories.dart';

// import 'package:kids_learning_app/orders/my_orders.dart';

// import 'package:kids_learning_app/provider/provider_home.dart';
// import 'package:kids_learning_app/provider/provider_orders.dart';

// import 'package:kids_learning_app/services/add_provider.dart';

// import 'package:kids_learning_app/components/homepage.dart';

// import 'firebase_options.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();

//     FirebaseAuth.instance.authStateChanges().listen((User? user) {
//       if (user == null) {
//         print("User is currently signed out!");
//       } else {
//         print("User is signed in!");
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,

//       theme: ThemeData(
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color.fromARGB(
//             255,
//             237,
//             233,
//             233,
//           ),
//           titleTextStyle: TextStyle(
//             color: Colors.orange,
//             fontSize: 17,
//             fontWeight: FontWeight.bold,
//           ),
//           iconTheme: IconThemeData(
//             color: Colors.orange,
//           ),
//         ),
//       ),

//       // بداية التطبيق
//       // المستخدم يدخل إلى Login
//       home: const Login(),

//       routes: {
//         // Authentication
//         "signup": (context) => const siginup(),
//         "login": (context) => const Login(),

//         // Client
//         "homepage": (context) => const Homepage(),

//         // Categories
//         "AddCategories": (context) => const AddCategories(),

//         // Service Provider
//         "AddProvider": (context) => const AddProviderPage(),
//         "providerHome": (context) => const ProviderHomePage(),
//         "ProviderHomePage": (context) => const ProviderHomePage(),

//         // Orders
//         "myOrders": (context) => const MyOrdersPage(),
//         "providerOrders": (context) => const ProviderOrdersPage(),
//       },
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile/auth/forgot_password.dart';
import 'package:mobile/auth/login.dart';
import 'package:mobile/auth/siginup.dart';
import 'package:mobile/categres/categres.dart';
import 'package:mobile/core/theme/app_theme.dart';

import 'package:mobile/firebase_options.dart';

import 'package:mobile/notes/addNode.dart';
import 'package:mobile/notes/hidden_notes.dart';
import 'package:mobile/notes/note_home_screen.dart';
import 'package:mobile/notes/pinned_notes.dart';

// import 'package:kids_learning_app/provider/add_provider.dart';

// import 'firebase_options.dart';

// import 'package:kids_learning_app/auth/login.dart';
// import 'package:kids_learning_app/auth/siginup.dart';

// import 'package:kids_learning_app/components/homepage.dart';

// import 'package:kids_learning_app/categories/AddCategories.dart';

// import 'package:kids_learning_app/orders/my_orders.dart';

// import 'package:kids_learning_app/provider/provider_home.dart';
// import 'package:kids_learning_app/provider/provider_orders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        debugPrint("User is currently signed out!");
      } else {
        debugPrint("User is signed in!");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      // =========================================================
      // البداية
      // =========================================================
      //
      // المستخدم العادي يدخل Homepage
      // وليس ProviderHomePage
      //
      home: FirebaseAuth.instance.currentUser != null
          ? const NoteHomeScreen()
          : const Login(),
      routes: {
        // Auth
        'HiddenNotesPage': (context) => const HiddenNotesPage(),
        'AddNotePage': (context) => const AddNotePage(),
        'PinnedNotesPage': (context) => const PinnedNotesPage(),
        "signup": (context) => const siginup(),
        "login": (context) => const Login(),
        "forgot_password": (context) => const ForgotPassword(),
        // Client
        "NoteHomeScreen": (context) => const NoteHomeScreen(),

        "AddUserAndCategoryPage": (context) => const AddUserAndCategoryPage(),

        // Provider
        // "providerHome": (context) => const ProviderHomePage(),
        // "providerOrders": (context) => const ProviderOrdersPage(),

        // Categories
        // "AddCategories": (context) => const AddCategories(),

        // Provider
        // "AddProvider": (context) => const AddProviderPage(),

        // "AddProvider": (context) => const AddProviderPage(),
      },
    );
  }
}
