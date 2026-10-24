import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/navigation.dart';
import '../../services/incoming/incoming_file.dart';
import '../../services/incoming/incoming_source.dart';
import '../../services/incoming/pdf_backend.dart';
import '../../services/incoming/saved_documents.dart';
import 'incoming_file_screen.dart';
import 'incoming_list_screen.dart';

final incomingSourceProvider = Provider<IncomingSource>((ref) => PlatformIncomingSource());

final pdfBackendProvider = Provider<PdfBackend>((ref) => const PdfxBackend());

/// Where "Save a copy" keeps documents. Overridden in main() and in tests.
final savedDocumentsProvider = Provider<SavedDocuments>((ref) {
  throw UnimplementedError('savedDocumentsProvider must be overridden');
});

class IncomingState {
  const IncomingState({this.opening = 0});

  /// Documents the phone is still copying in.
  final int opening;
}

/// Receives documents other apps open with UniMarkLy and opens the right
/// screen for them.
///
/// It only ever opens a viewer. Nothing is imported and no record is changed
/// from here: the screens it opens ask first.
class IncomingController extends Notifier<IncomingState> {
  StreamSubscription<IncomingEvent>? _sub;
  bool _started = false;
  final _recent = <String, DateTime>{};
  final _backlog = <IncomingArrived>[];

  /// Two arrivals of the same file within this time are one open, delivered
  /// twice by the system.
  @visibleForTesting
  static Duration duplicateWindow = const Duration(seconds: 4);

  @override
  IncomingState build() => const IncomingState();

  /// Starts listening, once the app can show screens. Documents that arrived
  /// earlier (the one that started the app) are handled first, in order.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final source = ref.read(incomingSourceProvider);
    _sub = source.events.listen(handle);
    ref.onDispose(() => _sub?.cancel());
    for (final event in await source.ready()) {
      handle(event);
    }
  }

  void handle(IncomingEvent event) {
    switch (event) {
      case IncomingStarted(:final count):
        state = IncomingState(opening: state.opening + count);
      case IncomingArrived():
        final done = event.files.length + event.failures.length;
        state = IncomingState(opening: math.max(0, state.opening - done));
        _deliver(event);
    }
  }

  void _deliver(IncomingArrived arrived) {
    final nav = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (nav == null || context == null) {
      // The first screen is not up yet; try again after the next frame.
      _backlog.add(arrived);
      WidgetsBinding.instance.addPostFrameCallback((_) => _flush());
      return;
    }

    final files = <IncomingFile>[];
    for (final f in arrived.files) {
      if (_isRepeat(f)) {
        deleteCopy(f);
      } else {
        files.add(f);
      }
    }

    if (files.isNotEmpty) {
      nav.push(MaterialPageRoute<void>(
        builder: (_) => files.length == 1 ? IncomingFileScreen(file: files.single) : IncomingListScreen(files: files),
      ));
    }
    // Shown after the screen is pushed, so it sits on top of it.
    if (arrived.failures.isNotEmpty) {
      showDialog<void>(context: context, builder: (_) => IncomingFailuresDialog(failures: arrived.failures));
    }
  }

  void _flush() {
    if (_backlog.isEmpty) return;
    if (navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _flush());
      return;
    }
    final pending = [..._backlog];
    _backlog.clear();
    for (final a in pending) {
      _deliver(a);
    }
  }

  bool _isRepeat(IncomingFile f) {
    final now = DateTime.now();
    _recent.removeWhere((_, t) => now.difference(t) > duplicateWindow);
    final key = '${f.name}|${f.size}';
    if (_recent.containsKey(key)) return true;
    _recent[key] = now;
    return false;
  }

  /// Deletes the private copy of an incoming document (and its folder).
  static Future<void> deleteCopy(IncomingFile f) async {
    try {
      final folder = Directory(p.dirname(f.path));
      // Only ever inside the incoming-copies folder.
      if (p.basename(p.dirname(folder.path)) == 'incoming') await folder.delete(recursive: true);
    } catch (_) {}
  }
}

final incomingProvider = NotifierProvider<IncomingController, IncomingState>(IncomingController.new);

/// "Opening 2 documents…" over whatever screen is showing.
class IncomingOverlay extends ConsumerWidget {
  const IncomingOverlay({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opening = ref.watch(incomingProvider.select((s) => s.opening));
    return Stack(
      children: [
        if (child != null) child!,
        if (opening > 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.inverseSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Theme.of(context).colorScheme.onInverseSurface),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opening == 1 ? 'Opening the document…' : 'Opening $opening documents…',
                          style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class IncomingFailuresDialog extends StatelessWidget {
  const IncomingFailuresDialog({super.key, required this.failures});

  final List<IncomingFailure> failures;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(failures.length == 1 ? 'This file could not be opened' : 'Some files could not be opened'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in failures)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name, style: Theme.of(context).textTheme.titleSmall),
                      Text(f.message),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      );
}
