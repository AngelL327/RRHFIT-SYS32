import 'package:flutter/material.dart';
import 'package:rrhfit_sys32/core/theme.dart';
import 'package:rrhfit_sys32/logic/models/incapacidad_model.dart';
import 'package:data_table_2/data_table_2.dart';

Widget tableGenerator(List<IncapacidadModel> sorted, BuildContext context, List<DataColumn> columns, List<DataRow> rows) {
  // Wrap the paginated table in a Container so we can keep the border and background
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black54, width: 2),
      borderRadius: BorderRadius.circular(4),
    ),
    padding: const EdgeInsets.all(4),
    child: PaginatedDataTable2(
      minWidth: 900,
      horizontalMargin: 8,
      header: const Text(
                      'Incapacidades',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
      columnSpacing: 2,
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Colors.black,
      ),
      headingRowHeight: 50,
      headingRowDecoration: BoxDecoration(
        color: AppTheme.tableHeaderBG,
      ),
      dataTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
      // default rows per page and options
      rowsPerPage: 15,
      availableRowsPerPage: const [5, 10, 25, 50],
      showFirstLastButtons: true,
      // columns are passed through; they may include Center widgets for headers
      columns: columns,
      // Use a DataTableSource wrapper around the provided DataRow list
      source: _RowsDataSource(rows),
    ),
  );
}

class _RowsDataSource extends DataTableSource {
  final List<DataRow> _rows;

  _RowsDataSource(this._rows);

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= _rows.length) return null;
    return _rows[index];
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _rows.length;

  @override
  int get selectedRowCount => 0;
}