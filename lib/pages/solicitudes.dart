import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rrhfit_sys32/widgets/type.dart';
import 'package:rrhfit_sys32/widgets/reporte_solicitudes_widget.dart';
import 'package:rrhfit_sys32/pages/empleados/solicitar_incapacidad_page.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String?
  _departamentoIdSeleccionado; // aquí guardaremos el ID real del departamento

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _currentIndex = 0;

  final TextEditingController _empleadoCtrl = TextEditingController();
  final TextEditingController _departamentoCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  final TextEditingController _puestoCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();

  String? _empleadoId;
  String _tipoSolicitud = "Vacaciones";
  DateTime? _fechaSeleccionada;
  String _busqueda = "";
  String _fechaFiltro = "Más recientes";
  String _tipoFiltro = "Todos";

  Future<void> _guardarSolicitud() async {
    try {
      // Lista de departamentos válidos (IDs)
      final List<String> departamentosValidos = [
        "Pq9yWMvEpFCNCSP0BPvh",
        "cSp2PYb3nOT9hV49qF4D",
        "sGZFP2jHDK2v6gjyWd3r",
        "uh8jHSxUmUXufhbmGjTQ",
        "wir7mpTi0bbZExvjVr1T",
      ];

      // Validar departamento seleccionado
      if (_departamentoIdSeleccionado == null ||
          !departamentosValidos.contains(_departamentoIdSeleccionado)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("El departamento seleccionado no es válido"),
          ),
        );
        return;
      }

      // 1. Validar empleado seleccionado
      if (_empleadoId == null || _empleadoCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selecciona un empleado válido de la lista"),
          ),
        );
        return;
      }

      // 2. Cargar empleado desde BD
      final empSnap = await _db.collection("empleados").doc(_empleadoId).get();
      if (!empSnap.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Empleado no encontrado en la base de datos"),
          ),
        );
        return;
      }
      final data = empSnap.data() as Map<String, dynamic>;

      // 3. Validar código (opcional, si quieres forzar que coincida con la BD)
      final codigoReal = (data['codigo_empleado'] ?? '').toString();
      if (_codigoCtrl.text.trim().toLowerCase() !=
          codigoReal.trim().toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("El código no coincide con el empleado seleccionado"),
          ),
        );
        return;
      }

      // 4. Validar puesto
      if (_puestoCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("El puesto no puede ir vacío")),
        );
        return;
      }

      // 5. Validar fecha
      if (_fechaSeleccionada == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Selecciona una fecha")));
        return;
      }

      // 6. Guardar en solicitudes
      await _db.collection("solicitudes").add({
        "empleado": _empleadoCtrl.text.trim(),
        "empleadoId": _empleadoId,
        "codigo": codigoReal.trim(), // siempre usamos el código de la BD
        "departamento": _departamentoCtrl.text.trim(),
        "puesto": _puestoCtrl.text.trim(),
        "descripcion": _descripcionCtrl.text.trim(),
        "tipo": _tipoSolicitud,
        "fecha": _fechaSeleccionada,
        "estado": "Pendiente",
        "creadoEn": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud creada correctamente")),
      );

      // 7. Limpiar formulario
      _empleadoCtrl.clear();
      _departamentoCtrl.clear();
      _puestoCtrl.clear();
      _codigoCtrl.clear();
      _descripcionCtrl.clear();
      _fechaSeleccionada = null;
      _empleadoId = null;

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al crear solicitud: $e")));
    }
  }

  Future<void> _actualizarEstado(String docId, String nuevoEstado) async {
    await _db.collection("solicitudes").doc(docId).update({
      "estado": nuevoEstado,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Solicitudes - Gestión de solicitudes de empleados',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    "Acerca de Solicitudes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  content: const Text(
                    "En esta sección puedes gestionar todas las solicitudes enviadas por "
                    "los empleados, como vacaciones, permisos médicos y cambios de turno.\n\n"
                    "Puedes:\n"
                    "• Crear nuevas solicitudes\n"
                    "• Revisar solicitudes pendientes\n"
                    "• Aprobar o rechazar solicitudes\n"
                    "• Ver reportes y estadísticas completas\n\n"
                    "Todo se actualiza automáticamente en tiempo real.",
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

      body: _currentIndex == 0 ? _buildListScreen() : _buildCreateScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCreateScreenDialog(),
                ),
              ),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListScreen() {
    String _estadoFiltro = "Pendiente";

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection("solicitudes").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data!.docs;
              final total = docs.length;
              final pendientes = docs
                  .where((d) => (d["estado"] ?? "") == "Pendiente")
                  .length;
              final aprobadas = docs
                  .where((d) => (d["estado"] ?? "") == "Aprobada")
                  .length;
              final rechazadas = docs
                  .where((d) => (d["estado"] ?? "") == "Rechazada")
                  .length;

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    _buildCounterCard(
                      "Pendientes",
                      pendientes,
                      Colors.orange,
                      Icons.hourglass_empty,
                    ),
                    _buildCounterCard(
                      "Aprobadas",
                      aprobadas,
                      Colors.green,
                      Icons.check_circle,
                    ),
                    _buildCounterCard(
                      "Rechazadas",
                      rechazadas,
                      Colors.red,
                      Icons.cancel,
                    ),
                    _buildCounterCard(
                      "Total",
                      total,
                      Colors.blue,
                      Icons.list_alt,
                    ),
                  ],
                ),
              );
            },
          ),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      //Campo de búsqueda
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Buscar por nombre de empleado...",
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF9E9E9E),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFFE0E0E0),
                              ), // borde gris claro
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF90CAF9),
                              ), // azul al enfocar
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _busqueda = val.toLowerCase();
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonFormField<String>(
                            initialValue: _tipoFiltro,
                            items:
                                [
                                      {
                                        "label": "Todos",
                                        "icon": Icons.list_alt,
                                      },
                                      {
                                        "label": "Vacaciones",
                                        "icon": Icons.beach_access,
                                      },
                                      {
                                        "label": "Permiso médico",
                                        "icon": Icons.local_hospital,
                                      },
                                      {
                                        "label": "Cambio de turno",
                                        "icon": Icons.access_time,
                                      },
                                    ]
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item["label"] as String,
                                        child: Row(
                                          children: [
                                            Icon(
                                              item["icon"] as IconData,
                                              size: 18,
                                              color: Color(0xFF616161),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(item["label"] as String),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) =>
                                setState(() => _tipoFiltro = val!),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            icon: const Icon(
                              Icons.filter_list,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: DropdownButtonFormField<String>(
                    initialValue: _fechaFiltro,
                    items: ["Más recientes", "Más antiguas"]
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _fechaFiltro = val!),
                    decoration: const InputDecoration(
                      labelText: "Ordenar",
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: const TabBar(
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "Pendientes"),
                Tab(text: "Aprobadas"),
                Tab(text: "Rechazadas"),
                Tab(text: "Reportes"),
              ],
            ),
          ),

          // Contenido de cada Tab
          Expanded(
            child: TabBarView(
              children: [
                _buildSolicitudList("", "Pendiente"),
                _buildSolicitudList("", "Aprobada"),
                _buildSolicitudList("", "Rechazada"),
                ReporteSolicitudesWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudList(String uid, String estado) {
    final stream = _db
        .collection("solicitudes")
        .where("estado", isEqualTo: estado)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nombre = (data["empleado"] ?? "").toString().toLowerCase();
          final tipo = data["tipo"] ?? "";

          final matchBusqueda = _busqueda.isEmpty || nombre.contains(_busqueda);
          final matchTipo = _tipoFiltro == "Todos" || tipo == _tipoFiltro;

          return matchBusqueda && matchTipo;
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            Color estadoColor = estado == "Aprobada"
                ? Colors.green
                : estado == "Rechazada"
                ? Colors.red
                : Colors.orange;

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color.fromARGB(255, 175, 180, 173),
                  width: 0.4,
                ),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data["empleado"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Tipo de solicitud
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Tipo: ${data["tipo"] ?? ""}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Departamento
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Depto: ${data["departamento"] ?? ""}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Fecha: ${(data["fecha"] as Timestamp?)?.toDate().toString().split(" ")[0] ?? ""}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.description,
                          size: 20,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              // Mostrar diálogo con el texto completo
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        data["descripcion"] ?? "",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              data["descripcion"] ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    if (estado == "Pendiente")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _actualizarEstado(doc.id, "Aprobada"),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text("Aprobar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _actualizarEstado(doc.id, "Rechazada"),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text("Rechazar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCounterCard(
    String titulo,
    int cantidad,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              cantidad.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateScreenDialog() {
    return Container(
      padding: const EdgeInsets.all(16), // Espaciado interno
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255), // Color de fondo
        borderRadius: BorderRadius.circular(12), // Opcional: bordes redondeados
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Crear Solicitud",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _tipoSolicitud,
            items: ["Vacaciones", "Permiso médico", "Cambio de turno"]
                .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                .toList(),
            onChanged: (val) => setState(() => _tipoSolicitud = val!),
            decoration: InputDecoration(
              labelText: "Tipo de Solicitud",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          EmpleadoAutocomplete(
            empleadoCtrl: _empleadoCtrl,
            codigoCtrl: _codigoCtrl,
            departamentoCtrl: _departamentoCtrl,
            onDepartamentoSeleccionado: (departamentoId) {
              _departamentoIdSeleccionado = departamentoId;
            },
            onEmpleadoSeleccionado: (empleadoId) {
              _empleadoId = empleadoId;
            },
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _puestoCtrl,
            decoration: const InputDecoration(
              labelText: "Puesto",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _descripcionCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Descripción",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    DateTime? fecha = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha != null)
                      setState(() => _fechaSeleccionada = fecha);
                  },
                  child: Text(
                    _fechaSeleccionada == null
                        ? "Seleccionar Fecha"
                        : "Fecha: ${_fechaSeleccionada!.toString().split(" ")[0]}",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await _guardarSolicitud();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Crear Solicitud",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Crear Solicitud",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _tipoSolicitud,
            items: ["Vacaciones", "Permiso médico", "Cambio de turno"]
                .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                .toList(),
            onChanged: (val) => setState(() => _tipoSolicitud = val!),
            decoration: InputDecoration(
              labelText: "Tipo de Solicitud",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _empleadoCtrl,
            decoration: InputDecoration(
              labelText: "Empleado",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _departamentoCtrl,
            decoration: InputDecoration(
              labelText: "Departamento",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descripcionCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Descripción",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    DateTime? fecha = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha != null) {
                      setState(() => _fechaSeleccionada = fecha);
                    }
                  },
                  child: Text(
                    _fechaSeleccionada == null
                        ? "Seleccionar Fecha"
                        : "Fecha: ${_fechaSeleccionada!.toString().split(" ")[0]}",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _guardarSolicitud,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Crear Solicitud",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
