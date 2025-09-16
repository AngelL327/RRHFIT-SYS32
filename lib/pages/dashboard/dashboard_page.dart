import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarX(
            controller: _controller,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
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
              selectedIconTheme:
                  const IconThemeData(color: Colors.white, size: 22),
              itemPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              selectedItemPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
            extendedTheme: const SidebarXTheme(
              width: 220,
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32),
              ),
            ),
            headerBuilder: (context, extended) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Fittlay',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            items: const [
              SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
              SidebarXItem(icon: Icons.people, label: 'Empleados'),
              SidebarXItem(icon: Icons.access_time, label: 'Asistencia'),
              SidebarXItem(icon: Icons.assignment, label: 'Solicitudes'),
              SidebarXItem(icon: Icons.healing, label: 'Incapacidades'),
              SidebarXItem(icon: Icons.receipt_long, label: 'Nómina'),
              SidebarXItem(icon: Icons.picture_as_pdf, label: 'Vouchers'),
              SidebarXItem(icon: Icons.factory, label: 'Producción'),
              SidebarXItem(icon: Icons.shopping_cart, label: 'Ventas'),
              SidebarXItem(icon: Icons.settings, label: 'Configuración'),
            ],
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF9F7F5),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    children: [
                      _DashboardCard(title: 'Empleados Activos', value: '9'),
                      _DashboardCard(title: 'Horas Totales Hoy', value: '56'),
                      _DashboardCard(
                          title: 'Horas Extra Acumuladas', value: '27'),
                      _DashboardCard(
                          title: 'Solicitudes Pendientes', value: '1'),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  const _DashboardCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 200,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}