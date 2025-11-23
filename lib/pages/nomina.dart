import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanillasScreen extends StatefulWidget {
  const PlanillasScreen({super.key});

  @override
  State<PlanillasScreen> createState() => _PlanillasScreenState();
}

class _PlanillasScreenState extends State<PlanillasScreen> {
  bool _cargando = false;
  bool _mostrarFormulario = false;
  String _busqueda = "";
  String? _selectedEmpleadoId;

  final _horasExtraCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _sueldoCtrl = TextEditingController();
  String _areaId = "";

  @override
  void dispose() {
    _horasExtraCtrl.dispose();
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _sueldoCtrl.dispose();
    super.dispose();
  }

  double calcularISR(double sueldo) {
    if (sueldo <= 21457.76) return 0.0;
    else if (sueldo <= 30969.88) {
      return double.parse(((sueldo - 21457.76) * 0.15).toStringAsFixed(2));
    } else if (sueldo <= 67604.36) {
      double cuotaFija = (30969.88 - 21457.76) * 0.15;
      return double.parse((cuotaFija + (sueldo - 30969.88) * 0.20).toStringAsFixed(2));
    } else {
      double cuotaFija15 = (30969.88 - 21457.76) * 0.15;
      double cuotaFija20 = (67604.36 - 30969.88) * 0.20;
      return double.parse((cuotaFija15 + cuotaFija20 + (sueldo - 67604.36) * 0.25).toStringAsFixed(2));
    }
  }

