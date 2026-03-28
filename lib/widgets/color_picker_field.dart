import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

const Color guidePrimary = Color(0xFF6200EE);
const Color guidePrimaryVariant = Color(0xFF3700B3);
const Color guideSecondary = Color(0xFF03DAC6);
const Color guideSecondaryVariant = Color(0xFF018786);
const Color guideError = Color(0xFFB00020);
const Color guideErrorDark = Color(0xFFCF6679);
const Color blueBlues = Color(0xFF174378);

// Make a custom ColorSwatch to name map from the above custom colors.
final Map<ColorSwatch<Object>, String>
colorsNameMap = <ColorSwatch<Object>, String>{
  ColorTools.createPrimarySwatch(guidePrimary): 'Guide Purple',
  ColorTools.createPrimarySwatch(guidePrimaryVariant): 'Guide Purple Variant',
  ColorTools.createAccentSwatch(guideSecondary): 'Guide Teal',
  ColorTools.createAccentSwatch(guideSecondaryVariant): 'Guide Teal Variant',
  ColorTools.createPrimarySwatch(guideError): 'Guide Error',
  ColorTools.createPrimarySwatch(guideErrorDark): 'Guide Error Dark',
  ColorTools.createPrimarySwatch(blueBlues): 'Blue blues',
};

class ColorPickerField extends StatefulWidget {
  final ValueNotifier<Color> colorNotifier;
  // final Function(Color) onChange;

  const ColorPickerField({
    super.key,
    required this.colorNotifier,
    // required this.onChange,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late Color _dialogColor;

  @override
  void initState() {
    super.initState();
    _dialogColor = widget.colorNotifier.value;
    widget.colorNotifier.addListener(_onColorNotifierChanged);
  }

  @override
  void dispose() {
    widget.colorNotifier.removeListener(_onColorNotifierChanged);
    super.dispose();
  }

  void _onColorNotifierChanged() {
    setState(() {
      _dialogColor = widget.colorNotifier.value;
    });
  }

  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      // Use the _dialogColor as start and active color.
      color: _dialogColor,
      // Update the _dialogColor using the callback.
      onColorChanged: (Color color) => setState(() {
        _dialogColor = color;
        widget.colorNotifier.value = color;
        // widget.onChange(color);
      }),
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      // New in version 3.0.0 custom transitions support.
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> a1,
            Animation<double> a2,
            Widget widget,
          ) {
            final double curvedValue =
                Curves.easeInOutBack.transform(a1.value) - 1.0;
            return Transform(
              transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
              child: Opacity(opacity: a1.value, child: widget),
            );
          },
      transitionDuration: const Duration(milliseconds: 400),
      constraints: const BoxConstraints(
        minHeight: 460,
        minWidth: 300,
        maxWidth: 320,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColorIndicator(
      width: 44,
      height: 44,
      borderRadius: 4,
      color: _dialogColor,
      onSelectFocus: false,
      onSelect: () async {
        final Color colorBeforeDialog = _dialogColor;
        if (!(await colorPickerDialog())) {
          setState(() {
            _dialogColor = colorBeforeDialog;
          });
        }
      },
    );
  }
}
