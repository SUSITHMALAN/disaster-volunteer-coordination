import 'package:flutter/material.dart';

import '../models/resource.dart';

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

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resource.resourceName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('${resource.category.label} · ${resource.unit}'),
          const SizedBox(height: 6),
          Text(
            incidentTitle ?? 'Incident: ${resource.incidentId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ResourceQuantities(
            available: resource.availableQuantity,
            needed: resource.neededQuantity,
            used: resource.usedQuantity,
            unit: resource.unit,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                resource.isShortage
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: resource.isShortage
                    ? const Color(0xFFB3413E)
                    : const Color(0xFF2F6B4F),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resource.isShortage
                      ? 'Shortage: ${formatQuantity(resource.shortageQuantity)} ${resource.unit}'
                      : 'No shortage',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (onEdit != null || onIncident != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Update quantities'),
                  ),
                if (onIncident != null)
                  TextButton(
                    onPressed: onIncident,
                    child: const Text('View incident resources'),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => Wrap(
    spacing: 24,
    runSpacing: 12,
    children: [
      for (final entry in {
        'Available': available,
        'Needed': needed,
        'Used': used,
      }.entries)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${formatQuantity(entry.value)} $unit',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
    ],
  );
}
