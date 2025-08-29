import 'dart:io';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewer extends StatefulWidget {
  final String pdfPath;
  final int mode;
  final Color seedColor;
  final String currentLang;

  const PdfViewer({
    super.key,
    required this.pdfPath,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

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
        decoration: BoxDecoration(
          gradient: AppColors.getBodyGradient(widget.mode),
        ),
        child: Center(
          child: Text(
            Translations.getFoulDetectionText('noPdfAvailable', widget.currentLang),
            style: TextStyle(color: AppColors.getTextColor(widget.mode)),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getBodyGradient(widget.mode),
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
              valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
            ),
          ),
          pageLoaderBuilder: (_) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
            ),
          ),
        ),
      ),
    );
  }
}