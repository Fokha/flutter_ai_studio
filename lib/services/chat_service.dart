import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat.dart';

class ChatService extends ChangeNotifier {
  List<Chat> _chats = [];
  String? _currentChatId;
  bool _agentMode = false;
  String _provider = 'llama';
  String _model = 'llama3.1:8b';
  bool _isLoading = false;

  List<Chat> get chats => _chats;
  String? get currentChatId => _currentChatId;
  bool get agentMode => _agentMode;
  String get provider => _provider;
  String get model => _model;
  bool get isLoading => _isLoading;

  Chat? get currentChat {
    if (_currentChatId == null) return null;
    return _chats.firstWhere((c) => c.id == _currentChatId);
  }

  void createNewChat() {
    final chat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
    );
    _chats.insert(0, chat);
    _currentChatId = chat.id;
    notifyListeners();
  }

  void switchChat(String chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }

  void toggleAgentMode() {
    _agentMode = !_agentMode;
    notifyListeners();
  }

  void setProvider(String provider) {
    _provider = provider;
    notifyListeners();
  }

  void setModel(String model) {
    _model = model;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (_currentChatId == null) return;

    final chat = currentChat;
    if (chat == null) return;

    // Add user message
    chat.messages.add(Message(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Update title if first message
    if (chat.messages.length == 1) {
      chat.title = content.substring(0, content.length > 50 ? 50 : content.length);
    }

    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = _agentMode ? '/chat/agent' : '/chat';
      final response = await http.post(
        Uri.parse('http://localhost:5500$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': _provider,
          'model': _model,
          'message': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        chat.messages.add(Message(
          role: 'assistant',
          content: data['response'],
          timestamp: DateTime.now(),
          time: '${data['metrics']?['duration_ms'] ?? 0}ms',
          cost: data['metrics']?['cost_estimate'] == 0
              ? 'FREE'
              : '\$${data['metrics']?['cost_estimate']?.toStringAsFixed(4) ?? '0.0000'}',
          toolCalls: data['tool_calls'] != null
              ? (data['tool_calls'] as List)
                  .map((t) => ToolCall(
                        tool: t['tool'],
                        action: t['action'],
                      ))
                  .toList()
              : null,
        ));
      } else {
        chat.messages.add(Message(
          role: 'assistant',
          content: '❌ Error: ${response.statusCode}',
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      chat.messages.add(Message(
        role: 'assistant',
        content: '❌ Connection Error: $e',
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentChat() {
    if (_currentChatId == null) return;
    final chat = currentChat;
    if (chat != null) {
      chat.messages.clear();
      notifyListeners();
    }
  }

  void regenerateLastMessage() {
    if (_currentChatId == null) return;
    final chat = currentChat;
    if (chat == null || chat.messages.length < 2) return;

    final userMessage = chat.messages[chat.messages.length - 2].content;
    chat.messages.removeLast();
    chat.messages.removeLast();
    notifyListeners();
    
    sendMessage(userMessage);
  }
}
