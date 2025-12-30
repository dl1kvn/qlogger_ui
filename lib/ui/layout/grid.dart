import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PortraitOrSplit extends StatelessWidget {
  final Widget primary;
  final Widget secondary;

  const PortraitOrSplit({
    super.key,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final land = MediaQuery.of(context).orientation == Orientation.landscape;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: S.maxContentWidth),
        child: land
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: primary),
                  const SizedBox(width: S.x16),
                  Expanded(flex: 1, child: secondary),
                ],
              )
            : Column(
                children: [
                  primary,
                  const SizedBox(height: S.x16),
                  secondary,
                ],
              ),
      ),
    );
  }
}
