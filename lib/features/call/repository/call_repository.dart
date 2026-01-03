import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchat/common/api/api_service.dart';
import 'package:watchat/common/utils/utils.dart';
import 'package:watchat/features/call/screens/call_screen.dart';
import 'package:watchat/models/call.dart';

final callRepositoryProvider = Provider(
  (ref) => CallRepository(),
);

class CallRepository {
  CallRepository();

  // Для совместимости с существующим кодом, возвращаем пустой stream
  // В будущем можно реализовать через WebSocket
  Stream<dynamic> get callStream {
    // Возвращаем пустой stream, так как звонки обрабатываются через API
    return Stream<dynamic>.empty();
  }

  void makeCall(
    Call senderCallData,
    BuildContext context,
    Call receiverCallData,
  ) async {
    try {
      await ApiService.createCall(
        senderCallData.receiverId,
        senderCallData.callId,
        senderCallData.hasDialled,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: senderCallData.callId,
            call: senderCallData,
            isGroupChat: false,
          ),
        ),
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void makeGroupCall(
    Call senderCallData,
    BuildContext context,
    Call receiverCallData,
  ) async {
    try {
      // Для групповых звонков создаем вызов для каждого участника
      await ApiService.createCall(
        senderCallData.receiverId,
        senderCallData.callId,
        senderCallData.hasDialled,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: senderCallData.callId,
            call: senderCallData,
            isGroupChat: true,
          ),
        ),
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void endCall(
    String callerId,
    String receiverId,
    BuildContext context,
  ) async {
    try {
      await ApiService.endCall(receiverId);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void endGroupCall(
    String callerId,
    String receiverId,
    BuildContext context,
  ) async {
    try {
      await ApiService.endCall(receiverId);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
