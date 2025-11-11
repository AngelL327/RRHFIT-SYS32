import 'dart:math';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/Reportes/reporte_incapacidades_body.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/area_functions.dart';
import 'package:rrhfit_sys32/logic/empleados_functions.dart';
import 'package:rrhfit_sys32/logic/models/area_model.dart';
import 'package:rrhfit_sys32/logic/models/empleado_model.dart';
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/incapacidad_functions.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/pages/rrhh/add_incapacidad_page.dart';
import 'package:rrhfit_sys32/pages/rrhh/incapacidades_details_page.dart';
import 'package:rrhfit_sys32/widgets/search_bar.dart';
import 'package:rrhfit_sys32/widgets/summary_box.dart';
import 'package:rrhfit_sys32/widgets/table_widget.dart';

class IncapacidadesScreen extends StatefulWidget {
  const IncapacidadesScreen({super.key});

  @override
  State<IncapacidadesScreen> createState() => _IncapacidadesScreenState();
}

class _IncapacidadesScreenState extends State<IncapacidadesScreen> {
  String _query = '';
  String? _sortColumn;
  bool _sortAsc = true;

  // Available columns to sort by (label -> key)
  final Map<String, String> _sortColumns = {
    'Empleado': 'empleado',
    'Tipo': 'tipo',
    'Fecha Solicitud': 'fechaSolicitud',
    'Inicio': 'inicio',
    'Fin': 'fin',
    'Estado': 'estado',
    'Ente Emisor': 'enteEmisor',
    '# Certificado': 'numCertificado',
  };

  bool _matchesQuery(IncapacidadModel inc, String q) {
    if (q.isEmpty) return true;
    final qlc = q.toLowerCase();
    final empleado = inc.usuario.toLowerCase();
    final tipo = inc.tipoSolicitud.toLowerCase();
    final estado = inc.estado.toLowerCase();
    final fechaSolicitud = formatDate(inc.fechaSolicitud).toLowerCase();
    final inicio = formatDate(inc.fechaInicioIncapacidad).toLowerCase();
    final fin = formatDate(inc.fechaFinIncapacidad).toLowerCase();
    final enteEmisor = inc.enteEmisor.toLowerCase();
    final numCertificado = inc.numCertificado.toLowerCase();


    return empleado.contains(qlc) ||
        tipo.contains(qlc) ||
        estado.contains(qlc) ||
        fechaSolicitud.contains(qlc) ||
        inicio.contains(qlc) ||
        fin.contains(qlc) ||
        enteEmisor.contains(qlc) ||
        numCertificado.contains(qlc);
  }

  int _compareByColumn(IncapacidadModel a, IncapacidadModel b) {
    final col = _sortColumn;
    if (col == null) return 0;
    int res = 0;
    switch (col) {
      case 'empleado':
        res = a.usuario.toLowerCase().compareTo(b.usuario.toLowerCase());
        break;
      case 'tipo':
        res = a.tipoIncapacidad.toLowerCase().compareTo(b.tipoIncapacidad.toLowerCase());
        break;
      case 'estado':
        res = a.estado.toLowerCase().compareTo(b.estado.toLowerCase());
        break;
      case 'fechaSolicitud':
        res = a.fechaSolicitud.compareTo(b.fechaSolicitud);
        break;
      case 'inicio':
        res = a.fechaInicioIncapacidad.compareTo(b.fechaInicioIncapacidad);
        break;
      case 'fin':
        res = a.fechaFinIncapacidad.compareTo(b.fechaFinIncapacidad);
        break;
      case 'enteEmisor':
        res = a.enteEmisor.toLowerCase().compareTo(b.enteEmisor.toLowerCase());
        break;
      case 'numCertificado':
        res = a.numCertificado.toLowerCase().compareTo(b.numCertificado.toLowerCase());
        break;
      default:
        res = 0;
    }
    return _sortAsc ? res : -res;
  }

