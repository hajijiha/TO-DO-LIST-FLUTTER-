import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

// Keep native UI verification responsive when the test window is covered.
void enableFrameDriver() {
  enableFlutterDriverExtension(
    handler: (message) async {
      final binding = WidgetsBinding.instance;
      if (message != 'render-frame') {
        final command = jsonDecode(message ?? '') as Map<String, dynamic>;
        if (command['command'] != 'show') {
          throw ArgumentError('Unsupported verification command.');
        }
        Element? target;
        void visit(Element element) {
          if (element.widget.key ==
              ValueKey<String>(command['key'] as String)) {
            target = element;
          }
          element.visitChildElements(visit);
        }

        binding.rootElement?.visitChildElements(visit);
        if (target == null) {
          throw StateError('Verification widget is not mounted.');
        }
        await Scrollable.ensureVisible(
          target!,
          alignment: (command['alignment'] as num?)?.toDouble() ?? 0,
          duration: Duration.zero,
        );
      }
      if (binding.rootElement == null) {
        throw ArgumentError('Unsupported verification command.');
      }
      binding.scheduleWarmUpFrame();
      await binding.endOfFrame.timeout(const Duration(seconds: 5));
      return 'Frame rendered';
    },
  );
}
