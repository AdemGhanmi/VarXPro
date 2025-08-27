import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewer extends StatefulWidget {
  final String pdfPath;
  const PdfViewer({super.key, required this.pdfPath});

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    if (File(widget.pdfPath).existsSync()) {
      _pdfController = PdfController(document: PdfDocument.openFile(widget.pdfPath));
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pdfController == null) {
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
            "No PDF available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
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
      child: PdfView(
        controller: _pdfController!,
        scrollDirection: Axis.vertical,
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(
            loaderSwitchDuration: Duration(milliseconds: 200),
          ),
          documentLoaderBuilder: (_) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
            ),
          ),
          pageLoaderBuilder: (_) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF11FFB2)),
            ),
          ),
        ),
      ),
    );
  }
}