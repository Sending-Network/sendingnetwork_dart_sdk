
### 1) import sdk

```
import 'package:sendingnetwork_dart_sdk/sdn.dart';
```


### 2) Create a client and fill in the domain name of the server

```
final client = Client('SDN Example Chat', databaseBuilder: (_) async {
final dir = await getApplicationSupportDirectory();
final db = HiveCollectionsDatabase('sdn_example_chat', dir.path);
await db. open();
return db;
});
client.sdnnode = Uri.parse('https://XXX.network'); // The domain name of the node
  
```

## 2. Interface

Please refer to our gitbook for detailed API docuemntation:
https://sending-network.gitbook.io/sending.network/sdk-documentation/flutter-sdk