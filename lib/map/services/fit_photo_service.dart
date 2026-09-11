/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Provides business logic and API integrations for fit_photo_service.
 */

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

import '../../services/syncup_api_client.dart';

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
        final backendUrl = SyncUpApiClient.resolveBaseUrl();
        final proxyUrl = '$backendUrl/api/v1/proxy?url=${Uri.encodeComponent(originalUrl)}';
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

      final document = html_parser.parse(htmlContent);
      final photoUrls = <String>[];

      // Find images under room photo containers or galleries
      final images = document.querySelectorAll('img');
      for (final img in images) {
        final src = img.attributes['src'];
        if (src != null &&
            (src.contains('/room/') || src.contains('mistnost') || src.contains('/fit/') || src.contains('room-photo') || src.contains('room-schema')) &&
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
            if (kIsWeb) {
              final backendUrl = SyncUpApiClient.resolveBaseUrl();
              fullUrl = '$backendUrl/api/v1/proxy?url=${Uri.encodeComponent(fullUrl)}';
            }
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