  // === NÓMINA MASIVA PARA TODOS LOS EMPLEADOS ===
  Future<void> _generarNominaTodos() async {
    setState(() => _cargando = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection("empleados").get();
      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No hay empleados registrados")),
        );
        setState(() => _cargando = false);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      int generadas = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String empleadoId = doc.id;
        final String nombre = data['nombre'] ?? 'Sin nombre';
        final String dni = data['codigo_empleado'] ?? '000000';
        final double sueldoBase = (data['salario'] as num?)?.toDouble() ?? 0.0;
        final int horasExtra = 0;

        final double rap = double.parse((sueldoBase * 0.015).toStringAsFixed(2));
        final double ihss = double.parse((sueldoBase * 0.035).toStringAsFixed(2));
        final double isr = calcularISR(sueldoBase);
        final double pagoHorasExtra = (horasExtra * 80.0);
        final double sueldoBruto = sueldoBase + pagoHorasExtra;
        final double totalDeducciones = rap + ihss + isr;
        final double sueldoNeto = double.parse((sueldoBruto - totalDeducciones).toStringAsFixed(2));

        final nominaRef = FirebaseFirestore.instance.collection("nominas").doc();
        batch.set(nominaRef, {
          "empleado_id": empleadoId,
          "nombre": nombre,
          "dni": dni,
          "sueldo_base": sueldoBase,
          "horas_extra": horasExtra,
          "rap": rap,
          "seguro_social": ihss,
          "isr": isr,
          "pago_horas_extra": pagoHorasExtra,
          "total_deducciones": totalDeducciones,
          "sueldo_neto": sueldoNeto,
          "area_id": data['area_id'] ?? '',
          "fecha_generada": FieldValue.serverTimestamp(),
        });

        final voucherRef = FirebaseFirestore.instance.collection("vouchers").doc();
        batch.set(voucherRef, {
          "empleado_id": empleadoId,
          "nombre": nombre,
          "dni": dni,
          "sueldo_neto": sueldoNeto,
          "estado": "Generado",
          "fecha_creado": FieldValue.serverTimestamp(),
        });

        generadas++;
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Nómina generada para TODOS los empleados! ($generadas)"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  // === BORRAR TODAS LAS NÓMINAS ===
  Future<void> _borrarTodasLasNominas() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Borrar todas las nóminas?"),
        content: const Text("Esta acción NO se puede deshacer.\nSe eliminarán todas las nóminas y vouchers."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Borrar todo", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cargando = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      final nominas = await FirebaseFirestore.instance.collection("nominas").get();
      for (var doc in nominas.docs) batch.delete(doc.reference);

      final vouchers = await FirebaseFirestore.instance.collection("vouchers").get();
      for (var doc in vouchers.docs) batch.delete(doc.reference);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todas las nóminas han sido eliminadas"), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al borrar: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  // === GENERAR NÓMINA INDIVIDUAL (tu función original) ===
  Future<void> _agregarPlanilla() async {
    if (_selectedEmpleadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona un empleado")));
      return;
    }

    setState(() => _cargando = true);

    final double sueldoBase = double.tryParse(_sueldoCtrl.text) ?? 0.0;
    final int horasExtra = int.tryParse(_horasExtraCtrl.text) ?? 0;

    final double rap = double.parse((sueldoBase * 0.015).toStringAsFixed(2));
    final double ihss = double.parse((sueldoBase * 0.035).toStringAsFixed(2));
    final double isr = calcularISR(sueldoBase);
    final double pagoHorasExtra = double.parse((horasExtra * 80.0).toStringAsFixed(2));
    final double sueldoBruto = sueldoBase + pagoHorasExtra;
    final double totalDeducciones = rap + ihss + isr;
    final double sueldoNeto = sueldoBruto - totalDeducciones;

    try {
      await FirebaseFirestore.instance.collection("nominas").add({
        "empleado_id": _selectedEmpleadoId,
        "nombre": _nombreCtrl.text,
        "dni": _dniCtrl.text,
        "sueldo_base": sueldoBase,
        "horas_extra": horasExtra,
        "rap": rap,
        "seguro_social": ihss,
        "isr": isr,
        "pago_horas_extra": pagoHorasExtra,
        "total_deducciones": totalDeducciones,
        "sueldo_neto": sueldoNeto,
        "area_id": _areaId,
        "fecha_generada": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection("vouchers").add({
        "empleado_id": _selectedEmpleadoId,
        "nombre": _nombreCtrl.text,
        "dni": _dniCtrl.text,
        "sueldo_neto": sueldoNeto,
        "estado": "Generado",
        "fecha_creado": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Planilla individual generada")));
      
      setState(() {
        _selectedEmpleadoId = null;
        _nombreCtrl.clear();
        _dniCtrl.clear();
        _sueldoCtrl.clear();
        _horasExtraCtrl.clear();
        _mostrarFormulario = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _showDetallesDialog(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final fecha = (data['fecha_generada'] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Detalle - ${data['nombre']}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row("Nombre", data['nombre'] ?? ""),
              _row("DNI", data['dni'] ?? ""),
              _row("Sueldo Base", "L. ${(data['sueldo_base'] ?? 0).toStringAsFixed(2)}"),
              _row("Horas Extra", "${data['horas_extra'] ?? 0}"),
              _row("Pago Horas Extra", "L. ${(data['pago_horas_extra'] ?? 0).toStringAsFixed(2)}"),
              _row("RAP (1.5%)", "L. ${(data['rap'] ?? 0).toStringAsFixed(2)}"),
              _row("IHSS (3.5%)", "L. ${(data['seguro_social'] ?? 0).toStringAsFixed(2)}"),
              _row("ISR", "L. ${(data['isr'] ?? 0).toStringAsFixed(2)}"),
              const Divider(),
              _row("Total Deducciones", "L. ${(data['total_deducciones'] ?? 0).toStringAsFixed(2)}", bold: true),
              _row("Sueldo Neto", "L. ${(data['sueldo_neto'] ?? 0).toStringAsFixed(2)}", bold: true, color: Colors.green),
              _row("Fecha", fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : "—"),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text("$label:", style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600))),
          Expanded(flex: 5, child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : null, color: color))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          // CABECERA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Buscar nómina...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _busqueda = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(icon: const Icon(Icons.download, color: Colors.white), onPressed: () {}, tooltip: "Exportar"),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _mostrarFormulario = true),
                  icon: const Icon(Icons.person_add),
                  label: const Text("Individual"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _cargando ? null : _generarNominaTodos,
                  icon: _cargando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.people),
                  label: const Text("Todos"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _cargando ? null : _borrarTodasLasNominas,
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text("Borrar Todo"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // TABLA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("nominas").orderBy("fecha_generada", descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var docs = snapshot.data!.docs.where((d) =>
                      (d['nombre'] as String).toLowerCase().contains(_busqueda.toLowerCase())).toList();

                  return Card(
                    child: DataTable2(
                      columns: const [
                        DataColumn(label: Text("Nombre")),
                        DataColumn(label: Text("DNI")),
                        DataColumn(label: Text("Horas Extra")),
                        DataColumn(label: Text("Sueldo Base")),
                        DataColumn(label: Text("RAP")),
                        DataColumn(label: Text("IHSS")),
                        DataColumn(label: Text("ISR")),
                        DataColumn(label: Text("Neto")),
                        DataColumn(label: Text("Acción")),
                      ],
                      rows: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return DataRow(cells: [
                          DataCell(Text(data['nombre'] ?? "")),
                          DataCell(Text(data['dni'] ?? "")),
                          DataCell(Text("${data['horas_extra'] ?? 0}")),
                          DataCell(Text("L. ${(data['sueldo_base'] ?? 0).toStringAsFixed(2)}")),
                          DataCell(Text("L. ${(data['rap'] ?? 0).toStringAsFixed(2)}")),
                          DataCell(Text("L. ${(data['seguro_social'] ?? 0).toStringAsFixed(2)}")),
                          DataCell(Text("L. ${(data['isr'] ?? 0).toStringAsFixed(2)}")),
                          DataCell(Text("L. ${(data['sueldo_neto'] ?? 0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(ElevatedButton(onPressed: () => _showDetallesDialog(d), child: const Text("Ver"))),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Formulario individual (igual que antes)
          if (_mostrarFormulario)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Generar Nómina Individual", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  // ... (tu dropdown y campos, igual que antes)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("empleados").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final empleados = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: _selectedEmpleadoId,
                        decoration: const InputDecoration(labelText: "Seleccionar Empleado"),
                        isExpanded: true,
                        items: empleados.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(value: doc.id, child: Text("${data['nombre']} - ${data['codigo_empleado']}"));
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final doc = empleados.firstWhere((e) => e.id == value);
                          final data = doc.data() as Map<String, dynamic>;
                          setState(() {
                            _selectedEmpleadoId = value;
                            _nombreCtrl.text = data['nombre'] ?? '';
                            _dniCtrl.text = data['codigo_empleado'] ?? '';
                            _areaId = data['area_id'] ?? '';
                            _sueldoCtrl.text = (data['salario'] ?? 0).toStringAsFixed(2);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _nombreCtrl, enabled: false, decoration: const InputDecoration(labelText: "Nombre"))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _dniCtrl, enabled: false, decoration: const InputDecoration(labelText: "Código/DNI"))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: _sueldoCtrl, enabled: false, decoration: const InputDecoration(labelText: "Sueldo Base"))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _horasExtraCtrl, decoration: const InputDecoration(labelText: "Horas Extra"), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _agregarPlanilla,
                      icon: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                      label: const Text("Generar Individual"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  TextButton(onPressed: () => setState(() => _mostrarFormulario = false), child: const Text("Cancelar")),
                ],
              ),
            ),
        ],
      ),
    );
  }
}