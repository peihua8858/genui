// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:genui/genui.dart';
import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart' as gl;
import 'package:logging/logging.dart';

import 'ai_client.dart';
import 'package:genui/parsing.dart';
import 'dart:convert';
import 'package:dartantic_ai/src/chat_models/google_chat/google_message_mappers.dart';

class FakeAiClient implements AiClient {
  FakeAiClient({required this.transport});

  final Transport transport;
  final _errorController = StreamController<Object>.broadcast();

  Stream<Object> get errorStream => _errorController.stream;

  Completer<void>? sendRequestCompleter;
  final _assetImageCatalogPath = 'assets/hainan_response2.json';
  final Logger _logger = genUiLogger;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
    Map<String, Object?>? clientDataModel,
    CancellationSignal? cancellationSignal,
  }) async {
    var chunkCount = 0;
    _logger.info('sendRequest>>>>>Received Google stream chunk $chunkCount');
    _fakeResponse();
    // final streams = _fakeGenerateContentResponse();
    // final chatResults = streams.map((response) {
    //   chunkCount++;
    //   _logger.info('sendRequest>>>>Received Google stream chunk $chunkCount');
    //   return response.toChatResult("model");
    // });
    // _logger.info('sendRequest>>>>>Received Google stream chatResults.length ${chatResults.length}');
    // await for (final chatResult in chatResults) {
    //   addTextResponse(chatResult.output.text);
    // }
  }

  void addA2uiMessage(A2uiMessage message) {
    transport.addMessage(message);
  }

  void addTextResponse(String text) {
    _logger.info('addTextResponse>>>>Received chunk:${text}');
    transport.addChunk(text);
  }

  void addError(Object error) {
    _errorController.add(error);
  }

  @override
  void dispose() {
    _errorController.close();
  }

  Future<void> _fakeResponse1() async {
    final streams = _fakeGenerateContentResponse();
    await for (final response in streams) {
      final chatResult = response.toChatResult("model");
      _logger.info('sendRequest>>>>Received Google stream chunk:${chatResult}');
      final content = chatResult.output.text;
      if (content.contains("``json")) {
        addTextResponse(chatResult.output.text);
      } else {
        final chars = content.characters.toList();
        for (final content in chars) {
          addTextResponse(content);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  }

  ///
  /// 模拟测试数据
  ///
  Stream<gl.GenerateContentResponse> _fakeGenerateContentResponse() async* {
    await for (final String line in assetFakeJson()) {
      yield gl.GenerateContentResponse.fromJson(jsonDecode(line));
    }
  }

  /// Loads the asset image catalog from the asset bundle and prepends the asset
  /// path to the image file names.
  Stream<String> assetFakeJson() async* {
    var index = 0;
    _logger.info("assetFakeJson: >>>>>>$_assetImageCatalogPath");
    final result = Stream.fromFuture(rootBundle.loadString(_assetImageCatalogPath));
    final lines = result.transform(const LineSplitter());
    await for (final String line in lines) {
      _logger.info("assetFakeJson: $line");
      if (line.isEmpty) {
        continue;
      }
      if (index > 0) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      index++;
      yield line;
    }
  }

  Future<void> _fakeResponse() async {
    final text =
        "您好！很高兴能为您规划海南之旅。海南是一个充满热带风情的地方，无论是想在三亚的沙滩上放松，还是去万宁冲浪，亦或是探索海口的古老街巷，都能找到适合您的旅行方式。\n\n为了更好地开始，我们可以先看看您对哪种类型的海南之旅最感兴趣：\n\n```json\n{\n  \"createSurface\": {\n    \"surfaceId\": \"hainan_inspiration\",\n    \"catalogId\": \"https://a2ui.org/specification/v0_9/standard_catalog.json\",\n    \"sendDataModel\": true\n  }\n}\n```\n\n```json\n{\n  \"updateComponents\": {\n    \"surfaceId\": \"hainan_inspiration\",\n    \"components\": [\n      {\n        \"id\": \"root\",\n        \"component\": \"Column\",\n        \"children\": [\n          \"inspiration_title\",\n          \"inspiration_carousel\",\n          \"destination_heading\",\n          \"destination_trailhead\"\n        ]\n      },\n      {\n        \"id\": \"inspiration_title\",\n        \"component\": \"Text\",\n        \"text\": \"开启您的海南之旅\",\n        \"variant\": \"h2\"\n      },\n      {\n        \"id\": \"inspiration_carousel\",\n        \"component\": \"TravelCarousel\",\n        \"title\": \"选择您的旅行风格\",\n        \"items\": [\n          {\n            \"description\": \"三亚：悠闲的海滩度假与高端酒店享受\",\n            \"imageChildId\": \"sanya_beach_img\",\n            \"action\": {\n              \"event\": {\n                \"name\": \"select_inspiration\",\n                \"context\": {\n                  \"style\": \"beach_luxury\",\n                  \"location\": \"Sanya\"\n                }\n              }\n            }\n          },\n          {\n            \"description\": \"万宁：动感的冲浪体验与最美滨海公路\",\n            \"imageChildId\": \"wanning_surf_img\",\n            \"action\": {\n              \"event\": {\n                \"name\": \"select_inspiration\",\n                \"context\": {\n                  \"style\": \"adventure_surf\",\n                  \"location\": \"Wanning\"\n                }\n              }\n            }\n          },\n          {\n            \"description\": \"海口：感受骑楼老街的南洋文化与地道美食\",\n            \"imageChildId\": \"haikou_culture_img\",\n            \"action\": {\n              \"event\": {\n                \"name\": \"select_inspiration\",\n                \"context\": {\n                  \"style\": \"culture_food\",\n                  \"location\": \"Haikou\"\n                }\n              }\n            }\n          },\n          {\n            \"description\": \"中部雨林：探索呀诺达热带雨林的自然奥秘\",\n            \"imageChildId\": \"rainforest_img\",\n            \"action\": {\n              \"event\": {\n                \"name\": \"select_inspiration\",\n                \"context\": {\n                  \"style\": \"nature_exploration\",\n                  \"location\": \"Central Hainan\"\n                }\n              }\n            }\n          }\n        ]\n      },\n      {\n        \"id\": \"sanya_beach_img\",\n        \"component\": \"Image\",\n        \"url\": \"assets/travel_images/kata_noi_beach_phuket_thailand.jpg\",\n        \"variant\": \"mediumFeature\",\n        \"fit\": \"cover\"\n      },\n      {\n        \"id\": \"wanning_surf_img\",\n        \"component\": \"Image\",\n        \"url\": \"assets/travel_images/promthep_cape_phuket_thailand.jpg\",\n        \"variant\": \"mediumFeature\",\n        \"fit\": \"cover\"\n      },\n      {\n        \"id\": \"haikou_culture_img\",\n        \"component\": \"Image\",\n        \"url\": \"assets/travel_images/temple_of_heaven_beijing_china.jpg\",\n        \"variant\": \"mediumFeature\",\n        \"fit\": \"cover\"\n      },\n      {\n        \"id\": \"rainforest_img\",\n        \"component\": \"Image\",\n        \"url\": \"assets/travel_images/jedediah_smith_redwoods_california.jpg\",\n        \"variant\": \"mediumFeature\",\n        \"fit\": \"cover\"\n      },\n      {\n        \"id\": \"destination_heading\",\n        \"component\": \"Text\",\n        \"text\": \"准备好开始规划了吗？\",\n        \"variant\": \"h3\"\n      },\n      {\n        \"id\": \"destination_trailhead\",\n        \"component\": \"Trailhead\",\n        \"topics\": [\n          \"为我规划三亚5天行程\",\n          \"万宁冲浪环岛游建议\",\n          \"海口吃货3日攻略\",\n          \"海南全岛自驾游规划\"\n        ],\n        \"action\": {\n          \"event\": {\n            \"name\": \"start_itinerary_flow\"\n          }\n        }\n      }\n    ]\n  }\n}\n```\n\n您可以点击上方感兴趣的旅行风格，或者直接告诉我您的想法（比如：出行人数、天数、预算等），我将为您量身定制一份详细的行程单！";
    // final text =
    //     "你好！深圳是一座充满活力的现代化大都市，被称为中国的“硅谷”。这里有创新的科技、琳琅满目的购物中心，以及独具特色的主题公园。\n\n为了更好地为您规划行程，我准备了一些关于深圳的信息。如果您准备好了，我们可以开始为您定制专属的旅行计划。\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"createSurface\": {\n    \"surfaceId\": \"shenzhen_info_surface\",\n    \"catalogId\": \"https://a2ui.org/specification/v0_9/standard_catalog.json\",\n    \"sendDataModel\": true\n  }\n}\n```\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"updateComponents\": {\n    \"surfaceId\": \"shenzhen_info_surface\",\n    \"components\": [\n      {\n        \"id\": \"root\",\n        \"component\": \"Column\",\n        \"children\": [\n          \"shenzhen_header\",\n          \"shenzhen_card\",\n          \"itinerary_options\"\n        ]\n      },\n      {\n        \"id\": \"shenzhen_header\",\n        \"component\": \"Text\",\n        \"text\": \"探索深圳\",\n        \"variant\": \"h2\"\n      },\n      {\n        \"id\": \"shenzhen_card\",\n        \"component\": \"InformationCard\",\n        \"title\": \"深圳：创新的窗口\",\n        \"subtitle\": \"中国，广东省\",\n        \"imageChildId\": \"shenzhen_image\",\n        \"body\": \"深圳从一个渔村迅速崛起为国际化大都市，以其前卫的建筑、蓬勃发展的科技产业和宜人的城市绿化而闻名。这里有世界之窗、欢乐谷等著名景点，还有华强北的电子奇迹和南山区的现代景观。\"\n      },\n      {\n        \"id\": \"shenzhen_image\",\n        \"component\": \"Image\",\n        \"url\": \"assets/travel_images/temple_of_heaven_beijing_china.jpg\",\n        \"variant\": \"mediumFeature\",\n        \"fit\": \"cover\"\n      },\n      {\n        \"id\": \"itinerary_options\",\n        \"component\": \"Trailhead\",\n        \"topics\": [\n          \"创建深圳旅行行程\",\n          \"了解深圳的美食\",\n          \"探索广东地区\"\n        ],\n        \"action\": {\n          \"event\": {\n            \"name\": \"select_topic\",\n            \"context\": {\n              \"destination\": \"深圳\"\n            }\n          }\n        }\n      }\n    ]\n  }\n}\n```你可以点击上方的卡片来选择你感兴趣的地区，或者直接告诉我你的旅行偏好（比如人数、天数、预算等），我将为你制定专属行程。";
    // final text ="深圳未来几天的天气预报如下（2026年3月17日更新）：\n\n*   **3月17日（今天）**：多云，气温 18°C - 24°C，空气质量优。\n*   **3月18日（周三）**：阴转小雨，气温 19°C - 23°C，建议出门带伞。\n*   **3月19日（周四）**：阴天，气温 20°C - 25°C，湿度较高。\n*   **3月20日（周五）**：多云转晴，气温 21°C - 27°C，天气回暖。\n\n如果您计划前往深圳，除了天气，我也为您准备了一些旅行建议：\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"createSurface\": {\n    \"surfaceId\": \"shenzhen_travel_guide\",\n    \"catalogId\": \"travel_catalog\",\n    \"sendDataModel\": true\n  }\n}\n```\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"updateComponents\": {\n    \"surfaceId\": \"shenzhen_travel_guide\",\n    \"components\": [\n      {\n        \"id\": \"root\",\n        \"component\": \"Column\",\n        \"children\": [\n          \"header_text\",\n          \"travel_trailhead\"\n        ],\n        \"spacing\": 16,\n        \"align\": \"start\"\n      },\n      {\n        \"id\": \"header_text\",\n        \"component\": \"Text\",\n        \"text\": \"探索深圳更多精彩\",\n        \"variant\": \"h3\"\n      },\n      {\n        \"id\": \"travel_trailhead\",\n        \"component\": \"Trailhead\",\n        \"topics\": [\n          \"深圳热门酒店预订\",\n          \"世界之窗与欢乐海岸\",\n          \"必吃粤式早茶推荐\",\n          \"深圳湾公园攻略\"\n        ],\n        \"action\": {\n          \"event\": {\n            \"name\": \"explore_topic\",\n            \"context\": {\n              \"city\": \"深圳\"\n            }\n          }\n        }\n      }\n    ]\n  }\n}\n```";
    final result = JsonBlockParser.splitTextAndJsonToObjects(text);
    if (result.isNotEmpty) {
      for (final item in result) {
        if (item is String) {
          final chars = item.characters.toList();
          for (final content in chars) {
            addTextResponse(content);
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } else if (item is Map<String, dynamic>) {
          try {
            // The model sometimes omits the version, so we inject it if
            // it's missing.
            if (!item.containsKey('version')) {
              item['version'] = 'v0.9';
            }
            final message = A2uiMessage.fromJson(item);
            addA2uiMessage(message);
            genUiLogger.info('Emitted A2UI message from prompt extraction: $message');
          } catch (e) {
            genUiLogger.warning('Failed to parse extracted JSON as A2uiMessage: $e');
          }
        }
      }
    }
  }
}
