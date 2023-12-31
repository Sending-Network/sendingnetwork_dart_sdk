import 'dart:async';
import 'dart:typed_data';

import 'package:sendingnetwork_dart_sdk/encryption.dart';
import 'package:sendingnetwork_dart_sdk/sdn.dart';
import 'package:sendingnetwork_dart_sdk/src/utils/compute_callback.dart';

/// provides native implementations for demanding arithmetic operations
/// in order to prevent the UI from blocking
///
/// possible implementations might be:
/// - native code
/// - another Dart isolate
/// - a web worker
/// - a dummy implementations
///
/// Rules for extension (important for [noSuchMethod] implementations)
/// - always only accept exactly *one* positioned argument
/// - catch the corresponding case in [NativeImplementations.noSuchMethod]
/// - always write a dummy implementations
abstract class NativeImplementations {
  const NativeImplementations();

  /// a dummy implementation executing all calls in the same thread causing
  /// the UI to likely freeze
  static const dummy = NativeImplementationsDummy();

  FutureOr<RoomKeys> generateUploadKeys(
    GenerateUploadKeysArgs args, {
    bool retryInDummy = true,
  });

  FutureOr<Uint8List> keyFromPassphrase(
    KeyFromPassphraseArgs args, {
    bool retryInDummy = true,
  });

  FutureOr<Uint8List?> decryptFile(
    EncryptedFile file, {
    bool retryInDummy = true,
  });

  FutureOr<SDNImageFileResizedResponse?> shrinkImage(
    SDNImageFileResizeArguments args, {
    bool retryInDummy = false,
  });

  FutureOr<SDNImageFileResizedResponse?> calcImageMetadata(
    Uint8List bytes, {
    bool retryInDummy = false,
  });

  @override

  /// this implementation will catch any non-implemented method
  dynamic noSuchMethod(Invocation invocation) {
    final dynamic argument = invocation.positionalArguments.single;
    final memberName = invocation.memberName.toString().split('"')[1];

    Logs().d(
      'Missing implementations of Client.nativeImplementations.$memberName. '
      'You should consider implementing it. '
      'Fallback from NativeImplementations.dummy used.',
    );
    switch (memberName) {
      case 'generateUploadKeys':
        return dummy.generateUploadKeys(argument);
      case 'keyFromPassphrase':
        return dummy.keyFromPassphrase(argument);
      case 'decryptFile':
        return dummy.decryptFile(argument);
      case 'shrinkImage':
        return dummy.shrinkImage(argument);
      case 'calcImageMetadata':
        return dummy.calcImageMetadata(argument);
      default:
        return super.noSuchMethod(invocation);
    }
  }
}

class NativeImplementationsDummy extends NativeImplementations {
  const NativeImplementationsDummy();

  @override
  Future<Uint8List?> decryptFile(
    EncryptedFile file, {
    bool retryInDummy = true,
  }) {
    return decryptFileImplementation(file);
  }

  @override
  Future<RoomKeys> generateUploadKeys(
    GenerateUploadKeysArgs args, {
    bool retryInDummy = true,
  }) async {
    return generateUploadKeysImplementation(args);
  }

  @override
  Future<Uint8List> keyFromPassphrase(
    KeyFromPassphraseArgs args, {
    bool retryInDummy = true,
  }) {
    return generateKeyFromPassphrase(args);
  }

  @override
  SDNImageFileResizedResponse? shrinkImage(
    SDNImageFileResizeArguments args, {
    bool retryInDummy = false,
  }) {
    return SDNImageFile.resizeImplementation(args);
  }

  @override
  SDNImageFileResizedResponse? calcImageMetadata(
    Uint8List bytes, {
    bool retryInDummy = false,
  }) {
    return SDNImageFile.calcMetadataImplementation(bytes);
  }
}

/// a [NativeImplementations] based on Flutter's `compute` function
///
/// this implementations simply wraps the given [compute] function around
/// the implementation of [NativeImplementations.dummy]
class NativeImplementationsIsolate extends NativeImplementations {
  /// pass by Flutter's compute function here
  final ComputeCallback compute;

  NativeImplementationsIsolate(this.compute);

  /// creates a [NativeImplementationsIsolate] based on a [ComputeRunner] as
  // ignore: deprecated_member_use_from_same_package
  /// known from [Client.runInBackground]
  factory NativeImplementationsIsolate.fromRunInBackground(
      ComputeRunner runInBackground) {
    return NativeImplementationsIsolate(
      computeCallbackFromRunInBackground(runInBackground),
    );
  }

  Future<T> runInBackground<T, U>(
      FutureOr<T> Function(U arg) function, U arg) async {
    final compute = this.compute;
    return await compute(function, arg);
  }

  @override
  Future<Uint8List?> decryptFile(
    EncryptedFile file, {
    bool retryInDummy = true,
  }) {
    return runInBackground<Uint8List?, EncryptedFile>(
      NativeImplementations.dummy.decryptFile,
      file,
    );
  }

  @override
  Future<RoomKeys> generateUploadKeys(
    GenerateUploadKeysArgs args, {
    bool retryInDummy = true,
  }) async {
    return runInBackground<RoomKeys, GenerateUploadKeysArgs>(
      NativeImplementations.dummy.generateUploadKeys,
      args,
    );
  }

  @override
  Future<Uint8List> keyFromPassphrase(
    KeyFromPassphraseArgs args, {
    bool retryInDummy = true,
  }) {
    return runInBackground<Uint8List, KeyFromPassphraseArgs>(
      NativeImplementations.dummy.keyFromPassphrase,
      args,
    );
  }

  @override
  Future<SDNImageFileResizedResponse?> shrinkImage(
    SDNImageFileResizeArguments args, {
    bool retryInDummy = false,
  }) {
    return runInBackground<SDNImageFileResizedResponse?,
        SDNImageFileResizeArguments>(
      NativeImplementations.dummy.shrinkImage,
      args,
    );
  }

  @override
  FutureOr<SDNImageFileResizedResponse?> calcImageMetadata(
    Uint8List bytes, {
    bool retryInDummy = false,
  }) {
    return runInBackground<SDNImageFileResizedResponse?, Uint8List>(
      NativeImplementations.dummy.calcImageMetadata,
      bytes,
    );
  }
}
