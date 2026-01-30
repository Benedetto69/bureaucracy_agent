import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Checkpoint item for decision validation
class CheckpointItem {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isRequired;

  const CheckpointItem({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isRequired = true,
  });

  CheckpointItem copyWith({bool? isCompleted}) {
    return CheckpointItem(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      isRequired: isRequired,
    );
  }
}

/// Decision checkpoint widget shown before generating documents
class DecisionCheckpoint extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<CheckpointItem> items;
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;
  final ValueChanged<List<CheckpointItem>>? onItemsChanged;

  const DecisionCheckpoint({
    super.key,
    this.title = 'Prima di procedere',
    this.subtitle = 'Conferma di aver considerato questi punti',
    required this.items,
    this.onProceed,
    this.onCancel,
    this.onItemsChanged,
  });

  @override
  State<DecisionCheckpoint> createState() => _DecisionCheckpointState();
}

class _DecisionCheckpointState extends State<DecisionCheckpoint> {
  late List<CheckpointItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(DecisionCheckpoint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = List.from(widget.items);
    }
  }

  bool get _canProceed {
    return _items
        .where((item) => item.isRequired)
        .every((item) => item.isCompleted);
  }

  int get _completedCount => _items.where((item) => item.isCompleted).length;

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
      );
    });
    widget.onItemsChanged?.call(_items);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _items.isEmpty ? 0.0 : _completedCount / _items.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceLight,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.warning.withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(progress),

          // Checkpoint items
          ..._items.asMap().entries.map((entry) {
            return _buildCheckpointItem(entry.key, entry.value);
          }),

          // Action buttons
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(10),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.checklist_rtl_outlined,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _canProceed ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_completedCount/${_items.length}',
                style: TextStyle(
                  color: _canProceed ? AppColors.success : AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointItem(int index, CheckpointItem item) {
    final isLast = index == _items.length - 1;

    return InkWell(
      onTap: () => _toggleItem(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? AppColors.success
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isCompleted
                      ? AppColors.success
                      : AppColors.textTertiary.withAlpha(100),
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: item.isCompleted
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      if (item.isRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Obbligatorio',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      height: 1.4,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.textTertiary.withAlpha(100),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.surfaceElevated),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Annulla'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed ? widget.onProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceed
                    ? AppColors.success
                    : AppColors.textDisabled,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: AppColors.surface,
                disabledForegroundColor: AppColors.textDisabled,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _canProceed
                        ? Icons.check_circle_outline
                        : Icons.lock_outline,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(_canProceed ? 'Procedi' : 'Completa tutti i punti'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
