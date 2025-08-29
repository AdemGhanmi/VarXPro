import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/perspective_controller.dart';

class TransformPointForm extends StatefulWidget {
  final int mode;
  final Color seedColor;
  final String currentLang;

  const TransformPointForm({
    super.key,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  _TransformPointFormState createState() => _TransformPointFormState();
}

class _TransformPointFormState extends State<TransformPointForm> {
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
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
              Text(
                Translations.getOffsideText('transformPoints', widget.currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(widget.mode),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Translations.getOffsideText('xCoordinate', widget.currentLang),
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
                          return Translations.getOffsideText('enterXCoordinate', widget.currentLang);
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _yController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Translations.getOffsideText('yCoordinate', widget.currentLang),
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
                          return Translations.getOffsideText('enterYCoordinate', widget.currentLang);
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<PerspectiveBloc>().add(
                                TransformPointEvent(
                                  double.parse(_xController.text),
                                  double.parse(_yController.text),
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                        foregroundColor: AppColors.getTextColor(widget.mode),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Translations.getOffsideText('transform', widget.currentLang),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(widget.mode),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<PerspectiveBloc>().add(
                                InverseTransformPointEvent(
                                  double.parse(_xController.text),
                                  double.parse(_yController.text),
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                        foregroundColor: AppColors.getTextColor(widget.mode),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        Translations.getOffsideText('inverseTransform', widget.currentLang),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(widget.mode),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
