import 'package:flutter/widgets.dart';

/// The app's navigator, so something that happens outside any screen (another
/// app opening a document) can still open the right one.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
