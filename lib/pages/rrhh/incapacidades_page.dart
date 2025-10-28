import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/globals.dart';
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/incapacidad_functions.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/pages/generate_pdf_screen.dart';
import 'package:rrhfit_sys32/pages/rrhh/incapacidades_details_page.dart';
import 'package:rrhfit_sys32/widgets/search_bar.dart';
import 'package:rrhfit_sys32/widgets/summary_box.dart';

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

    return empleado.contains(qlc) ||
        tipo.contains(qlc) ||
        estado.contains(qlc) ||
        fechaSolicitud.contains(qlc) ||
        inicio.contains(qlc) ||
        fin.contains(qlc);
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
        res = a.tipoSolicitud.toLowerCase().compareTo(b.tipoSolicitud.toLowerCase());
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
      default:
        res = 0;
    }
    return _sortAsc ? res : -res;
  }

  @override
  Widget build(BuildContext context) {
    print(Global().currentUser?.email ?? 'No user email');
    print(Global().currentUser?.uid ?? 'No user UID');
    print(Global().currentUser?.displayName ?? 'No user display name');


    return Scaffold(
      appBar: AppBar(
            title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Incapacidades - Gestión de incapacidades de empleados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color.fromRGBO(0, 150, 32, 1),
        foregroundColor: const Color.fromARGB(255, 251, 255, 250),
        elevation: 0,
        centerTitle: true,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(0, 150, 32, 1), 
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
                    //get current month
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

            // Search bar
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GeneratePDFScreen(title: "Reporte de Incapacidades"),
                  ),
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
                  // apply sorting if selected
                  final sorted = List<IncapacidadModel>.from(filtered);
                  if (_sortColumn != null) {
                    sorted.sort((a, b) => _compareByColumn(a, b));
                  }

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No hay resultados que coincidan con la búsqueda'));
                  }

                  // Horizontal + vertical scrollable table
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        border: TableBorder.all(color: Colors.black54, width: 2),
                        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                        dataTextStyle: TextStyle(fontSize: 13, color: Colors.black87),
                        columns: const [
                          DataColumn(label: Text('Empleado')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Ente Emisor')),
                          DataColumn(label: Text('# Certificado')),
                          DataColumn(label: Text('Fecha Solicitud')),
                          DataColumn(label: Text('Inicio de incapacidad')),
                          DataColumn(label: Text('Fin de incapacidad')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Detalles')),
                        ],
                        rows: sorted.map((inc) {
                          return DataRow(cells: [
                            DataCell(Text(inc.usuario)),
                            DataCell(Text(inc.tipoSolicitud)),
                            DataCell(Text(inc.enteEmisor)),
                            DataCell(Text(inc.numCertificado)),
                            DataCell(Text(formatDate(inc.fechaSolicitud))),
                            DataCell(Text(formatDate(inc.fechaInicioIncapacidad))),
                            DataCell(Text(formatDate(inc.fechaFinIncapacidad))),
                            DataCell(inc.estado == "Pendiente" ? const Text("Pendiente", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),)
                            : inc.estado == "Aprobada" ? const Text("Aprobada", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),)
                            : const Text("Rechazada", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),)),

                            DataCell(ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
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
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}