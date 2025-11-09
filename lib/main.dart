import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/utilities/obtener_username.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rrhfit_sys32/pages/auth_page.dart';
import 'package:rrhfit_sys32/pages/mainpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:rrhfit_sys32/pages/loginweb.dart';

// El modo web no mantiene el inicio de sesion parece error de firebase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://mmrnyhyltodxfirygqua.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1tcm55aHlsdG9keGZpcnlncXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTM1ODQsImV4cCI6MjA3NzE4OTU4NH0.eLjSLmSBfo04om7j2Wgx7Vc_5yVemKXMHaEO9FHeOe8', // tu anon/key
  );

  // Configurar persistencia de sesión en Web
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(const MyApp());
}

/// Obtiene el usuario inicial al arrancar la app
Future<User?> getInitialUser() async {
  return FirebaseAuth.instance.currentUser;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fittlay Planillas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            print("Usuario web activo UID: ${snapshot.data!.uid}");
            Global().currentUser = snapshot.data;
            // Redirige a tu página web de solicitudes
            return const AuthWebPage(); // o directamente SolicitudesEmpleadoPage si quieres
          } else {
            print("No hay usuario web logueado");
            return const AuthWebPage();
          }
        },
      );
    }
    return FutureBuilder<User?>(
      future: getInitialUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData) {
              print("Usuario activo  UID: ${snapshot.data!.uid}");
              Global().currentUser = snapshot.data;
              return const MainPage();
            } else {
              print("No hay usuario logueado");
              return const AuthPage();
            }
          },
        );
      },
    );
  }
}
