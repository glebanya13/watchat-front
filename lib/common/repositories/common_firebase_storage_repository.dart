import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final commonFirebaseStorageRepositoryProvider = Provider(
  (ref) => CommonFirebaseStorageRepository(
    firebaseStorage: FirebaseStorage.instance,
  ),
);

class CommonFirebaseStorageRepository {
  final FirebaseStorage firebaseStorage;
  CommonFirebaseStorageRepository({
    required this.firebaseStorage,
  });

  Future<String> storeFileToFirebase(String ref, dynamic file) async {
    UploadTask uploadTask;
    
    if (kIsWeb) {
      Uint8List fileBytes;
      String? fileName;
      
      if (file is XFile) {
        fileBytes = await file.readAsBytes();
        fileName = file.name;
      } else if (file is PlatformFile) {
        fileBytes = file.bytes ?? Uint8List(0);
        fileName = file.name;
      } else {
        throw Exception('На веб-платформе требуется XFile или PlatformFile');
      }
      
      uploadTask = firebaseStorage.ref().child(ref).putData(
        fileBytes,
        SettableMetadata(contentType: _getContentType(ref, fileName)),
      );
    } else {
      if (file is File) {
        uploadTask = firebaseStorage.ref().child(ref).putFile(file);
      } else {
        throw Exception('На мобильных платформах требуется File');
      }
    }
    
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }
  
  String? _getContentType(String path, [String? fileName]) {
    String checkString = fileName ?? path;
    if (checkString.toLowerCase().endsWith('.jpg') || 
        checkString.toLowerCase().endsWith('.jpeg') ||
        checkString.contains('image')) {
      return 'image/jpeg';
    } else if (checkString.toLowerCase().endsWith('.png')) {
      return 'image/png';
    } else if (checkString.toLowerCase().endsWith('.gif')) {
      return 'image/gif';
    } else if (checkString.toLowerCase().endsWith('.mp4') ||
               checkString.toLowerCase().endsWith('.mov') ||
               checkString.contains('video')) {
      return 'video/mp4';
    } else if (checkString.toLowerCase().endsWith('.mp3') ||
               checkString.toLowerCase().endsWith('.aac') ||
               checkString.contains('audio')) {
      return 'audio/mpeg';
    } else if (checkString.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    } else if (checkString.toLowerCase().endsWith('.doc') ||
               checkString.toLowerCase().endsWith('.docx')) {
      return 'application/msword';
    }
    return null;
  }
}
