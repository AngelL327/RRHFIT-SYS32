  import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';

DataTable tableGenerator(List<IncapacidadModel> sorted, BuildContext context, List<DataColumn> columns, List<DataRow> rows) {
    return DataTable(
      border: TableBorder.all(color: Colors.black54, width: 2),
      headingTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
      dataTextStyle: TextStyle(fontSize: 13, color: Colors.black87),
      columns: columns,
      rows: rows,
    );
  }