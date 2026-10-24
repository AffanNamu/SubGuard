import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Every record in every table gets a UUID, so changes made on several
/// devices can merge when sync is added.
String newId() => _uuid.v4();
