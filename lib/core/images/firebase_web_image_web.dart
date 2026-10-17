import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViews = <String>{};

/// Renders Firebase Storage URLs with a real HTML &lt;img&gt;.
///
/// CanvasKit's [Image.network] / fetch require bucket CORS and fail with
/// `statusCode: 0` / `Failed to fetch` on localhost. Browser &lt;img&gt; tags do not.
Widget buildFirebaseWebImage({
  required String url,
  required BoxFit fit,
  Widget? placeholder,
  Widget? errorWidget,
  bool passThroughPointer = false,
}) {
  final viewType =
      'vauvau-fb-img-${url.hashCode.toRadixString(16)}-${fit.name}'
      '${passThroughPointer ? '-np' : ''}';

  if (!_registeredViews.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final img = web.HTMLImageElement()
        ..src = url
        ..draggable = false
        ..alt = '';
      img.style
        ..setProperty('width', '100%')
        ..setProperty('height', '100%')
        ..setProperty('object-fit', _cssObjectFit(fit))
        ..setProperty('object-position', 'center')
        ..setProperty('border', '0')
        ..setProperty('display', 'block');
      if (passThroughPointer) {
        // Let Flutter gestures (story taps / long press) reach the app.
        img.style.setProperty('pointer-events', 'none');
      }
      return img;
    });
    _registeredViews.add(viewType);
  }

  return HtmlElementView(viewType: viewType);
}

String _cssObjectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitWidth:
    case BoxFit.fitHeight:
    case BoxFit.scaleDown:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.cover:
      return 'cover';
  }
}
