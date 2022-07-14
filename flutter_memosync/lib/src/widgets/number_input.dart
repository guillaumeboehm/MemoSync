import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Number input widget
class NumberInputField extends StatelessWidget {
  /// Default constructor
  // ignore: prefer_const_constructors_in_immutables
  NumberInputField({
    Key? key,
    required this.controller,
    required this.submit,
    this.width,
    this.lowerBound,
    this.upperBound,
    this.hint,
  }) : super(key: key);

  /// Controller for the input text
  final TextEditingController controller;

  /// submit callback
  final void Function() submit;

  /// Text input width
  final double? width;

  /// Lower bound of the input
  final int? lowerBound;

  /// Upper bound of the input
  final int? upperBound;

  /// Upper bound of the input
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              controller.text = min(
                (int.tryParse(
                          controller.text.isEmpty ? '0' : controller.text,
                        ) ??
                        0) +
                    1,
                upperBound ?? double.infinity,
              ).toString();
            },
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width ?? 50,
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9]+')),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
              onChanged: (value) {
                if (value.isEmpty) {
                  controller.text = '0';
                } else {
                  var number = num.tryParse(value) ?? 0;
                  number = number
                      .clamp(
                        lowerBound ?? 0,
                        upperBound ?? double.infinity,
                      )
                      .round();
                  value = number.toString();
                  if (controller.text != value) controller.text = value;
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: hint,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              controller.text = max(
                (int.tryParse(
                          controller.text.isEmpty ? '0' : controller.text,
                        ) ??
                        0) -
                    1,
                lowerBound ?? 0,
              ).toString();
            },
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );
  }
}
