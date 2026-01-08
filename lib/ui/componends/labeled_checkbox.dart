import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabeledCheckbox extends StatelessWidget {
  final String label;
  final RxBool value;

  const LabeledCheckbox({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => InkWell(
      onTap: () => value.value = !value.value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value.value,
              onChanged: (v) => value.value = v ?? false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ));
  }
}

class CheckboxRow extends StatelessWidget {
  final List<LabeledCheckbox> checkboxes;

  const CheckboxRow({
    super.key,
    required this.checkboxes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: checkboxes
          .map((cb) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: cb,
              ))
          .toList(),
    );
  }
}

class RoundToggle extends StatelessWidget {
  final String label;
  final RxBool value;
  final double size;

  const RoundToggle({
    super.key,
    required this.label,
    required this.value,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
      onTap: () => value.value = !value.value,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value.value ? Colors.green : Colors.grey.shade400,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ));
  }
}

class RoundToggleRow extends StatelessWidget {
  final List<RoundToggle> toggles;

  const RoundToggleRow({
    super.key,
    required this.toggles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: toggles
          .map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: t,
              ))
          .toList(),
    );
  }
}
