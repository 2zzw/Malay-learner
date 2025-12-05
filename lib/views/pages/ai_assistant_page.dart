import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// =============================================================================
// MODELS
// =============================================================================

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// =============================================================================
// AI ASSISTANT PAGE
// =============================================================================

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // IMPORTANT: In the actual execution environment, the key is injected.
  // Do not modify this line.
  static const String apiKey = "";

  @override
  void initState() {
    super.initState();
    // 添加一条初始问候语
    _messages.add(
      ChatMessage(
        text:
            "Apa khabar! I am your Malay AI Tutor. Ask me anything about Malay vocabulary, grammar, or translation.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  // 发送消息并调用 Gemini API
  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final responseText = await _callGeminiAPI(text);

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Maaf, something went wrong. Please try again later.\nError: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
  }

  // 调用 Gemini API
  Future<String> _callGeminiAPI(String userMessage) async {
    // 如果没有 API Key (本地运行且未配置时)，返回模拟回复
    if (apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return "这是模拟回复：API Key 未配置。在实际环境中，这里会返回 Gemini 的真实回复。\n\n你的问题是: \"$userMessage\"";
    }

    const String url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent";

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {"text": userMessage},
          ],
        },
      ],
      "systemInstruction": {
        "parts": [
          {
            "text":
                "You are a friendly and helpful Malay language tutor. You explain Malay words, grammar, and cultural context in a simple and engaging way. If the user speaks English, explain in English. If the user speaks Chinese, explain in Chinese.",
          },
        ],
      },
    };

    try {
      final response = await http.post(
        Uri.parse("$url?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network Error: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 保持透明，利用背景的模糊
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.teal, size: 20),
            SizedBox(width: 8),
            Text(
              "AI Tutor",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // 顶部添加高斯模糊背景，防止文字在滚动时重叠
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 背景层
          Image.network(
            'https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          // 叠加层：强模糊，使背景变成柔和的底色，保证文字可读性
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.white.withOpacity(0.6)),
          ),

          // 2. 聊天内容
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg);
                    },
                  ),
                ),

                // 加载指示器
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Thinking...",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 底部输入区
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 聊天气泡构建
  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Colors
                    .teal
                    .shade600 // 用户：深色背景
              : Colors.white.withOpacity(0.9), // AI：浅色毛玻璃背景
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: msg.isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: msg.isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser) ...[
              const Text(
                "AI Tutor",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: msg.isUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 底部输入框
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // 几乎不透明的底部栏
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 文本框
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Ask about Malay...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 发送按钮
            GestureDetector(
              onTap: _isLoading ? null : _handleSendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isLoading ? Colors.grey : Colors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
