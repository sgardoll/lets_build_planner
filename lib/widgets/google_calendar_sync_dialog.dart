import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gc;
import 'package:lets_build_planner/services/google_calendar_service.dart';

class GoogleCalendarSyncDialog extends StatefulWidget {
  const GoogleCalendarSyncDialog({super.key});

  @override
  State<GoogleCalendarSyncDialog> createState() => _GoogleCalendarSyncDialogState();
}

class _GoogleCalendarSyncDialogState extends State<GoogleCalendarSyncDialog> {
  List<gc.CalendarListEntry> _calendars = [];
  String? _selectedId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await GoogleCalendarSyncService.instance.listCalendars();
      final saved = await GoogleCalendarSyncService.instance.getSavedCalendarId();
      
      setState(() {
        _calendars = list;
        _selectedId = saved ?? (list.isNotEmpty ? list.first?.id : null);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load calendars: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _signInAndRetry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    final signedIn = await GoogleCalendarSyncService.instance.signIn();
    if (!signedIn) {
      setState(() {
        _error = 'Sign-in was cancelled or failed. Please try again.';
        _loading = false;
      });
      return;
    }
    
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Sync to Google Calendar', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(), 
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
              )
            ]),
            const SizedBox(height: 12),
            if (_loading) const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
            else if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Sign-in Required', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please sign in to Google to access your calendars. Make sure to allow calendar permissions.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _signInAndRetry, 
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Sign In to Google'),
                ),
              )
            ] else if (_calendars.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('No Calendars Available', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('No editable calendars found in your Google account.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text('Tip: Create a new calendar in Google Calendar, then refresh.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(child: ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Refresh')))
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose a calendar to sync your content items to:', 
                      style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text('Items will be added as all-day events with your content details.', 
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedId,
                decoration: const InputDecoration(
                  labelText: 'Select Calendar',
                  border: OutlineInputBorder(),
                ),
                items: _calendars.map((c) => DropdownMenuItem<String>(
                  value: c.id, 
                  child: Text(c.summary ?? c.id ?? 'Calendar'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedId = v),
              ),
              const SizedBox(height: 16),
              Row(children: [
                TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reload')),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _selectedId == null ? null : () async {
                    await GoogleCalendarSyncService.instance.saveSelectedCalendar(_selectedId!);
                    if (!mounted) return;
                    Navigator.of(context).pop(_selectedId);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Use this calendar'),
                )
              ])
            ]
          ]),
        ),
      ),
    );
  }
}