/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020, 2021 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:core';

import 'package:sendingnetwork_dart_sdk/src/client.dart';

extension MxcUriExtension on Uri {
  /// Returns a download Link to this content.
  Uri getDownloadLink(Client sdn) => isScheme('mxc')
      ? sdn.node != null
          ? sdn.node?.resolve(
                  '_api/media/v3/download/$host${hasPort ? ':$port' : ''}$path') ??
              Uri()
          : Uri()
      : this;

  /// Returns a scaled thumbnail link to this content with the given `width` and
  /// `height`. `method` can be `ThumbnailMethod.crop` or
  /// `ThumbnailMethod.scale` and defaults to `ThumbnailMethod.scale`.
  /// If `animated` (default false) is set to true, an animated thumbnail is requested
  /// as per MSC2705. Thumbnails only animate if the media repository supports that.
  Uri getThumbnail(Client sdn,
      {num? width,
      num? height,
      ThumbnailMethod? method = ThumbnailMethod.crop,
      bool? animated = false}) {
    if (!isScheme('mxc')) return this;
    final node = sdn.node;
    if (node == null) {
      return Uri();
    }
    return Uri(
      scheme: node.scheme,
      host: node.host,
      path: '/_api/media/v3/thumbnail/$host${hasPort ? ':$port' : ''}$path',
      port: node.port,
      queryParameters: {
        if (width != null) 'width': width.round().toString(),
        if (height != null) 'height': height.round().toString(),
        if (method != null) 'method': method.toString().split('.').last,
        if (animated != null) 'animated': animated.toString(),
      },
    );
  }
}

enum ThumbnailMethod { crop, scale }
