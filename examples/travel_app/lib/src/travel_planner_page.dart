// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart' hide Conversation;
import 'package:genui/genui.dart' as genui;

import 'ai_client/ai_client.dart';
import 'ai_client/google_generative_ai_client.dart';
import 'asset_images.dart';
import 'catalog.dart';
// Conditionally import non-web version so we can read from shell env vars in
// non-web version.
import 'config/io_get_api_key.dart'
    if (dart.library.html) 'config/web_get_api_key.dart';
import 'tools/booking/booking_service.dart';
import 'tools/booking/list_hotels_tool.dart';
import 'widgets/conversation.dart';

Future<void> loadImagesJson() async {
  _imagesJson = await assetImageCatalogJson();
}

/// The main page for the travel planner application.
///
/// This stateful widget manages the core user interface and application logic.
/// It initializes the [SurfaceController] and [A2uiTransportAdapter], maintains
/// the conversation history, and handles the interaction between the user, the
/// AI, and the dynamically generated UI.
///
/// The page allows users to interact with the generative AI to plan trips. It
/// features a text field to send prompts, a view to display the dynamically
/// generated UI, and a menu to switch between different AI models.
class TravelPlannerPage extends StatefulWidget {
  /// Creates a new [TravelPlannerPage].
  ///
  /// An optional [aiClient] can be provided, which is useful for
  /// testing or using a custom AI client implementation. If not provided, a
  /// default [GoogleGenerativeAiClient] is created.
  const TravelPlannerPage({this.aiClient, super.key});

  /// The AI client to use for the application.
  ///
  /// If null, a default instance will be created.
  /// This must be an instance of [AiClient].
  final AiClient? aiClient;

  @override
  State<TravelPlannerPage> createState() => _TravelPlannerPageState();
}

class _TravelPlannerPageState extends State<TravelPlannerPage>
    with AutomaticKeepAliveClientMixin {
  late final SurfaceController _surfaceController;
  late final genui.Conversation _uiConversation;
  late final A2uiTransportAdapter _transportAdapter;

  final ValueNotifier<List<ChatMessage>> _messages = ValueNotifier([]);
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);
  String _currentStreamingText = '';

  // We keep a reference to the client to dispose it if we created it.
  AiClient? _client;
  bool _didCreateClient = false;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Wire up the controller's onSend to the appropriate client
    _transportAdapter = A2uiTransportAdapter(
      onSend: (message) async {
        // Reset streaming text for new turn
        _currentStreamingText = '';
        _messages.value = [..._messages.value, message];
        // Send request
        await _sendRequest(_client!, message, _messages.value);
      },
    );
