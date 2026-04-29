import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _assetPrefix = 'assets/profile_icons/';

class AvatarData {
  final String iconName;
  final int colorValue;

  const AvatarData({
    required this.iconName,
    required this.colorValue,
  });

  static const List<String> availableIcons = [
    'silverware.svg',
    'silverware-fork-knife.svg',
    'pizza.svg',
    'hamburger.svg',
    'pasta.svg',
    'noodles.svg',
    'bowl.svg',
    'rice.svg',
    'chicken.svg',
    'fish.svg',
    'grill.svg',
    'hot-dog.svg',
    'sausage.svg',
    'french-fries.svg',
    'pretzel.svg',
    'baguette.svg',
    'bread.svg',
    'egg.svg',
    'corn.svg',
    'apple.svg',
    'leaf.svg',
    'chili.svg',
    'fork-drink.svg',
    'soy-sauce.svg',
  ];

  static const List<int> availableColors = [
    0xFFE57373, 0xFF81C784, 0xFF64B5F6, 0xFFFFD54F,
    0xFFBA68C8, 0xFF4DB6AC, 0xFFFF8A65, 0xFFA1887F,
  ];

  static const AvatarData defaultAvatar = AvatarData(
    iconName: 'silverware.svg',
    colorValue: 0xFFE57373,
  );

  static AvatarData generateFromUsername(String username) {
    final hash = username.hashCode.abs();
    return AvatarData(
      iconName: availableIcons[hash % availableIcons.length],
      colorValue: availableColors[hash % availableColors.length],
    );
  }

  AvatarData copyWith({String? iconName, int? colorValue}) {
    return AvatarData(
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class AvatarCircle extends StatelessWidget {
  final String iconName;
  final int colorValue;
  final double size;

  const AvatarCircle({
    super.key,
    required this.iconName,
    required this.colorValue,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final padding = size * 0.22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(colorValue),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SvgPicture.asset(
          '$_assetPrefix$iconName',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
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
  late String _selectedIcon;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialData.iconName;
    _selectedColor = widget.initialData.colorValue;
  }

  void _onIconSelected(String iconName) {
    setState(() => _selectedIcon = iconName);
    widget.onChanged(AvatarData(iconName: iconName, colorValue: _selectedColor));
  }

  void _onColorSelected(int colorValue) {
    setState(() => _selectedColor = colorValue);
    widget.onChanged(AvatarData(iconName: _selectedIcon, colorValue: colorValue));
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
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SvgPicture.asset(
              '$_assetPrefix$_selectedIcon',
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
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
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: SvgPicture.asset(
                    '$_assetPrefix$icon',
                    colorFilter: ColorFilter.mode(
                      isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
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
