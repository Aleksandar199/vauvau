import 'package:flutter/widgets.dart';

import 'app_image_provider_io.dart'
    if (dart.library.html) 'app_image_provider_web.dart' as impl;

ImageProvider appImageProvider(String url) => impl.appImageProvider(url);
