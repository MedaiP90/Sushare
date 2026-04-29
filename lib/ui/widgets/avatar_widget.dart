import 'package:flutter/material.dart';

class AvatarData {
  final int iconCodePoint;
  final int colorValue;

  const AvatarData({
    required this.iconCodePoint,
    required this.colorValue,
  });

  static const List<int> availableIcons = [
    0xe25c, // restaurant
    0xe56c, // lunch_dining
    0xef47, // ramen_dining
    0xed9c, // bakery_dining
    0xea68, // local_cafe
    0xebeb, // local_bar
    0xec38, // local_pizza
    0xe8f1, // cake
    0xe532, // egg_alt
    0xeb55, // outdoor_grill
    0xe843, // set_meal
    0xe570, // no_food
  ];

  static const List<int> availableColors = [
    0xFFE57373, 0xFF81C784, 0xFF64B5F6, 0xFFFFD54F,
    0xFFBA68C8, 0xFF4DB6AC, 0xFFFF8A65, 0xFFA1887F,
  ];

  static final AvatarData defaultAvatar = AvatarData(
    iconCodePoint: availableIcons[0],
    colorValue: availableColors[0],
  );

  static AvatarData generateFromUsername(String username) {
    final hash = username.hashCode.abs();
    return AvatarData(
      iconCodePoint: availableIcons[hash % availableIcons.length],
      colorValue: availableColors[hash % availableColors.length],
    );
  }

  AvatarData copyWith({int? iconCodePoint, int? colorValue}) {
    return AvatarData(
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class AvatarCircle extends StatelessWidget {
  final int iconCodePoint;
  final int colorValue;
  final double size;
  final double iconSize;

  const AvatarCircle({
    super.key,
    required this.iconCodePoint,
    required this.colorValue,
    this.size = 40,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(colorValue),
      ),
      child: Icon(
        IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class AvatarSelector extends StatefulWidget {
  final AvatarData initialData;
  final ValueChanged<AvatarData> onChanged;

  const AvatarSelector({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  late int _selectedIcon;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialData.iconCodePoint;
    _selectedColor = widget.initialData.colorValue;
  }

  void _onIconSelected(int iconCodePoint) {
    setState(() => _selectedIcon = iconCodePoint);
    widget.onChanged(AvatarData(
      iconCodePoint: iconCodePoint,
      colorValue: _selectedColor,
    ));
  }

  void _onColorSelected(int colorValue) {
    setState(() => _selectedColor = colorValue);
    widget.onChanged(AvatarData(
      iconCodePoint: _selectedIcon,
      colorValue: colorValue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(_selectedColor),
          ),
          child: Icon(
            IconData(_selectedIcon, fontFamily: 'MaterialIcons'),
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose Icon',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AvatarData.availableIcons.map((icon) {
            final isSelected = icon == _selectedIcon;
            return GestureDetector(
              onTap: () => _onIconSelected(icon),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  IconData(icon, fontFamily: 'MaterialIcons'),
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose Color',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AvatarData.availableColors.map((color) {
            final isSelected = color == _selectedColor;
            return GestureDetector(
              onTap: () => _onColorSelected(color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(color),
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 3,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}