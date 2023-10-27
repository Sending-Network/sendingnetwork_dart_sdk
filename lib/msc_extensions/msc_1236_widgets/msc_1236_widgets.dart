library msc_1236_widgets;

import 'package:sendingnetwork_dart_sdk/sdn.dart';

export 'src/widget.dart';

extension SDNWidgets on Room {
  /// Returns all present Widgets in the room.
  List<SDNWidget> get widgets => {
        ...states['m.widget'] ?? states['im.vector.modular.widgets'] ?? {},
      }.values.expand((e) {
        try {
          return [SDNWidget.fromJson(e.content, this)];
        } catch (_) {
          return <SDNWidget>[];
        }
      }).toList();

  Future<String> addWidget(SDNWidget widget) {
    final user = client.userID;
    final widgetId =
        '${widget.name!.toLowerCase().replaceAll(RegExp(r'\W'), '_')}_${user!}';

    final json = widget.toJson();
    json['creatorUserId'] = user;
    json['id'] = widgetId;
    return client.setRoomStateWithKey(
      id,
      'im.vector.modular.widgets',
      widgetId,
      json,
    );
  }

  Future<String> deleteWidget(String widgetId) {
    return client.setRoomStateWithKey(
      id,
      'im.vector.modular.widgets',
      widgetId,
      {},
    );
  }
}
