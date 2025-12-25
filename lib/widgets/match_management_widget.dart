import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../services/feedback_service.dart';
import '../models/match.dart';
import '../constants/translation_keys.dart';

class MatchManagementWidget extends StatelessWidget {
  final Match match;
  final bool isOwner;

  const MatchManagementWidget({
    super.key,
    required this.match,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOwner) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    switch (match.status) {
      case 'open':
        buttons.addAll([
          _ActionButton(
            label: LocalizationService().translate(TranslationKeys.startMatch),
            icon: Icons.play_arrow,
            color: Colors.green,
            onPressed: () => _updateStatus(context, 'in_progress'),
          ),
          _ActionButton(
            label: LocalizationService()
                .translate(TranslationKeys.rescheduleMatch),
            icon: Icons.schedule,
            onPressed: () => _showRescheduleDialog(context),
          ),
          _ActionButton(
            label: LocalizationService().translate(TranslationKeys.cancelMatch),
            icon: Icons.cancel,
            color: Colors.red,
            onPressed: () => _updateStatus(context, 'cancelled'),
          ),
        ]);
        break;
      case 'in_progress':
        buttons.add(
          _ActionButton(
            label:
                LocalizationService().translate(TranslationKeys.completeMatch),
            icon: Icons.flag,
            color: Colors.blue,
            onPressed: () => _showResultDialog(context),
          ),
        );
        break;
    }

    return buttons;
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      await context.read<ApiService>().updateMatchStatus(match.id, status);
      if (context.mounted) {
        context.showSuccess('Match status updated');
      }
    } catch (e) {
      if (context.mounted) {
        context.showError(e);
      }
    }
  }

  void _showRescheduleDialog(BuildContext context) {
    DateTime selectedDate = match.matchDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            LocalizationService().translate(TranslationKeys.rescheduleMatch)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(LocalizationService()
                  .translate(TranslationKeys.newMatchDate)),
              subtitle: Text(selectedDate.toString().split('.')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null && context.mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (time != null) {
                    selectedDate = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute);
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text(LocalizationService().translate(TranslationKeys.cancel)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context
                    .read<ApiService>()
                    .rescheduleMatch(match.id, selectedDate);
                if (context.mounted) {
                  context.showSuccess('Match rescheduled');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showError(e);
                }
              }
            },
            child: Text(LocalizationService().translate(TranslationKeys.save)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context) {
    final team1Controller = TextEditingController();
    final team2Controller = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(LocalizationService().translate(TranslationKeys.recordResult)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: team1Controller,
              decoration: InputDecoration(
                labelText:
                    LocalizationService().translate(TranslationKeys.team1Score),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: team2Controller,
              decoration: InputDecoration(
                labelText:
                    LocalizationService().translate(TranslationKeys.team2Score),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText:
                    LocalizationService().translate(TranslationKeys.matchNotes),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text(LocalizationService().translate(TranslationKeys.cancel)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ApiService>().recordMatchResult(
                      match.id,
                      team1Score: int.tryParse(team1Controller.text),
                      team2Score: int.tryParse(team2Controller.text),
                      notes: notesController.text.isEmpty
                          ? null
                          : notesController.text,
                    );
                if (context.mounted) {
                  context.showSuccess('Match result recorded');
                }
              } catch (e) {
                if (context.mounted) {
                  context.showError(e);
                }
              }
            },
            child: Text(LocalizationService().translate(TranslationKeys.save)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color != null ? Colors.white : null,
      ),
    );
  }
}
