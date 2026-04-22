import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'dart:ui';

import 'src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Remove o # da URL no Flutter Web

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FATAL][flutter] ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('[FATAL][platform] $error');
    debugPrintStack(stackTrace: stackTrace);
    return true;
  };

  runApp(const GestorComercialApp());
}
