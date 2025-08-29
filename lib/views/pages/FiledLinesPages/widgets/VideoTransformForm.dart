import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/perspective_controller.dart';

class VideoTransformForm extends StatefulWidget {
  final int mode;
  final Color seedColor;
  final String currentLang;

  const VideoTransformForm({
    super.key,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  _VideoTransformFormState createState() => _VideoTransformFormState();
}

class _VideoTransformFormState extends State<VideoTransformForm> {
  File? _selectedVideo;
  bool _overlayLines = true;
  String _codec = 'mp4v';

  Future<void> _pickVideo(BuildContext context) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = await Permission.videos.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.getOffsideText('photoAccessDenied', widget.currentLang),
            style: TextStyle(color: AppColors.getTextColor(widget.mode)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.getOffsideText('photoAccessPermanentlyDenied', widget.currentLang),
            style: TextStyle(color: AppColors.getTextColor(widget.mode)),
          ),
          action: SnackBarAction(
            label: Translations.getOffsideText('settings', widget.currentLang),
            onPressed: () => openAppSettings(),
            textColor: AppColors.getTextColor(widget.mode),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        final file = File(picked.path);
        if (!file.path.endsWith('.mp4')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Translations.getOffsideText('videoMustBeMp4', widget.currentLang),
                style: TextStyle(color: AppColors.getTextColor(widget.mode)),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        setState(() {
          _selectedVideo = file;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.getOffsideText('noImageSelected', widget.currentLang),
              style: TextStyle(color: AppColors.getTextColor(widget.mode)),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${Translations.getOffsideText('errorPickingImage', widget.currentLang)}: $e',
            style: TextStyle(color: AppColors.getTextColor(widget.mode)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calibrated = context.watch<PerspectiveBloc>().state.health?.calibrated ?? false;
    return Card(
      color: AppColors.getSurfaceColor(widget.mode).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: calibrated ? () => _pickVideo(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                foregroundColor: AppColors.getTextColor(widget.mode),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedVideo != null
                    ? '${Translations.getOffsideText('pickedImage', widget.currentLang)}: ${_selectedVideo!.path.split('/').last}'
                    : Translations.getOffsideText('pickAndAnalyze', widget.currentLang),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(widget.mode),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _overlayLines,
                  onChanged: (value) {
                    setState(() {
                      _overlayLines = value!;
                    });
                  },
                  checkColor: AppColors.getTextColor(widget.mode),
                  fillColor: MaterialStateProperty.all(AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                ),
                Text(
                  Translations.getOffsideText('overlayLines', widget.currentLang),
                  style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _codec,
              decoration: InputDecoration(
                labelText: Translations.getOffsideText('codec', widget.currentLang),
                labelStyle: TextStyle(color: AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                  ),
                ),
                filled: true,
                fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
              ),
              dropdownColor: AppColors.getSurfaceColor(widget.mode),
              style: TextStyle(color: AppColors.getTextColor(widget.mode)),
              items: const [
                DropdownMenuItem(value: 'mp4v', child: Text('MP4V')),
                DropdownMenuItem(value: 'avc1', child: Text('AVC1')),
                DropdownMenuItem(value: 'vp09', child: Text('VP09')),
              ],
              onChanged: (value) {
                setState(() {
                  _codec = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedVideo != null)
              ElevatedButton(
                onPressed: calibrated
                    ? () {
                        context.read<PerspectiveBloc>().add(
                              TransformVideoEvent(
                                _selectedVideo!,
                                overlayLines: _overlayLines,
                                codec: _codec,
                              ),
                            );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                  foregroundColor: AppColors.getTextColor(widget.mode),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  Translations.getOffsideText('transformVideo', widget.currentLang),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(widget.mode),
                  ),
                ),
              ),
            if (!calibrated)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  Translations.getOffsideText('pleaseCalibrateFirst', widget.currentLang),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
