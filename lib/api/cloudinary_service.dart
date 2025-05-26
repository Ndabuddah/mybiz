import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;

  CloudinaryService({required this.cloudName, required this.uploadPreset});

  // Upload image to Cloudinary and return the URL
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Verify file exists
      if (!await imageFile.exists()) {
        debugPrint('File not found: ${imageFile.path}');
        return null;
      }

      // Create upload URL
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      // Create multipart request
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Send request
      final response = await request.send();

      // Process response
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'] as String;
      } else {
        final errorResponse = await response.stream.bytesToString();
        debugPrint('Failed to upload image: ${response.statusCode}, $errorResponse');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  // Upload PDF to Cloudinary and return the URL
  Future<String?> uploadPdf(File pdfFile) async {
    try {
      if (!await pdfFile.exists()) {
        debugPrint('PDF file not found: ${pdfFile.path}');
        return null;
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');

      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = uploadPreset
            ..fields['resource_type'] = 'raw'
            ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'] as String;
      } else {
        final errorResponse = await response.stream.bytesToString();
        debugPrint('Failed to upload PDF: ${response.statusCode}, $errorResponse');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary PDF upload error: $e');
      return null;
    }
  }
}
