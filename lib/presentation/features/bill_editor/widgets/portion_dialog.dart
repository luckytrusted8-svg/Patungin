import 'package:flutter/material.dart';
import '../../../../core/constants/strings.dart';

class PortionDialog extends StatefulWidget {
  final String participantName;
  final String itemName;
  final int initialPortion;

  const PortionDialog({
    super.key,
    required this.participantName,
    required this.itemName,
    required this.initialPortion,
  });

  @override
  State<PortionDialog> createState() => _PortionDialogState();
}

class _PortionDialogState extends State<PortionDialog> {
  late int _portion;

  @override
  void initState() {
    super.initState();
    _portion = widget.initialPortion;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Porsi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Berapa porsi ${widget.itemName} yang diambil oleh ${widget.participantName}?',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _portion > 1 ? () => setState(() => _portion--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$_portion',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => _portion++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Porsi 2 berarti membayar 2x lipat dibanding porsi 1.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_portion),
          child: const Text(AppStrings.ok),
        ),
      ],
    );
  }
}
