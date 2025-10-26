import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/logic/utilities/format_date.dart';
import 'package:rrhfit_sys32/logic/incapacidad_function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:rrhfit_sys32/pages/generate_pdf_screen.dart';
import 'package:rrhfit_sys32/pages/rrhh/incapacidades_details_page.dart';
import 'package:rrhfit_sys32/widgets/alert_message.dart';
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
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            Row(
              children: [
                GeneratePDFScreen(title: "Reporte de Incapacidades"),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SearchBarWidget(
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
                        });
                      },
                    ),
                  ),
                ),
              ],
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
                        headingTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                        dataTextStyle: TextStyle(fontSize: 18, color: Colors.black87),
                        columns: const [
                          DataColumn(label: Text('Empleado')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Fecha Solicitud')),
                          DataColumn(label: Text('Inicio de incapacidad')),
                          DataColumn(label: Text('Fin de incapacidad')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: sorted.map((inc) {
                          return DataRow(cells: [
                            DataCell(Text(inc.usuario)),
                            DataCell(Text(inc.tipoSolicitud)),
                            DataCell(Text(formatDate(inc.fechaSolicitud))),
                            DataCell(Text(formatDate(inc.fechaInicioIncapacidad))),
                            DataCell(Text(formatDate(inc.fechaFinIncapacidad))),
                            DataCell(inc.estado == "Pendiente" ? const Text("Pendiente", style: TextStyle(color: Colors.orange),)
                            : inc.estado == "Aprobada" ? const Text("Aprobada", style: TextStyle(color: Colors.green),)
                            : const Text("Rechazada", style: TextStyle(color: Colors.red),)),

                            DataCell(ElevatedButton(
                              child: const Text('Detalles'),
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Detalles de Incapacidad'),
                                    content: SingleChildScrollView(
                                      child: ListBody(
                                        children: [
                                          Text('ID: ${inc.id}'),
                                          const SizedBox(height: 6),
                                          Text('Empleado: ${inc.usuario}'),
                                          Text('Tipo: ${inc.tipoSolicitud}'),
                                          const SizedBox(height: 6),
                                          Text('Fecha Solicitud: ${formatDate(inc.fechaSolicitud)}'),
                                          Text('Fecha Expediente: ${formatDate(inc.fechaExpediente)}'),
                                          Text('Inicio incapacidad: ${formatDate(inc.fechaInicioIncapacidad)}'),
                                          Text('Fin incapacidad: ${formatDate(inc.fechaFinIncapacidad)}'),
                                          const SizedBox(height: 6),
                                          Text('Estado: ${inc.estado}'),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      if (inc.estado == 'Pendiente') ...[
                                        TextButton(
                                          onPressed: () async {
                                            // Approve
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('solicitudes')
                                                  .doc(inc.id)
                                                  .update({'estado': 'Aprobada'});
                                              Navigator.of(ctx).pop();
                                              setState(() {});
                                              successScaffoldMsg(context, 'Solicitud aprobada');
                                            } catch (e) {
                                              Navigator.of(ctx).pop();
                                              successScaffoldMsg(context, 'Error al aprobar: $e');
                                            }
                                          },
                                          child: const Text('Aprobar'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Reject
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('solicitudes')
                                                  .doc(inc.id)
                                                  .update({'estado': 'Rechazada'});
                                              Navigator.of(ctx).pop();
                                              setState(() {});
                                              successScaffoldMsg(context, 'Solicitud rechazada');
                                            } catch (e) {
                                              Navigator.of(ctx).pop();
                                              successScaffoldMsg(context, 'Error al rechazar: $e');
                                            }
                                          },
                                          child: const Text('Rechazar'),
                                        ),
                                      ],
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  ),
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