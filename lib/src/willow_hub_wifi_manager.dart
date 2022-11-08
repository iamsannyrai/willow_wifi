import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:willow_ble/willow_ble.dart';

import 'esp/constants.pb.dart';
import 'esp/wifi_config.pb.dart';
import 'security0.dart';

class WillowHubWifiManager {
  final FlutterReactiveBle _ble;
  final WillowHubInteractor _willowHubInteractor;

  WillowHubWifiManager(
      FlutterReactiveBle ble, WillowHubInteractor willowHubInteractor)
      : _ble = ble,
        _willowHubInteractor = willowHubInteractor;

  Future<void> establishSession(String deviceId, Security0 sec) async {
    List<int>? resp;

    final provSession = WillowHubCharacteristic.provSession(deviceId);

    // Establish session by letting the provided security object
    // perform its handshake.
    while (true) {
      var req = sec.securityRequest(resp);
      if (req == null) {
        // No more requests to send, meaning handshake is complete.
        break;
      }
      await _ble.writeCharacteristicWithoutResponse(provSession, value: req);
      resp = await _ble.readCharacteristic(provSession);
    }
  }

  Future<Status> setWifiConfig(
      String deviceId, List<int> ssid, List<int> passphrase) async {
    var req = WiFiConfigPayload(
      msg: WiFiConfigMsgType.TypeCmdSetConfig,
      cmdSetConfig: CmdSetConfig(
        ssid: ssid,
        passphrase: passphrase,
      ),
    );

    var respData = await _willowHubInteractor.writeRead(
        WillowHubCharacteristic.provConfig(deviceId), req.writeToBuffer());
    var resp = WiFiConfigPayload.fromBuffer(respData);

    return resp.respSetConfig.status;
  }

  Future<Status> applyWifiConfig(String deviceId) async {
    var req = WiFiConfigPayload(
      msg: WiFiConfigMsgType.TypeCmdApplyConfig,
      cmdApplyConfig: CmdApplyConfig(),
    );

    var respData = await _willowHubInteractor.writeRead(
        WillowHubCharacteristic.provConfig(deviceId), req.writeToBuffer());
    var resp = WiFiConfigPayload.fromBuffer(respData);

    return resp.respApplyConfig.status;
  }

  Future<RespGetStatus> getWifiStatus(String deviceId) async {
    var req = WiFiConfigPayload(
      msg: WiFiConfigMsgType.TypeCmdGetStatus,
      cmdGetStatus: CmdGetStatus(),
    );

    var respData = await _willowHubInteractor.writeRead(
        WillowHubCharacteristic.provConfig(deviceId), req.writeToBuffer());
    var resp = WiFiConfigPayload.fromBuffer(respData);

    return resp.respGetStatus;
  }
}
