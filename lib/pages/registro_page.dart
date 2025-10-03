import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/pages/mainpage.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({Key? key}) : super(key: key);

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  bool _mostrarPassword = false;

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

      // guardar la info de documento para mostrar en el usuario, y guardar localmente
   

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      _mostrarAlerta('Error al registrar: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Color(0XFF1D9FCB),
        elevation: 30,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 17, 17, 17),
                ),
                floatingLabelStyle: const TextStyle(
                  color: Color.fromARGB(255, 2, 97, 174),
                ),
                suffix: const Icon(
                  Icons.person,
                  size: 18,
                  color: Color(0XFF1D9FCB),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 2, 97, 174),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apellidoController,
              decoration: InputDecoration(
                labelText: 'Apellido',
                labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 17, 17, 17),
                ),
                floatingLabelStyle: const TextStyle(
                  color: Color.fromARGB(255, 2, 97, 174),
                ),
                suffix: const Icon(
                  Icons.person,
                  size: 18,
                  color: Color(0XFF1D9FCB),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 2, 97, 174),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electronico',
                labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 17, 17, 17),
                ),
                floatingLabelStyle: const TextStyle(
                  color: Color.fromARGB(255, 2, 97, 174),
                ),
                suffix: const Icon(
                  Icons.email,
                  size: 18,
                  color: Color(0XFF1D9FCB),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 2, 97, 174),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: !_mostrarPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(
                  color: Color.fromARGB(255, 17, 17, 17),
                ),
                floatingLabelStyle: const TextStyle(
                  color: Color.fromARGB(255, 2, 97, 174),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                    color: Color(0XFF1D9FCB),
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarPassword = !_mostrarPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 2, 97, 174),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4E5F3),
              ),
              child: const Text(
                'Registrarse',
                style: TextStyle(fontSize: 14, color: Color(0XFF1D9FCB)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
