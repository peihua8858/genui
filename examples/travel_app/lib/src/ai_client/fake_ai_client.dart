// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:genui/genui.dart';

import 'ai_client.dart';
import 'package:genui/parsing.dart';
import 'dart:convert';

class FakeAiClient implements AiClient {
  FakeAiClient({required this.transport});

  final Transport transport;
  final _errorController = StreamController<Object>.broadcast();

  Stream<Object> get errorStream => _errorController.stream;

  Completer<void>? sendRequestCompleter;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
    Map<String, Object?>? clientDataModel,
    CancellationSignal? cancellationSignal,
  }) async {
    final text =
        "你好！深圳是一座充满活力的现代化大都市，被称为中国的“硅谷”。这里有创新的科技、琳琅满目的购物中心，以及独具特色的主题公园。\n\n为了更好地为您规划行程，我准备了一些关于深圳的信息。如果您准备好了，我们可以开始为您定制专属的旅行计划。\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"createSurface\": {\n    \"surfaceId\": \"shenzhen_info_surface\",\n    \"catalogId\": \"https://a2ui.org/specification/v0_9/standard_catalog.json\",\n    \"sendDataModel\": true\n  }\n}\n```\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"updateComponents\": {\n    \"surfaceId\": \"shenzhen_info_surface\",\n    \"components\": [\n      {\n        \"id\": \"root\",\n        \"component\": \"Column\",\n        \"children\": [\n          \"shenzhen_header\",\n          \"shenzhen_card\",\n          \"itinerary_options\"\n        ]\n      },\n      {\n        \"id\": \"shenzhen_header\",\n        \"component\": \"Text\",\n        \"text\": \"探索深圳\",\n        \"variant\": \"h2\"\n      },\n      {\n        \"id\": \"shenzhen_card\",\n        \"component\": \"InformationCard\",\n        \"title\": \"深圳：创新的窗口\",\n        \"subtitle\": \"中国，广东省\",\n        \"imageChildId\": \"shenzhen_image\",\n        \"body\": \"深圳从一个渔村迅速崛起为国际化大都市，以其前卫的建筑、蓬勃发展的科技产业和宜人的城市绿化而闻名。这里有世界之窗、欢乐谷等著名景点，还有华强北的电子奇迹和南山区的现代景观。\"\n      },\n      {\n        \"id\": \"shenzhen_image\",\n        \"component\": \"Image\",\n        \"url\": \"assets/travel_images/temple_of_heaven_beijing_china.jpg\",\n        \"variant\": \"mediumFeature\",\n        \"fit\": \"cover\"\n      },\n      {\n        \"id\": \"itinerary_options\",\n        \"component\": \"Trailhead\",\n        \"topics\": [\n          \"创建深圳旅行行程\",\n          \"了解深圳的美食\",\n          \"探索广东地区\"\n        ],\n        \"action\": {\n          \"event\": {\n            \"name\": \"select_topic\",\n            \"context\": {\n              \"destination\": \"深圳\"\n            }\n          }\n        }\n      }\n    ]\n  }\n}\n```你可以点击上方的卡片来选择你感兴趣的地区，或者直接告诉我你的旅行偏好（比如人数、天数、预算等），我将为你制定专属行程。";
    // final text ="深圳未来几天的天气预报如下（2026年3月17日更新）：\n\n*   **3月17日（今天）**：多云，气温 18°C - 24°C，空气质量优。\n*   **3月18日（周三）**：阴转小雨，气温 19°C - 23°C，建议出门带伞。\n*   **3月19日（周四）**：阴天，气温 20°C - 25°C，湿度较高。\n*   **3月20日（周五）**：多云转晴，气温 21°C - 27°C，天气回暖。\n\n如果您计划前往深圳，除了天气，我也为您准备了一些旅行建议：\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"createSurface\": {\n    \"surfaceId\": \"shenzhen_travel_guide\",\n    \"catalogId\": \"travel_catalog\",\n    \"sendDataModel\": true\n  }\n}\n```\n\n```json\n{\n  \"version\": \"v0.9\",\n  \"updateComponents\": {\n    \"surfaceId\": \"shenzhen_travel_guide\",\n    \"components\": [\n      {\n        \"id\": \"root\",\n        \"component\": \"Column\",\n        \"children\": [\n          \"header_text\",\n          \"travel_trailhead\"\n        ],\n        \"spacing\": 16,\n        \"align\": \"start\"\n      },\n      {\n        \"id\": \"header_text\",\n        \"component\": \"Text\",\n        \"text\": \"探索深圳更多精彩\",\n        \"variant\": \"h3\"\n      },\n      {\n        \"id\": \"travel_trailhead\",\n        \"component\": \"Trailhead\",\n        \"topics\": [\n          \"深圳热门酒店预订\",\n          \"世界之窗与欢乐海岸\",\n          \"必吃粤式早茶推荐\",\n          \"深圳湾公园攻略\"\n        ],\n        \"action\": {\n          \"event\": {\n            \"name\": \"explore_topic\",\n            \"context\": {\n              \"city\": \"深圳\"\n            }\n          }\n        }\n      }\n    ]\n  }\n}\n```";
    final ParseResult? parseResult = JsonBlockParser.splitTextAndJsonBlocks(text);
    genUiLogger.warning('addEvent:Response has  parseResult: $parseResult"');
    if (parseResult != null && parseResult.jsonBlocks.isNotEmpty) {
      genUiLogger.warning('addEvent:Response has  add prefix>>>>>start"');
      final chars = parseResult.prefix.characters.toList();
      for (final content in chars) {
        addTextResponse(content);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      // transport.addChunk(parseResult.prefix);
      genUiLogger.warning('addEvent:Response has  add prefix>>>>>end"');
      genUiLogger.warning('addEvent:Response has  add jsonBlocks>>>>>start"');
      List<String> jsonBlocks = parseResult.jsonBlocks;
      for (final content in jsonBlocks) {
        try {
          final jsonBlock = (jsonDecode(content) as Object);
          if (jsonBlock is Map<String, dynamic>) {
            // The model sometimes omits the version, so we inject it if
            // it's missing.
            if (!jsonBlock.containsKey('version')) {
              jsonBlock['version'] = 'v0.9';
            }
            final message = A2uiMessage.fromJson(jsonBlock);
            addA2uiMessage(message);
            genUiLogger.info('Emitted A2UI message from prompt extraction: $message');
          }
        } catch (e) {
          genUiLogger.warning('Failed to parse extracted JSON as A2uiMessage: $e');
        }
      }
      genUiLogger.warning('addEvent:Response has  add jsonBlocks>>>>>end"');
      genUiLogger.warning('addEvent:Response has  add suffix>>>>>start"');
      final chars1 = parseResult.suffix.characters.toList();
      for (final content in chars1) {
        addTextResponse(content);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      // transport.addChunk(parseResult.suffix);
      genUiLogger.warning('addEvent:Response has  add suffix>>>>>end"');
    }
  }

  void addA2uiMessage(A2uiMessage message) {
    transport.addMessage(message);
  }

  void addTextResponse(String text) {
    transport.addChunk(text);
  }

  void addError(Object error) {
    _errorController.add(error);
  }

  @override
  void dispose() {
    _errorController.close();
  }
}
