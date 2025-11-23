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

  final List<Color> cardColors = [
    const Color(0xFF2E7D32),
    const Color(0xFF39B5DA),
    const Color(0xFFF57C00),
    const Color(0xFF145A32),
    const Color(0xFF1976D2),
  ];

  @override
  void dispose() {
    _horasExtraCtrl.dispose();
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _sueldoCtrl.dispose();
    super.dispose();
  }

  // ===== Formateo de moneda L 1,000.00 =====
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_US',
      symbol: 'L ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  double calcularISR(double sueldo) {
    if (sueldo <= 21457.76)
      return 0.0;
    else if (sueldo <= 30969.88) {
      return double.parse(((sueldo - 21457.76) * 0.15).toStringAsFixed(2));
    } else if (sueldo <= 67604.36) {
      double cuotaFija = (30969.88 - 21457.76) * 0.15;
      return double.parse(
        (cuotaFija + (sueldo - 30969.88) * 0.20).toStringAsFixed(2),
      );
    } else {
      double cuotaFija15 = (30969.88 - 21457.76) * 0.15;
      double cuotaFija20 = (67604.36 - 30969.88) * 0.20;
      return double.parse(
        (cuotaFija15 + cuotaFija20 + (sueldo - 67604.36) * 0.25)
            .toStringAsFixed(2),
      );
    }
  }

  // === NÓMINA MASIVA PARA TODOS LOS EMPLEADOS ===
  Future<void> _generarNominaTodos() async {
    setState(() => _cargando = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("empleados")
          .get();
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

        final double rap = double.parse(
          (sueldoBase * 0.015).toStringAsFixed(2),
        );
        final double ihss = double.parse(
          (sueldoBase * 0.035).toStringAsFixed(2),
        );
        final double isr = calcularISR(sueldoBase);
        final double pagoHorasExtra = (horasExtra * 80.0);
        final double sueldoBruto = sueldoBase + pagoHorasExtra;
        final double totalDeducciones = rap + ihss + isr;
        final double sueldoNeto = double.parse(
          (sueldoBruto - totalDeducciones).toStringAsFixed(2),
        );

        final nominaRef = FirebaseFirestore.instance
            .collection("nominas")
            .doc();
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

        final voucherRef = FirebaseFirestore.instance
            .collection("vouchers")
            .doc();
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
          content: Text(
            "¡Nómina generada para TODOS los empleados! ($generadas)",
          ),
          backgroundColor: cardColors[2],
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
        backgroundColor: const Color(0xFF145A32), // Fondo verde oscuro
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ), // Bordes redondeados
        title: const Text(
          "¿Borrar nómina de empleados?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Esta acción NO se puede deshacer.\nSe eliminarán todas las nóminas y vouchers.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  Colors.grey[300], // Fondo gris claro para cancelar
              foregroundColor: Colors.black, // Texto negro
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  Color(0xFFF57C00), // Fondo rojo para acción peligrosa
              foregroundColor: Colors.white, // Texto blanco
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Borrar todo"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cargando = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      final nominas = await FirebaseFirestore.instance
          .collection("nominas")
          .get();
      for (var doc in nominas.docs) batch.delete(doc.reference);

      final vouchers = await FirebaseFirestore.instance
          .collection("vouchers")
          .get();
      for (var doc in vouchers.docs) batch.delete(doc.reference);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Todas las nóminas han sido eliminadas correctamente"),
          backgroundColor: cardColors[2],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al borrar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  // === GENERAR NÓMINA INDIVIDUAL ===
  Future<void> _agregarPlanilla() async {
    if (_selectedEmpleadoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selecciona un empleado")));
      return;
    }

    setState(() => _cargando = true);

    final double sueldoBase = double.tryParse(_sueldoCtrl.text) ?? 0.0;
    final int horasExtra = int.tryParse(_horasExtraCtrl.text) ?? 0;

    final double rap = double.parse((sueldoBase * 0.015).toStringAsFixed(2));
    final double ihss = double.parse((sueldoBase * 0.035).toStringAsFixed(2));
    final double isr = calcularISR(sueldoBase);
    final double pagoHorasExtra = double.parse(
      (horasExtra * 80.0).toStringAsFixed(2),
    );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Planilla individual generada"),
          backgroundColor: cardColors[0],
        ),
      );

      setState(() {
        _selectedEmpleadoId = null;
        _nombreCtrl.clear();
        _dniCtrl.clear();
        _sueldoCtrl.clear();
        _horasExtraCtrl.clear();
        _mostrarFormulario = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
        backgroundColor: Color(0xFF2E7D32).withOpacity(0.98),
        title: Text(
          "Detalles del empleado",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        content: SizedBox(
          width: 350, // ancho más grande
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row("Nombre", data['nombre'] ?? "", color: Colors.white),
                _row("DNI", data['dni'] ?? "", color: Colors.white),
                _row(
                  "Sueldo Base",
                  _formatCurrency(data['sueldo_base'] ?? 0),
                  color: Colors.white,
                ),
                _row(
                  "Horas Extra",
                  "${data['horas_extra'] ?? 0}",
                  color: Colors.white,
                ),
                _row(
                  "Pago Horas Extra",
                  _formatCurrency(data['pago_horas_extra'] ?? 0),
                  color: Colors.white,
                ),
                _row(
                  "RAP (1.5%)",
                  _formatCurrency(data['rap'] ?? 0),
                  color: Colors.white,
                ),
                _row(
                  "IHSS (3.5%)",
                  _formatCurrency(data['seguro_social'] ?? 0),
                  color: Colors.white,
                ),
                _row(
                  "ISR",
                  _formatCurrency(data['isr'] ?? 0),
                  color: Colors.white,
                ),
                const Divider(color: Colors.grey),
                _row(
                  "Total Deducciones",
                  _formatCurrency(data['total_deducciones'] ?? 0),
                  bold: true,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
                _row(
                  "Sueldo Neto",
                  _formatCurrency(data['sueldo_neto'] ?? 0),
                  bold: true,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                _row(
                  "Fecha",
                  fecha != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
                      : "—",
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),

        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF145A32), // fondo verde oscuro
              foregroundColor: Colors.white, // color del texto
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: color ?? Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: color ?? Colors.white,
              ),
            ),
          ),
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
              color: cardColors[4],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Buscar empleado...",
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        prefixIcon: Icon(Icons.search, color: cardColors[4]),
                      ),
                      onChanged: (v) => setState(() => _busqueda = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const SizedBox(width: 8),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _cargando ? null : _generarNominaTodos,
                  icon: _cargando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Icon(
                          Icons.people,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                  label: const Text("Todos"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _cargando ? null : _borrarTodasLasNominas,
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  label: const Text("Borrar Todo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // TABLA
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("nominas")
                      .orderBy("fecha_generada", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    var docs = snapshot.data!.docs
                        .where(
                          (d) => (d['nombre'] as String).toLowerCase().contains(
                            _busqueda.toLowerCase(),
                          ),
                        )
                        .toList();

                    return DataTable2(
                      headingRowColor: WidgetStateProperty.all(
                        cardColors[4].withOpacity(0.9),
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columns: const [
                        DataColumn(label: Text("Nombre")),
                        DataColumn(label: Text("Sueldo Base")),
                        DataColumn(label: Text("RAP")),
                        DataColumn(label: Text("IHSS")),
                        DataColumn(label: Text("ISR")),
                        DataColumn(label: Text("Neto")),
                        DataColumn(label: Text("Detalles")),
                      ],
                      rows: docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                data['nombre'] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(_formatCurrency(data['sueldo_base'] ?? 0)),
                            ),
                            DataCell(Text(_formatCurrency(data['rap'] ?? 0))),
                            DataCell(
                              Text(_formatCurrency(data['seguro_social'] ?? 0)),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(data['isr'] ?? 0),
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(data['sueldo_neto'] ?? 0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton(
                                onPressed: () => _showDetallesDialog(d),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cardColors[4],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(" Ver detalles"),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
}
