import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';
import 'auth_service.dart';
import '../utils/server_date.dart';

/// Callback pour les événements WebSocket
typedef MessageCallback = void Function(MessageModel message);
typedef MessagesReadCallback =
    void Function(int senderId, List<int> messageIds);
typedef TypingCallback = void Function(int userId);
typedef WebSocketErrorCallback = void Function(String message);

/// Service pour gérer les messages avec support WebSocket
class MessagesService {
  MessagesService._privateConstructor();
  static final MessagesService instance = MessagesService._privateConstructor();

  // Le service messages tourne sur le port 8002
  String get baseUrl => ApiConfig.messagesUrl;

  // URL WebSocket
  String get wsUrl {
    final httpUrl = baseUrl;
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://');
    }
    return httpUrl.replaceFirst('http://', 'ws://');
  }

  // WebSocket
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  // Callbacks
  MessageCallback? onNewMessage;
  MessageCallback? onMessageSent;
  MessagesReadCallback? onMessagesRead;
  TypingCallback? onTyping;
  WebSocketErrorCallback? onErrorMessage;
  VoidCallback? onConnected;
  VoidCallback? onDisconnected;

  bool get isConnected => _isConnected;

  /// Connecte au WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await AuthService.instance.getAccessToken();
    if (token == null) {
      return;
    }

    try {
      final uri = Uri.parse('$wsUrl/ws/$token');

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      onConnected?.call();

      // Démarrer le ping pour maintenir la connexion
      _startPing();
    } catch (e) {
      _scheduleReconnect();
    }
  }

  /// Déconnecte du WebSocket
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    onDisconnected?.call();
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final type = json['type'] as String?;

      switch (type) {
        case 'new_message':
          final message = MessageModel.fromJson(json['message']);
          onNewMessage?.call(message);
          break;
        case 'message_sent':
          final message = MessageModel.fromJson(json['message']);
          onMessageSent?.call(message);
          break;
        case 'messages_read':
          final readerId = json['reader_id'] as int;
          final messageIds = (json['message_ids'] as List).cast<int>();
          onMessagesRead?.call(readerId, messageIds);
          break;
        case 'typing':
          final userId = json['user_id'] as int;
          onTyping?.call(userId);
          break;
        case 'pong':
          // Réponse au ping, connexion OK
          break;
        case 'error':
          final errorMessage = (json['message'] as String?) ?? 'Unknown error';
          onErrorMessage?.call(errorMessage);
          break;
      }
    } catch (e) {}
  }

  void _onError(dynamic error) {
    _isConnected = false;
    onErrorMessage?.call('WebSocket connection error');
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _onDone() {
    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _send({'action': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  bool _send(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      return false;
    }

    try {
      _channel!.sink.add(jsonEncode(data));
      return true;
    } catch (e) {
      _isConnected = false;
      onDisconnected?.call();
      _scheduleReconnect();
      return false;
    }
  }

  /// Envoie un message via WebSocket (temps réel)
  bool sendMessageRealtime(int receiverId, String content) {
    return _send({
      'action': 'send_message',
      'receiver_id': receiverId,
      'content': content,
    });
  }

  /// Notifie que l'utilisateur tape
  void sendTyping(int receiverId) {
    _send({'action': 'typing', 'receiver_id': receiverId});
  }

  /// Marque les messages comme lus via WebSocket
  bool markAsReadRealtime(int senderId) {
    return _send({'action': 'mark_read', 'sender_id': senderId});
  }

  // ============ API REST (fallback et chargement initial) ============

  /// Récupère la liste des conversations
  Future<List<ConversationPreview>> getConversations() async {
    final authHeader = await AuthService.instance.getAuthHeader();
    if (authHeader == null) return [];

    final url = Uri.parse('$baseUrl/conversations');
    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
    );

    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map((e) => ConversationPreview.fromJson(e)).toList();
    }
    return [];
  }

  /// Récupère les messages d'une conversation
  Future<ConversationOut?> getConversation(
    int userId, {
    int limit = 50,
    int? beforeId,
  }) async {
    final authHeader = await AuthService.instance.getAuthHeader();
    if (authHeader == null) return null;

    String urlStr = '$baseUrl/conversations/$userId?limit=$limit';
    if (beforeId != null) {
      urlStr += '&before_id=$beforeId';
    }

    final url = Uri.parse(urlStr);
    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return ConversationOut.fromJson(data);
    }
    return null;
  }

  /// Envoie un message via REST (fallback)
  Future<MessageModel?> sendMessage(int receiverId, String content) async {
    final authHeader = await AuthService.instance.getAuthHeader();
    if (authHeader == null) return null;

    final url = Uri.parse('$baseUrl/messages');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode({'receiver_id': receiverId, 'content': content}),
    );

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return MessageModel.fromJson(data);
    }
    return null;
  }

  /// Marque les messages comme lus via REST
  Future<bool> markAsRead(int userId, {List<int>? messageIds}) async {
    final authHeader = await AuthService.instance.getAuthHeader();
    if (authHeader == null) return false;

    final url = Uri.parse('$baseUrl/conversations/$userId/read');
    final body = messageIds != null ? {'message_ids': messageIds} : {};

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode(body),
    );

    return resp.statusCode == 200;
  }

  /// Récupère le nombre de messages non lus
  Future<int> getUnreadCount() async {
    final authHeader = await AuthService.instance.getAuthHeader();
    if (authHeader == null) return 0;

    final url = Uri.parse('$baseUrl/messages/unread-count');
    final resp = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['unread_count'] as int;
    }
    return 0;
  }
}

// ============ Modèles ============

class UserBasicInfo {
  final int id;
  final String username;
  final String? avatarUrl;

  UserBasicInfo({required this.id, required this.username, this.avatarUrl});

  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      content: json['content'] as String,
      isRead: json['is_read'] as bool,
      createdAt: parseServerDate(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? parseServerDate(json['read_at'] as String)
          : null,
    );
  }

  /// Vérifie si ce message a été envoyé par l'utilisateur donné
  bool isSentBy(int userId) => senderId == userId;
}

class ConversationPreview {
  final UserBasicInfo user;
  final MessageModel lastMessage;
  final int unreadCount;

  ConversationPreview({
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationPreview.fromJson(Map<String, dynamic> json) {
    return ConversationPreview(
      user: UserBasicInfo.fromJson(json['user']),
      lastMessage: MessageModel.fromJson(json['last_message']),
      unreadCount: json['unread_count'] as int,
    );
  }
}

class ConversationOut {
  final UserBasicInfo user;
  final List<MessageModel> messages;
  final bool hasMore;

  ConversationOut({
    required this.user,
    required this.messages,
    required this.hasMore,
  });

  factory ConversationOut.fromJson(Map<String, dynamic> json) {
    return ConversationOut(
      user: UserBasicInfo.fromJson(json['user']),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => MessageModel.fromJson(e))
          .toList(),
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
