import 'dart:async';

import 'package:flutter/services.dart';

import 'incoming_file.dart';

/// Where documents from other apps come from. An interface so tests can supply
/// documents without a phone.
abstract class IncomingSource {
  /// Documents that arrive while the app is running.
  Stream<IncomingEvent> get events;

  /// Called once, when the app can show things. Returns what arrived before
  /// then (the document that started the app, for example), in order.
  Future<List<IncomingEvent>> ready();
}

/// The Android and iOS side of the app (MainActivity, AppDelegate) copies each
/// document into the app's private cache and reports it through this channel.
class PlatformIncomingSource implements IncomingSource {
  PlatformIncomingSource() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const _channel = MethodChannel('com.nassaracoretech.unimarkly/incoming');
  final _events = StreamController<IncomingEvent>.broadcast();

  @override
  Stream<IncomingEvent> get events => _events.stream;

  @override
  Future<List<IncomingEvent>> ready() async {
    try {
      final held = await _channel.invokeMethod<List<Object?>>('ready') ?? const [];
      return [for (final raw in held) ?parse(raw)];
    } on MissingPluginException {
      return const []; // desktop, or a test: nothing can arrive
    } on PlatformException {
      return const [];
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method == 'event') {
      final event = parse(call.arguments);
      if (event != null) _events.add(event);
    }
    return null;
  }

  /// Reads one event as the platform code writes it.
  static IncomingEvent? parse(Object? raw) {
    if (raw is! Map) return null;
    switch (raw['type']) {
      case 'started':
        return IncomingStarted((raw['count'] as num?)?.toInt() ?? 1);
      case 'files':
        return IncomingArrived(
          files: [
            for (final f in (raw['files'] as List? ?? const []))
              if (f is Map) IncomingFile.fromMap(f),
          ],
          failures: [
            for (final f in (raw['failures'] as List? ?? const []))
              if (f is Map) IncomingFailure.fromMap(f),
          ],
        );
    }
    return null;
  }
}
