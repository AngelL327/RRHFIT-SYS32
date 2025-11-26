import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmpleadoAutocomplete extends StatefulWidget {
  final TextEditingController empleadoCtrl;
  final TextEditingController codigoCtrl;
  final TextEditingController departamentoCtrl;

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

  String? _codigoCorrecto;
  String? _empleadoValido;
  String? _departamentoValido;

  // 🔹 Función para mostrar mensajes
  void _mensaje(String texto, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: ok ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
      
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
            decoration: InputDecoration(
              labelText: "Empleado",
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              errorText: _empleadoValido == "error"
                  ? " Seleccione uno de los empleados sugeridos."
                  : null,
            ),
            onChanged: (value) async {
              // VALIDAR SI EXISTE EN BASE DE DATOS
              if (value.isEmpty) return;

              final snap = await _db
                  .collection("empleados")
                  .where("nombre", isEqualTo: value)
                  .get();

              if (snap.docs.isEmpty) {
                setState(() => _empleadoValido = "error");
              } else {
                setState(() => _empleadoValido = "ok");
              }
            },
          ),

          itemBuilder: (context, suggestion) {
            return ListTile(
              title: Text(suggestion["nombre"]),
            );
          },

          onSelected: (suggestion) {
            widget.empleadoCtrl.text = suggestion["nombre"];
            widget.codigoCtrl.text = suggestion["codigo_empleado"]; 
            _codigoCorrecto = suggestion["codigo_empleado"];
            widget.onEmpleadoSeleccionado?.call(suggestion["id"]);

            setState(() => _empleadoValido = "ok");
            _mensaje("Empleado seleccionado correctamente", ok: true);
          },
        ),

        const SizedBox(height: 10),

        TextField(
          controller: widget.codigoCtrl,
          decoration: InputDecoration(
            labelText: "Código de empleado",
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            errorText: (widget.codigoCtrl.text.isNotEmpty &&
                    widget.codigoCtrl.text != _codigoCorrecto)
                ? "Código incorrecto"
                : null,
          ),
          onChanged: (value) {
            if (_codigoCorrecto == null) return;

            if (value.trim() == _codigoCorrecto) {
              _mensaje("Código verificado correctamente", ok: true);
            }
          },
        ),

        const SizedBox(height: 20),

      
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
              return {
                "id": doc.id,
                "nombre": doc["nombre"] ?? '',
              };
            }).toList();
          },

          builder: (context, controller, focusNode) => TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: "Departamento",
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              errorText: _departamentoValido == "error"
                  ? " Seleccione uno de los departamentos sugeridos "
                  : null,
            ),
            onChanged: (value) async {
              if (value.isEmpty) return;

              final snap = await _db
                  .collection("departamento")
                  .where("nombre", isEqualTo: value)
                  .get();

              if (snap.docs.isEmpty) {
                setState(() => _departamentoValido = "error");
              } else {
                setState(() => _departamentoValido = "ok");
              }
            },
          ),

          itemBuilder: (context, suggestion) {
            return ListTile(
              title: Text(suggestion["nombre"]),
            );
          },

          onSelected: (suggestion) {
            widget.departamentoCtrl.text = suggestion["nombre"];
            widget.onDepartamentoSeleccionado?.call(suggestion["id"]);

            setState(() => _departamentoValido = "ok");
            _mensaje("Departamento seleccionado", ok: true);
          },
        ),
      ],
    );
  }
}
