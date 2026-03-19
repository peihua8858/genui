// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

/// A widget to display an internal message in the chat.
class InternalMessageView extends StatelessWidget {
  /// Creates a new [InternalMessageView].
  const InternalMessageView({super.key, required this.content});

  /// The content of the message.
  final String content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.grey.shade200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Internal message: $content'),
        ),
      ),
    );
  }
}

class ChatMessageView2 extends StatefulWidget {
  const ChatMessageView2({
    super.key,
    required this.controller,
    required this.icon,
    required this.alignment,
    this.charDuration = const Duration(milliseconds: 50),
  });

  /// 完整文本
  final CombinedTextPartController controller;

  /// 图标
  final IconData icon;

  /// 对齐方式
  final MainAxisAlignment alignment;

  /// 每个字符显示间隔
  final Duration charDuration;

  @override
  State<ChatMessageView2> createState() => _ChatMessageViewState2();
}

class _ChatMessageViewState2 extends State<ChatMessageView2> {
  bool get isStart => widget.alignment == MainAxisAlignment.start;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: widget.alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isStart ? 5 : 25),
                  topRight: Radius.circular(isStart ? 25 : 5),
                  bottomLeft: const Radius.circular(25),
                  bottomRight: const Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStart) ...[
                      Icon(widget.icon),
                      const SizedBox(width: 8.0),
                    ],
                    Flexible(
                      child: ValueListenableBuilder<String>(
                        valueListenable: widget.controller,
                        builder: (context, value, child) {
                          return Text(value);
                        },
                      ),
                    ),
                    if (!isStart) ...[
                      const SizedBox(width: 8.0),
                      Icon(widget.icon),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A controller for a combined text part.
class CombinedTextPartController extends ValueNotifier<String> {
  final List<ValueNotifier<String>> _controllers;
  final List<VoidCallback> _listeners = [];

  CombinedTextPartController(List<ValueNotifier<String>> values)
    : _controllers = List.unmodifiable(values),
      super(_combine(values)) {
    for (final ValueNotifier<String> controller in _controllers) {
      void listener() {
        value = _combine(_controllers);
      }

      controller.addListener(listener);
      _listeners.add(listener);
    }
  }

  static String _combine(List<ValueNotifier<String>> controllers) {
    return controllers.map((e) => e.value).join();
  }

  List<ValueNotifier<String>> get controllers => _controllers;

  @override
  void dispose() {
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].removeListener(_listeners[i]);
    }
    _listeners.clear();
    super.dispose();
  }
}

/// A widget to display a chat message.
class ChatMessageView extends StatelessWidget {
  /// Creates a new [ChatMessageView].
  const ChatMessageView({
    super.key,
    required this.text,
    required this.icon,
    required this.alignment,
  });

  /// The text of the message.
  final String text;

  /// The icon to display next to the message.
  final IconData icon;

  /// The alignment of the message.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == MainAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    alignment == MainAxisAlignment.start ? 5 : 25,
                  ),
                  topRight: Radius.circular(
                    alignment == MainAxisAlignment.start ? 25 : 5,
                  ),
                  bottomLeft: const Radius.circular(25),
                  bottomRight: const Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStart) ...[Icon(icon), const SizedBox(width: 8.0)],
                    Flexible(child: Text(text)),
                    if (!isStart) ...[const SizedBox(width: 8.0), Icon(icon)],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageView1 extends StatefulWidget {
  const ChatMessageView1({
    super.key,
    required this.text,
    required this.icon,
    required this.alignment,
    this.charDuration = const Duration(milliseconds: 50),
    this.animate = false,
    this.onTypingCompleted,
  });

  /// 完整文本
  final String text;

  /// 图标
  final IconData icon;

  /// 对齐方式
  final MainAxisAlignment alignment;

  /// 每个字符显示间隔
  final Duration charDuration;
  final VoidCallback? onTypingCompleted;

  /// 是否播放打字动画
  final bool animate;

  @override
  State<ChatMessageView1> createState() => _ChatMessageViewState1();
}

class _ChatMessageViewState1 extends State<ChatMessageView1> {
  String _displayedText = '';
  Timer? _timer;
  int _currentIndex = 0;
  late List<String> _chars;

  bool get isStart => widget.alignment == MainAxisAlignment.start;

  @override
  void initState() {
    super.initState();
    _chars = widget.text.characters.toList();
    if (widget.animate) {
      _startTyping(fromBeginning: true);
    } else {
      _displayedText = widget.text;
      _currentIndex = _chars.length;
    }
  }

  @override
  void didUpdateWidget(covariant ChatMessageView1 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果外部传入的 text 变了，重新开始逐字显示
    if (oldWidget.text != widget.text) {
      _chars = widget.text.characters.toList();
      if (_timer == null || !_timer!.isActive) {
        _startTyping();
      }
    }
  }

  void _startTyping({bool fromBeginning = false}) {
    if (fromBeginning) {
      _currentIndex = 0;
      _displayedText = '';
    }
    if (_chars.isEmpty) return;

    _timer = Timer.periodic(widget.charDuration, (timer) {
      if (_currentIndex < _chars.length) {
        setState(() {
          _currentIndex++;
          _displayedText = _chars.take(_currentIndex).join();
        });
      } else {
        timer.cancel();
        widget.onTypingCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: widget.alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isStart ? 5 : 25),
                  topRight: Radius.circular(isStart ? 25 : 5),
                  bottomLeft: const Radius.circular(25),
                  bottomRight: const Radius.circular(25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStart) ...[Icon(widget.icon), const SizedBox(width: 8.0)],
                    Flexible(child: Text(_displayedText)),
                    if (!isStart) ...[const SizedBox(width: 8.0), Icon(widget.icon)],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
