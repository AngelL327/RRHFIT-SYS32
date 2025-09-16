import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import '../core/theme.dart';

class AppSidebar extends StatelessWidget {
  final SidebarXController controller;
  const AppSidebar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: controller,
      theme: SidebarXTheme(
        decoration: const BoxDecoration(
          color: AppTheme.primary,
        ),
        textStyle: const TextStyle(color: Colors.white70),
        selectedTextStyle: const TextStyle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white70),
        selectedIconTheme: const IconThemeData(color: Colors.white),
      ),
      extendedTheme: const SidebarXTheme(
        width: 280,
      ),
      items: const [
        SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
        SidebarXItem(icon: Icons.people, label: 'Empleados'),
        SidebarXItem(icon: Icons.access_time, label: 'Asistencia'),
        SidebarXItem(icon: Icons.person, label: 'Perfil'),
        SidebarXItem(icon: Icons.request_page, label: 'Solicitudes'),
        SidebarXItem(icon: Icons.healing, label: 'Incapacidades'),
        SidebarXItem(icon: Icons.receipt, label: 'Nómina'),
        SidebarXItem(icon: Icons.picture_as_pdf, label: 'Vouchers'),
        SidebarXItem(icon: Icons.factory, label: 'Producción'),
        SidebarXItem(icon: Icons.shopping_cart, label: 'Ventas'),
        SidebarXItem(icon: Icons.settings, label: 'Configuración'),
      ],
    );
  }
}
