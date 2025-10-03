import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    // Opción 1: Obtener datos del usuario actual de Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      setState(() {
        userEmail = user.email ?? 'No email';
        // Para el nombre, puedes usar displayName si lo tienes configurado
        userName = user.displayName ?? 'Usuario';
      });
    } else {
      // Opción 2: Obtener datos de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final nombre = prefs.getString('nombre') ?? '';
      final apellido = prefs.getString('apellido') ?? '';
      final email = prefs.getString('email') ?? '';
      
      setState(() {
        userName = '$nombre $apellido'.trim();
        if (userName.isEmpty) userName = 'Usuario';
        userEmail = email.isNotEmpty ? email : 'No email';
      });
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    
    // Opcional: Limpiar SharedPreferences al cerrar sesión
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1D9FCB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Sobre mi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Soy un estudiante de la UNAH.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}