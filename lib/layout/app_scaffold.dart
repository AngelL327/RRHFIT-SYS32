import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import '../pages/dashboard/dashboard_page.dart';
import 'sidebar.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);

  final _pages = <Widget>[
    const DashboardPage(),
    const Center(child: Text("Empleados Page")),
    const Center(child: Text("Asistencia Page")),
    const Center(child: Text("Perfil Page")),
    const Center(child: Text("Solicitudes Page")),
    const Center(child: Text("Incapacidades Page")),
    const Center(child: Text("Nómina Page")),
    const Center(child: Text("Vouchers Page")),
    const Center(child: Text("Producción Page")),
    const Center(child: Text("Ventas Page")),
    const Center(child: Text("Configuración Page")),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      body: Row(
        children: [
          // SidebarX ocupa un ancho fijo.
          SizedBox(
            width: isDesktop ? 280 : 72,
            child: AppSidebar(controller: _controller),
          ),
          // Contenido principal
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
