import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gc;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lets_build_planner/models/content_item.dart';

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner;
  _GoogleAuthClient(this._headers, [http.Client? inner]) : _inner = inner ?? http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class GoogleCalendarSyncService {
  GoogleCalendarSyncService._();
  static final GoogleCalendarSyncService instance = GoogleCalendarSyncService._();

  static const _prefCalendarIdKey = 'google_calendar_id';
  static const _prefAccountEmailKey = 'google_calendar_account_email';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[gc.CalendarApi.calendarScope, 'email']);
  GoogleSignInAccount? _account;

  Future<GoogleSignInAccount?> _ensureSignedIn() async {
    try {
      _account ??= await _googleSignIn.signIn();
      return _account;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Explicitly trigger Google Sign-In flow
  Future<bool> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      return _account != null;
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return false;
    }
  }

  /// Check if user is currently signed in
  bool get isSignedIn => _account != null;

  /// Sign out of Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _account = null;
    } catch (e) {
      debugPrint('Google sign-out error: $e');
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final account = await _ensureSignedIn();
    if (account == null) {
      throw StateError('Google sign-in canceled');
    }
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null || token.isEmpty) throw StateError('No access token');
    return {'Authorization': 'Bearer $token'};
  }

  Future<gc.CalendarApi> _calendarApi() async {
    final headers = await _authHeaders();
    final client = _GoogleAuthClient(headers);
    return gc.CalendarApi(client);
  }

  Future<List<gc.CalendarListEntry>> listCalendars() async {
    final api = await _calendarApi();
    final cal = await api.calendarList.list();
    final items = cal.items ?? <gc.CalendarListEntry>[];
    return items.where((e) => (e.accessRole ?? '') != 'reader').toList();
  }

  Future<void> saveSelectedCalendar(String calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCalendarIdKey, calendarId);
    await prefs.setString(_prefAccountEmailKey, _account?.email ?? '');
  }

  Future<String?> getSavedCalendarId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_prefAccountEmailKey);
      
      // Ensure we're signed in to get current email
      await _ensureSignedIn();
      final currentEmail = _account?.email;
      
      if (savedEmail == null || savedEmail.isEmpty || currentEmail == null || savedEmail != currentEmail) {
        return null;
      }
      return prefs.getString(_prefCalendarIdKey);
    } catch (e) {
      debugPrint('Error getting saved calendar ID: $e');
      return null;
    }
  }

  Future<void> clearSavedCalendar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefCalendarIdKey);
    await prefs.remove(_prefAccountEmailKey);
  }

  Future<void> syncItemsToCalendar({required List<ContentItem> items, String? calendarId}) async {
    final api = await _calendarApi();
    final id = calendarId ?? await getSavedCalendarId();
    if (id == null || id.isEmpty) {
      throw StateError('No target Google Calendar selected');
    }

    for (final item in items) {
      final date = item.datePublished ?? item.dateScheduled;
      if (date == null) continue;

      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      final eventId = _buildEventId(item);
      final event = gc.Event(
        id: eventId,
        summary: item.title.isEmpty ? 'Untitled' : item.title,
        description: _composeDescription(item),
        start: gc.EventDateTime(date: _dateOnly(startDate)),
        end: gc.EventDateTime(date: _dateOnly(endDate)),
        transparency: item.datePublished == null && item.dateScheduled != null ? 'transparent' : null,
      );

      try {
        await api.events.update(event, id, eventId);
      } catch (_) {
        try {
          await api.events.insert(event, id);
        } catch (e) {
          debugPrint('Failed to upsert event for item ${item.id}: $e');
        }
      }
    }
  }

  String _composeDescription(ContentItem item) {
    final parts = <String>[];
    if (item.description.isNotEmpty) parts.add(item.description);
    if (item.url.isNotEmpty) parts.add('Link: ${item.url}');
    if (item.videoLink.isNotEmpty) parts.add('Video: ${item.videoLink}');
    parts.add('Type: ${item.contentType.displayName}');
    return parts.join('\n\n');
  }

  String _buildEventId(ContentItem item) {
    final marker = item.datePublished != null ? 'pub' : 'sch';
    final raw = 'lb_${item.id}_$marker';
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}