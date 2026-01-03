import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:watchat/features/auth/controller/auth_controller.dart';
import 'package:watchat/features/call/repository/call_repository.dart';
import 'package:watchat/models/call.dart';

final callControllerProvider = Provider((ref) {
  final callRepository = ref.read(callRepositoryProvider);
  return CallController(
    callRepository: callRepository,
    ref: ref,
  );
});

class CallController {
  final CallRepository callRepository;
  final ProviderRef ref;
  CallController({
    required this.callRepository,
    required this.ref,
  });

  Stream<dynamic> get callStream => callRepository.callStream;

  void makeCall(BuildContext context, String receiverName, String receiverUid,
      String receiverProfilePic, bool isGroupChat) {
    ref.read(userDataAuthProvider).whenData((value) async {
      if (value == null) return;
      
      String callId = const Uuid().v1();
      Call senderCallData = Call(
        callerId: value.uid,
        callerName: value.name,
        callerPic: value.profilePic,
        receiverId: receiverUid,
        receiverName: receiverName,
        receiverPic: receiverProfilePic,
        callId: callId,
        hasDialled: true,
      );

      Call recieverCallData = Call(
        callerId: value.uid,
        callerName: value.name,
        callerPic: value.profilePic,
        receiverId: receiverUid,
        receiverName: receiverName,
        receiverPic: receiverProfilePic,
        callId: callId,
        hasDialled: false,
      );
      if (isGroupChat) {
        callRepository.makeGroupCall(senderCallData, context, recieverCallData);
      } else {
        callRepository.makeCall(senderCallData, context, recieverCallData);
      }
    });
  }

  void endCall(
    String callerId,
    String receiverId,
    BuildContext context,
  ) {
    callRepository.endCall(callerId, receiverId, context);
  }
}
