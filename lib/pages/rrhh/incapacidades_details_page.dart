import "package:flutter/material.dart";

class IncapacidadDetallesScreen extends StatelessWidget {
  const IncapacidadDetallesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implementar la pantalla de detalles de incapacidad
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Incapacidad'),
      ),
      body: const Center(
        child: Text('Aquí se mostrarán los detalles de la incapacidad'),
      ),
    );
  }
}