import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

import 'package:sendingnetwork_dart_sdk/sdn.dart';

class NativeImplementationsWebWorker extends NativeImplementations {
  final Worker worker;
  final Duration timeout;
  final WebWorkerStackTraceCallback onStackTrace;

  final Map<double, Completer<dynamic>> _completers = {};
  final _random = Random();

  /// the default handler for stackTraces in web workers
  static StackTrace defaultStackTraceHandler(String obfuscatedStackTrace) {
    return StackTrace.fromString(obfuscatedStackTrace);
  }

  NativeImplementationsWebWorker(
    Uri href, {
    this.timeout = const Duration(seconds: 30),
    this.onStackTrace = defaultStackTraceHandler,
  }) : worker = Worker(href.toString()) {
    worker.onMessage.listen(_handleIncomingMessage);
  }

  Future<T> operation<T, U>(WebWorkerOperations name, U argument) async {
    final label = _random.nextDouble();
    final completer = Completer<T>();
    _completers[label] = completer;
    final message = WebWorkerData(label, name, argument);
    worker.postMessage(message.toJson());

    return completer.future.timeout(timeout);
  }

  void _handleIncomingMessage(MessageEvent event) {
    final data = event.data;
    // don't forget handling errors of our second thread...
    if (data['label'] == 'stacktrace') {
      final origin = event.data['origin'];
      final completer = _completers[origin];

      final error = event.data['error']!;

      Future.value(
        onStackTrace.call(event.data['stacktrace'] as String),
      ).then(
        (stackTrace) => completer?.completeError(
          WebWorkerError(error: error, stackTrace: stackTrace),
        ),
      );
    } else {
      final response = WebWorkerData.fromJson(event.data);
      _completers[response.label]!.complete(response.data);
    }
  }

  @override
  Future<SDNImageFileResizedResponse?> calcImageMetadata(
    Uint8List bytes, {
    bool retryInDummy = false,
  }) async {
    try {
      final result = await operation<Map<dynamic, dynamic>, Uint8List>(
        WebWorkerOperations.calcImageMetadata,
        bytes,
      );
      return SDNImageFileResizedResponse.fromJson(Map.from(result));
    } catch (e, s) {
      if (!retryInDummy) {
        Logs().e(
            'Web worker computation error. Ignoring and returning null', e, s);
        return null;
      }
      Logs().e('Web worker computation error. Fallback to main thread', e, s);
      return NativeImplementations.dummy.calcImageMetadata(bytes);
    }
  }

  @override
  Future<SDNImageFileResizedResponse?> shrinkImage(
    SDNImageFileResizeArguments args, {
    bool retryInDummy = false,
  }) async {
    try {
      final result =
          await operation<Map<dynamic, dynamic>, Map<String, dynamic>>(
        WebWorkerOperations.shrinkImage,
        args.toJson(),
      );
      return SDNImageFileResizedResponse.fromJson(Map.from(result));
    } catch (e, s) {
      if (!retryInDummy) {
        Logs().e(
            'Web worker computation error. Ignoring and returning null', e, s);
        return null;
      }
      Logs().e('Web worker computation error. Fallback to main thread', e, s);
      return NativeImplementations.dummy.shrinkImage(args);
    }
  }
}

class WebWorkerData {
  final Object? label;
  final WebWorkerOperations? name;
  final Object? data;

  const WebWorkerData(this.label, this.name, this.data);

  factory WebWorkerData.fromJson(LinkedHashMap<dynamic, dynamic> data) =>
      WebWorkerData(
        data['label'],
        data.containsKey('name')
            ? WebWorkerOperations.values[data['name']]
            : null,
        data['data'],
      );

  Map<String, Object?> toJson() => {
        'label': label,
        if (name != null) 'name': name!.index,
        'data': data,
      };
}

enum WebWorkerOperations {
  shrinkImage,
  calcImageMetadata,
}

class WebWorkerError extends Error {
  /// the error thrown in the web worker. Usually a [String]
  final Object? error;

  /// de-serialized [StackTrace]
  @override
  final StackTrace stackTrace;

  WebWorkerError({required this.error, required this.stackTrace});

  @override
  String toString() {
    return '$error, $stackTrace';
  }
}

/// converts a stringifyed, obfuscated [StackTrace] into a [StackTrace]
typedef WebWorkerStackTraceCallback = FutureOr<StackTrace> Function(
    String obfuscatedStackTrace);
