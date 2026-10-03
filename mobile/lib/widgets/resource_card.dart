import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../theme/app_theme.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final String? incidentTitle;
  final VoidCallback? onEdit;
  final VoidCallback? onIncident;

  const ResourceCard({
    super.key,
    required this.resource,
    this.incidentTitle,
    this.onEdit,
    this.onIncident,
  });

  double get _progress {
    if (resource.neededQuantity <= 0) {
      return resource.availableQuantity > 0 ? 1 : 0;
    }

    final value = resource.availableQuantity / resource.neededQuantity;

    return value.clamp(0, 1).toDouble();
  }

  num get _remaining {
    final value = resource.availableQuantity - resource.usedQuantity;

    return value < 0 ? 0 : value;
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (_progress * 100).round();

    final statusColor = resource.isShortage
        ? AppTheme.danger
        : AppTheme.emerald;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: resource.isShortage
              ? AppTheme.danger.withValues(alpha: 0.35)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESOURCE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            resource.resourceName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${resource.category.label} · ${resource.unit}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppTheme.backgroundAlt,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${formatQuantity(resource.availableQuantity)} / '
                  '${formatQuantity(resource.neededQuantity)} '
                  '${resource.unit} ($progressPercent%)',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                resource.isShortage
                    ? 'Needs +${formatQuantity(resource.shortageQuantity)} ${resource.unit}'
                    : 'No shortage',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildIncidentSection(),

          const SizedBox(height: 16),

          const Divider(height: 1, color: AppTheme.border),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Available',
                  '${formatQuantity(resource.availableQuantity)} ${resource.unit}',
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Used',
                  '${formatQuantity(resource.usedQuantity)} ${resource.unit}',
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Remaining',
                  '${formatQuantity(_remaining)} ${resource.unit}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                resource.isShortage
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 20,
                color: statusColor,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  resource.isShortage
                      ? 'Shortage of ${formatQuantity(resource.shortageQuantity)} ${resource.unit}'
                      : 'Supply requirement fulfilled',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (onEdit != null || onIncident != null) ...[
            const SizedBox(height: 16),

            const Divider(height: 1, color: AppTheme.border),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Update quantities'),
                  ),

                if (onIncident != null)
                  TextButton.icon(
                    onPressed: onIncident,
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('View incident'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncidentSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INCIDENT',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                incidentTitle ?? 'Incident ${_shortId(resource.incidentId)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'ID: ${_shortId(resource.incidentId)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ResourceQuantities extends StatelessWidget {
  final num available;
  final num needed;
  final num used;
  final String unit;

  const ResourceQuantities({
    super.key,
    required this.available,
    required this.needed,
    required this.used,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildQuantity('Available', available)),
        Expanded(child: _buildQuantity('Needed', needed)),
        Expanded(child: _buildQuantity('Used', used)),
      ],
    );
  }

  Widget _buildQuantity(String label, num value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatQuantity(value)} $unit',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