//     final Catalog catalog = asCatalog(
//       systemPromptFragments: [
//         '''
// When you need additional information from the user, try to use the component '${BasicCatalogItems.choicePicker.name}' to ask for it.
// ''',
//         '''
// If there is no way to itemize all the options, either use the component '${BasicCatalogItems.textField.name}' or add option 'Other' to the '${BasicCatalogItems.choicePicker.name}'.
// ''',
//       ],
//     );
    _surfaceController = SurfaceController(catalogs: [travelAppCatalog]);

    // Create the appropriate content generator based on configuration
    _client = widget.aiClient;
    if (_client == null) {
      _didCreateClient = true;
      _client = GoogleGenerativeAiClient(
        catalog: travelAppCatalog,
        systemInstruction: prompt,
        additionalTools: [
          ListHotelsTool(onListHotels: BookingService.instance.listHotels),
        ],
        apiKey: getApiKey(),
      );
    }

    _wireClient(_client!, _transportAdapter);

    _uiConversation = genui.Conversation(
      transport: _transportAdapter,
      controller: _surfaceController,
    );

    _uiConversation.state.addListener(() {
      _isProcessing.value = _uiConversation.state.value.isWaiting;
    });

    _uiConversation.events.listen((event) {
      genUiLogger.info("addEvent:Conversation<><><><><> event: $event");
      if (event is ConversationContentReceived) {
        genUiLogger.info(
          "addEvent:Conversation>>>ConversationContentReceived event.text: ${event.text}",
        );
        genUiLogger.info(
          "addEvent:Conversation>>>ConversationContentReceived _currentStreamingText: $_currentStreamingText",
        );
        if (event.text.isNotEmpty) {
          genUiLogger.info(
            "addEvent:Conversation<><><><><>add text event: ${event.text}",
          );
          // _currentStreamingText += event.text;
          final updatedMessages = List<ChatMessage>.from(_messages.value);
          if (updatedMessages.isNotEmpty &&
              updatedMessages.last.role == .model &&
              !updatedMessages.last.parts.any(
                (p) => p is DataPart && p.isUiPart,
              )) {
            updatedMessages.removeLast();
          }
          ValueNotifier<String> streamingText = ValueNotifier("");
          updatedMessages.add(ChatMessage.model1(streamingText));
          _messages.value = updatedMessages;
          int currentIndex = 0;
          final chars = event.text.characters.toList();
          Timer.periodic(const Duration(milliseconds: 50), (timer) {
            if (currentIndex < chars.length) {
              streamingText.value += chars[currentIndex];
              currentIndex++;
            } else {
              timer.cancel();
            }
          });
          _scrollToBottom();
        }
      } else if (event is ConversationSurfaceAdded) {
        genUiLogger.info(
          "addEvent:Conversation>>>ConversationSurfaceAdded event.surfaceId: ${event.surfaceId}",
        );
        final updatedMessages = List<ChatMessage>.from(_messages.value);
        updatedMessages.add(
          ChatMessage(
            role: .model,
            parts: [
              UiPart.create(
                definition: event.definition,
                surfaceId: event.surfaceId,
              ),
            ],
          ),
        );
        _messages.value = updatedMessages;
        // Reset streaming text so that any subsequent text is treated as a new
        // message chunk after the UI component, rather than being appended to
        // the previous text block (which would be confusing if the UI is in the
        // middle).
        _currentStreamingText = '';
        _scrollToBottom();
      } else if (event is ConversationComponentsUpdated) {
        _scrollToBottom();
      }
    });
  }

  void _wireClient(AiClient client, A2uiTransportAdapter controller) {
    client.a2uiMessageStream.listen(controller.addMessage);
    client.textResponseStream.listen(controller.addChunk);
  }

  Future<void> _sendRequest(
    AiClient client,
    ChatMessage message,
    Iterable<ChatMessage> history,
  ) {
    return client.sendRequest(message, history: history);
  }

  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  void dispose() {
    _surfaceController.dispose();
    _uiConversation.dispose();
    if (_didCreateClient) {
      _client?.dispose();
    }
    _textController.dispose();
    _scrollController.dispose();
    _messages.dispose();
    _isProcessing.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _triggerInference(ChatMessage message) async {
    await _uiConversation.sendRequest(message);
  }

  void _sendPrompt(String text) {
    if (_isProcessing.value || text.trim().isEmpty) return;
    _scrollToBottom();
    _textController.clear();
    _triggerInference(ChatMessage.user(text));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Center(
        child: Column(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: _messages,
                  builder: (context, messages, child) {
                    return Conversation(
                      messages: messages,
                      surfaceController: _surfaceController,
                      scrollController: _scrollController,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isProcessing,
                builder: (context, isThinking, child) {
                  return _ChatInput(
                    controller: _textController,
                    isThinking: isThinking,
                    onSend: _sendPrompt,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isThinking,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isThinking;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(25.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isThinking,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Enter your prompt...',
                ),
                onSubmitted: isThinking ? null : onSend,
              ),
            ),
            if (isThinking)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            else
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => onSend(controller.text),
              ),
          ],
        ),
      ),
    );
  }
}

String? _imagesJson;

// TODO(polina-c): construct examples automatically after improving catalog API.
final prompt = <String>[
  PromptFragments.currentDate(),

  // PromptFragments.uiGenerationRestriction(
  //   prefix: PromptBuilder.defaultImportancePrefix,
  // ),
];
