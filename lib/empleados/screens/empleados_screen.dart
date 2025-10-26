import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/widgets/first_seccion.dart';
import 'package:rrhfit_sys32/empleados/widgets/second_seccion.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  late final EmployeeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EmployeeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FirstSeccion(controller: _controller),
          SecondSeccion(controller: _controller),
        ],
      ),
    );
  }
}
