import 'package:sendingnetwork_dart_sdk/src/room.dart';

class SDNWidget {
  final Room room;
  final String? creatorUserId;
  final Map<String, dynamic>? data;
  final String? id;
  final String? name;
  final String type;

  /// use [buildWidgetUrl] instead
  final String url;
  final bool waitForIframeLoad;

  SDNWidget({
    required this.room,
    this.creatorUserId,
    this.data = const {},
    this.id,
    required this.name,
    required this.type,
    required this.url,
    this.waitForIframeLoad = false,
  });

  factory SDNWidget.fromJson(Map<String, dynamic> json, Room room) => SDNWidget(
        room: room,
        creatorUserId:
            json.containsKey('creatorUserId') ? json['creatorUserId'] : null,
        data: json.containsKey('data') ? json['data'] : {},
        id: json.containsKey('id') ? json['id'] : null,
        name: json['name'],
        type: json['type'],
        url: json['url'],
        waitForIframeLoad: json.containsKey('waitForIframeLoad')
            ? json['waitForIframeLoad']
            : false,
      );

  /// creates an `m.etherpad` [SDNWidget]
  factory SDNWidget.etherpad(Room room, String name, Uri url) => SDNWidget(
        room: room,
        name: name,
        type: 'm.etherpad',
        url: url.toString(),
        data: {
          'url': url.toString(),
        },
      );

  /// creates an `m.jitsi` [SDNWidget]
  factory SDNWidget.jitsi(Room room, String name, Uri url,
          {bool isAudioOnly = false}) =>
      SDNWidget(
        room: room,
        name: name,
        type: 'm.jitsi',
        url: url.toString(),
        data: {
          'domain': url.host,
          'conferenceId': url.pathSegments.last,
          'isAudioOnly': isAudioOnly,
        },
      );

  /// creates an `m.video` [SDNWidget]
  factory SDNWidget.video(Room room, String name, Uri url) => SDNWidget(
        room: room,
        name: name,
        type: 'm.video',
        url: url.toString(),
        data: {
          'url': url.toString(),
        },
      );

  /// creates an `m.custom` [SDNWidget]
  factory SDNWidget.custom(Room room, String name, Uri url) => SDNWidget(
        room: room,
        name: name,
        type: 'm.custom',
        url: url.toString(),
        data: {
          'url': url.toString(),
        },
      );

  Future<Uri> buildWidgetUrl() async {
    // See https://github.com/sdn-org/sdn-doc/issues/1236 for a
    // description, specifically the section
    // `What does the other stuff in content mean?`
    final userProfile = await room.client.fetchOwnProfile();
    var parsedUri = url;

    // a key-value map with the strings to be replaced
    final replaceMap = {
      r'$sdn_user_id': userProfile.userId,
      r'$sdn_room_id': room.id,
      r'$sdn_display_name': userProfile.displayName ?? '',
      r'$sdn_avatar_url': userProfile.avatarUrl?.toString() ?? '',
      // removing potentially dangerous keys containing anything but
      // `[a-zA-Z0-9_-]` as well as non string values
      if (data != null)
        ...Map.from(data!)
          ..removeWhere((key, value) =>
              !RegExp(r'^[\w-]+$').hasMatch(key) || !value is String)
          ..map((key, value) => MapEntry('\$key', value)),
    };

    replaceMap.forEach((key, value) {
      parsedUri = parsedUri.replaceAll(key, Uri.encodeComponent(value));
    });

    return Uri.parse(parsedUri);
  }

  Map<String, dynamic> toJson() => {
        'creatorUserId': creatorUserId,
        'data': data,
        'id': id,
        'name': name,
        'type': type,
        'url': url,
        'waitForIframeLoad': waitForIframeLoad,
      };
}
