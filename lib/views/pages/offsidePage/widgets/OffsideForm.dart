  import 'dart:io';
  import 'package:VarXPro/lang/translation.dart';
  import 'package:VarXPro/model/appcolor.dart';
  import 'package:VarXPro/views/pages/offsidePage/controller/offside_controller.dart';
  import 'package:VarXPro/views/pages/offsidePage/widgets/image_picker_widget.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';

  import 'package:provider/provider.dart';

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

    @override
    void dispose() {
      _lineStartXController.dispose();
      _lineStartYController.dispose();
      _lineEndXController.dispose();
      _lineEndYController.dispose();
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
              children: [
                ImagePickerWidget(
                  onImagePicked: (File image) {
                    if (_formKey.currentState!.validate()) {
                      context.read<OffsideBloc>().add(
                            DetectOffsideSingleEvent(
                              image: image,
                              attackDirection: _attackDirection,
                              lineStart: _useFixedLine
                                  ? [
                                      int.parse(_lineStartXController.text),
                                      int.parse(_lineStartYController.text)
                                    ]
                                  : null,
                              lineEnd: _useFixedLine
                                  ? [
                                      int.parse(_lineEndXController.text),
                                      int.parse(_lineEndYController.text)
                                    ]
                                  : null,
                            ),
                          );
                      context.read<OffsideBloc>().add(UpdatePickedImageEvent(image));
                    }
                  },
                  buttonText: Translations.getOffsideText('pickAndAnalyze', widget.currentLang),
                  mode: widget.mode,
                  seedColor: widget.seedColor,
                ),
                SizedBox(height: widget.constraints.maxWidth * 0.04),
                DropdownButtonFormField<String>(
                  value: _attackDirection,
                  decoration: InputDecoration(
                    labelText: Translations.getOffsideText('attackDirection', widget.currentLang),
                    labelStyle: TextStyle(color: AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                  ),
                  dropdownColor: AppColors.getSurfaceColor(widget.mode),
                  items: ['right', 'left', 'up', 'down']
                      .map((dir) => DropdownMenuItem(
                            value: dir,
                            child: Text(
                              dir.toUpperCase(),
                              style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _attackDirection = value!;
                    });
                  },
                ),
                SizedBox(height: widget.constraints.maxWidth * 0.04),
                SwitchListTile(
                  title: Text(
                    Translations.getOffsideText('useFixedLine', widget.currentLang),
                    style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                  ),
                  value: _useFixedLine,
                  activeColor: AppColors.getTertiaryColor(widget.seedColor, widget.mode),
                  onChanged: (value) {
                    setState(() {
                      _useFixedLine = value;
                    });
                  },
                ),
                if (_useFixedLine) ...[
                  SizedBox(height: widget.constraints.maxWidth * 0.04),
                  Text(
                    Translations.getOffsideText('lineCoordinates', widget.currentLang),
                    style: TextStyle(
                      color: AppColors.getTextColor(widget.mode),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: widget.constraints.maxWidth * 0.03),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lineStartXController,
                          decoration: InputDecoration(
                            labelText: Translations.getOffsideText('startX', widget.currentLang),
                            labelStyle: TextStyle(color: AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                          ),
                          style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty
                              ? Translations.getOffsideText('startX', widget.currentLang)
                              : null,
                        ),
                      ),
                      SizedBox(width: widget.constraints.maxWidth * 0.02),
                      Expanded(
                        child: TextFormField(
                          controller: _lineStartYController,
                          decoration: InputDecoration(
                            labelText: Translations.getOffsideText('startY', widget.currentLang),
                            labelStyle: TextStyle(color: AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                          ),
                          style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty
                              ? Translations.getOffsideText('startY', widget.currentLang)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.constraints.maxWidth * 0.03),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lineEndXController,
                          decoration: InputDecoration(
                            labelText: Translations.getOffsideText('endX', widget.currentLang),
                            labelStyle: TextStyle(color: AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                          ),
                          style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty
                              ? Translations.getOffsideText('endX', widget.currentLang)
                              : null,
                        ),
                      ),
                      SizedBox(width: widget.constraints.maxWidth * 0.02),
                      Expanded(
                        child: TextFormField(
                          controller: _lineEndYController,
                          decoration: InputDecoration(
                            labelText: Translations.getOffsideText('endY', widget.currentLang),
                            labelStyle: TextStyle(color: AppColors.getTertiaryColor(widget.seedColor, widget.mode)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.getTertiaryColor(widget.seedColor, widget.mode).withOpacity(0.3),
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.getSurfaceColor(widget.mode).withOpacity(0.6),
                          ),
                          style: TextStyle(color: AppColors.getTextColor(widget.mode)),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty
                              ? Translations.getOffsideText('endY', widget.currentLang)
                              : null,
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