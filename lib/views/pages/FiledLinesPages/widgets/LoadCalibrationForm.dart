import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/perspective_controller.dart';

class LoadCalibrationForm extends StatefulWidget {
  final int mode;
  final Color seedColor;
  final String currentLang;

  const LoadCalibrationForm({
    super.key,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  _LoadCalibrationFormState createState() => _LoadCalibrationFormState();
}

class _LoadCalibrationFormState extends State<LoadCalibrationForm> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.getSurfaceColor(widget.mode).withOpacity(0.8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: Translations.getOffsideText('calibrationName', widget.currentLang),
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
                style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Translations.getOffsideText('enterCalibrationName', widget.currentLang);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<PerspectiveBloc>().add(
                          LoadCalibrationByNameEvent(_nameController.text),
                        );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                  foregroundColor: AppColors.getTextColor(widget.mode),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  Translations.getOffsideText('loadCalibration', widget.currentLang),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(widget.mode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
