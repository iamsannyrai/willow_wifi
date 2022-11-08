import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:willow_ble/willow_ble.dart';

import 'willow_hub_mqtt_manager.dart';
import 'willow_hub_wifi_manager.dart';

class WillowWifi {
  static final WillowWifi _willowWifi = WillowWifi._internal();

  factory WillowWifi() {
    return _willowWifi;
  }

  WillowWifi._internal();

  late WillowHubWifiManager willowHubWifiManager;
  late WillowHubMQTTManager willowHubMQTTManager;

  /// init function initializes hub interactor, hub wifi manager and hubMqtt manager
  void init(FlutterReactiveBle ble) {
    final hubInteractor = WillowHubInteractor(ble);
    willowHubWifiManager = WillowHubWifiManager(ble, hubInteractor);
    willowHubMQTTManager = WillowHubMQTTManager(hubInteractor);
  }
}
