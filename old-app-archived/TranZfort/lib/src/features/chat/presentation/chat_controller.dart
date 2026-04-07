import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_providers.dart';

class ChatController {
  final WidgetRef ref;
  final BuildContext context;
  final void Function(VoidCallback) setState;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final String conversationId;

  ChatController({
    required this.ref,
    required this.context,
    required this.setState,
    required this.messageController,
    required this.scrollController,
    required this.conversationId,
  });

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    await ref.read(chatSendProvider.notifier).sendText(conversationId, text);
    _scrollToBottom();
  }

  Future<void> sendLocation() async {
    await ref.read(chatSendProvider.notifier).sendMapCard(conversationId);
    _scrollToBottom();
  }

  Future<void> sendVoiceNote(String filePath, int durationSeconds) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    await ref.read(chatSendProvider.notifier).sendVoice(
      conversationId: conversationId,
      audioFile: file,
      durationSeconds: durationSeconds,
    );
    _scrollToBottom();
  }

  Future<void> openMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class VoiceRecordingController {
  final void Function(VoidCallback) setState;
  final AudioRecorder recorder;
  final AudioPlayer audioPlayer;

  VoiceRecordingController({
    required this.setState,
    required this.recorder,
    required this.audioPlayer,
  });

  Future<String?> startRecording() async {
    if (await recorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(), path: path);
      return path;
    }
    return null;
  }

  Future<String?> stopRecording() async {
    return await recorder.stop();
  }

  Future<void> playVoice(String url, String messageId, {
    required void Function(String?) setPlayingMessageId,
    required void Function(bool) setIsPlaying,
  }) async {
    setPlayingMessageId(messageId);
    setIsPlaying(true);

    try {
      await audioPlayer.setUrl(url);
      audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          setPlayingMessageId(null);
          setIsPlaying(false);
        }
      });

      await audioPlayer.play();
    } catch (e) {
      setPlayingMessageId(null);
      setIsPlaying(false);
    }
  }

  Future<void> stopVoice({
    required void Function(String?) setPlayingMessageId,
    required void Function(bool) setIsPlaying,
  }) async {
    await audioPlayer.stop();
    setPlayingMessageId(null);
    setIsPlaying(false);
  }
}
