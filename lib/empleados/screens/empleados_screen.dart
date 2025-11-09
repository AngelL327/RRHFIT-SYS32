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
                    FirstSeccion(controller: _controller),
                    const SizedBox(height: 12),
                    ReportSeccion(),
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
