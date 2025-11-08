import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/pages/empleados/solicitar_incapacidad_page.dart';
import 'package:rrhfit_sys32/pages/empleados/tracker_page.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:rrhfit_sys32/pages/empleados/mi_perfil_page.dart';

class EmpleadoMainPage extends StatefulWidget {
  const EmpleadoMainPage({super.key});

  @override
  State<EmpleadoMainPage> createState() => _EmpleadoMainPageState();
}

class _EmpleadoMainPageState extends State<EmpleadoMainPage> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  String _empleadoId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          // Crear ID legible: nombre_apellido (sin espacios, en minúsculas)
          final nombre = (data['nombre'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
          final apellido = (data['apellido'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
          
          setState(() {
            _empleadoId = '${nombre}_${apellido}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  final List<SidebarXItem> _sidebarItems = const [
    SidebarXItem(icon: Icons.track_changes, label: 'Tracker'),
    SidebarXItem(icon: Icons.assignment, label: 'Mis Solicitudes'),
    SidebarXItem(icon: Icons.person, label: 'Mi Perfil'),
  ];

  List<Widget> _getPages() {
    return [
      TrackerPage(empleadoId: _empleadoId),
      SolicitudesEmpleadoPage(empleadoId: _empleadoId, empleadoNombre: ''),
      MiPerfilPage(empleadoId: _empleadoId),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SidebarX(
            controller: _controller,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(0),
              decoration: BoxDecoration(color: Colors.green.shade700),
              textStyle: const TextStyle(color: Colors.white),
              selectedTextStyle: const TextStyle(color: Colors.white),
              itemTextPadding: const EdgeInsets.only(left: 16),
              selectedItemTextPadding: const EdgeInsets.only(left: 16),
              itemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              selectedItemDecoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              iconTheme: const IconThemeData(color: Colors.white70, size: 22),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 22,
              ),
              itemPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              selectedItemPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
            ),
            extendedTheme: const SidebarXTheme(
              width: 220,
              decoration: BoxDecoration(color: Color(0xFF2E7D32)),
            ),
            headerBuilder: (context, extended) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Fittlay',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8), // Espacio entre el texto y la imagen
      Image.asset(
        'assets/images/fittlay.png',
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red, size: 80);
        },
      ),
                ],
              ),
            ),
            items: _sidebarItems,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return _getPages()[_controller.selectedIndex];
              },
            ),
          ),
        ],
      ),
    );
  }
}
