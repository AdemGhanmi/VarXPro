import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:VarXPro/lang/translation.dart';
import 'package:VarXPro/model/appcolor.dart';
import 'package:VarXPro/views/pages/FiledLinesPages/controller/perspective_controller.dart';

class CalibrationForm extends StatefulWidget {
  final int mode;
  final Color seedColor;
  final String currentLang;

  const CalibrationForm({
    super.key,
    required this.mode,
    required this.seedColor,
    required this.currentLang,
  });

  @override
  _CalibrationFormState createState() => _CalibrationFormState();
}

class _CalibrationFormState extends State<CalibrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _points = List.generate(4, (_) => List.generate(2, (_) => TextEditingController()));
  final _widthController = TextEditingController(text: '400');
  final _heightController = TextEditingController(text: '600');
  final _nameController = TextEditingController();

  @override
  void dispose() {
    for (var point in _points) {
      for (var coord in point) {
        coord.dispose();
      }
    }
    _widthController.dispose();
    _heightController.dispose();
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
              Text(
                Translations.getOffsideText('calibrationPoints', widget.currentLang),
                style: TextStyle(
                  color: AppColors.getTextColor(widget.mode),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '${Translations.getOffsideText('point', widget.currentLang)} ${index + 1}:',
                        style: TextStyle(color: AppColors.getTextColor(widget.mode).withOpacity(0.7)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _points[index][0],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: Translations.getOffsideText('x', widget.currentLang),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _points[index][1],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: Translations.getOffsideText('y', widget.currentLang),
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
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Translations.getOffsideText('outputWidth', widget.currentLang),
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
                          return Translations.getOffsideText('enterWidth', widget.currentLang);
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Translations.getOffsideText('outputHeight', widget.currentLang),
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
                          return Translations.getOffsideText('enterHeight', widget.currentLang);
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: Translations.getOffsideText('saveAs', widget.currentLang),
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
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final sourcePoints = _points
                        .map((point) => [
                              double.parse(point[0].text),
                              double.parse(point[1].text),
                            ])
                        .toList();
                    context.read<PerspectiveBloc>().add(
                          SetCalibrationEvent(
                            sourcePoints: sourcePoints,
                            dstWidth: int.parse(_widthController.text),
                            dstHeight: int.parse(_heightController.text),
                            saveAs: _nameController.text.isNotEmpty ? _nameController.text : null,
                          ),
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
                  Translations.getOffsideText('setCalibration', widget.currentLang),
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
