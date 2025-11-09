import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rrhfit_sys32/pages/mainpage.dart';
import 'package:rrhfit_sys32/pages/empleados/solicitar_incapacidad_page.dart';
import 'package:rrhfit_sys32/pages/mainpageweb.dart';
class AuthWebPage extends StatefulWidget {
  const AuthWebPage({super.key});

  @override
  State<AuthWebPage> createState() => _AuthWebPageState();
}

class _AuthWebPageState extends State<AuthWebPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final codigoController = TextEditingController();

  bool loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _codigoCorrecto; // para validar código
  String? _empleadoId;
  String? _nombreEmpleado;
  String? _areaId;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final codigoIngresado = codigoController.text.trim();

      if (email.isEmpty || password.isEmpty || codigoIngresado.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Todos los campos son obligatorios")),
        );
        setState(() => loading = false);
        return;
      }

      // Login con Firebase Auth
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Buscar empleado en Firestore
      final empleadoSnap = await _db
          .collection('empleados')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (empleadoSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario no registrado en empleados")),
        );
        await _auth.signOut();
        setState(() => loading = false);
        return;
      }

      final empleadoData = empleadoSnap.docs.first.data();
      _codigoCorrecto = empleadoData['codigo_empleado'] ?? '';
      _nombreEmpleado = empleadoData['nombre'] ?? '';
      _areaId = empleadoData['departamento_id'] ?? '';
      _empleadoId = empleadoSnap.docs.first.id;

      // Validar código
      if (codigoIngresado != _codigoCorrecto) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("El código no coincide")));
        await _auth.signOut();
        setState(() => loading = false);
        return;
      }

      // Login exitoso: ir a MainPage con datos correctos
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainPageweb(
            empleadoId: _empleadoId!,
            empleadoNombre: _nombreEmpleado!,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error al iniciar sesión")),
      );
    } finally {
      setState(() => loading = false);
    }
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildForm(),
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
                      Icons.remove_red_eye_outlined,
                      size: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codigoController,
                  decoration: InputDecoration(
                    hintText: 'Código de empleado',
                    suffixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                loading
                    ? const CircularProgressIndicator()
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
