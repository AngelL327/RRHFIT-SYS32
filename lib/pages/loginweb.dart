import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/utilities/obtener_username.dart';
import 'package:rrhfit_sys32/pages/empleados/EmpleadoMainPage.dart';

class AuthWebPage extends StatefulWidget {
  const AuthWebPage({super.key});

  @override
  State<AuthWebPage> createState() => _AuthWebPageState();
}

class _AuthWebPageState extends State<AuthWebPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email y contraseña son obligatorios")),
        );
        setState(() => loading = false);
        return;
      }
      // Login con Firebase Auth
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar que el usuario existe en Firestore
      final usuarioDoc = await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .get();
      
      Global().currentUser = cred.user;
      Global().userName = await obtenerUsername(cred.user!.uid);
      Global().empleadoID = await obtenerEmpleadoID(cred.user!.uid);


      if (!usuarioDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario no registrado en el sistema")),
        );
        await _auth.signOut();
        setState(() => loading = false);
        return;
      }

      // Login exitoso: ir a EmpleadoMainPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EmpleadoMainPage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        mensaje = "Usuario no encontrado";
      } else if (e.code == 'wrong-password') {
        mensaje = "Contraseña incorrecta";
      } else if (e.code == 'invalid-email') {
        mensaje = "Correo electrónico inválido";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text("Esta página es solo para web")),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1A7B94),
                          Color(0xFF2C9FB6),
                          Color(0xFF9ADFE8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Imagen
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/fittlay.png',
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.business,
                                size: 120,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sistema de Recursos Humanos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildForm(),
                ),
              ),
            ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¡HOLA!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C9FB6),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Inicia sesión en tu cuenta.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 30),
          const Icon(Icons.person, size: 55, color: Colors.black),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Correo',
                    suffixIcon: const Icon(Icons.email_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    suffixIcon: const Icon(
                      Icons.lock_outline,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                loading
                    ? const CircularProgressIndicator(
                        color: Color(0xFF2C9FB6),
                      )
                    : ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C9FB6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(140, 38),
                        ),
                        child: const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}