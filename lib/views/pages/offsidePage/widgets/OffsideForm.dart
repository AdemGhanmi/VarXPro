// File: lib/views/pages/offsidePage/widgets/OffsideForm.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../lang/translation.dart';
import '../../../../model/appcolor.dart';
import '../../../../provider/langageprovider.dart';
import '../controller/offside_controller.dart';

class OffsideForm extends StatefulWidget {
  final BoxConstraints constraints;
  final String currentLang;
  final int mode;
  final Color seedColor;
  const OffsideForm({
    super.key,
    required this.constraints,
    required this.currentLang,
    required this.mode,
    required this.seedColor,
  });
  @override
  _OffsideFormState createState() => _OffsideFormState();
}

class _OffsideFormState extends State<OffsideForm> {
  final _formKey = GlobalKey<FormState>();
  final _lineStartXController = TextEditingController(text: '640');
  final _lineStartYController = TextEditingController(text: '0');
  final _lineEndXController = TextEditingController(text: '690');
  final _lineEndYController = TextEditingController(text: '720');
  String _attackDirection = 'right';
  bool _useFixedLine = false;

  bool _picking = false;

  @override
  void dispose() {
    _lineStartXController.dispose();
    _lineStartYController.dispose();
    _lineEndXController.dispose();
    _lineEndYController.dispose();
    super.dispose();
  }

  Future<bool> _ensureGalleryPermission() async {
    final statuses = await [
      Permission.photos,
      Permission.storage,
      Permission.videos,
      Permission.mediaLibrary,
    ].request();

    final granted = statuses.values.any((s) => s.isGranted || s.isLimited);
    return granted;
  }

  Future<void> _pickImage(BuildContext context) async {
    if (_picking) return;
    _picking = true;

    final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    try {
      final ok = await _ensureGalleryPermission();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Translations.getOffsideText('photoAccessDenied', currentLang))),
        );
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      if (!mounted) return;
      final bloc = context.read<OffsideBloc>();
      if (bloc.state.isLoading) return;

      if (_formKey.currentState!.validate()) {
        bloc.add(UpdatePickedImageEvent(File(pickedFile.path)));

        bloc.add(
          DetectOffsideSingleEvent(
            image: File(pickedFile.path),
            attackDirection: _attackDirection,
            lineStart: _useFixedLine
                ? [
                    int.tryParse(_lineStartXController.text) ?? 0,
                    int.tryParse(_lineStartYController.text) ?? 0,
                  ]
                : null,
            lineEnd: _useFixedLine
                ? [
                    int.tryParse(_lineEndXController.text) ?? 0,
                    int.tryParse(_lineEndYController.text) ?? 0,
                  ]
                : null,
          ),
        );
      }
    } finally {
      _picking = false;
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    if (_picking) return;
    _picking = true;

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result == null || result.files.isEmpty) return;

      if (!mounted) return;
      final bloc = context.read<OffsideBloc>();
      if (bloc.state.isLoading) return;

      final video = File(result.files.first.path!);
      bloc.add(
        DetectOffsideVideoEvent(
          video: video,
          attackDirection: _attackDirection,
          lineStart: _useFixedLine
              ? [
                  int.tryParse(_lineStartXController.text) ?? 0,
                  int.tryParse(_lineStartYController.text) ?? 0,
                ]
              : null,
          lineEnd: _useFixedLine
              ? [
                  int.tryParse(_lineEndXController.text) ?? 0,
                  int.tryParse(_lineEndYController.text) ?? 0,
                ]
              : null,
        ),
      );
    } finally {
      _picking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<OffsideBloc, bool>((b) => b.state.isLoading);

    return Card(
      color: AppColors.getSurfaceColor(widget.mode).withOpacity(0.88),
      elevation: 8,
      shadowColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : () => _pickImage(context),
                      icon: Icon(Icons.photo_camera, color: AppColors.getTextColor(widget.mode)),
                      label: Text(
                        Translations.getOffsideText('pickAndAnalyze', widget.currentLang),
                        style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  SizedBox(width: widget.constraints.maxWidth * 0.04),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : () => _pickVideo(context),
                      icon: Icon(Icons.video_file, color: AppColors.getTextColor(widget.mode)),
                      label: Text(
                        Translations.getOffsideText('pickAndAnalyzeVideo', widget.currentLang),
                        style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getSecondaryColor(widget.seedColor, widget.mode),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _attackDirection,
                decoration: InputDecoration(
                  labelText: Translations.getOffsideText('attackDirection', widget.currentLang),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                ),
                dropdownColor: AppColors.getSurfaceColor(widget.mode),
                items: ['right', 'left', 'up', 'down']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _attackDirection = v ?? 'right'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(Translations.getOffsideText('useFixedLine', widget.currentLang)),
                value: _useFixedLine,
                activeColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                onChanged: (v) => setState(() => _useFixedLine = v),
              ),
              if (_useFixedLine) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lineStartXController,
                        decoration: InputDecoration(
                          labelText: Translations.getOffsideText('startX', widget.currentLang),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lineStartYController,
                        decoration: InputDecoration(
                          labelText: Translations.getOffsideText('startY', widget.currentLang),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lineEndXController,
                        decoration: InputDecoration(
                          labelText: Translations.getOffsideText('endX', widget.currentLang),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lineEndYController,
                        decoration: InputDecoration(
                          labelText: Translations.getOffsideText('endY', widget.currentLang),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}