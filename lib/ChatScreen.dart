import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

enum UserRole { regular, police }

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late String userId;
  final databaseReference = FirebaseDatabase.instance.reference();
  List<UserData> userList = [];
  late UserRole userRole;

  @override
  void initState() {
    super.initState();
    _getUser();
    _fetchUsers();
  }

  Future<void> _getUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
        userRole = user.email == "police@example.com"
            ? UserRole.police
            : UserRole.regular;
      });
    }
  }

  Future<void> _fetchUsers() async {
    try {
      DatabaseEvent snapshot = await databaseReference.child('Users').once();
      if (snapshot.snapshot.value != null && snapshot.snapshot.value is Map) {
        Map<dynamic, dynamic> values =
            Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          userList.clear();
          values.forEach((key, value) {
            final userData = UserData(userId: key, name: value['name']);
            if (value['role'] == 'police' && userRole == UserRole.regular) {
              // Only allow regular users to see police users
              userList.add(userData);
            } else if (value['role'] == 'regular' &&
                userRole == UserRole.police) {
              // Only allow police users to see regular users
              userList.add(userData);
            }
          });
        });
      }
    } catch (error) {
      print("Error fetching users: $error");
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _navigateToChatView(UserData user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatViewScreen(
          currentUser: userId,
          recipientUser: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Chat'),
      ),
      body: Column(
        children: [
          userList.isEmpty
              ? CircularProgressIndicator()
              : Expanded(
                  child: ListView.builder(
                    itemCount: userList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(userList[index].name),
                        onTap: () => _navigateToChatView(userList[index]),
                      );
                    },
                  ),
                ),
          Divider(height: 1.0),
        ],
      ),
    );
  }
}

class ChatViewScreen extends StatefulWidget {
  final String currentUser;
  final UserData recipientUser;

  ChatViewScreen({required this.currentUser, required this.recipientUser});

  @override
  _ChatViewScreenState createState() => _ChatViewScreenState();
}

