import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/screens/empleados_screen.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/utilities/obtener_username.dart';
import 'package:rrhfit_sys32/pages/rrhh/incapacidades_page.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:rrhfit_sys32/pages/dashboard/dashboard_page.dart';
import 'package:rrhfit_sys32/pages/solicitudes.dart';
import 'package:rrhfit_sys32/pages/Usuario_page.dart';
import 'package:rrhfit_sys32/pages/generate_pdf_screen.dart';
import 'package:rrhfit_sys32/pages/rrhh/asistencia.dart';
import 'package:rrhfit_sys32/pages/subirpdf.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);

  final List<SidebarXItem> _sidebarItems = const [
    SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
    SidebarXItem(icon: Icons.people, label: 'Empleados'),
    SidebarXItem(icon: Icons.access_time, label: 'Asistencia'),
    SidebarXItem(icon: Icons.assignment, label: 'Solicitudes'),
    SidebarXItem(icon: Icons.healing, label: 'Incapacidades'),
    SidebarXItem(icon: Icons.picture_as_pdf_sharp, label: 'SubirPDF prueba'),
    SidebarXItem(icon: Icons.exit_to_app, label: 'Configuracion'),
  ];

  final List<Widget> _pages = [
    const DashboardPage(),
    // Center(child: Text("Página de Empleados", style: TextStyle(fontSize: 22))),
    EmpleadosScreen(),
   // Center(child: Text("Página de Asistencia", style: TextStyle(fontSize: 22))),
    const AsistenciaScreen(),
    const SolicitudesScreen(),
    const IncapacidadesScreen(),
    const PdfStorageWidget(),
    const PerfilPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = Global().currentUser;
      if (user == null) {
        // If Global.currentUser is not set yet, try to avoid crashing.
        return;
      }
      final uid = user.uid;
      final nombreCompleto = await obtenerUsername(uid);
      Global().userName = nombreCompleto;
      // Refresh the UI in case any widget depends on Global().userName
      if (mounted) setState(() {});
    } catch (e) {
      // Keep silent on error but log for debugging
      // ignore: avoid_print
      print('Error cargando nombre de usuario: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/fittlay.png',
                      height: 80, // Ajusta el tamaño
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Text( 'Fittlay', style: TextStyle
                  ( fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, ), ),
              
                ],
              ),
            ),

            items: _sidebarItems,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return _pages[_controller.selectedIndex];
              },
            ),
          ),
        ],
      ),
    );
  }
}
