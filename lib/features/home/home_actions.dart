import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/scan.dart';
import '../scan/scan_screen.dart';
import '../scan/upload_flow.dart';

/// Adds booklet photos and, once some are stored, opens the Scan & Extract
/// screen for that upload. Without a [source] the three ways are offered.
Future<void> startUpload(BuildContext context, WidgetRef ref, {UploadSource? source}) async {
  void open(String batchId) {
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ScanScreen(batchId: batchId)));
  }

  if (source == null) {
    await showUploadSheet(context, ref, open);
    return;
  }
  final id = await runUpload(context, ref, source);
  if (id != null) open(id);
}

/// "24 Oct 2026", for lists of uploads.
String shortDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// What an upload is called in a list: its title, or its course and date.
String batchName(BatchSummary b) {
  final t = b.title?.trim();
  if (t != null && t.isNotEmpty) return t;
  return '${b.course.code} · ${shortDate(b.createdAt)}';
}

/// "12 images | 8 confirmed"
String batchLine(BatchCounts c) {
  final images = '${c.images} ${c.images == 1 ? 'image' : 'images'}';
  return '$images | ${c.confirmed} confirmed';
}

/// Up to two letters from a name: "Ada Okafor" gives "AO".
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final first = parts.first.characters.first;
  final last = parts.length > 1 ? parts.last.characters.first : '';
  return (first + last).toUpperCase();
}
