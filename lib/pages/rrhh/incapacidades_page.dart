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
import 'package:rrhfit_sys32/logic/models/incapacidad_row.dart';
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
  // Default to current month and year for the report selector
  int? _selectedMonth = DateTime.now().month;
  int? _selectedYear = DateTime.now().year;

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
        res = a.tipoIncapacidad.toLowerCase().compareTo(
          b.tipoIncapacidad.toLowerCase(),
        );
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
        res = a.numCertificado.toLowerCase().compareTo(
          b.numCertificado.toLowerCase(),
        );
        break;
      default:
        res = 0;
    }
    return _sortAsc ? res : -res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Incapacidades - Gestion de incapacidades de empleados. ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
                    "Acerca de Incapacidades",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  content: const Text(
                    "Esta sección permite registrar y administrar las incapacidades "
                    "otorgadas a los empleados.\n\n"
                    "En esta sección puedes:\n"
                    "• Registrar nuevas incapacidades\n"
                    "• Ver historial por empleado\n"
                    "• Editar o eliminar registros\n"
                    "• Consultar fechas, motivos y documentos de respaldo\n"
                    "• Controlar vigencia y días restantes\n\n"
                    "La información se sincroniza en Firestore.",
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

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Summary
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //Total de solicitudes
                  FutureBuilder<String?>(
                    future: getCountIncapacidades(),
                    builder: (context, snapshot) {
                      final text =
                          snapshot.connectionState == ConnectionState.waiting
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
                      final text =
                          snapshot.connectionState == ConnectionState.waiting
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
                      final text =
                          snapshot.connectionState == ConnectionState.waiting
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
                      final text =
                          snapshot.connectionState == ConnectionState.waiting
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
            ),
            const SizedBox(height: 16),

            // Search bar and PDF button
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
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
                          const Icon(Icons.add_circle, color: AppTheme.cream),
                          const SizedBox(width: 8),
                          Text(
                            'Añadir nueva solicitud',
                            style: TextStyle(
                              color: AppTheme.cream,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      tooltip:
                          'Añade una nueva solicitud de incapacidad a un empleado',
                      onPressed: () async {
                        final created = await showAddIncapacidadDialog(context);
                        if (created == true) {
                          setState(() {});
                        }
                      },
                    ),

                    // Open dialog to select month/year and generate PDF
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: ElevatedButton.icon(
                        style: AppTheme.lightTheme.elevatedButtonTheme.style,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Imprimir reporte de incapacidades'),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) {
                              int? dialogMonth = _selectedMonth;
                              int? dialogYear = _selectedYear;
                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return AlertDialog(
                                    title: const Text(
                                      'Seleccionar periodo del reporte',
                                    ),
                                    content: Row(
                                      children: [
                                        DropdownButton<int?>(
                                          value: dialogMonth,
                                          hint: const Text('Mes (Todos)'),
                                          items: [
                                            DropdownMenuItem<int?>(
                                              value: null,
                                              child: Text('Todos'),
                                            ),
                                            for (var m = 1; m <= 12; m++)
                                              DropdownMenuItem<int?>(
                                                value: m,
                                                child: Text(
                                                  '${m.toString().padLeft(2, '0')} - ${_monthName(m)}',
                                                ),
                                              ),
                                          ],
                                          onChanged: (val) => setDialogState(
                                            () => dialogMonth = val,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        DropdownButton<int?>(
                                          value: dialogYear,
                                          hint: const Text('Año'),
                                          items: _yearItems(),
                                          onChanged: (val) => setDialogState(
                                            () => dialogYear = val,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      // Generate button uses existing GeneratePDFButton inside the dialog so the PDF preview appears as before
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child:
                                            GeneratePDFButton<IncapacidadRow>(
                                              buttonLabel: 'Generar',
                                              reportTitle:
                                                  'Reporte de Incapacidades',
                                              fetchData: () {
                                                final year =
                                                    dialogYear ??
                                                    (dialogMonth != null
                                                        ? DateTime.now().year
                                                        : null);
                                                if (year != null &&
                                                    dialogMonth != null)
                                                  return getRegistros(
                                                    year,
                                                    dialogMonth,
                                                  );
                                                return getRegistros();
                                              },
                                              tableHeaders: [
                                                'Fecha Solicitud',
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
                                              rowMapper: (row) =>
                                                  row.toStringList(),
                                              reportMonth: dialogMonth,
                                              reportYear: dialogYear,
                                              columnFlexes: [
                                                1.0,
                                                1.15,
                                                1.15,
                                                1.15,
                                                1.3,
                                                1.15,
                                                1.3,
                                                1.5,
                                                1.3,
                                                1.4,
                                              ],
                                              bodyContent: null,
                                            ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    //Search bar
                    SearchBarWidget(
                      hintText: 'Buscar por empleado, tipo, estado o fecha',
                      initialQuery: _query,
                      onChanged: (value) => value.isNotEmpty
                          ? setState(() => _query = value.toLowerCase())
                          : null,
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
                        });
                      },
                    ),
                  ],
                ),
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
                    return const Center(
                      child: Text('No hay incapacidades registradas'),
                    );
                  }

                  final filtered = list
                      .where((inc) => _matchesQuery(inc, _query))
                      .toList();
                  final sorted = List<IncapacidadModel>.from(filtered);
                  if (_sortColumn != null) {
                    sorted.sort((a, b) => _compareByColumn(a, b));
                  }

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay resultados que coincidan con la búsqueda',
                      ),
                    );
                  }

                  const columns = [
                    DataColumn2(
                      label: Center(child: Text('Estado')),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Center(child: Text('Fecha Solicitud')),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Center(child: Text('Empleado')),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Center(child: Text('Tipo')),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Center(child: Text('Ente Emisor')),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Center(child: Text('# Certificado')),
                      size: ColumnSize.M,
                    ),
                    DataColumn2(
                      label: Center(child: Text('Inicio de \nincapacidad')),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Center(child: Text('Fin de \nincapacidad')),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Center(child: Text('Detalles')),
                      size: ColumnSize.S,
                    ),
                  ];

                  List<DataRow> dataRows = [];

                  for (var inc in sorted) {
                    dataRows.add(
                      DataRow2(
                        cells: [
                          DataCell(
                            inc.estado == "Pendiente"
                                ? Center(
                                    child: const Text(
                                      "Pendiente",
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : inc.estado == "Aprobada"
                                ? Center(
                                    child: const Text(
                                      "Aprobada",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: const Text(
                                      "Rechazada",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          DataCell(
                            Center(child: Text(formatDate(inc.fechaSolicitud))),
                          ),
                          DataCell(Text(inc.usuario)),
                          DataCell(Text(inc.tipoIncapacidad)),
                          DataCell(Text(inc.enteEmisor)),
                          DataCell(Text(inc.numCertificado)),
                          DataCell(
                            Center(
                              child: Text(
                                formatDate(inc.fechaInicioIncapacidad),
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Text(formatDate(inc.fechaFinIncapacidad)),
                            ),
                          ),

                          DataCell(
                            Center(
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Ver'),
                                  onPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (context) => buildDetallesDialog(
                                        context,
                                        inc,
                                        setState: () {
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future<List<IncapacidadRow>> getRegistros([int? year, int? month]) async {
    // If a month is provided but year is null, default to current year
    if (month != null && year == null) year = DateTime.now().year;
    List<IncapacidadModel> incapacidades;
    if (year != null && month != null) {
      incapacidades = await getIncapacidadesByMonth(year, month);
    } else {
      incapacidades = await getAllIncapacidades();
    }

    // Obtener empleados en paralelo (manteniendo el orden)
    final empleados = await Future.wait(
      incapacidades.map((inc) => getEmpleadoById(inc.userId)),
    );

    // Recolectar IDs de area únicos para pedirlos una sola vez
    final uniqueAreaIds = empleados
        .where((e) => e != null)
        .map((e) => e!.areaID)
        .toSet()
        .toList();

    // Pedir áreas en paralelo
    final areasList = await Future.wait(
      uniqueAreaIds.map((id) => getAreaById(id)),
    );

    // Map id -> AreaModel?
    final areaMap = <String?, AreaModel?>{};
    for (var i = 0; i < uniqueAreaIds.length; i++) {
      areaMap[uniqueAreaIds[i]] = areasList[i];
    }

    // Construir filas en orden
    final rows = <IncapacidadRow>[];
    for (var i = 0; i < incapacidades.length; i++) {
      final inc = incapacidades[i];
      final emp = empleados[i];
      final area = (emp != null) ? areaMap[emp.areaID] : null;
      rows.add(IncapacidadRow(incapacidad: inc, empleado: emp, area: area));
    }

    return rows;
  }

  String _monthName(int m) {
    const names = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return names[m - 1];
  }

  List<DropdownMenuItem<int?>> _yearItems() {
    final current = DateTime.now().year;
    final items = <DropdownMenuItem<int?>>[];
    for (var y = current; y >= current - 5; y--) {
      items.add(DropdownMenuItem<int?>(value: y, child: Text(y.toString())));
    }
    return items;
  }
}
