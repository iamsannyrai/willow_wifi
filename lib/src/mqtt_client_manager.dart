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

  factory MQTTClientManager() => _inst;

  /// must be called before connect, disconnect, subscribe or publish
  Future<void> initialize({
    required String serverEndPoint,
    required String clientIdentifier,
    required String crtFilePath,
    int port = 443,
    String? customAuthorizerName,
    Function()? onConnected,
    Function()? onDisconnected,
    Function(String? topic)? onSubscribed,
  }) async {
    _inst.serverEndpoint = serverEndPoint;
    _inst.clientIdentifier = clientIdentifier;
    _inst.port = port;
    _inst.mqttServerClient = MqttServerClient.withPort(
      serverEndPoint,
      clientIdentifier,
      port,
    );
    _inst.customAuthorizerName = customAuthorizerName;

    _inst.mqttServerClient.logging(on: true);
    _inst.mqttServerClient.keepAlivePeriod = 60;
    _inst.mqttServerClient.onConnected = onConnected;
    _inst.mqttServerClient.onDisconnected = onDisconnected;
    _inst.mqttServerClient.onSubscribed = onSubscribed;

    ByteData deviceCert = await rootBundle.load(crtFilePath);
    final context = SecurityContext.defaultContext;
    if (customAuthorizerName != null) context.setAlpnProtocols(["mqtt"], false);
    context.useCertificateChainBytes(deviceCert.buffer.asUint8List());
    _inst.mqttServerClient.securityContext = context;
    _inst.mqttServerClient.secure = true;
    //TODO  remove later
    // for testing, always return true
    _inst.mqttServerClient.onBadCertificate = (Object? e) => true;
    _inst.mqttServerClient.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean();
    _inst.mqttServerClient.connectionMessage = connMessage;
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

      await _inst.mqttServerClient.connect(userName, password);
    }
  }

  void disconnectWithBroker() {
    _inst.mqttServerClient.disconnect();
  }

  void subscribeTopic(String topic, [MqttQos qosLevel = MqttQos.exactlyOnce]) {
    _inst.mqttServerClient.subscribe(topic, qosLevel);
  }

  /// method to publish message in a [topic],
  /// [message] can be be either string or Map or List<Map>,
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
    _inst.mqttServerClient.publishMessage(topic, qosLevel, builder.payload!);
  }
}
