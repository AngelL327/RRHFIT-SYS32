import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:rrhfit_sys32/pages/empleados/solicitar_incapacidad_page.dart';
import 'package:rrhfit_sys32/pages/empleados/mi_perfil_page.dart';
import 'package:rrhfit_sys32/pages/empleados/tracker_page.dart';

class MainPageweb extends StatefulWidget {
  final String empleadoId;
  final String empleadoNombre;

  const MainPageweb({
    super.key,
    required this.empleadoId,
    required this.empleadoNombre,
  });

  @override
  State<MainPageweb> createState() => _MainPageState();
}

class _MainPageState extends State<MainPageweb> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);

  late String empleadoId;
  late String empleadoNombre;

  @override
  void initState() {
    super.initState();
    empleadoId = widget.empleadoId;
    empleadoNombre = widget.empleadoNombre;
  }

  List<Widget> get webPages => [
        TrackerPage(
        empleadoId: empleadoId,   // agregar este parámetro
        empleadoUid: empleadoId,  // mantener empleadoUid como antes
      ),
        SolicitudesEmpleadoPage(
          empleadoId: empleadoId,
          empleadoNombre: empleadoNombre,
        ),
        MiPerfilPage(empleadoId: empleadoId),
      ];

  final List<SidebarXItem> _sidebarItemsWeb = const [
    SidebarXItem(icon: Icons.dashboard, label: 'Tracker'),
    SidebarXItem(icon: Icons.people, label: 'Mis solicitudes'),
    SidebarXItem(icon: Icons.access_time, label: 'Mi perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text("Esta página es solo para web")),
      );
    }

    print("EmpleadoID en MainPageweb: ${Global().empleadoID}");

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
              itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              selectedItemDecoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              iconTheme: const IconThemeData(color: AppTheme.cream, size: 22),
              selectedIconTheme: const IconThemeData(color: AppTheme.cream, size: 22),
              itemPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              selectedItemPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            extendedTheme: const SidebarXTheme(
              width: 220,
              decoration: BoxDecoration(color: AppTheme.primaryDark),
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
                  const SizedBox(height: 8),
                  Text(
                    empleadoNombre,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.cream,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            items: _sidebarItemsWeb,
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final index = _controller.selectedIndex.clamp(0, webPages.length - 1);
                return webPages[index];
              },
            ),
          ),
        ],
      ),
    );
  }
}
