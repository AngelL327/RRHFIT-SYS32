import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class PlanillasScreen extends StatefulWidget {
  const PlanillasScreen({super.key});

  @override
  State<PlanillasScreen> createState() => _PlanillasScreenState();
}

class _PlanillasScreenState extends State<PlanillasScreen> {
  // Controladores del formulario
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _sueldoCtrl = TextEditingController();
  final _horasExtraCtrl = TextEditingController();
  final _areaIdCtrl = TextEditingController();

  bool _cargando = false;
  bool _mostrarFormulario = false;
  String _busqueda = "";

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

    double rap = sueldoBase * 0.015;
    double ihss = sueldoBase * 0.035;
    double pagoExtra = horasExtra * 80;
    double sueldoBruto = sueldoBase + pagoExtra;
    double totalDeducciones = rap + ihss;
    double sueldoNeto = sueldoBruto - totalDeducciones;

    final data = {
      "nombre": _nombreCtrl.text,
      "dni": _dniCtrl.text,
      "sueldo_base": sueldoBase,
      "horas_extra": horasExtra,
      "rap": rap,
      "seguro_social": ihss,
      "total_deducciones": totalDeducciones,
      "sueldo_neto": sueldoNeto,
      "area_id": _areaIdCtrl.text.isEmpty ? null : _areaIdCtrl.text,
      "fecha_generada": FieldValue.serverTimestamp(),
    };
     
    await FirebaseFirestore.instance.collection("nominas").add(data);
    await FirebaseFirestore.instance.collection("vouchers").add({
    "nombre": _nombreCtrl.text,
    "dni": _dniCtrl.text,
    "sueldo_neto": sueldoNeto,
    "estado": "Generado",
    "fecha_creado": FieldValue.serverTimestamp(),
  });

    _nombreCtrl.clear();
    _dniCtrl.clear();
    _sueldoCtrl.clear();
    _horasExtraCtrl.clear();
    _areaIdCtrl.clear();

    setState(() {
      _cargando = false;
      _mostrarFormulario = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ======= BARRA SUPERIOR =======
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Buscar",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _busqueda = v.trim()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print),
                  label: const Text("Imprimir"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _mostrarFormulario = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Nuevo"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  icon: const Icon(Icons.edit),
                  label: const Text("Editar"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.delete),
                  label: const Text("Eliminar"),
                ),
              ],
            ),
          ),

          // ====== TABLA ======
          Expanded(
            child: StreamBuilder(
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

                return DataTable2(
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(label: Text("Nombre")),
                    DataColumn(label: Text("DNI")),
                    DataColumn(label: Text("Horas trabajadas")),
                    DataColumn(label: Text("Horas extra")),
                    DataColumn(label: Text("Sueldo base")),
                    DataColumn(label: Text("Deducciones y totales")),
                  ],
                  rows: docs.map((d) {
                    return DataRow(
                      cells: [
                        DataCell(Text(d["nombre"])),
                        DataCell(Text(d["dni"])),
                        DataCell(
                          Text("0"),
                        ), // si luego quieres calcularlo, se agrega
                        DataCell(Text("${d["horas_extra"]}")),
                        DataCell(Text("L. ${d["sueldo_base"]}")),
                        DataCell(
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                            ),
                            onPressed: () {},
                            child: const Text("Ver detalles"),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // ====== FORMULARIO (oculto) ======
          if (_mostrarFormulario)
            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Agregar Planilla",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                    controller: _areaIdCtrl,
                    decoration: const InputDecoration(
                      labelText: "Área ID (Opcional)",
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _cargando ? null : _agregarPlanilla,
                    icon: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.save),
                    label: const Text("Guardar Planilla"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
