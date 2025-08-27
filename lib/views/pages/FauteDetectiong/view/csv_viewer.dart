import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class CsvDataGridSource extends DataGridSource {
  final List<String> _headers;
  final List<List<dynamic>> _rows;

  CsvDataGridSource({required List<List<dynamic>> csvData})
      : _headers = csvData.isNotEmpty
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
            style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF11FFB2),
                  ),
                ),
              ),
            ))
        .toList();
  }
}

class CsvViewer extends StatelessWidget {
  final List<List<dynamic>> csvData;

  const CsvViewer({super.key, required this.csvData});

  @override
  Widget build(BuildContext context) {
    if (csvData.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071628),
              Color(0xFF0D2B59),
            ],
          ),
        ),
        child: const Center(
          child: Text(
            "No CSV data available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final source = CsvDataGridSource(csvData: csvData);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071628),
            Color(0xFF0D2B59),
          ],
        ),
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