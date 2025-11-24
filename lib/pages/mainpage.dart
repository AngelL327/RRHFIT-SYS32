import 'package:features_tour/features_tour.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/empleados/screens/empleados_screen.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/utilities/obtener_username.dart';
import 'package:rrhfit_sys32/pages/rrhh/incapacidades_page.dart';
import 'package:rrhfit_sys32/reclutamiento/screen/reclutamiento_screen.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:rrhfit_sys32/pages/dashboard/dashboard_page.dart';
import 'package:rrhfit_sys32/pages/solicitudes.dart';
import 'package:rrhfit_sys32/pages/Usuario_page.dart';
import 'package:rrhfit_sys32/pages/rrhh/asistencia.dart';
import 'package:rrhfit_sys32/pages/empleados/mi_perfil_page.dart';
import 'package:rrhfit_sys32/pages/empleados/tracker_page.dart';
import 'package:rrhfit_sys32/pages/empleados/solicitar_incapacidad_page.dart';
import 'package:rrhfit_sys32/pages/empleados/EmpleadoMainPage.dart';
import 'package:rrhfit_sys32/pages/nomina.dart';
import 'package:rrhfit_sys32/pages/voucherscreen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  String empleadoId = '';
  String empleadoUid = '';
  String nombre = '';
  String areaId = '';
  String codigoEmpleado = '';

  List<Widget> get webPages => [
    TrackerPage(empleadoId: empleadoId, empleadoUid: empleadoUid),
    SolicitudesEmpleadoPage(
      empleadoId: empleadoId,
      empleadoNombre: '',
      empleadoUid: empleadoUid,
    ),
    MiPerfilPage(empleadoId: empleadoId),
    TrackerPage(empleadoId: empleadoId, empleadoUid: empleadoUid),
    EmpleadoMainPage(),
  ];

  final List<SidebarXItem> _sidebarItems = const [
    SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
    SidebarXItem(icon: Icons.people, label: 'Reclutamiento'),
    SidebarXItem(icon: Icons.people, label: 'Empleados'),
    SidebarXItem(icon: Icons.access_time, label: 'Asistencia'),
    SidebarXItem(icon: Icons.assignment, label: 'Solicitudes'),
    SidebarXItem(icon: Icons.healing, label: 'Incapacidades'),
    SidebarXItem(icon: Icons.attach_money, label: 'Nomina'),
    SidebarXItem(icon: Icons.exit_to_app, label: 'Configuracion'),
  ];
  final List<SidebarXItem> _sidebarItems2 = const [
    SidebarXItem(icon: Icons.dashboard, label: 'Tracker'),
    SidebarXItem(icon: Icons.people, label: 'Mis solicitudes'),
    SidebarXItem(icon: Icons.access_time, label: 'Mi perfil'),
  ];

  final List<Widget> _pages = [
    const DashboardPage(),
    const ReclutamientoScreen(),
    EmpleadosScreen(),
    const AsistenciaScreen(),
    const SolicitudesScreen(),
    const IncapacidadesScreen(),

    PlanillasScreen(),
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
      Global().empleadoID = await obtenerEmpleadoID(uid);
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
    //  Si es modo Web, solo mostrar SolicitudesScreen
    if (kIsWeb) {
      final webSidebarItems = _sidebarItems2.sublist(
        0,
        3,
      ); // solo los primeros 4
      final webPagesList = webPages; // tus 4 páginas web
      return Scaffold(
        body: Row(
          children: [
            SidebarX(
              controller: _controller,
              theme: SidebarXTheme(
                margin: const EdgeInsets.all(0),
                decoration: BoxDecoration(color: AppTheme.primary),
                textStyle: const TextStyle(color: AppTheme.cream),
                selectedTextStyle: const TextStyle(color: AppTheme.cream),
                itemTextPadding: const EdgeInsets.only(left: 16),
                selectedItemTextPadding: const EdgeInsets.only(left: 16),
                itemDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                selectedItemDecoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                iconTheme: const IconThemeData(color: AppTheme.cream, size: 22),
                selectedIconTheme: const IconThemeData(
                  color: AppTheme.cream,
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
                decoration: BoxDecoration(color: AppTheme.primary),
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
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Text(
                      'Fittlay',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.cream,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              items: webSidebarItems,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Limitar índice solo a las páginas web disponibles
                  final index = _controller.selectedIndex.clamp(
                    0,
                    webPagesList.length - 1,
                  );
                  return webPagesList[index];
                },
              ),
            ),
          ],
        ),
      );
    }

    //  En cualquier otra plataforma, mostrar la vista completa con Sidebar
    return Scaffold(
      body: Row(
        children: [
          SidebarX(
            controller: _controller,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(0),
              decoration: BoxDecoration(color: AppTheme.primary),
              textStyle: const TextStyle(color: AppTheme.cream),
              selectedTextStyle: const TextStyle(color: AppTheme.cream),
              itemTextPadding: const EdgeInsets.only(left: 16),
              selectedItemTextPadding: const EdgeInsets.only(left: 16),
              itemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              selectedItemDecoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              iconTheme: const IconThemeData(color: AppTheme.cream, size: 22),
              selectedIconTheme: const IconThemeData(
                color: AppTheme.cream,
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
              decoration: BoxDecoration(color: AppTheme.primary),
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
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Text(
                    'Fittlay',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.cream,
                      fontWeight: FontWeight.bold,
                    ),
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
                return _pages[_controller.selectedIndex];
              },
            ),
          ),
        ],
      ),
    );
  }
}
