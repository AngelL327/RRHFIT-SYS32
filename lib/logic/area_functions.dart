
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rrhfit_sys32/logic/models/area_model.dart';

Future<AreaModel?> getAreaById(String? id) async {
  if (id == null) return null;
  final snapshot = await FirebaseFirestore.instance
      .collection('area')
      .where('area_id', isEqualTo: id)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final doc = snapshot.docs.first;
    final data = doc.data();
    return AreaModel.fromJson(data);
  } else {
    return null; // No area found with the given id
  }
}

