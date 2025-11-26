import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/pages/mainpage.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  bool _mostrarPassword = false;
  bool loading = false;

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty || nombre.length < 3) {
      _mostrarAlerta('El nombre debe tener al menos 3 letras');
      return;
    }
    if (!email.contains('@')) {
      _mostrarAlerta('El correo debe contener un @');
      return;
    }
    if (password.length < 8) {
      _mostrarAlerta('La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() => loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'email': email,
            'nombre': nombre,
            'apellido': apellido,
            'fechaRegistro': Timestamp.now(),
          });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _mostrarAlerta('Error al registrar: ${e.message}');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isWide
          ? Row(
              children: [
                // PANEL IZQUIERDO (GRADIENTE + LOGO)
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/fittlay.png',
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            'Sistema de Recursos Humanos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // PANEL DERECHO - FORMULARIO
                Expanded(
                  flex: 2,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
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
            '¡REGÍSTRATE!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C9FB6),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crea tu cuenta para acceder al sistema.',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          const Icon(Icons.person_add, size: 60, color: Color(0xFF1A7B94)),
          const SizedBox(height: 20),

          // TARJETA DEL FORMULARIO
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    hintText: "Nombre",
                    suffixIcon: const Icon(Icons.person, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _apellidoController,
                  decoration: InputDecoration(
                    hintText: "Apellido",
                    suffixIcon: const Icon(Icons.person, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Correo electrónico",
                    suffixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  decoration: InputDecoration(
                    hintText: "Contraseña",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF1A7B94),
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarPassword = !_mostrarPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // BOTÓN REGISTRARSE
                loading
                    ? const CircularProgressIndicator(color: Color(0xFF2C9FB6))
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C9FB6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          minimumSize: const Size(150, 40),
                        ),
                        child: const Text(
                          "REGISTRARSE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                const SizedBox(height: 15),

                // BOTÓN PARA VOLVER A LOGIN
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // vuelve a AuthPage
                  },
                  child: const Text(
                    '¿Ya tienes una cuenta? Iniciar sesión',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C9FB6),
                      fontWeight: FontWeight.w500,
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
