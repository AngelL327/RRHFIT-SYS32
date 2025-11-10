import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:data_table_2/data_table_2.dart';

DataTable2 tableGenerator(
    List<IncapacidadModel> sorted, 
    BuildContext context, 
    List<DataColumn> columns, 
    List<DataRow> rows
) {
  return DataTable2(
    border: TableBorder.all(color: Colors.black54, width: 2),
    minWidth: 900,
    headingTextStyle: const TextStyle(
      fontWeight: FontWeight.bold, 
      fontSize: 15, 
      color: Colors.black,
    ),
    headingRowHeight: 50,
    headingRowDecoration: BoxDecoration(
      color: AppTheme.tableHeaderBG,
    ),
    dataTextStyle: const TextStyle(
      fontSize: 14, 
      color: Colors.black87,
    ),
    fixedTopRows: 1,
    columns: columns,
    rows: rows,
  );
}
