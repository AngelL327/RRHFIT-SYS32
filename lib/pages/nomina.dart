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
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _sueldoCtrl = TextEditingController();
  final _horasExtraCtrl = TextEditingController();
  final _diasIncapacidadCtrl = TextEditingController();
  final _areaIdCtrl = TextEditingController();

  bool _cargando = false;
  bool _mostrarFormulario = false;
  String _busqueda = "";

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _sueldoCtrl.dispose();
    _horasExtraCtrl.dispose();
    _diasIncapacidadCtrl.dispose();
    _areaIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _agregarPlanilla() async {
    if (_nombreCtrl.text.isEmpty ||
        _dniCtrl.text.isEmpty ||
        _sueldoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa los campos obligatorios")),
      );
      return;
    }

    setState(() => _cargando = true);

    double sueldoBase = double.tryParse(_sueldoCtrl.text) ?? 0;
    int horasExtra = int.tryParse(_horasExtraCtrl.text) ?? 0;
    int diasIncapacidad = int.tryParse(_diasIncapacidadCtrl.text) ?? 0;

    double rap = double.parse((sueldoBase * 0.015).toStringAsFixed(2));
    double ihss = double.parse((sueldoBase * 0.035).toStringAsFixed(2));
    double pagoExtra = double.parse((horasExtra * 80).toStringAsFixed(2));
    double descuentoIncapacidad = double.parse(
      ((sueldoBase / 30) * diasIncapacidad).toStringAsFixed(2),
    );

    double sueldoBruto = double.parse(
      (sueldoBase + pagoExtra).toStringAsFixed(2),
    );
    double totalDeducciones = double.parse(
      (rap + ihss + descuentoIncapacidad).toStringAsFixed(2),
    );
    double sueldoNeto = double.parse(
      (sueldoBruto - totalDeducciones).toStringAsFixed(2),
    );

    final data = {
      "nombre": _nombreCtrl.text,
      "dni": _dniCtrl.text,
      "sueldo_base": sueldoBase,
      "horas_extra": horasExtra,
      "dias_incapacidad": diasIncapacidad,
      "rap": rap,
      "seguro_social": ihss,
      "descuento_incapacidad": descuentoIncapacidad,
      "total_deducciones": totalDeducciones,
      "sueldo_neto": sueldoNeto,
      "area_id": _areaIdCtrl.text.isEmpty ? null : _areaIdCtrl.text,
      "fecha_generada": FieldValue.serverTimestamp(),
    };

    try {
      // Guardar nómina
      await FirebaseFirestore.instance.collection("nominas").add(data);

      // Guardar voucher (incluye dias de incapacidad)
      await FirebaseFirestore.instance.collection("vouchers").add({
        "nombre": _nombreCtrl.text,
        "dni": _dniCtrl.text,
        "sueldo_neto": sueldoNeto,
        "dias_incapacidad": diasIncapacidad,
        "estado": "Generado",
        "fecha_creado": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Planilla guardada correctamente")),
      );

      _nombreCtrl.clear();
      _dniCtrl.clear();
      _sueldoCtrl.clear();
      _horasExtraCtrl.clear();
      _diasIncapacidadCtrl.clear();
      _areaIdCtrl.clear();

      setState(() {
        _cargando = false;
        _mostrarFormulario = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
    }
  }

  void _showDetallesDialog(QueryDocumentSnapshot d) {
    final nombre = d["nombre"] ?? '';
    final dni = d["dni"] ?? '';
    final sueldoBase = (d["sueldo_base"] ?? 0).toDouble();
    final horasExtra = (d["horas_extra"] ?? 0).toInt();
    final diasIncapacidad = (d["dias_incapacidad"] ?? 0).toInt();
    final rap = (d["rap"] ?? 0).toDouble();
    final ihss = (d["seguro_social"] ?? 0).toDouble();
    final descuentoIncapacidad = (d["descuento_incapacidad"] ?? 0).toDouble();
    final totalDeducciones = (d["total_deducciones"] ?? 0).toDouble();
    final sueldoNeto = (d["sueldo_neto"] ?? 0).toDouble();
    final fecha = (d["fecha_generada"] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detalle - $nombre"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detalleRow("Nombre", nombre),
              _detalleRow("DNI", dni),
              _detalleRow("Sueldo base", "L. ${sueldoBase.toStringAsFixed(2)}"),
              _detalleRow("Horas extra", horasExtra.toString()),
              _detalleRow("Días incapacidad", diasIncapacidad.toString()),
              _detalleRow(
                "Pago por horas extra",
                "L. ${(horasExtra * 80).toStringAsFixed(2)}",
              ),
              _detalleRow("RAP (1.5%)", "L. ${rap.toStringAsFixed(2)}"),
              _detalleRow("IHSS (3.5%)", "L. ${ihss.toStringAsFixed(2)}"),
              _detalleRow(
                "Descuento incapacidad",
                "L. ${descuentoIncapacidad.toStringAsFixed(2)}",
              ),
              const Divider(),
              _detalleRow(
                "Total deducciones",
                "L. ${totalDeducciones.toStringAsFixed(2)}",
              ),
              _detalleRow("Sueldo neto", "L. ${sueldoNeto.toStringAsFixed(2)}"),
              const SizedBox(height: 8),
              _detalleRow(
                "Fecha",
                fecha != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
                    : "Sin fecha",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _detalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 5, child: Text(value)),
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
          // ===== CABECERA MEJORADA =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                // Buscar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Buscar empleado...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _busqueda = v.trim()),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.download, color: Colors.white),
                  tooltip: "Exportar PDF",
                ),

                const SizedBox(width: 4),

                ElevatedButton(
                  onPressed: () => setState(() => _mostrarFormulario = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("+ Nuevo"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ===== TABLA =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("nominas")
                    .orderBy("fecha_generada", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((d) {
                    return d["nombre"].toString().toLowerCase().contains(
                      _busqueda.toLowerCase(),
                    );
                  }).toList();

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DataTable2(
                      border: TableBorder.all(color: Colors.black12),
                      columnSpacing: 12,
                      columns: const [
                        DataColumn(label: Text("Nombre")),
                        DataColumn(label: Text("DNI")),
                        DataColumn(label: Text("Horas extra")),
                        DataColumn(label: Text("Incapacidad")),
                        DataColumn(label: Text("Sueldo base")),
                        DataColumn(label: Text("Detalles")),
                      ],

                      rows: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>? ?? {};

                        return DataRow(
                          cells: [
                            DataCell(Text(data["nombre"] ?? "")),
                            DataCell(Text(data["dni"] ?? "")),
                            DataCell(
                              Text(
                                "${data.containsKey("horas_extra") ? data["horas_extra"] : 0}",
                              ),
                            ),
                            DataCell(
                              Text(
                                "${data.containsKey("dias_incapacidad") ? data["dias_incapacidad"] : 0} días",
                              ),
                            ),
                            DataCell(
                              Text(
                                "L. ${data.containsKey("sueldo_base") ? data["sueldo_base"] : 0}",
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                ),
                                onPressed: () {},
                                child: const Text("Ver detalles"),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),

          // ===== FORMULARIO =====
          if (_mostrarFormulario)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Agregar Planilla",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: "Nombre",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dniCtrl,
                          decoration: const InputDecoration(labelText: "DNI"),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sueldoCtrl,
                          decoration: const InputDecoration(
                            labelText: "Sueldo Base (L.)",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _horasExtraCtrl,
                          decoration: const InputDecoration(
                            labelText: "Horas extra",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  TextField(
                    controller: _diasIncapacidadCtrl,
                    decoration: const InputDecoration(
                      labelText: "Días de incapacidad",
                    ),
                    keyboardType: TextInputType.number,
                  ),

                  TextField(
                    controller: _areaIdCtrl,
                    decoration: const InputDecoration(
                      labelText: "Área ID (Opcional)",
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _agregarPlanilla,
                      icon: _cargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text("Guardar Planilla"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
