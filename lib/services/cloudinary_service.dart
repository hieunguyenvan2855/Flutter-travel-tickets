import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic('dge9tl4hr', 'abcdef', cache: false);

  Future<String?> uploadImage(String filePath) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(filePath, folder: 'tours'),
      );
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }
}
