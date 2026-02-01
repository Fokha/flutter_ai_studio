class Chat {
  final String id;
  String title;
  final List<Message> messages;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });
}

class Message {
  final String role;
  final String content;
  final DateTime timestamp;
  final String? time;
  final String? cost;
  final List<ToolCall>? toolCalls;

  Message({
    required this.role,
    required this.content,
    required this.timestamp,
    this.time,
    this.cost,
    this.toolCalls,
  });
}

class ToolCall {
  final String tool;
  final String action;

  ToolCall({required this.tool, required this.action});
}
