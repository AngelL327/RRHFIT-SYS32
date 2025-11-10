import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmpleadoAutocomplete extends StatefulWidget {
  final TextEditingController empleadoCtrl;
  final TextEditingController codigoCtrl; // el usuario lo llena manualmente
  final TextEditingController departamentoCtrl; // nuevo campo: departamento
  final void Function(String empleadoId)? onEmpleadoSeleccionado;
  final void Function(String departamentoId)? onDepartamentoSeleccionado;

  const EmpleadoAutocomplete({
    super.key,
    required this.empleadoCtrl,
    required this.codigoCtrl,
    required this.departamentoCtrl,
    this.onEmpleadoSeleccionado,
    this.onDepartamentoSeleccionado,
  });

  @override
  State<EmpleadoAutocomplete> createState() => _EmpleadoAutocompleteState();
}

class _EmpleadoAutocompleteState extends State<EmpleadoAutocomplete> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _codigoCorrecto; // se guarda el código real del empleado

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔹 AUTOCOMPLETE DE EMPLEADO
        TypeAheadField<Map<String, dynamic>>(
          controller: widget.empleadoCtrl,
          suggestionsCallback: (pattern) async {
            if (pattern.trim().isEmpty) return [];

            final snapshot = await _db
                .collection("empleados")
                .where("nombre", isGreaterThanOrEqualTo: pattern)
                .where("nombre", isLessThanOrEqualTo: "$pattern\uf8ff")
                .limit(10)
                .get();

            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                "id": doc.id,
                "nombre": data["nombre"] ?? '',
                "codigo_empleado": data["codigo_empleado"] ?? '',
              };
            }).toList();
          },

          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: "Empleado",
              border: OutlineInputBorder(),
              hintText: "Escribe el nombre del empleado...",
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          itemBuilder: (context, suggestion) => ListTile(
            title: Text(suggestion["nombre"]),
          ),

          onSelected: (suggestion) {
            widget.empleadoCtrl.text = suggestion["nombre"];
            _codigoCorrecto = suggestion["codigo_empleado"]; // guardamos el real
            widget.onEmpleadoSeleccionado?.call(suggestion["id"]);
          },

          decorationBuilder: (context, child) => Material(
            type: MaterialType.card,
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),

          itemSeparatorBuilder: (context, index) => const Divider(height: 1),
        ),

        const SizedBox(height: 10),

        ///  CAMPO DE CÓDIGO (VALIDACIÓN MANUAL)
        TextField(
          controller: widget.codigoCtrl,
          decoration: const InputDecoration(
            labelText: "Código de empleado",
            border: OutlineInputBorder(),
            hintText: "Ingresa tu código de empleado",
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            if (_codigoCorrecto != null ) {
              if (value.trim() != _codigoCorrecto) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(" Código verificado correctamente"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } 
            }
          },
        ),

        const SizedBox(height: 20),

        /// 🔹 AUTOCOMPLETE DE DEPARTAMENTO (nuevo)
        TypeAheadField<Map<String, dynamic>>(
          controller: widget.departamentoCtrl,
          suggestionsCallback: (pattern) async {
            if (pattern.trim().isEmpty) return [];

            final snapshot = await _db
                .collection("departamento")
                .where("nombre", isGreaterThanOrEqualTo: pattern)
                .where("nombre", isLessThanOrEqualTo: "$pattern\uf8ff")
                .limit(10)
                .get();

            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                "id": doc.id,
                "nombre": data["nombre"] ?? '',
              };
            }).toList();
          },

          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: "Departamento",
              border: OutlineInputBorder(),
              hintText: "Escribe el nombre del departamento...",
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          itemBuilder: (context, suggestion) => ListTile(
            title: Text(suggestion["nombre"]),
          ),

          onSelected: (suggestion) {
            widget.departamentoCtrl.text = suggestion["nombre"];
            widget.onDepartamentoSeleccionado?.call(suggestion["id"]);
          },

          decorationBuilder: (context, child) => Material(
            type: MaterialType.card,
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),

          itemSeparatorBuilder: (context, index) => const Divider(height: 1),
        ),
      ],
    );
  }
}
