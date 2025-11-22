import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/empleados/controllers/empleado_controller.dart';

class FirstSeccion extends StatefulWidget {
  final EmpleadoController controller;
  const FirstSeccion({super.key, required this.controller});

  @override
  State<FirstSeccion> createState() => _FirstSeccionState();
}

class _FirstSeccionState extends State<FirstSeccion> {
  final columns = [
    "EmpleadoID",
    "Nombre",
    "Codigo",
    "Correo",
    "Telefono",
    "Estado",
    "Departamento",
    "Puesto",
    "Fecha de Contratacion",
  ];

  late final TextEditingController _searchController;
  String _selected = 'Nombre';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.clamp(600.0, 1200.0);
            return Container(
              width: maxWidth,
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: Colors.black,
                      onChanged: (v) {
                        widget.controller.setSearchTerm(v);
                      },
                      decoration: InputDecoration(
                        labelText: 'Buscar',
                        labelStyle: const TextStyle(color: Colors.black87),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.black54,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 12.0,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 220,
                      minWidth: 120,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selected,
                      isDense: true,
                      isExpanded: true,
                      items: columns
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: SizedBox(
                                width: 200,
                                child: Text(
                                  tipo,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (String? valor) {
                        if (valor == null) return;
                        setState(() {
                          _selected = valor;
                        });
                        widget.controller.setFilterField(valor);
                      },
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        labelText: "Filtrar",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