class _ChatViewScreenState extends State<ChatViewScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FlutterSoundRecorder _soundRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _durationText;
  String? _currentPlayingVoiceUrl;
  late AudioPlayer _audioPlayer;
  late DatabaseReference _messagesRef;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _messagesRef = _database.reference().child('messages');
    _audioPlayer = AudioPlayer();
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _durationText =
            '${duration.inMinutes}:${duration.inSeconds.remainder(60)}';
      });
    });
  }

  @override
  void dispose() {
    if (_isRecording) {
      _soundRecorder.stopRecorder();
    }
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      try {
        await _soundRecorder.openRecorder();
        await _soundRecorder
            .setSubscriptionDuration(Duration(milliseconds: 10));
      } catch (err) {
        print('Error initializing audio recorder: $err');
      }
    } else {
      // Handle microphone permission denied
    }
  }

  Future<void> _sendTextMessage(String text) async {
    _messagesRef.push().set({
      'senderId': widget.currentUser,
      'receiverId': widget.recipientUser.userId,
      'timestamp': ServerValue.timestamp,
      'text': text,
      'type': 'text',
    });
    _textController.clear();
  }

  Future<void> _sendImageMessage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final String fileName =
          'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference reference = _storage.ref().child(fileName);
      final UploadTask uploadTask = reference.putFile(File(pickedImage.path));
      final TaskSnapshot downloadUrl = await uploadTask;
      final String imageUrl = await downloadUrl.ref.getDownloadURL();

      _messagesRef.push().set({
        'senderId': widget.currentUser,
        'receiverId': widget.recipientUser.userId,
        'timestamp': ServerValue.timestamp,
        'imageUrl': imageUrl,
        'type': 'image',
      });
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/flutter_sound_${DateTime.now().millisecondsSinceEpoch}.aac';

    try {
      await _soundRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
        bitRate: 128000, // Adjust as needed
        numChannels: 1, // Adjust as needed
        sampleRate: 44100, // Adjust as needed
      );
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recorder: $e');
      // Handle errors here
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;

    final recordingPath = await _soundRecorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    if (recordingPath != null) {
      final String fileName =
          'voices/${DateTime.now().millisecondsSinceEpoch}.aac';
      final Reference reference = _storage.ref().child(fileName);
      final UploadTask uploadTask = reference.putFile(File(recordingPath));
      final TaskSnapshot downloadUrl = await uploadTask;
      final String voiceUrl = await downloadUrl.ref.getDownloadURL();

      _messagesRef.push().set({
        'senderId': widget.currentUser,
        'receiverId': widget.recipientUser.userId,
        'timestamp': ServerValue.timestamp,
        'voiceUrl': voiceUrl,
        'type': 'voice',
      });
    }
  }

  void _playVoiceMessage(String voiceUrl) async {
    if (_isPlaying) {
      await _audioPlayer
          .stop(); // Ensure to stop the currently playing audio first
      setState(() {
        _isPlaying = false;
        _currentPlayingVoiceUrl = null; // Reset the currently playing URL
      });
    }

    setState(() {
      _isPlaying = true;
      _currentPlayingVoiceUrl = voiceUrl;
    });

    await _audioPlayer
        .play(UrlSource(voiceUrl), mode: PlayerMode.mediaPlayer)
        .catchError((error) {
      print('Error during playback: $error');
      setState(() {
        _isPlaying = false;
        _currentPlayingVoiceUrl =
            null; // Reset the currently playing URL if an error occurs
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _currentPlayingVoiceUrl = null; // Reset after playback completes
      });
    });
  }

  void _deleteMessage(String messageId) {
    _messagesRef.child(messageId).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientUser.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _messagesRef.orderByChild('timestamp').onValue,
              builder: (context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                DataSnapshot dataValues = snapshot.data!.snapshot;
                if (dataValues.value is! Map) {
                  return SizedBox();
                }

                Map<dynamic, dynamic> values =
                    dataValues.value as Map<dynamic, dynamic>;
                List<Map<dynamic, dynamic>> messages = values.entries
                    .map((e) => {...e.value, 'key': e.key})
                    .where((message) =>
                        (message['senderId'] == widget.currentUser &&
                            message['receiverId'] ==
                                widget.recipientUser.userId) ||
                        (message['receiverId'] == widget.currentUser &&
                            message['senderId'] == widget.recipientUser.userId))
                    .toList();

                // Sort messages by timestamp
                messages
                    .sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isSentByMe = message['senderId'] == widget.currentUser;

                    if (message['type'] == 'text') {
                      return Dismissible(
                        key: Key(message['key']),
                        onDismissed: (direction) {
                          _deleteMessage(message['key']);
                        },
                        background: Container(color: Colors.red),
                        child: ListTile(
                          title: Align(
                            alignment: isSentByMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              margin: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSentByMe
                                    ? Colors.blue[200]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _buildMessageText(message['text']),
                            ),
                          ),
                        ),
                      );
                    } else if (message['type'] == 'image') {
                      return Column(
                        crossAxisAlignment: isSentByMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Dismissible(
                            key: Key(message['key']),
                            onDismissed: (direction) {
                              _deleteMessage(message['key']);
                            },
                            background: Container(color: Colors.red),
                            child: Container(
                              width:
                                  200, // Increased image size for better visibility
                              height:
                                  200, // Increased image size for better visibility
                              child: Image.network(message['imageUrl']),
                            ),
                          ),
                          Text(
                            isSentByMe ? 'You' : widget.recipientUser.name,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    } else if (message['type'] == 'voice') {
                      return Dismissible(
                        key: Key(message['key']),
                        onDismissed: (direction) {
                          _deleteMessage(message['key']);
                        },
                        background: Container(color: Colors.red),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: isSentByMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _currentPlayingVoiceUrl ==
                                              message['voiceUrl'] &&
                                          _isPlaying
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                ),
                                onPressed: () {
                                  _playVoiceMessage(message['voiceUrl']);
                                },
                              ),
                              Text(
                                  _currentPlayingVoiceUrl == message['voiceUrl']
                                      ? _durationText ?? ''
                                      : ''),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return SizedBox();
                    }
                  },
                );
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _sendImageMessage,
                ),
                if (_isRecording)
                  AvatarGlow(
                    glowColor: Colors.red,
                    duration: Duration(milliseconds: 2000),
                    repeat: true,
                    child: Material(
                      shape: CircleBorder(),
                      child: IconButton(
                        icon: Icon(Icons.mic),
                        onPressed: () {},
                      ),
                    ),
                  ),
                if (!_isRecording)
                  IconButton(
                    icon: Icon(Icons.mic_none),
                    onPressed: _startRecording,
                  ),
                if (_isRecording)
                  IconButton(
                    icon: Icon(Icons.stop),
                    onPressed: _stopRecordingAndSend,
                  ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Send a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendTextMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText(String text) {
    List<String> words = text.split(' ');
    List<Widget> widgets = [];
    for (String word in words) {
      if (word.startsWith('http') || word.startsWith('https')) {
        widgets.add(
          GestureDetector(
            onTap: () {
              _launchURL(word);
            },
            child: Text(
              word,
              style: TextStyle(color: Colors.blue),
            ),
          ),
        );
      } else {
        widgets.add(Text(word));
      }
      widgets.add(SizedBox(width: 4)); // Adjust spacing between words
    }
    return Wrap(children: widgets);
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class UserData {
  final String userId;
  final String name;

  UserData({required this.userId, required this.name});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}