  @override
  Widget build(BuildContext context) {
    print(Global().currentUser?.email ?? 'No user email');
    print(Global().currentUser?.uid ?? 'No user UID');
    print(Global().userName ?? 'No user display name');



    return Scaffold(
      appBar: AppBar(
            title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Incapacidades - Gestión de incapacidades de empleados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor:  AppTheme.primary,
        foregroundColor: AppTheme.cream,
        elevation: 0,
        centerTitle: true,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary, 
                Color.fromRGBO(50, 200, 120, 1), 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                //Total de solicitudes
                FutureBuilder<String?>(
                  future: getCountIncapacidades(),
                  builder: (context, snapshot) {
                    final text = snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : (snapshot.data ?? '0');
                    return SummaryBox(
                      title: 'Total de solicitudes:',
                      number: text,
                      color: Colors.blueGrey,
                    );
                  },
                ),
                //Total de solicitudes revisadas
                FutureBuilder<String?>(
                  future: getCountIncapacidadesRevisadas(),
                  builder: (context, snapshot) {
                    final text = snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : (snapshot.data ?? '0');
                    return SummaryBox(
                      title: 'Solicitudes revisadas:',
                      number: text,
                      color: Colors.green,
                    );
                  },
                ),
                //Total de solicitudes pendientes
                FutureBuilder<String?>(
                  future: getCountIncapacidadesPendientes(),
                  builder: (context, snapshot) {
                    final text = snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : (snapshot.data ?? '0');
                    return SummaryBox(
                      title: 'Solicitudes pendientes:',
                      number: text,
                      color: Colors.orange,
                    );
                  },
                ),
                //Total de solicitudes rechazadas
                FutureBuilder<String?>(
                  future: getCountIncapacidadesRechazadas(),
                  builder: (context, snapshot) {
                    final text = snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : (snapshot.data ?? '0');
                    return SummaryBox(
                      title: 'Solicitudes rechazadas:',
                      number: text,
                      color: Colors.red,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar and PDF button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Añadir nueva solicitud de incapacidad
                  IconButton(
                    style: AppTheme.lightTheme.elevatedButtonTheme.style,
                    icon: Row(
                      children: [
                        const Icon(Icons.add_circle, color: AppTheme.cream ),
                        const SizedBox(width: 8),
                        Text('Añadir nueva solicitud', style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.bold, fontSize: 16),),
                      ],
                    ),
                    tooltip: 'Añadir nueva solicitud de incapacidad',
                    onPressed: () async {
                      final created = await showAddIncapacidadDialog(context);
                      if (created == true) {
                        setState(() {});
                      }
                    },
                  ),




                  //Reporte PDF
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GeneratePDFButton<dynamic>(
                      buttonLabel: 'Imprimir reporte de incapacidades',
                      reportTitle: 'Reporte de Incapacidades',
                      fetchData: getRegistros,
                      tableHeaders: [
                        'Fecha Inicio',
                        'Fecha Fin',
                        'Tipo',
                        'Estado',
                        'Empleado',
                        'Emisor y Documento',
                        'Correo',
                        'Motivo',
                        'Area',
                      ],
                      rowMapper: (inc) {
                        return [
                          formatDate((inc[0] as IncapacidadModel).fechaInicioIncapacidad),
                          formatDate((inc[0] as IncapacidadModel).fechaFinIncapacidad),
                          (inc[0] as IncapacidadModel).tipoIncapacidad,
                          (inc[0] as IncapacidadModel).estado,
                          (inc[0] as IncapacidadModel).usuario,
                          "${(inc[0] as IncapacidadModel).enteEmisor}\n#${(inc[0] as IncapacidadModel).numCertificado}",
                          //(inc[1] as EmpleadoModel).correo,
                          "Correo@gmail.com",
                          (inc[0] as IncapacidadModel).motivo.length > 30 ? '${(inc[0] as IncapacidadModel).motivo.substring(0, 30)}...' : (inc[0] as IncapacidadModel).motivo,
                          //(inc[2] as AreaModel).nombre,
                          "No asignada",

                        ];
                      },
                      columnFlexes: [1.15, 1.15, 1.3, 1.15, 1.3, 1.5, 1.3, 1.4, 1.2],
                      bodyContent: null,
                    ),
                  ),




                  //Search bar
                  SearchBarWidget(
                  hintText: 'Buscar por empleado, tipo, estado o fecha',
                  initialQuery: _query,
                  onChanged: (value) => value.isNotEmpty ? setState(() => _query = value.toLowerCase()) : null,
                  onClear: () => setState(() => _query = ''),
                  sortColumns: _sortColumns,
                  currentSortColumn: _sortColumn,
                  currentSortAsc: _sortAsc,
                  onSortSelected: (key) {
                    setState(() {
                      if (key == null) {
                        _sortColumn = null;
                        _sortAsc = true;
                      } else if (_sortColumn == key) {
                        _sortAsc = !_sortAsc;
                      } else {
                        _sortColumn = key;
                        _sortAsc = true;
                      }
                    },
                    );
                  },
                ),
                ],
              ),
            ),
            const SizedBox(height: 16),




            // Table
            Expanded(
              child: FutureBuilder<List<IncapacidadModel>>( 
                future: getAllIncapacidades(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final list = snapshot.data ?? [];

                  if (list.isEmpty) {
                    return const Center(child: Text('No hay incapacidades registradas'));
                  }

                  final filtered = list.where((inc) => _matchesQuery(inc, _query)).toList();                  
                  final sorted = List<IncapacidadModel>.from(filtered);
                  if (_sortColumn != null) {
                    sorted.sort((a, b) => _compareByColumn(a, b));
                  }

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No hay resultados que coincidan con la búsqueda'));
                  }

                  const columns = [
                        DataColumn2(label: Center(child: Text('Fecha Solicitud')), size: ColumnSize.M),
                        DataColumn2(label: Center(child: Text('Empleado')), size: ColumnSize.M),
                        DataColumn2(label: Center(child: Text('Tipo')), size: ColumnSize.M),
                        DataColumn2(label: Center(child: Text('Ente Emisor')), size: ColumnSize.M),
                        DataColumn2(label: Center(child: Text('# Certificado')), size: ColumnSize.M),
                        DataColumn2(label: Center(child: Text('Inicio de incapacidad')), size: ColumnSize.L),
                        DataColumn2(label: Center(child: Text('Fin de incapacidad')), size: ColumnSize.L),
                        DataColumn2(label: Center(child: Text('Estado')), size: ColumnSize.M),
                        DataColumn2(label: Center(child: Text('Detalles')), size: ColumnSize.S),
                      ];

                  List<DataRow> dataRows = [];

                  for (var inc in sorted) {
                    dataRows.add(
                      DataRow(cells: [
                        DataCell(Center(child: Text(formatDate(inc.fechaSolicitud)))),
                        DataCell(Text(inc.usuario)),
                        DataCell(Text(inc.tipoIncapacidad)),
                        DataCell(Text(inc.enteEmisor)),
                        DataCell(Center(child: Text(inc.numCertificado))),
                        DataCell(Center(child: Text(formatDate(inc.fechaInicioIncapacidad)))),
                        DataCell(Center(child: Text(formatDate(inc.fechaFinIncapacidad)))),
                        DataCell(inc.estado == "Pendiente" ? 
                        Center(child: const Text("Pendiente", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),))
                        : inc.estado == "Aprobada" ? 
                        Center(child: const Text("Aprobada", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),))
                        : Center(child: const Text("Rechazada", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),))),

                        DataCell(
                          Center(
                            child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Ver'),
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => buildDetallesDialog(context, inc, setState: () {
                                  setState(() {});
                                }),
                              );
                            },
                                                    ),
                          )),
                      ]),
                    );
                  }

                  // Horizontal + vertical scrollable table
                  // return SingleChildScrollView(
                  //   scrollDirection: Axis.horizontal,
                  //   child: SingleChildScrollView(
                  //     child: tableGenerator(sorted, context, columns, dataRows),
                  //   ),
                  // );
                  return Padding(
                    padding: const EdgeInsets.all(30),
                    child: tableGenerator(sorted, context, columns, dataRows),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<List<dynamic>> getRegistros() async {
    List results = [];

    List<IncapacidadModel> incapacidades = await getAllIncapacidades();
    for (var inc in incapacidades) {
      EmpleadoModel? emp = await getEmpleadoById(inc.userId);
      if (emp == null) continue;

      AreaModel? area = await getAreaById(emp?.areaID);
      if (area == null) continue;
      
      results.add([inc, emp, area]);
    }

    return results;
  }
}