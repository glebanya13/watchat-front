import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../../models/user_model.dart';
import '../../models/message.dart';
import '../../models/group.dart';
import '../../models/status_model.dart';
import '../../common/enums/message_enum.dart';

class ApiService {
  static Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    final response = await ApiClient.post('/auth/send-code', {
      'phoneNumber': phoneNumber,
    });
    
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Ошибка отправки кода: ${response.statusCode} - ${errorBody['message'] ?? response.body}');
    }
    
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyCode(String phoneNumber, String code) async {
    final response = await ApiClient.post('/auth/verify-code', {
      'phoneNumber': phoneNumber,
      'code': code,
    });
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Ошибка верификации кода');
    }
    
    final data = jsonDecode(response.body);
    return data;
  }

  // Users
  static Future<UserModel?> getCurrentUser() async {
    final response = await ApiClient.get('/users/me');
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return null;
      }
      final data = jsonDecode(response.body);
      return UserModel.fromMap(data);
    }
    if (response.statusCode == 204) {
      return null;
    }
    if (response.statusCode == 401) {
      await ApiClient.setToken(null);
    }
    return null;
  }

  static Future<UserModel> createUser(String name, String? profilePic) async {
    final token = await ApiClient.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации отсутствует');
    }
    final response = await ApiClient.post('/users', {
      'name': name,
      if (profilePic != null && profilePic.isNotEmpty) 'profilePic': profilePic,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorBody = response.body;
      String errorMessage = 'Ошибка создания пользователя: ${response.statusCode}';
      try {
        final errorData = jsonDecode(errorBody);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        errorMessage = errorBody.isNotEmpty ? errorBody : errorMessage;
      }
      throw Exception(errorMessage);
    }
    final data = jsonDecode(response.body);
    return UserModel.fromMap(data);
  }

  static Future<UserModel> updateUser(String name, String? profilePic) async {
    final response = await ApiClient.put('/users/me', {
      'name': name,
      if (profilePic != null) 'profilePic': profilePic,
    });
    final data = jsonDecode(response.body);
    return UserModel.fromMap(data);
  }

  static Future<void> setUserOnlineStatus(bool isOnline) async {
    await ApiClient.put('/users/me/online', {'isOnline': isOnline});
  }

  static Future<List<UserModel>> getAllUsers() async {
    final response = await ApiClient.get('/users/all');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UserModel.fromMap(e)).toList();
    }
    return [];
  }

  static Future<UserModel?> getUserById(String uid) async {
    final response = await ApiClient.get('/users/$uid');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromMap(data);
    }
    return null;
  }

  // Messages
  static Future<List<Map<String, dynamic>>> getChatContacts() async {
    final response = await ApiClient.get('/messages/contacts');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Message>> getChatMessages(String contactId, {int limit = 50, int offset = 0}) async {
    final response = await ApiClient.get('/messages/chat/$contactId?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Message.fromMap(e)).toList();
    }
    return [];
  }

  static Future<Message> sendMessage({
    required String? receiverId,
    required String? groupId,
    required String text,
    required MessageEnum type,
    String repliedMessage = '',
    String repliedTo = '',
    MessageEnum repliedMessageType = MessageEnum.text,
  }) async {
    final response = await ApiClient.post('/messages', {
      if (receiverId != null) 'receiverId': receiverId,
      if (groupId != null) 'groupId': groupId,
      'text': text,
      'type': type.type,
      'repliedMessage': repliedMessage,
      'repliedTo': repliedTo,
      'repliedMessageType': repliedMessageType.type,
    });
    if (response.statusCode == 403) {
      try {
        final data = jsonDecode(response.body);
        final errorMessage = data['message'] ?? 'Ваш аккаунт заблокирован. Вы не можете отправлять сообщения.';
        throw Exception(errorMessage);
      } catch (e) {
        if (e.toString().contains('заблокирован') || e.toString().contains('Blocked')) {
          rethrow;
        }
        throw Exception('Ваш аккаунт заблокирован. Вы не можете отправлять сообщения.');
      }
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Ошибка отправки сообщения');
      } catch (e) {
        throw Exception('Ошибка отправки сообщения: ${response.statusCode}');
      }
    }
    
    final data = jsonDecode(response.body);
    return Message.fromMap(data);
  }

  static Future<void> markMessageAsSeen(String messageId) async {
    await ApiClient.put('/messages/$messageId/seen', null);
  }

  // Groups
  static Future<List<Group>> getUserGroups() async {
    final response = await ApiClient.get('/groups');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Group.fromMap(e)).toList();
    }
    return [];
  }

  static Future<List<Message>> getGroupMessages(String groupId, {int limit = 50, int offset = 0}) async {
    final response = await ApiClient.get('/messages/group/$groupId?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Message.fromMap(e)).toList();
    }
    return [];
  }

  static Future<Group> createGroup(String name, String? groupPic, List<String> memberUids) async {
    final response = await ApiClient.post('/groups', {
      'name': name,
      if (groupPic != null) 'groupPic': groupPic,
      'memberUids': memberUids,
    });
    final data = jsonDecode(response.body);
    return Group.fromMap(data);
  }

  // Calls
  static Future<Map<String, dynamic>> createCall(String receiverId, String callId, bool hasDialled) async {
    final response = await ApiClient.post('/calls', {
      'receiverId': receiverId,
      'callId': callId,
      'hasDialled': hasDialled,
    });
    return jsonDecode(response.body);
  }

  static Future<void> endCall(String receiverId) async {
    await ApiClient.delete('/calls/$receiverId');
  }

  // Status
  static Future<Status> createStatus(List<String> photoUrls, {List<String>? whoCanSee}) async {
    final response = await ApiClient.post('/status', {
      'photoUrls': photoUrls,
      if (whoCanSee != null) 'whoCanSee': whoCanSee,
    });
    final data = jsonDecode(response.body);
    return Status.fromMap(data);
  }

  static Future<List<Status>> getStatuses() async {
    final response = await ApiClient.get('/status');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Status.fromMap(e)).toList();
    }
    return [];
  }

  // Files
  static Future<void> cleanupErrorMessages() async {
    await ApiClient.post('/messages/cleanup-errors', null);
  }

  static Future<String> uploadFile(List<int> fileBytes, String folder, String fileName) async {
    final encodedFolder = folder.replaceAll('/', '_');
    final url = '/files/upload/$encodedFolder';
    final streamedResponse = await ApiClient.uploadFile(url, fileName, fileBytes, 'file');
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Ошибка загрузки файла: ${response.statusCode} - ${response.body}');
    }
    final data = jsonDecode(response.body);
    final fileUrl = data['url'] as String?;
    if (fileUrl == null || fileUrl.isEmpty) {
      throw Exception('Сервер не вернул URL файла');
    }
    return '${ApiClient.baseUrl}$fileUrl';
  }
}

