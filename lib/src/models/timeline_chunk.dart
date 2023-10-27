import 'package:sendingnetwork_dart_sdk/sdn.dart';

class TimelineChunk {
  String prevBatch; // pos of the first event of the database timeline chunk
  String nextBatch;

  List<Event> events;
  TimelineChunk(
      {required this.events, this.prevBatch = '', this.nextBatch = ''});
}
