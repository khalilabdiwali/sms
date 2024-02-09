import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
// Make sure to import your audio recording package here
// Replace 'YourAudioRecorderClass' with the actual class from your package
import 'package:record/record.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Record audioRecord;
  // Replace with your actual audio recorder class
  late final AudioPlayer audioPlayer;

  bool isRecording = false;
  String audioPath = '';

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = Record(); // Initialize your audio recorder here
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      if (path != null) {
        setState(() {
          isRecording = false;
          audioPath = path;
        });
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      if (audioPath.isNotEmpty) {
        Source urlSource = UrlSource(audioPath);
        await audioPlayer.play(urlSource);
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRecording) Text('Recording in process'),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: isRecording ? Icon(Icons.pause) : Icon(Icons.mic),
            ),
            SizedBox(height: 25),
            if (!isRecording && audioPath.isNotEmpty)
              ElevatedButton(
                onPressed: playRecording,
                child: Text('Play Recording'),
              ),
          ],
        ),
      ),
    );
  }
}
