// lib/core/network/cloudinary_service.dart
// ──────────────────────────────────────────────────────────────────
// Photo upload service for Jagruk Durbe.
//
// All uploads route through the backend's /uploads/photo endpoint, which:
//   - Authenticates the user via JWT bearer token
//   - Validates MIME type and file size
//   - Runs an NSFW classifier (NudeNet) and rejects inappropriate content
//   - Uploads the cleared image to Cloudinary on the server side
//   - Returns the secure CDN URL
//
// Class name kept as CloudinaryService for backward compatibility
// with existing callers — only the implementation has changed.
// ──────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';                                    // ✅ NEW — for MediaType

// ⚠️ Adjust these import paths if your project structure differs:
import '../constants/app_constants.dart';                                        // for AppConstants.baseUrl
import 'api_service.dart';                                                       // for ApiService.getToken()

class CloudinaryService {

  static const String _uploadEndpoint = '/uploads/photo';

  // ──────────────────────────────────────────────────────────────
  // Upload a single image file via the backend NSFW filter.
  //
  // Returns the secure HTTPS URL on success.
  // Throws an Exception on any failure — including NSFW rejection.
  // The Exception's message is user-safe and can be shown directly
  // (e.g., "This image cannot be uploaded — it contains inappropriate content.").
  // ──────────────────────────────────────────────────────────────
  static Future<String> uploadImage(File imageFile) async {
    try {
      // ✅ Get JWT token for authenticated upload
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Login required to upload photos.');
      }

      final uri = Uri.parse('${AppConstants.baseUrl}$_uploadEndpoint');

      // ✅ Detect MIME from file extension and set it explicitly.
      // Without this, Android sometimes sends application/octet-stream,
      // which the backend's MIME whitelist rejects.
      final ext = imageFile.path.split('.').last.toLowerCase();
      String mimeType;
      if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'webp') {
        mimeType = 'image/webp';
      } else {
        mimeType = 'image/jpeg';                                                  // jpg / jpeg / unknown → default
      }

      // ✅ Build multipart request — binary upload, explicit content-type
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),                                 // ✅ NEW
        ),
      );

      // ✅ Send with a generous timeout.
      // First upload after backend startup may take up to ~30s
      // (NudeNet model loads lazily on first request).
      // All subsequent uploads complete in <2s.
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception(
            'Upload timed out. Check your internet connection.'),
      );

      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      }

      // Non-200: backend returns {"detail": "..."} with a user-friendly message.
      String message;
      try {
        final body = jsonDecode(response.body);
        message = body['detail']?.toString() ?? 'Upload failed (${response.statusCode}).';
      } catch (_) {
        message = 'Upload failed (${response.statusCode}).';
      }
      throw Exception(message);

    } catch (e) {
      // Preserve original Exception messages so UI shows the right text.
      if (e is Exception) rethrow;
      throw Exception('Photo upload failed: $e');
    }
  }
}
