import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/widgets/first_seccion.dart';
import 'package:rrhfit_sys32/empleados/widgets/second_seccion.dart';

class EmpleadosScreen extends StatelessWidget {
  const EmpleadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Column(children: [FirstSeccion(), SecondSeccion()]));
  }
}
