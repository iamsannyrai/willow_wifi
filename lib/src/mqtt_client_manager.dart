import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTClientManager {
  late String serverEndpoint;
  late String clientIdentifier;
  late int port;
  late MqttServerClient mqttServerClient;

  String get connectionState =>
      mqttServerClient.connectionStatus?.state.name ??
      MqttConnectionState.disconnected.name;
  String? customAuthorizerName;

  static final MQTTClientManager _inst = MQTTClientManager._internal();

  MQTTClientManager._internal();

  factory MQTTClientManager({
    required String serverEndPoint,
    required String clientIdentifier,
    int port = 443,
    String? customAuthorizerName,
  }) {
    _inst.serverEndpoint = serverEndPoint;
    _inst.clientIdentifier = clientIdentifier;
    _inst.port = port;
    _inst.mqttServerClient = MqttServerClient.withPort(
      serverEndPoint,
      clientIdentifier,
      port,
    );
    _inst.customAuthorizerName = customAuthorizerName;

    return _inst;
  }

  /// must be called before connect, disconnect, subscribe or publish
  Future<void> initializeWithCertificate({
    required String crtFilePath,
    Function()? onConnected,
    Function()? onDisconnected,
    Function(String? topic)? onSubscribed,
  }) async {
    mqttServerClient.logging(on: true);
    mqttServerClient.keepAlivePeriod = 60;
    mqttServerClient.onConnected = onConnected;
    mqttServerClient.onDisconnected = onDisconnected;
    mqttServerClient.onSubscribed = onSubscribed;

    ByteData deviceCert = await rootBundle.load(crtFilePath);
    final context = SecurityContext.defaultContext;
    if (customAuthorizerName != null) context.setAlpnProtocols(["mqtt"], false);
    context.useCertificateChainBytes(deviceCert.buffer.asUint8List());
    mqttServerClient.securityContext = context;
    mqttServerClient.secure = true;
    // for testing, always return true
    mqttServerClient.onBadCertificate = (Object? e) => true;
    mqttServerClient.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean();
    mqttServerClient.connectionMessage = connMessage;
  }

  Future<void> connectToBroker(
      {required String username, required String password}) async {
    if (connectionState != MqttConnectionState.connected.name) {
      String userName;
      if (customAuthorizerName != null) {
        userName =
            "$username?x-amz-customauthorizer-name=$customAuthorizerName";
      } else {
        userName = username;
      }

      await mqttServerClient.connect(userName, password);
    }
  }

  void disconnectWithBroker() {
    mqttServerClient.disconnect();
  }

  void subscribeTopic(String topic, [MqttQos qosLevel = MqttQos.exactlyOnce]) {
    mqttServerClient.subscribe(topic, qosLevel);
  }

  /// method to publish message in a [topic]
  /// [message] can be be either string or Map or List<Map>
  /// string is for command and Map or List<Map> is for data
  void publishMessage(
    String topic,
    dynamic message, [
    MqttQos qosLevel = MqttQos.exactlyOnce,
  ]) {
    final builder = MqttClientPayloadBuilder();
    if (message is Map || message is List<Map>) {
      builder.addString(jsonEncode(message));
    } else {
      builder.addString(message);
    }
    mqttServerClient.publishMessage(topic, qosLevel, builder.payload!);
  }
}
