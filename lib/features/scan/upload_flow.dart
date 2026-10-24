import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../domain/models.dart';
import '../../providers/providers.dart';
import '../../services/scan/image_source.dart';
import '../../services/scan/intake_service.dart';
import '../setup/course_setup_screen.dart';

enum UploadSource { camera, gallery, files }

/// The whole of "add booklet photos", from a button to photos stored and
/// queued. Returns the batch the photos went into, or null if nothing was added.
///
/// [batchId] adds to an upload already open; without it a new batch is made.
Future<String?> runUpload(
  BuildContext context,
  WidgetRef ref,
  UploadSource source, {
  String? batchId,
  String? courseId,
}) async {
  final settings = ref.read(settingsProvider);

  // Which course are these booklets for?
  var course = courseId;
  if (batchId != null) {
    course = ref.read(batchProvider(batchId))?.course.id ?? course;
  }
  if (course == null) {
    final chosen = await chooseCourse(context, ref);
    if (chosen == null || !context.mounted) return null;
    course = chosen;
  }

  // Pick the photos. A refusal (camera permission, for example) is explained.
  late final List<PickedImage> picked;
  try {
    final input = ref.read(imageSourceProvider);
    picked = switch (source) {
      UploadSource.camera => await input.takePhoto(settings.photoQuality),
      UploadSource.gallery => await input.chooseImages(settings.photoQuality),
      UploadSource.files => await input.chooseFiles(),
    };
  } catch (e) {
    if (context.mounted) {
      showMessage(
        context,
        source == UploadSource.camera
            ? 'The camera could not be opened. Allow camera access for UniMarkLy in your phone settings, or choose photos instead.'
            : 'The photos could not be opened. Allow access for UniMarkLy in your phone settings and try again.',
      );
    }
    return null;
  }
  if (picked.isEmpty || !context.mounted) return null;
  return addPhotos(context, ref, picked, courseId: course, batchId: batchId);
}

/// Stores [picked] photos in a batch of [courseId] and queues them for reading:
/// the part of "add photos" that is the same whether they came from the camera,
/// the gallery, or another app that opened them with UniMarkLy.
///
/// Photos already stored are asked about once; photos that can not be used are
/// listed with the reason. Returns the batch, or null if nothing was added.
Future<String?> addPhotos(
  BuildContext context,
  WidgetRef ref,
  List<PickedImage> picked, {
  required String courseId,
  String? batchId,
}) async {
  final scans = ref.read(scanRepositoryProvider);
  final settings = ref.read(settingsProvider);
  final course = courseId;

  final id = batchId ?? await scans.createBatch(course);
  final intake = ref.read(intakeServiceProvider);
  var report = await intake.addImages(courseId: course, batchId: id, images: picked);

  if (!context.mounted) return report.added.isEmpty ? null : id;

  // Photos already stored: ask, once, what to do with all of them.
  if (report.duplicates.isNotEmpty) {
    final addAnyway = await _askAboutDuplicates(context, report);
    if (addAnyway && context.mounted) {
      final again = await intake.addImages(
        courseId: course,
        batchId: id,
        images: [for (final d in report.duplicates) d.picked],
        addDuplicates: true,
      );
      report = IntakeReport(
        added: [...report.added, ...again.added],
        duplicates: const [],
        rejected: [...report.rejected, ...again.rejected],
      );
    }
  }

  if (!context.mounted) return report.added.isEmpty ? null : id;
  if (report.rejected.isNotEmpty) await _showRejected(context, report);

  if (report.added.isEmpty) {
    // Nothing usable went in. Do not leave an empty batch behind.
    if (batchId == null) await scans.softDeleteBatch(id);
    return null;
  }

  if (settings.readAutomatically) {
    // Reads in the background; the screen shows real progress.
    ref.read(processingProvider.notifier).start(id);
  }
  return id;
}

/// Asks which course, unless there is only one. Null if the examiner backed
/// out, or has to make a course first.
Future<String?> chooseCourse(
  BuildContext context,
  WidgetRef ref, {
  String question = 'Which course are these booklets for?',
  String createMessage = 'Booklets are filed under a course, so UniMarkLy can match each exam number to the class list. '
      'Create the course, add its class list, then come back to scan.',
}) async {
  final courses = ref.read(coursesProvider).valueOrNull ?? const <Course>[];
  if (courses.isEmpty) {
    final create = await confirm(
      context,
      title: 'Create a course first',
      message: createMessage,
      confirmLabel: 'Create a course',
    );
    if (create && context.mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseSetupScreen()));
    }
    return null;
  }
  if (courses.length == 1) return courses.single.id;

  // The course used most recently comes first.
  final recent = <String>[];
  for (final b in ref.read(batchesProvider).valueOrNull ?? const []) {
    if (!recent.contains(b.course.id)) recent.add(b.course.id);
  }
  final ordered = [
    ...courses.where((c) => recent.contains(c.id)).toList()..sort((a, b) => recent.indexOf(a.id).compareTo(recent.indexOf(b.id))),
    ...courses.where((c) => !recent.contains(c.id)),
  ];

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(question, style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final c in ordered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  minTileHeight: 64,
                  title: Text(c.title, style: Theme.of(ctx).textTheme.titleMedium),
                  subtitle: Text([if (c.session.isNotEmpty) c.session, if (c.semester.isNotEmpty) c.semester].join(' · ')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(ctx, c.id),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Future<bool> _askAboutDuplicates(BuildContext context, IntakeReport report) {
  final n = report.duplicates.length;
  final names = report.duplicates.take(3).map((d) => d.picked.name).join(', ');
  return confirm(
    context,
    title: n == 1 ? 'This photo is already added' : '$n photos are already added',
    message: '${n > 3 ? '$names and ${n - 3} more' : names} ${n == 1 ? 'is' : 'are'} already in this course. '
        'Adding the same booklet twice can count its marks twice.',
    confirmLabel: 'Add anyway',
    cancelLabel: 'Skip ${n == 1 ? 'it' : 'them'}',
  );
}

Future<void> _showRejected(BuildContext context, IntakeReport report) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(report.rejected.length == 1 ? '1 photo could not be added' : '${report.rejected.length} photos could not be added'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final r in report.rejected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: Theme.of(ctx).textTheme.titleSmall),
                      Text(r.reason),
                    ],
                  ),
                ),
              if (report.added.isNotEmpty)
                Text('${report.added.length} other ${report.added.length == 1 ? 'photo was' : 'photos were'} added.'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );

/// The three ways to add photos, as a bottom sheet: used by the centre button.
Future<void> showUploadSheet(BuildContext context, WidgetRef ref, void Function(String batchId) onAdded) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add exam booklets', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Photos stay on this phone.', style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 12),
            for (final (icon, label, hint, source) in [
              (Icons.photo_camera_rounded, 'Take photo', 'Photograph one booklet cover', UploadSource.camera),
              (Icons.photo_library_rounded, 'Choose images', 'Pick several photos from your gallery', UploadSource.gallery),
              (Icons.upload_file_rounded, 'Upload many', 'Pick image files from your phone storage', UploadSource.files),
            ])
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  minTileHeight: 68,
                  leading: Icon(icon),
                  title: Text(label, style: Theme.of(ctx).textTheme.titleMedium),
                  subtitle: Text(hint),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final id = await runUpload(context, ref, source);
                    if (id != null) onAdded(id);
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
