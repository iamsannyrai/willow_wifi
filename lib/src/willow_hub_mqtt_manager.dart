import 'package:willow_ble/willow_ble.dart';

class WillowHubMQTTManager {
  final WillowHubInteractor _willowHubInteractor;

  WillowHubMQTTManager(WillowHubInteractor willowHubInteractor)
      : _willowHubInteractor = willowHubInteractor;

  Future<String> setHubConfig(
      {required String deviceId,
      required String mqttClientId,
      required String mqttPassword,
      required String mqttBroker}) async {
    var req = "user=$mqttClientId\n"
        "passwd=$mqttPassword\n"
        "broker=$mqttBroker\n";

    var resp = await _willowHubInteractor.writeReadString(
        WillowHubCharacteristic.hubConfig(deviceId), req);

    return resp;
  }
}
