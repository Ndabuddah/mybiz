import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';

import '../../api/gemini_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  List<ChatMessage> _messages = [ChatMessage(content: "Hi there! I'm your AI business assistant. How can I help you today?", isUser: false, timestamp: DateTime.now())];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(content: message, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _geminiService.generateBusinessContent(message);

      setState(() {
        _messages.add(ChatMessage(content: response, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(content: "Sorry, I couldn't process your request. Please try again.", isUser: false, timestamp: DateTime.now(), isError: true));
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Wave', style: AppStyles.h2(isDarkMode: isDarkMode)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Show options
            },
            icon: Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message, isDarkMode);
                },
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)), const SizedBox(width: 8), Text('AI is thinking...', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54))],
                ),
              ),

            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Write anything here...',
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: TextStyle(fontSize: 16),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(decoration: BoxDecoration(gradient: AppStyles.primaryGradient, shape: BoxShape.circle), child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send, color: Colors.white), padding: const EdgeInsets.all(12), constraints: const BoxConstraints())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDarkMode) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(color: message.isUser ? AppColors.primaryColor : (isDarkMode ? AppColors.darkCard : Colors.white), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isUser)
              Text(message.content, style: const TextStyle(color: Colors.white))
            else
              MarkdownWidget(
                data: message.content,
                config: MarkdownConfig(
                  configs: [PreConfig(theme: PreTheme(textStyle: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black87, fontFamily: 'monospace'), decoration: BoxDecoration(color: isDarkMode ? Colors.black26 : Colors.grey[200], borderRadius: BorderRadius.circular(8))))],
                ),
              ),
            const SizedBox(height: 4),
            Text('${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 10, color: message.isUser ? Colors.white70 : (isDarkMode ? Colors.white38 : Colors.black38))),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({required this.content, required this.isUser, required this.timestamp, this.isError = false});
}
