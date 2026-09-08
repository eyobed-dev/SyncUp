import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class FitPhotoService {
  FitPhotoService._();
  static final FitPhotoService instance = FitPhotoService._();

  final Map<String, List<String>> _photoCache = {};

  Future<List<String>> fetchRoomPhotos(String roomId) async {
    final cleanId = roomId.trim().toUpperCase();
    if (_photoCache.containsKey(cleanId)) {
      return _photoCache[cleanId]!;
    }

    try {
      final originalUrl = 'https://www.fit.vut.cz/fit/room/$cleanId/.en';
      Uri url = Uri.parse(originalUrl);

      if (kIsWeb) {
        // Use the /get endpoint which returns JSON to avoid transparent proxy issues
        final proxyUrl = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(originalUrl)}';
        url = Uri.parse(proxyUrl);
      }

      final response = await http.get(
        url,
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _photoCache[cleanId] = const [];
        return const [];
      }

      String htmlContent = response.body;
      if (kIsWeb) {
        try {
          final jsonResp = jsonDecode(response.body);
          htmlContent = jsonResp['contents'] ?? '';
        } catch (e) {
          // If it fails to parse JSON, maybe it was already raw HTML
        }
      }

      final document = html_parser.parse(htmlContent);
      final photoUrls = <String>[];

      // Find images under room photo containers or galleries
      final images = document.querySelectorAll('img');
      for (final img in images) {
        final src = img.attributes['src'];
        if (src != null &&
            (src.contains('/room/') || src.contains('mistnost') || src.contains('/fit/')) &&
            !src.endsWith('.svg') &&
            !src.contains('logo') &&
            !src.contains('icon')) {
          String fullUrl = src;
          if (fullUrl.startsWith('//')) {
            fullUrl = 'https:$fullUrl';
          } else if (fullUrl.startsWith('/')) {
            fullUrl = 'https://www.fit.vut.cz$fullUrl';
          }
          if (!photoUrls.contains(fullUrl)) {
            photoUrls.add(fullUrl);
          }
        }
      }

      _photoCache[cleanId] = photoUrls;
      return photoUrls;
    } catch (e) {
      debugPrint('Error fetching room photos for $cleanId: $e');
      _photoCache[cleanId] = const [];
      return const [];
    }
  }
}
