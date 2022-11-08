Willow Wifi package used to connect willow hub to wifi and mqtt protocol

Usage:

1. Initialize WillowWifi
```dart
  final willowWifi = WillowWifi();
  willowWifi.init(ble)
```
where 'ble' is an instance of FlutterReactiveBle from flutter_reactive_ble

Now you can access to 'willowhubWifiManager' and 'willowHubMQTTManager' with
```dart
  willowWifi.willowHubWifiManager
  
  willowWifi.willowMQTTManager
```


