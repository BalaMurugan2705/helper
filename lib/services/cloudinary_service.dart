import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Uploads images to Cloudinary's free tier using an unsigned upload
/// preset, so no backend or API secret is needed from the app.
class CloudinaryService {
  static const String _cloudName = 'x62grd6n';
  static const String _uploadPreset = 'domiq_helper';

  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): $body');
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String;
    return _forceJpegDelivery(secureUrl);
  }

  /// Some picked photos (e.g. HEIC from an iPhone gallery) upload fine but
  /// can't be decoded by browsers' ImageDecoder API. Inserting an `f_jpg`
  /// transformation makes Cloudinary transcode to a plain JPEG on delivery,
  /// regardless of the original stored format.
  String _forceJpegDelivery(String secureUrl) {
    const marker = '/image/upload/';
    final index = secureUrl.indexOf(marker);
    if (index == -1) return secureUrl;
    final insertAt = index + marker.length;
    return '${secureUrl.substring(0, insertAt)}f_jpg,q_auto/${secureUrl.substring(insertAt)}';
  }
}
