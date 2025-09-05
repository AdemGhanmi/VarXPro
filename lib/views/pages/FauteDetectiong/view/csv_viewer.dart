import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class CsvDataGridSource extends DataGridSource {
  final List<String> _headers;
  final List<List<dynamic>> _rows;
  final int mode;
  final Color seedColor;
  final String currentLang;

  CsvDataGridSource({
    required List<List<dynamic>> csvData,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  })  : _headers = csvData.isNotEmpty
            ? csvData.first.map((e) => e.toString()).toList()
            : [],
        _rows = csvData.length > 1 ? csvData.sublist(1) : [] {
    _buildDataGridRows();
  }

  List<DataGridRow> _dataGridRows = [];

  void _buildDataGridRows() {
    _dataGridRows = _rows.map((row) {
      return DataGridRow(
        cells: List.generate(
          _headers.length,
          (i) => DataGridCell<String>(
            columnName: _headers[i],
            value: i < row.length ? row[i].toString() : '',
          ),
        ),
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            cell.value.toString(),
            style: TextStyle(color: AppColors.getTextColor(mode)),
          ),
        );
      }).toList(),
    );
  }

  List<GridColumn> buildColumns() {
    return _headers
        .map((header) => GridColumn(
              columnName: header,
              label: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  header,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTertiaryColor(seedColor, mode),
                  ),
                ),
              ),
            ))
        .toList();
  }
}

class CsvViewer extends StatelessWidget {
  final List<List<dynamic>> csvData;
  final int mode;
  final Color seedColor;
  final String currentLang;

  const CsvViewer({
    super.key,
    required this.csvData,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    if (csvData.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBodyGradient(mode),
        ),
        child: Center(
          child: Text(
            Translations.getFoulDetectionText('noCsvAvailable', currentLang),
            style: TextStyle(color: AppColors.getTextColor(mode)),
          ),
        ),
      );
    }
    final source = CsvDataGridSource(csvData: csvData, mode: mode, seedColor: seedColor, currentLang: currentLang);
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getBodyGradient(mode),
      ),
      child: SfDataGrid(
        source: source,
        columns: source.buildColumns(),
        columnWidthMode: ColumnWidthMode.fill,
        gridLinesVisibility: GridLinesVisibility.both,
        headerGridLinesVisibility: GridLinesVisibility.both,
      ),
    );
  }
}
