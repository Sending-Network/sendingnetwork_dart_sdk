/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2020, 2021 Famedly GmbH
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

/// Workaround until [File] in dart:io and dart:html is unified

import 'dart:async';
import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:image/image.dart';
import 'package:mime/mime.dart';

import 'package:sendingnetwork_dart_sdk/sdn.dart';
import 'package:sendingnetwork_dart_sdk/src/utils/compute_callback.dart';

class SDNFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  /// Encrypts this file and returns the
  /// encryption information as an [EncryptedFile].
  Future<EncryptedFile> encrypt() async {
    return await encryptFile(bytes);
  }

  SDNFile({required this.bytes, required String name, String? mimeType})
      : mimeType = mimeType ??
            lookupMimeType(name, headerBytes: bytes) ??
            'application/octet-stream',
        name = name.split('/').last;

  /// derivatives the MIME type from the [bytes] and correspondingly creates a
  /// [SDNFile], [SDNImageFile], [SDNAudioFile] or a [SDNVideoFile]
  factory SDNFile.fromMimeType(
      {required Uint8List bytes, required String name, String? mimeType}) {
    final msgType = msgTypeFromMime(mimeType ??
        lookupMimeType(name, headerBytes: bytes) ??
        'application/octet-stream');
    if (msgType == MessageTypes.Image) {
      return SDNImageFile(bytes: bytes, name: name, mimeType: mimeType);
    }
    if (msgType == MessageTypes.Video) {
      return SDNVideoFile(bytes: bytes, name: name, mimeType: mimeType);
    }
    if (msgType == MessageTypes.Audio) {
      return SDNAudioFile(bytes: bytes, name: name, mimeType: mimeType);
    }
    return SDNFile(bytes: bytes, name: name, mimeType: mimeType);
  }

  int get size => bytes.length;

  String get msgType {
    return msgTypeFromMime(mimeType);
  }

  Map<String, dynamic> get info => ({
        'mimetype': mimeType,
        'size': size,
      });

  static String msgTypeFromMime(String mimeType) {
    if (mimeType.toLowerCase().startsWith('image/')) {
      return MessageTypes.Image;
    }
    if (mimeType.toLowerCase().startsWith('video/')) {
      return MessageTypes.Video;
    }
    if (mimeType.toLowerCase().startsWith('audio/')) {
      return MessageTypes.Audio;
    }
    return MessageTypes.File;
  }
}

class SDNImageFile extends SDNFile {
  SDNImageFile({
    required Uint8List bytes,
    required String name,
    String? mimeType,
    int? width,
    int? height,
    this.blurhash,
  })  : _width = width,
        _height = height,
        super(bytes: bytes, name: name, mimeType: mimeType);

  /// Creates a new image file and calculates the width, height and blurhash.
  static Future<SDNImageFile> create({
    required Uint8List bytes,
    required String name,
    String? mimeType,
    @Deprecated('Use [nativeImplementations] instead') ComputeRunner? compute,
    NativeImplementations nativeImplementations = NativeImplementations.dummy,
  }) async {
    if (compute != null) {
      nativeImplementations =
          NativeImplementationsIsolate.fromRunInBackground(compute);
    }
    final metaData = await nativeImplementations.calcImageMetadata(bytes);

    return SDNImageFile(
      bytes: metaData?.bytes ?? bytes,
      name: name,
      mimeType: mimeType,
      width: metaData?.width,
      height: metaData?.height,
      blurhash: metaData?.blurhash,
    );
  }

  /// Builds a [SDNImageFile] and shrinks it in order to reduce traffic.
  /// If shrinking does not work (e.g. for unsupported MIME types), the
  /// initial image is preserved without shrinking it.
  static Future<SDNImageFile> shrink({
    required Uint8List bytes,
    required String name,
    int maxDimension = 1600,
    String? mimeType,
    Future<SDNImageFileResizedResponse?> Function(SDNImageFileResizeArguments)?
        customImageResizer,
    @Deprecated('Use [nativeImplementations] instead') ComputeRunner? compute,
    NativeImplementations nativeImplementations = NativeImplementations.dummy,
  }) async {
    if (compute != null) {
      nativeImplementations =
          NativeImplementationsIsolate.fromRunInBackground(compute);
    }
    final image = SDNImageFile(name: name, mimeType: mimeType, bytes: bytes);

    return await image.generateThumbnail(
            dimension: maxDimension,
            customImageResizer: customImageResizer,
            nativeImplementations: nativeImplementations) ??
        image;
  }

  int? _width;

  /// returns the width of the image
  int? get width => _width;

  int? _height;

  /// returns the height of the image
  int? get height => _height;

  /// If the image size is null, allow us to update it's value.
  void setImageSizeIfNull({required int? width, required int? height}) {
    _width ??= width;
    _height ??= height;
  }

  /// generates the blur hash for the image
  final String? blurhash;

  @override
  String get msgType => 'm.image';

  @override
  Map<String, dynamic> get info => ({
        ...super.info,
        if (width != null) 'w': width,
        if (height != null) 'h': height,
        if (blurhash != null) 'xyz.amorgan.blurhash': blurhash,
      });

