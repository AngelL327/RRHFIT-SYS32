import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/widgets/first_seccion.dart';
import 'package:rrhfit_sys32/empleados/widgets/report_seccion.dart';
import 'package:rrhfit_sys32/empleados/widgets/second_seccion.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  late final EmpleadoController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = EmpleadoController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        title: const Text(
          'Empleados - Gestión de Empleados',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
            tooltip: "¿Qué es esta sección?",
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: const Color(0xFF2E7D32),

                  title: const Text(
                    "Acerca de los Empleados",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  content: const Text(
                    "Esta sección permite visualizar, administrar y generar empleados "
                    "En este panel puedes:\n"
                    "• Ver lista de empleados\n"
                    "• Actualizar empleados\n"
                    "• Filtrar empleados \n"
                    "• Generar reportes de asistencia perfecta\n"
                    "Toda la información se obtiene en tiempo real ",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  actions: [
                    TextButton(
                      child: const Text(
                        "Cerrar",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReportSeccion(),
                    const SizedBox(height: 2),
                    FirstSeccion(controller: _controller),
                    const SizedBox(height: 12),
                    SecondSeccion(controller: _controller),
                    const SizedBox(height: 12),
                    // ThirdSeccion(controller: _controller),
                    // const SizedBox(height: 20),
                    // const ReportAsistenciaPerfecta(),
                    // const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
