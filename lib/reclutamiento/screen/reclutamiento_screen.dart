import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:features_tour/features_tour.dart';
import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'dart:math';

import 'package:rrhfit_sys32/reclutamiento/screen/vacante_detail_screen.dart';
import 'package:rrhfit_sys32/reclutamiento/widgets/vacante_card.dart';

class ReclutamientoScreen extends StatefulWidget {
  const ReclutamientoScreen({super.key});

  @override
  State<ReclutamientoScreen> createState() => _ReclutamientoScreenState();
}

class _ReclutamientoScreenState extends State<ReclutamientoScreen> {
  final tourController = FeaturesTourController('ReclutamientoScreen');

  List<Map<String, String>> departamentos = [];
  List<Map<String, String>> areas = [];
  List<Map<String, String>> puestos = [];

  String? selectedDepartamentoId;
  String? selectedAreaId;
  String? selectedPuestoId;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    tourController.start(context);
  }

  Future<void> _loadDropdowns() async {
    try {
      final depSnap = await FirebaseFirestore.instance
          .collection('departamento')
          .get();
      final areaSnap = await FirebaseFirestore.instance
          .collection('area')
          .get();
      final puestoSnap = await FirebaseFirestore.instance
          .collection('puesto')
          .get();

      setState(() {
        departamentos = depSnap.docs
            .map(
              (d) => {
                'id': d.id,
                'nombre': (d.data()['nombre'] ?? '').toString(),
              },
            )
            .toList();
        areas = areaSnap.docs
            .map(
              (d) => {
                'id': d.id,
                'nombre': (d.data()['nombre'] ?? '').toString(),
              },
            )
            .toList();
        puestos = puestoSnap.docs
            .map(
              (d) => {
                'id': d.id,
                'nombre': (d.data()['nombre'] ?? '').toString(),
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error cargando dropdowns: $e');
    }
  }

  String _generateVacanteId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _showCrearVacanteDialog() async {
    DateTime? fechaFinal;
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: FeaturesTour(
            controller: tourController,
            index: 0,
            introduce: Text("Aquí puedes crear una nueva vacante"),
            child: Text('Crear vacante'),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 500,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedDepartamentoId,
                          decoration: const InputDecoration(
                            labelText: 'Departamento',
                          ),
                          items: departamentos
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d['id'],
                                  child: Text(d['nombre'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedDepartamentoId = val;
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Seleccione un departamento' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedAreaId,
                          decoration: const InputDecoration(labelText: 'Área'),
                          items: areas
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d['id'],
                                  child: Text(d['nombre'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedAreaId = val;
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Seleccione un área' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedPuestoId,
                          decoration: const InputDecoration(
                            labelText: 'Puesto',
                          ),
                          items: puestos
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d['id'],
                                  child: Text(d['nombre'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedPuestoId = val;
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Seleccione un puesto' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fechaFinal == null
                                    ? 'Fecha final: no seleccionada'
                                    : 'Fecha final: ${fechaFinal?.toLocal().toString().split(' ')[0]}',
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: now,
                                  lastDate: DateTime(now.year + 5),
                                );
                                if (picked != null) {
                                  setState(() {
                                    fechaFinal = picked;
                                  });
                                }
                              },
                              child: const Text('Seleccionar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Crear'),
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                if (fechaFinal == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seleccione la fecha de finalización'),
                    ),
                  );
                  return;
                }

                final depNombre =
                    departamentos.firstWhere(
                      (d) => d['id'] == selectedDepartamentoId,
                    )['nombre'] ??
                    '';
                final areaNombre =
                    areas.firstWhere(
                      (a) => a['id'] == selectedAreaId,
                    )['nombre'] ??
                    '';
                final puestoNombre =
                    puestos.firstWhere(
                      (p) => p['id'] == selectedPuestoId,
                    )['nombre'] ??
                    '';

                final vacanteId = _generateVacanteId();

                await FirebaseFirestore.instance
                    .collection('vacantes')
                    .doc(vacanteId)
                    .set({
                      'vacante_id': vacanteId,
                      'departamentoId': selectedDepartamentoId,
                      'departamentoNombre': depNombre,
                      'areaId': selectedAreaId,
                      'areaNombre': areaNombre,
                      'puestoId': selectedPuestoId,
                      'puestoNombre': puestoNombre,
                      'createdAt': FieldValue.serverTimestamp(),
                      'endDate': Timestamp.fromDate(fechaFinal!),
                      'estado': 'activa',
                    });

                setState(() {});
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vacante creada',
                      style: TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToVacanteDetail(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VacanteDetailScreen(
          vacante: doc,
          departamentos: departamentos,
          areas: areas,
          puestos: puestos,
        ),
      ),
    );
  }

  Widget _buildVacanteCard(DocumentSnapshot doc) {
    return ImprovedVacanteCard(
      doc: doc,
      onVerPressed: () => _navigateToVacanteDetail(doc),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (subtitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: FeaturesTour(
          controller: tourController,
          index: 1,
          introduce: Text("Esta es la sección de reclutamiento"),
          child: const Text('Reclutamiento'),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ Envolvemos todo en SingleChildScrollView
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mejorado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade700, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade300.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.work_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FeaturesTour(
                                controller: tourController,
                                index: 2,
                                introduce: Text(
                                  "En esta seccion puedes ver el resumen de las vacantes",
                                ),
                                child: Text(
                                  'Gestión de Vacantes',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Administra y monitorea el estado de las vacantes laborales',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SECCIÓN DE ESTADÍSTICAS
              FeaturesTour(
                controller: tourController,
                index: 3,
                introduce: Text("Aquí puedes ver un resumen de las vacantes"),
                child: Text(
                  'Resumen de Vacantes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // StreamBuilder para estadísticas
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vacantes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Calcular estadísticas
                  int totalVacantes = docs.length;
                  int vacantesActivas = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['estado'] == 'activa';
                  }).length;

                  int vacantesOcupadas = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['estado'] == 'ocupada';
                  }).length;

                  int vacantesPorVencer = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['estado'] == 'activa' && data['endDate'] != null) {
                      final endDate = (data['endDate'] as Timestamp).toDate();
                      final daysLeft = endDate
                          .difference(DateTime.now())
                          .inDays;
                      return daysLeft <= 7 && daysLeft > 0;
                    }
                    return false;
                  }).length;

                  int vacantesExpiradas = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['estado'] == 'activa' && data['endDate'] != null) {
                      final endDate = (data['endDate'] as Timestamp).toDate();
                      return endDate.isBefore(DateTime.now());
                    }
                    return false;
                  }).length;

                  double tasaOcupacion = totalVacantes > 0
                      ? (vacantesOcupadas / totalVacantes) * 100
                      : 0;

                  return Column(
                    children: [
                      // Primera fila de estadísticas
                      Row(
                        children: [
                          _buildStatsCard(
                            title: 'Total Vacantes',
                            value: totalVacantes.toString(),
                            icon: Icons.work_outline,
                            color: Colors.blue.shade600,
                            subtitle: 'General',
                          ),
                          const SizedBox(width: 12),
                          _buildStatsCard(
                            title: 'Vacantes Activas',
                            value: vacantesActivas.toString(),
                            icon: Icons.people_alt,
                            color: Colors.green.shade600,
                            subtitle: 'Disponibles',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Segunda fila de estadísticas
                      Row(
                        children: [
                          FeaturesTour(
                            controller: tourController,
                            index: 4,
                            introduce: Text(
                              "Número de vacantes que están actualmente ocupadas",
                            ),
                            child: _buildStatsCard(
                              title: 'Vacantes Ocupadas',
                              value: vacantesOcupadas.toString(),
                              icon: Icons.person,
                              color: Colors.purple.shade600,
                              subtitle: 'Asignadas',
                            ),
                          ),
                          const SizedBox(width: 12),
                          FeaturesTour(
                            controller: tourController,
                            index: 5,
                            introduce: Text(
                              "Número de vacantes que están próximas a vencer",
                            ),
                            child: _buildStatsCard(
                              title: 'Por Vencer',
                              value: vacantesPorVencer.toString(),
                              icon: Icons.warning,
                              color: Colors.orange.shade600,
                              subtitle: 'Próximas',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tercera fila de estadísticas
                      Row(
                        children: [
                          FeaturesTour(
                            controller: tourController,
                            index: 6,
                            introduce: Text(
                              "Número de vacantes que han expirado",
                            ),
                            child: _buildStatsCard(
                              title: 'Expiradas',
                              value: vacantesExpiradas.toString(),
                              icon: Icons.error_outline,
                              color: Colors.red.shade600,
                              subtitle: 'Vencidas',
                            ),
                          ),
                          const SizedBox(width: 12),
                          FeaturesTour(
                            controller: tourController,
                            index: 7,
                            introduce: Text(
                              "Porcentaje de vacantes ocupadas respecto al total",
                            ),
                            child: _buildStatsCard(
                              title: 'Tasa Ocupación',
                              value: '${tasaOcupacion.toStringAsFixed(1)}%',
                              icon: Icons.trending_up,
                              color: Colors.teal.shade600,
                              subtitle: 'Eficiencia',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Botón crear vacante
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade300.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _showCrearVacanteDialog,
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: const Text(
                    'Crear vacante',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // VACANTES ACTIVAS
              Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vacantes Activas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vacantes')
                      .where('estado', isEqualTo: 'activa')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return _buildEmptyState(
                        'No hay vacantes activas',
                        Icons.work_outline,
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildVacanteCard(docs[index]),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // VACANTES OCUPADAS
              Row(
                children: [
                  Icon(Icons.person, color: Colors.purple.shade600, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Vacantes Ocupadas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vacantes')
                      .where('estado', isEqualTo: 'ocupada')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorWidget(snapshot.error.toString());
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return _buildEmptyState(
                        'No hay vacantes ocupadas',
                        Icons.work_history,
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildVacanteCard(docs[index]),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20), // Espacio final
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    bool isIndexError = error.contains('index') || error.contains('Índice');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar las vacantes',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            if (isIndexError) ...[
              const SizedBox(height: 16),
              const Text(
                'Es necesario crear un índice en Firebase. Esto puede tomar algunos minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Usa el botón "Crear vacante" para agregar nuevas posiciones',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