  /// Computes a thumbnail for the image.
  /// Also sets height and width on the original image if they were unset.
  Future<SDNImageFile?> generateThumbnail({
    int dimension = Client.defaultThumbnailSize,
    Future<SDNImageFileResizedResponse?> Function(SDNImageFileResizeArguments)?
        customImageResizer,
    @Deprecated('Use [nativeImplementations] instead') ComputeRunner? compute,
    NativeImplementations nativeImplementations = NativeImplementations.dummy,
  }) async {
    if (compute != null) {
      nativeImplementations =
          NativeImplementationsIsolate.fromRunInBackground(compute);
    }
    final arguments = SDNImageFileResizeArguments(
      bytes: bytes,
      maxDimension: dimension,
      fileName: name,
      calcBlurhash: true,
    );
    final resizedData = customImageResizer != null
        ? await customImageResizer(arguments)
        : await nativeImplementations.shrinkImage(arguments);

    if (resizedData == null) {
      return null;
    }

    // we should take the opportunity to update the image dimension
    setImageSizeIfNull(
        width: resizedData.originalWidth, height: resizedData.originalHeight);

    // the thumbnail should rather return null than the enshrined image
    if (resizedData.width > dimension || resizedData.height > dimension) {
      return null;
    }

    final thumbnailFile = SDNImageFile(
      bytes: resizedData.bytes,
      name: name,
      mimeType: mimeType,
      width: resizedData.width,
      height: resizedData.height,
      blurhash: resizedData.blurhash,
    );
    return thumbnailFile;
  }

  /// you would likely want to use [NativeImplementations] and
  /// [Client.nativeImplementations] instead
  static SDNImageFileResizedResponse? calcMetadataImplementation(
      Uint8List bytes) {
    final image = decodeImage(bytes);
    if (image == null) return null;

    return SDNImageFileResizedResponse(
      bytes: bytes,
      width: image.width,
      height: image.height,
      blurhash: BlurHash.encode(
        image,
        numCompX: 4,
        numCompY: 3,
      ).hash,
    );
  }

  /// you would likely want to use [NativeImplementations] and
  /// [Client.nativeImplementations] instead
  static SDNImageFileResizedResponse? resizeImplementation(
      SDNImageFileResizeArguments arguments) {
    final image = decodeImage(arguments.bytes);

    final resized = copyResize(image!,
        height: image.height > image.width ? arguments.maxDimension : null,
        width: image.width >= image.height ? arguments.maxDimension : null);

    final encoded = encodeNamedImage(arguments.fileName, resized);
    if (encoded == null) return null;
    final bytes = Uint8List.fromList(encoded);
    return SDNImageFileResizedResponse(
      bytes: bytes,
      width: resized.width,
      height: resized.height,
      originalHeight: image.height,
      originalWidth: image.width,
      blurhash: arguments.calcBlurhash
          ? BlurHash.encode(
              resized,
              numCompX: 4,
              numCompY: 3,
            ).hash
          : null,
    );
  }
}

class SDNImageFileResizedResponse {
  final Uint8List bytes;
  final int width;
  final int height;
  final String? blurhash;

  final int? originalHeight;
  final int? originalWidth;

  const SDNImageFileResizedResponse({
    required this.bytes,
    required this.width,
    required this.height,
    this.originalHeight,
    this.originalWidth,
    this.blurhash,
  });

  factory SDNImageFileResizedResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      SDNImageFileResizedResponse(
        bytes: Uint8List.fromList(
            (json['bytes'] as Iterable<dynamic>).whereType<int>().toList()),
        width: json['width'],
        height: json['height'],
        originalHeight: json['originalHeight'],
        originalWidth: json['originalWidth'],
        blurhash: json['blurhash'],
      );

  Map<String, dynamic> toJson() => {
        'bytes': bytes,
        'width': width,
        'height': height,
        if (blurhash != null) 'blurhash': blurhash,
        if (originalHeight != null) 'originalHeight': originalHeight,
        if (originalWidth != null) 'originalWidth': originalWidth,
      };
}

class SDNImageFileResizeArguments {
  final Uint8List bytes;
  final int maxDimension;
  final String fileName;
  final bool calcBlurhash;

  const SDNImageFileResizeArguments({
    required this.bytes,
    required this.maxDimension,
    required this.fileName,
    required this.calcBlurhash,
  });

  factory SDNImageFileResizeArguments.fromJson(Map<String, dynamic> json) =>
      SDNImageFileResizeArguments(
        bytes: json['bytes'],
        maxDimension: json['maxDimension'],
        fileName: json['fileName'],
        calcBlurhash: json['calcBlurhash'],
      );

  Map<String, Object> toJson() => {
        'bytes': bytes,
        'maxDimension': maxDimension,
        'fileName': fileName,
        'calcBlurhash': calcBlurhash,
      };
}

class SDNVideoFile extends SDNFile {
  final int? width;
  final int? height;
  final int? duration;

  SDNVideoFile(
      {required Uint8List bytes,
      required String name,
      String? mimeType,
      this.width,
      this.height,
      this.duration})
      : super(bytes: bytes, name: name, mimeType: mimeType);

  @override
  String get msgType => 'm.video';

  @override
  Map<String, dynamic> get info => ({
        ...super.info,
        if (width != null) 'w': width,
        if (height != null) 'h': height,
        if (duration != null) 'duration': duration,
      });
}

class SDNAudioFile extends SDNFile {
  final int? duration;

  SDNAudioFile(
      {required Uint8List bytes,
      required String name,
      String? mimeType,
      this.duration})
      : super(bytes: bytes, name: name, mimeType: mimeType);

  @override
  String get msgType => 'm.audio';

  @override
  Map<String, dynamic> get info => ({
        ...super.info,
        if (duration != null) 'duration': duration,
      });
}

extension ToSDNFile on EncryptedFile {
  SDNFile toSDNFile() {
    return SDNFile.fromMimeType(bytes: data, name: 'crypt');
  }
}
