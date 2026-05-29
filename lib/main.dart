import 'widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'utils/app_helpers.dart';
import 'models/chat.dart';
import 'models/app_user.dart';
import 'models/post.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

const List<String> kCategories = [
  "Tümü",
  "Aşk-İlişki",
  "İş Hayatı",
  "Okul Hayatı",
  "Günlük Yaşam",
  "Aile",
  "Sağlık ve Spor",
];

const List<String> kContentTypes = [
  "Tümü",
  "Dert",
  "Soru",
  "İtiraf",
  "Tavsiye İstiyorum",
];

class ContentModerator {
  static const List<String> bannedWords = [
    'amk',
    'aq',
    'a.q',
    'amq',
    'amına',
    'amina',
    'amınakoyim',
    'aminakoyim',
    'amcik',
    'amcık',
    'siktir',
    'sikik',
    'sikerim',
    'sikeyim',
    'orospu',
    'orospuçocuğu',
    'piç',
    'pic',
    'yarrak',
    'yarak',
    'göt',
    'got',
    'götveren',
    'ibne',
    'pezevenk',
    'kahpe',
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'bastard',
    'dick',
    'cock',
    'pussy',
    'motherfucker',
    'slut',
    'whore',
  ];

  static String normalize(String text) {
    var value = text.toLowerCase();
    value = value
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
    value = value.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return value;
  }

  static bool containsProfanity(String text) {
    final normalized = normalize(text);
    for (final word in bannedWords) {
      if (normalized.contains(normalize(word))) return true;
    }
    return false;
  }
}

Color genderBaseColor(String? gender) {
  switch (gender) {
    case "Kadın":
      return const Color(0xFFD96A96);
    case "Erkek":
      return const Color(0xFF5C8DDA);
    default:
      return const Color(0xFF7A7288);
  }
}

BoxDecoration genderCardDecoration(
  String? gender, {
  double opacity = 0.22,
  double radius = 24,
}) {
  final base = genderBaseColor(gender);
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        base.withOpacity(opacity + 0.06),
        base.withOpacity(opacity - 0.02),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: base.withOpacity(0.18)),
  );
}

ImageProvider? fileImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

Future<String?> pickImagePath() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery);
  return file?.path;
}

Future<void> showWarningPopup(BuildContext context, String message) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text("Uyarı"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tamam"),
        ),
      ],
    ),
  );
}

Future<void> showHowItWorksPopup(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text("Fısıltı nasıl çalışır? 👋"),
      content: const SingleChildScrollView(
        child: Text(
          "📝 Paylaş\n"
          "İçinden geçenleri anonim şekilde paylaşabilirsin.\n\n"
          "🖼️ Görsel ekle\n"
          "İstersen paylaşımına arka plan görseli ekleyebilirsin. Görsel hafif silik kalır, yazı ön planda olur.\n\n"
          "💬 Yorumlar\n"
          "Diğer kullanıcılar paylaşımına yorum yapabilir.\n\n"
          "🔒 Özel Sohbet\n"
          "Burada herkes herkese yazamaz. Sadece kendi paylaşımına yorum yapan kişiler arasından, sen istersen birine sohbet isteği gönderebilirsin.\n\n"
          "✅ Kontrol sende\n"
          "Kimse sana durduk yere özel mesaj atamaz.\n\n"
          "🤝 Saygılı ol\n"
          "Empati kur, kırıcı olma, güvenli alanı koru.",
          style: TextStyle(height: 1.45),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Anladım"),
        ),
      ],
    ),
  );
}

Future<File> captureWidget(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();
  final file = File(
    '${Directory.systemTemp.path}/fisilti_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(pngBytes);
  return file;
}

Future<void> showShareSheet(
  BuildContext context,
  Post post,
  AppUser author,
) async {
  final topComments = List<Comment>.from(post.comments)
    ..sort((a, b) => b.likeCount.compareTo(a.likeCount));
  final bestThree = topComments.take(3).toList();
  final repaintKey = GlobalKey();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 40, child: Divider(thickness: 4)),
            const SizedBox(height: 12),
            SizedBox(
              width: 320,
              height: 568,
              child: SharePreviewCard(
                repaintKey: repaintKey,
                post: post,
                author: author,
                comments: bestThree,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  final file = await captureWidget(repaintKey);
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: "Fısıltı'da bir paylaşım gördüm 👇",
                  );
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text("Kartı PNG Olarak Paylaş"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fısıltı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) {
        return Container(
          color: const Color(0xFF050505),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
                minWidth: 360,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      home: const GenderSelectionPage(),
    );
  }
}

class GenderSelectionPage extends StatefulWidget {
  const GenderSelectionPage({super.key});

  @override
  State<GenderSelectionPage> createState() => _GenderSelectionPageState();
}

class _GenderSelectionPageState extends State<GenderSelectionPage> {
  final UserSetupData setupData = UserSetupData();
  String? selectedGender;

  final List<String> genderOptions = const [
    "Kadın",
    "Erkek",
    "Diğer",
    "Belirtmek İstemiyorum",
  ];

  void goNext() {
    if (selectedGender == null) return;
    setupData.gender = selectedGender;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupPage(setupData: setupData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: "Seni biraz tanıyalım",
      subtitle: "Önce temel bilgilerini seçelim",
      child: Column(
        children: [
          ...genderOptions.map(
            (gender) => SelectionCard(
              title: gender,
              selected: selectedGender == gender,
              onTap: () => setState(() => selectedGender = gender),
            ),
          ),
          const Spacer(),
          PrimaryButton(text: "Devam Et", onPressed: goNext),
        ],
      ),
    );
  }
}

class ProfileSetupPage extends StatefulWidget {
  final UserSetupData setupData;

  const ProfileSetupPage({super.key, required this.setupData});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController controller = TextEditingController();
  String? errorText;
  String? selectedImagePath;
  bool loadingImage = false;

  bool _isLetter(String char) {
    return RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ]').hasMatch(char);
  }

  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.isEmpty) return "Nickname boş bırakılamaz.";
    if (nickname.length > 20) return "Nickname en fazla 20 karakter olabilir.";
    if (!RegExp(r'^[a-zA-Z0-9çÇğĞıİöÖşŞüÜ]+$').hasMatch(nickname)) {
      return "Sadece harf ve rakam kullanabilirsin.";
    }
    if (RegExp(r'^\d+$').hasMatch(nickname)) {
      return "Nickname sadece sayılardan oluşamaz.";
    }
    final int letterCount =
        nickname.split('').where((char) => _isLetter(char)).length;
    final double ratio = letterCount / nickname.length;
    if (ratio < 0.90) return "Nickname'in en az %90'ı harflerden oluşmalı.";
    if (ContentModerator.containsProfanity(nickname)) {
      return "Bu nickname topluluk kurallarına uygun değil.";
    }
    return null;
  }

  Future<void> pickProfileImage() async {
    setState(() => loadingImage = true);
    final path = await pickImagePath();
    if (!mounted) return;
    setState(() {
      selectedImagePath = path;
      loadingImage = false;
    });
  }

  void finishSetup() {
    final nickname = controller.text.trim().toLowerCase();
    final validation = validateNickname(nickname);
    setState(() => errorText = validation);
    if (validation != null) return;

    if (selectedImagePath == null || selectedImagePath!.isEmpty) {
      showWarningPopup(
        context,
        "Devam edebilmek için profil fotoğrafı seçmelisin.",
      );
      return;
    }

    widget.setupData.nickname = nickname;
    widget.setupData.profileImagePath = selectedImagePath;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainShell(setupData: widget.setupData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = fileImageProvider(selectedImagePath);

    return OnboardingScaffold(
      title: "Profilini tamamla",
      subtitle: "Profil fotoğrafı zorunlu",
      child: Column(
        children: [
          GestureDetector(
            onTap: pickProfileImage,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white12,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? loadingImage
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.add_a_photo_rounded, size: 32)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: pickProfileImage,
            child: const Text("Fotoğraf Seç"),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            maxLength: 20,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              prefixText: "@",
              hintText: "nickname",
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Sadece harf ve rakam kullan. Sadece sayı yazamazsın.",
            style: TextStyle(color: Colors.white60),
          ),
          const Spacer(),
          PrimaryButton(text: "Uygulamaya Başla", onPressed: finishSetup),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final UserSetupData setupData;

  const MainShell({super.key, required this.setupData});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final Map<String, AppUser> users;
  late final List<Post> posts;
  late final List<ChatRequest> chatRequests;
  late final List<ChatThread> chatThreads;

  final PageController pageController = PageController();
  int currentPageIndex = 0;
  int selectedTabIndex = 0;
  String selectedCategory = "Tümü";
  String selectedType = "Tümü";

  AppUser get currentUser => users["@${widget.setupData.nickname}"]!;

  @override
  void initState() {
    super.initState();

    users = {
      "@mavigece": AppUser(
        nickname: "@mavigece",
        gender: "Kadın",
        profileImagePath: null,
        bio: "Bazen sadece içimi dökmek istiyorum.",
      ),
      "@sessizbiri": AppUser(
        nickname: "@sessizbiri",
        gender: "Kadın",
        profileImagePath: null,
        bio: "Sessiz ama düşündüğünden fazla şey hissediyor.",
      ),
      "@geceyolcu": AppUser(
        nickname: "@geceyolcu",
        gender: "Erkek",
        profileImagePath: null,
        bio: "Gece daha çok düşünenlerden.",
      ),
      "@yorgunbiri": AppUser(
        nickname: "@yorgunbiri",
        gender: "Erkek",
        profileImagePath: null,
        bio: "Biraz yorgun, biraz dalgın.",
      ),
      "@${widget.setupData.nickname}": AppUser(
        nickname: "@${widget.setupData.nickname}",
        gender: widget.setupData.gender,
        profileImagePath: widget.setupData.profileImagePath,
        bio: "",
      ),
    };

    posts = [
      Post(
        id: "p1",
        content: "Sevdiğim kişi beni sadece arkadaş olarak görüyor.",
        category: "Aşk-İlişki",
        type: "Dert",
        nickname: "@mavigece",
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likeCount: 12,
        comments: [
          Comment(
            id: "c1",
            postId: "p1",
            nickname: "@sessizbiri",
            content:
                "Bazen biraz geri çekilmek karşı tarafın ilgisini ölçmek için işe yarıyor.",
            replyTargetNickname: "@mavigece",
          ),
          Comment(
            id: "c2",
            postId: "p1",
            nickname: "@geceyolcu",
            content: "Bence önce açıkça konuşmayı dene.",
            replyTargetNickname: "@mavigece",
          ),
        ],
      ),
      Post(
        id: "p2",
        content: "Patronuma yanlış mesaj attım ve rezil oldum.",
        category: "İş Hayatı",
        type: "İtiraf",
        nickname: "@yorgunbiri",
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        likeCount: 7,
      ),
      Post(
        id: "p3",
        content: "Bu bölüm gerçekten okunur mu yoksa bırakmalı mıyım?",
        category: "Okul Hayatı",
        type: "Soru",
        nickname: "@sessizbiri",
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        likeCount: 4,
      ),
    ];

    chatRequests = [];
    chatThreads = [];
  }

  double _score(Post post) {
    final commentCount =
        post.comments.where((c) => c.parentCommentId == null).length;
    final hours = DateTime.now().difference(post.createdAt).inHours;
    final freshness = 24 / (hours + 1);
    return post.likeCount + commentCount * 2 + freshness;
  }

  List<Post> get sortedPosts {
    final cloned = List<Post>.from(posts);
    cloned.sort((a, b) => _score(b).compareTo(_score(a)));
    return cloned;
  }

  List<Post> get filteredPosts {
    return sortedPosts.where((post) {
      final categoryOk =
          selectedCategory == "Tümü" || post.category == selectedCategory;
      final typeOk = selectedType == "Tümü" || post.type == selectedType;
      return categoryOk && typeOk;
    }).toList();
  }

  List<Post> get favoritePosts =>
      sortedPosts.where((post) => post.isLiked).toList();

  bool canSendChatRequestTo({
    required String fromUser,
    required String toUser,
  }) {
    final hasPending = chatRequests.any(
      (r) =>
          r.fromUser == fromUser &&
          r.toUser == toUser &&
          !r.accepted &&
          !r.rejected,
    );
    final hasThread = chatThreads.any((thread) => thread.otherUser == toUser);
    return !hasPending && !hasThread;
  }

  void sendChatRequest({
    required String fromUser,
    required String toUser,
    required String relatedPostId,
  }) {
    if (!canSendChatRequestTo(fromUser: fromUser, toUser: toUser)) return;
    setState(() {
      chatRequests.insert(
        0,
        ChatRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromUser: fromUser,
          toUser: toUser,
          relatedPostId: relatedPostId,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  ChatThread acceptChatRequest(ChatRequest request) {
    request.accepted = true;
    final existing = chatThreads.where((t) => t.otherUser == request.fromUser);
    if (existing.isNotEmpty) return existing.first;

    final thread = ChatThread(
      id: "thread_${request.id}",
      otherUser: request.fromUser,
      relatedPostId: request.relatedPostId,
      updatedAt: DateTime.now(),
      messages: [
        ChatMessage(
          id: "m_${request.id}",
          sender: request.fromUser,
          text: "Sohbet isteği kabul edildi 👋",
          createdAt: DateTime.now(),
        ),
      ],
      unreadCount: 1,
    );

    setState(() {
      chatThreads.insert(0, thread);
    });
    return thread;
  }

  void rejectChatRequest(ChatRequest request) {
    setState(() {
      request.rejected = true;
    });
  }

  void sendMessage(ChatThread thread, String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      thread.messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          sender: currentUser.nickname,
          text: text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      thread.updatedAt = DateTime.now();
    });
  }

  void togglePostLike(Post post) {
    setState(() {
      if (post.isLiked) {
        post.isLiked = false;
        if (post.likeCount > 0) post.likeCount -= 1;
      } else {
        post.isLiked = true;
        post.likeCount += 1;
      }
    });
  }

  void goToNextPost() {
    final displayedPosts = filteredPosts;
    if (displayedPosts.isEmpty) return;

    final nextIndex =
        currentPageIndex < displayedPosts.length - 1 ? currentPageIndex + 1 : 0;

    pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> openCreatePostPage() async {
    final newPost = await Navigator.push<Post>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostPage(
          nickname: currentUser.nickname.replaceAll("@", ""),
        ),
      ),
    );

    if (newPost != null) {
      setState(() {
        posts.insert(0, newPost);
        selectedTabIndex = 0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        pageController.jumpToPage(0);
        setState(() => currentPageIndex = 0);
      });
    }
  }

  Future<void> openCommentsPage(Post post) async {
    setState(() => post.unreadCommentCount = 0);

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          post: post,
          currentUser: currentUser,
          users: users,
          isPostOwner: post.nickname == currentUser.nickname,
          canSendChatRequestTo: (targetNick) => canSendChatRequestTo(
            fromUser: currentUser.nickname,
            toUser: targetNick,
          ),
          onSendChatRequest: (targetNick) {
            sendChatRequest(
              fromUser: currentUser.nickname,
              toUser: targetNick,
              relatedPostId: post.id,
            );
          },
        ),
      ),
    );

    setState(() {});
  }

  void updateProfile({
    required String newNicknameRaw,
    required String? newGender,
    required String? newProfileImagePath,
    required String newBio,
  }) {
    final oldNickname = currentUser.nickname;
    final newNickname = "@$newNicknameRaw";

    setState(() {
      for (int i = 0; i < posts.length; i++) {
        final post = posts[i];
        final updatedComments = post.comments
            .map(
              (comment) => Comment(
                id: comment.id,
                postId: comment.postId,
                content: comment.content,
                nickname:
                    comment.nickname == oldNickname ? newNickname : comment.nickname,
                replyTargetNickname: comment.replyTargetNickname == oldNickname
                    ? newNickname
                    : comment.replyTargetNickname,
                parentCommentId: comment.parentCommentId,
                likeCount: comment.likeCount,
                isLiked: comment.isLiked,
              ),
            )
            .toList();

        posts[i] = Post(
          id: post.id,
          content: post.content,
          category: post.category,
          type: post.type,
          nickname: post.nickname == oldNickname ? newNickname : post.nickname,
          createdAt: post.createdAt,
          backgroundImagePath: post.backgroundImagePath,
          comments: updatedComments,
          likeCount: post.likeCount,
          isLiked: post.isLiked,
          unreadCommentCount: post.unreadCommentCount,
        );
      }

      for (int i = 0; i < chatRequests.length; i++) {
        final r = chatRequests[i];
        chatRequests[i] = ChatRequest(
          id: r.id,
          fromUser: r.fromUser == oldNickname ? newNickname : r.fromUser,
          toUser: r.toUser == oldNickname ? newNickname : r.toUser,
          relatedPostId: r.relatedPostId,
          createdAt: r.createdAt,
          accepted: r.accepted,
          rejected: r.rejected,
        );
      }

      for (final thread in chatThreads) {
        if (thread.otherUser == oldNickname) {
          thread.otherUser = newNickname;
        }
        for (int i = 0; i < thread.messages.length; i++) {
          final msg = thread.messages[i];
          if (msg.sender == oldNickname) {
            thread.messages[i] = ChatMessage(
              id: msg.id,
              sender: newNickname,
              text: msg.text,
              createdAt: msg.createdAt,
            );
          }
        }
      }

      final user = users.remove(oldNickname)!;
      user.nickname = newNickname;
      user.gender = newGender;
      user.profileImagePath = newProfileImagePath;
      user.bio = newBio;
      users[newNickname] = user;

      widget.setupData.nickname = newNicknameRaw;
      widget.setupData.gender = newGender;
      widget.setupData.profileImagePath = newProfileImagePath;
    });
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(0, -1),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.18),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/logo.png",
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Fısıltı",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          HelpPulseButton(onTap: () => showHowItWorksPopup(context)),
        ],
      ),
    );
  }

  Widget buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = kCategories[index];
                final selected = selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      currentPageIndex = 0;
                    });
                    pageController.jumpToPage(0);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("İçerik tipi", style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      dropdownColor: Colors.grey.shade900,
                      isExpanded: true,
                      items: kContentTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedType = value;
                          currentPageIndex = 0;
                        });
                        pageController.jumpToPage(0);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildHomeTab() {
    final displayedPosts = filteredPosts;

    return Column(
      children: [
        buildHeader(),
        buildFilters(),
        Expanded(
          child: displayedPosts.isEmpty
              ? const Center(
                  child: Text(
                    "Bu filtrede paylaşım bulunamadı.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : PageView.builder(
                  controller: pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: displayedPosts.length,
                  onPageChanged: (index) {
                    setState(() => currentPageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final post = displayedPosts[index];
                    final author = users[post.nickname]!;
                    return PostCard(
                      post: post,
                      author: author,
                      onCommentTap: () => openCommentsPage(post),
                      onLikeTap: () => togglePostLike(post),
                      onPassTap: goToNextPost,
                      onShareTap: () => showShareSheet(context, post, author),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget buildFavoritesTab() {
    if (favoritePosts.isEmpty) {
      return const Center(
        child: Text(
          "Henüz favori postun yok.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoritePosts.length,
      itemBuilder: (context, index) {
        final post = favoritePosts[index];
        final author = users[post.nickname]!;
        final rootCommentCount =
            post.comments.where((c) => c.parentCommentId == null).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration:
              genderCardDecoration(author.gender, opacity: 0.20, radius: 20),
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(imagePath: author.profileImagePath, radius: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      author.nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _Tag(text: post.category),
                  const SizedBox(width: 8),
                  _Tag(text: post.type),
                ],
              ),
              const SizedBox(height: 14),
              Text(post.content,
                  style: const TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.favorite,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Text("${post.likeCount} beğeni"),
                  const SizedBox(width: 16),
                  UnreadCommentBadgeIcon(count: post.unreadCommentCount),
                  const SizedBox(width: 6),
                  Text("$rootCommentCount yorum"),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showShareSheet(context, post, author),
                    child: const Text("Paylaş"),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => openCommentsPage(post),
                    child: const Text("Aç"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildProfileTab() {
    final myPostCount =
        posts.where((post) => post.nickname == currentUser.nickname).length;
    final favoriteCount = posts.where((post) => post.isLiked).length;
    final chatCount = chatThreads.length +
        chatRequests
            .where((r) =>
                !r.rejected &&
                (r.toUser == currentUser.nickname ||
                    r.fromUser == currentUser.nickname))
            .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              UserAvatar(imagePath: currentUser.profileImagePath, radius: 46),
              const SizedBox(height: 14),
              Text(
                currentUser.nickname,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                currentUser.gender ?? "Belirtilmedi",
                style: const TextStyle(color: Colors.white70),
              ),
              if (currentUser.bio.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  currentUser.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push<EditProfileResult>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          currentNickname: currentUser.nickname.replaceAll("@", ""),
                          currentGender: currentUser.gender,
                          currentProfileImagePath: currentUser.profileImagePath,
                          currentBio: currentUser.bio,
                        ),
                      ),
                    );

                    if (result != null) {
                      updateProfile(
                        newNicknameRaw: result.nickname,
                        newGender: result.gender,
                        newProfileImagePath: result.profileImagePath,
                        newBio: result.bio,
                      );
                    }
                  },
                  child: const Text("Profili Düzenle"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: "Paylaşım",
                value: "$myPostCount",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyPostsPage(
                        nickname: currentUser.nickname,
                        posts: posts,
                        users: users,
                        onShareTap: (post) =>
                            showShareSheet(context, post, users[post.nickname]!),
                        onCommentTap: openCommentsPage,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: "Favori",
                value: "$favoriteCount",
                onTap: () => setState(() => selectedTabIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: "Sohbetlerim",
                value: "$chatCount",
                onTap: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatsPage(
                        currentUser: currentUser,
                        requests: chatRequests,
                        threads: chatThreads,
                        posts: posts,
                        users: users,
                        onAcceptRequest: acceptChatRequest,
                        onRejectRequest: rejectChatRequest,
                        onSendMessage: sendMessage,
                      ),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    String title;

    if (selectedTabIndex == 0) {
      body = buildHomeTab();
      title = "Akış";
    } else if (selectedTabIndex == 1) {
      body = buildFavoritesTab();
      title = "Favoriler";
    } else {
      body = buildProfileTab();
      title = "Profil";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: selectedTabIndex == 0
            ? body
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF111111),
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: "Akış",
                selected: selectedTabIndex == 0,
                onTap: () => setState(() => selectedTabIndex = 0),
              ),
              _BottomNavItem(
                icon: Icons.favorite_rounded,
                label: "Favoriler",
                selected: selectedTabIndex == 1,
                onTap: () => setState(() => selectedTabIndex = 1),
              ),
              _BottomActionItem(
                icon: Icons.add_circle_outline_rounded,
                label: "Yeni Post",
                onTap: openCreatePostPage,
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: "Profil",
                selected: selectedTabIndex == 2,
                onTap: () => setState(() => selectedTabIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final AppUser author;
  final VoidCallback onCommentTap;
  final VoidCallback onLikeTap;
  final VoidCallback onPassTap;
  final VoidCallback onShareTap;

  const PostCard({
    super.key,
    required this.post,
    required this.author,
    required this.onCommentTap,
    required this.onLikeTap,
    required this.onPassTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgProvider = fileImageProvider(post.backgroundImagePath);
    final rootCommentCount =
        post.comments.where((c) => c.parentCommentId == null).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: genderCardDecoration(
                  author.gender,
                  opacity: 0.24,
                  radius: 26,
                ),
              ),
            ),
            if (bgProvider != null)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Image(
                    image: bgProvider,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.22),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.10),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.14),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/logo.png",
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      UserAvatar(
                        imagePath: author.profileImagePath,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          author.nickname,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _Tag(text: post.category),
                      const SizedBox(width: 8),
                      _Tag(text: post.type),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    post.content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.42,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 12,
                          children: [
                            AnimatedActionButton(
                              icon: Icons.close_rounded,
                              label: "Geç",
                              onTap: onPassTap,
                              iconColor: Colors.redAccent,
                              textColor: Colors.redAccent,
                            ),
                            AnimatedActionButton(
                              icon: post.isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: "Beğen",
                              onTap: onLikeTap,
                              iconColor:
                                  post.isLiked ? Colors.redAccent : Colors.white,
                              textColor:
                                  post.isLiked ? Colors.redAccent : Colors.white,
                              trailingCountText: "(${post.likeCount})",
                            ),
                            AnimatedActionButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: "Yorum",
                              onTap: onCommentTap,
                              iconColor: Colors.white,
                              textColor: Colors.white,
                              trailingCountText: "(${rootCommentCount})",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onShareTap,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.share_rounded,
                            color: Colors.greenAccent,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsPage extends StatefulWidget {
  final Post post;
  final AppUser currentUser;
  final Map<String, AppUser> users;
  final bool isPostOwner;
  final bool Function(String targetNick) canSendChatRequestTo;
  final ValueChanged<String> onSendChatRequest;

  const CommentsPage({
    super.key,
    required this.post,
    required this.currentUser,
    required this.users,
    required this.isPostOwner,
    required this.canSendChatRequestTo,
    required this.onSendChatRequest,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController controller = TextEditingController();
  Comment? replyingTo;

  List<Comment> get rootComments =>
      widget.post.comments.where((c) => c.parentCommentId == null).toList();

  List<Comment> repliesOf(String parentId) =>
      widget.post.comments.where((c) => c.parentCommentId == parentId).toList();

  void startReply(Comment comment) {
    setState(() => replyingTo = comment);
  }

  void clearReply() {
    setState(() => replyingTo = null);
  }

  void toggleLike(Comment comment) {
    setState(() {
      if (comment.isLiked) {
        comment.isLiked = false;
        if (comment.likeCount > 0) comment.likeCount -= 1;
      } else {
        comment.isLiked = true;
        comment.likeCount += 1;
      }
    });
  }

  Future<void> submitComment() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (ContentModerator.containsProfanity(text)) {
      await showWarningPopup(
        context,
        "Bu içerik topluluk kurallarına uygun değil. Lütfen daha uygun bir ifade kullan.",
      );
      return;
    }

    final target =
        replyingTo == null ? widget.post.nickname : replyingTo!.nickname;

    setState(() {
      widget.post.comments.add(
        Comment(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          postId: widget.post.id,
          content: text,
          nickname: widget.currentUser.nickname,
          replyTargetNickname: target,
          parentCommentId: replyingTo?.id,
        ),
      );
      widget.post.unreadCommentCount += 1;
      controller.clear();
      replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final postAuthor = widget.users[widget.post.nickname]!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Yorumlar"),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration:
                genderCardDecoration(postAuthor.gender, opacity: 0.18, radius: 20),
            child: Column(
              children: [
                UserAvatar(imagePath: postAuthor.profileImagePath, radius: 28),
                const SizedBox(height: 10),
                Text(
                  postAuthor.nickname,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Tag(text: widget.post.category),
                    const Spacer(),
                    _Tag(text: widget.post.type),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.post.content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: rootComments.isEmpty
                ? const Center(
                    child: Text(
                      "Henüz yorum yok.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rootComments.length,
                    itemBuilder: (context, index) {
                      final comment = rootComments[index];
                      final replies = repliesOf(comment.id);
                      final commentAuthor = widget.users[comment.nickname]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommentCard(
                            comment: comment,
                            author: commentAuthor,
                            onLike: () => toggleLike(comment),
                            onReply: () => startReply(comment),
                            showChatRequest: widget.isPostOwner &&
                                comment.nickname != widget.currentUser.nickname &&
                                widget.canSendChatRequestTo(comment.nickname),
                            onChatRequest: () {
                              widget.onSendChatRequest(comment.nickname);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${comment.nickname} kullanıcısına sohbet isteği gönderildi.",
                                  ),
                                ),
                              );
                              setState(() {});
                            },
                          ),
                          if (replies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Column(
                                children: replies.map((reply) {
                                  final replyAuthor =
                                      widget.users[reply.nickname]!;
                                  return CommentCard(
                                    comment: reply,
                                    author: replyAuthor,
                                    onLike: () => toggleLike(reply),
                                    onReply: () => startReply(reply),
                                    isReply: true,
                                    showChatRequest: false,
                                    onChatRequest: null,
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
          if (replyingTo != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${replyingTo!.nickname} kullanıcısına yanıt veriliyor",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  GestureDetector(
                    onTap: clearReply,
                    child: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: replyingTo == null
                            ? "Yorum yaz..."
                            : "${replyingTo!.nickname} için yanıt yaz...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: submitComment,
                      child: const Text("Gönder"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentCard extends StatefulWidget {
  final Comment comment;
  final AppUser author;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final bool isReply;
  final bool showChatRequest;
  final VoidCallback? onChatRequest;

  const CommentCard({
    super.key,
    required this.comment,
    required this.author,
    required this.onLike,
    required this.onReply,
    this.isReply = false,
    required this.showChatRequest,
    required this.onChatRequest,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  double scale = 1.0;

  void handleLike() {
    widget.onLike();
    setState(() => scale = 1.12);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: widget.isReply ? 8 : 10),
      padding: const EdgeInsets.all(14),
      decoration: genderCardDecoration(
        widget.author.gender,
        opacity: widget.isReply ? 0.12 : 0.17,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(imagePath: widget.author.profileImagePath, radius: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${widget.comment.nickname}  →  ${widget.comment.replyTargetNickname}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.comment.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: handleLike,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 120),
                      child: Icon(
                        widget.comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: widget.comment.isLiked
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text("${widget.comment.likeCount}"),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onReply,
                child: const Text("Yanıtla"),
              ),
              if (widget.showChatRequest)
                GestureDetector(
                  onTap: widget.onChatRequest,
                  child: const Text("Sohbet isteği gönder"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreatePostPage extends StatefulWidget {
  final String nickname;

  const CreatePostPage({super.key, required this.nickname});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController controller = TextEditingController();
  String selectedCategory = kCategories[1];
  String selectedType = kContentTypes[1];
  String? selectedBackgroundImagePath;
  bool loadingImage = false;

  Future<void> pickBackgroundImage() async {
    setState(() => loadingImage = true);
    final path = await pickImagePath();
    if (!mounted) return;
    setState(() {
      selectedBackgroundImagePath = path;
      loadingImage = false;
    });
  }

  Future<void> submitPost() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (ContentModerator.containsProfanity(text)) {
      await showWarningPopup(
        context,
        "Bu içerik topluluk kurallarına uygun değil. Lütfen daha uygun bir ifade kullan.",
      );
      return;
    }

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      category: selectedCategory,
      type: selectedType,
      nickname: "@${widget.nickname}",
      createdAt: DateTime.now(),
      backgroundImagePath: selectedBackgroundImagePath,
    );

    if (!mounted) return;
    Navigator.pop(context, newPost);
  }

  @override
  Widget build(BuildContext context) {
    final categories = kCategories.where((e) => e != "Tümü").toList();
    final types = kContentTypes.where((e) => e != "Tümü").toList();
    final previewImage = fileImageProvider(selectedBackgroundImagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Yeni Paylaşım"),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: selectedCategory,
            dropdownColor: Colors.grey.shade900,
            decoration: InputDecoration(
              labelText: "Kategori",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: categories
                .map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedCategory = value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedType,
            dropdownColor: Colors.grey.shade900,
            decoration: InputDecoration(
              labelText: "İçerik Türü",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: types
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedType = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 6,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: "İçinde ne varsa yaz...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Arka plan görseli (opsiyonel)",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: pickBackgroundImage,
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                image: previewImage != null
                    ? DecorationImage(
                        image: previewImage,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.25),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              child: Center(
                child: loadingImage
                    ? const CircularProgressIndicator()
                    : Text(
                        previewImage == null ? "Görsel Seç" : "Görseli Değiştir",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: submitPost,
              child: const Text("Paylaş"),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final String currentNickname;
  final String? currentGender;
  final String? currentProfileImagePath;
  final String currentBio;

  const EditProfilePage({
    super.key,
    required this.currentNickname,
    required this.currentGender,
    required this.currentProfileImagePath,
    required this.currentBio,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController controller;
  late final TextEditingController bioController;
  String? selectedGender;
  String? selectedProfileImagePath;
  String? errorText;
  bool loadingImage = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.currentNickname);
    bioController = TextEditingController(text: widget.currentBio);
    selectedGender = widget.currentGender;
    selectedProfileImagePath = widget.currentProfileImagePath;
  }

  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.isEmpty) return "Nickname boş bırakılamaz.";
    if (nickname.length > 20) return "Nickname en fazla 20 karakter olabilir.";
    if (!RegExp(r'^[a-zA-Z0-9çÇğĞıİöÖşŞüÜ]+$').hasMatch(nickname)) {
      return "Sadece harf ve rakam kullanabilirsin.";
    }
    if (RegExp(r'^\d+$').hasMatch(nickname)) {
      return "Nickname sadece sayılardan oluşamaz.";
    }
    if (ContentModerator.containsProfanity(nickname)) {
      return "Bu nickname topluluk kurallarına uygun değil.";
    }
    return null;
  }

  Future<void> pickProfileImage() async {
    setState(() => loadingImage = true);
    final path = await pickImagePath();
    if (!mounted) return;
    setState(() {
      selectedProfileImagePath = path ?? selectedProfileImagePath;
      loadingImage = false;
    });
  }

  void save() {
    final nick = controller.text.trim().toLowerCase();
    final validation = validateNickname(nick);
    setState(() => errorText = validation);
    if (validation != null) return;

    if (selectedProfileImagePath == null || selectedProfileImagePath!.isEmpty) {
      showWarningPopup(context, "Profil fotoğrafı zorunlu.");
      return;
    }

    Navigator.pop(
      context,
      EditProfileResult(
        nickname: nick,
        gender: selectedGender,
        profileImagePath: selectedProfileImagePath,
        bio: bioController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = fileImageProvider(selectedProfileImagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Profili Düzenle"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white12,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? loadingImage
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.person, size: 32)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: pickProfileImage,
            child: const Text("Fotoğrafı Değiştir"),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            maxLength: 20,
            decoration: InputDecoration(
              prefixText: "@",
              hintText: "nickname",
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: bioController,
            maxLength: 120,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Biyografi ekle...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedGender,
            dropdownColor: Colors.grey.shade900,
            decoration: InputDecoration(
              labelText: "Cinsiyet",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: const [
              DropdownMenuItem(value: "Kadın", child: Text("Kadın")),
              DropdownMenuItem(value: "Erkek", child: Text("Erkek")),
              DropdownMenuItem(value: "Diğer", child: Text("Diğer")),
              DropdownMenuItem(
                value: "Belirtmek İstemiyorum",
                child: Text("Belirtmek İstemiyorum"),
              ),
            ],
            onChanged: (value) => setState(() => selectedGender = value),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: save,
              child: const Text("Kaydet"),
            ),
          ),
        ],
      ),
    );
  }
}

class MyPostsPage extends StatelessWidget {
  final String nickname;
  final List<Post> posts;
  final Map<String, AppUser> users;
  final ValueChanged<Post> onShareTap;
  final ValueChanged<Post> onCommentTap;

  const MyPostsPage({
    super.key,
    required this.nickname,
    required this.posts,
    required this.users,
    required this.onShareTap,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    final myPosts = posts.where((post) => post.nickname == nickname).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Paylaşımlarım"),
      ),
      body: myPosts.isEmpty
          ? const Center(
              child: Text(
                "Henüz paylaşımın yok.",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myPosts.length,
              itemBuilder: (context, index) {
                final post = myPosts[index];
                final author = users[post.nickname]!;
                final rootCommentCount =
                    post.comments.where((c) => c.parentCommentId == null).length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration:
                      genderCardDecoration(author.gender, opacity: 0.20, radius: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          UserAvatar(imagePath: author.profileImagePath, radius: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              author.nickname,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _Tag(text: post.category),
                          const SizedBox(width: 8),
                          _Tag(text: post.type),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post.content,
                          style: const TextStyle(fontSize: 16, height: 1.4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              size: 16, color: Colors.redAccent),
                          const SizedBox(width: 6),
                          Text("${post.likeCount} beğeni"),
                          const SizedBox(width: 16),
                          UnreadCommentBadgeIcon(count: post.unreadCommentCount),
                          const SizedBox(width: 6),
                          Text("$rootCommentCount yorum"),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => onShareTap(post),
                            child: const Text("Paylaş"),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => onCommentTap(post),
                            child: const Text("Aç"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class ChatsPage extends StatefulWidget {
  final AppUser currentUser;
  final List<ChatRequest> requests;
  final List<ChatThread> threads;
  final List<Post> posts;
  final Map<String, AppUser> users;
  final ChatThread Function(ChatRequest request) onAcceptRequest;
  final ValueChanged<ChatRequest> onRejectRequest;
  final void Function(ChatThread thread, String text) onSendMessage;

  const ChatsPage({
    super.key,
    required this.currentUser,
    required this.requests,
    required this.threads,
    required this.posts,
    required this.users,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.onSendMessage,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  List<ChatRequest> get incomingRequests => widget.requests
      .where((r) =>
          r.toUser == widget.currentUser.nickname &&
          !r.rejected &&
          !r.accepted)
      .toList();

  List<ChatRequest> get outgoingRequests => widget.requests
      .where((r) =>
          r.fromUser == widget.currentUser.nickname &&
          !r.rejected &&
          !r.accepted)
      .toList();

  String formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk";
    if (diff.inHours < 24) return "${diff.inHours} sa";
    return "${diff.inDays} g";
  }

  Post? postOf(String id) {
    try {
      return widget.posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> openIncomingRequest(ChatRequest request) async {
    final post = postOf(request.relatedPostId);
    final result = await Navigator.push<ChatThread?>(
      context,
      MaterialPageRoute(
        builder: (context) => IncomingRequestPage(
          request: request,
          sender: widget.users[request.fromUser]!,
          relatedPost: post,
          onAccept: () => widget.onAcceptRequest(request),
          onReject: () => widget.onRejectRequest(request),
        ),
      ),
    );
    if (result != null && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveChatPage(
            currentUser: widget.currentUser,
            otherUser: widget.users[result.otherUser]!,
            thread: result,
            onSendMessage: widget.onSendMessage,
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> openOutgoingRequest(ChatRequest request) async {
    final post = postOf(request.relatedPostId);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => OutgoingRequestPage(
          request: request,
          receiver: widget.users[request.toUser]!,
          relatedPost: post,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> openActiveChat(ChatThread thread) async {
    final other = widget.users[thread.otherUser]!;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveChatPage(
          currentUser: widget.currentUser,
          otherUser: other,
          thread: thread,
          onSendMessage: widget.onSendMessage,
        ),
      ),
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final activeThreads = widget.threads;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Sohbetlerim"),
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(text: "Gelen (${incomingRequests.length})"),
            Tab(text: "Gönderilen (${outgoingRequests.length})"),
            Tab(text: "Aktif (${activeThreads.length})"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          incomingRequests.isEmpty
              ? const Center(
                  child: Text(
                    "Bekleyen gelen sohbet isteği yok.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: incomingRequests.length,
                  itemBuilder: (context, index) {
                    final request = incomingRequests[index];
                    final sender = widget.users[request.fromUser]!;
                    return ChatListTile(
                      imagePath: sender.profileImagePath,
                      title: sender.nickname,
                      subtitle: "Gelen sohbet isteği",
                      trailingText: formatRelative(request.createdAt),
                      unreadCount: 0,
                      onTap: () => openIncomingRequest(request),
                    );
                  },
                ),
          outgoingRequests.isEmpty
              ? const Center(
                  child: Text(
                    "Bekleyen gönderilmiş istek yok.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: outgoingRequests.length,
                  itemBuilder: (context, index) {
                    final request = outgoingRequests[index];
                    final receiver = widget.users[request.toUser]!;
                    return ChatListTile(
                      imagePath: receiver.profileImagePath,
                      title: receiver.nickname,
                      subtitle: "Sohbet isteği gönderildi",
                      trailingText: formatRelative(request.createdAt),
                      unreadCount: 0,
                      onTap: () => openOutgoingRequest(request),
                    );
                  },
                ),
          activeThreads.isEmpty
              ? const Center(
                  child: Text(
                    "Henüz aktif sohbetin yok.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeThreads.length,
                  itemBuilder: (context, index) {
                    final thread = activeThreads[index];
                    final other = widget.users[thread.otherUser]!;
                    return ChatListTile(
                      imagePath: other.profileImagePath,
                      title: other.nickname,
                      subtitle: thread.lastMessage,
                      trailingText: formatRelative(thread.updatedAt),
                      unreadCount: thread.unreadCount,
                      onTap: () => openActiveChat(thread),
                    );
                  },
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}

class ChatListTile extends StatelessWidget {
  final String? imagePath;
  final String title;
  final String subtitle;
  final String trailingText;
  final int unreadCount;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: UserAvatar(imagePath: imagePath, radius: 22),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              trailingText,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
            const SizedBox(height: 6),
            if (unreadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$unreadCount",
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class IncomingRequestPage extends StatelessWidget {
  final ChatRequest request;
  final AppUser sender;
  final Post? relatedPost;
  final ChatThread Function() onAccept;
  final VoidCallback onReject;

  const IncomingRequestPage({
    super.key,
    required this.request,
    required this.sender,
    required this.relatedPost,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Gelen İstek"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UserAvatar(imagePath: sender.profileImagePath, radius: 42),
            const SizedBox(height: 12),
            Text(
              sender.nickname,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration:
                  genderCardDecoration(sender.gender, opacity: 0.18, radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("İlgili paylaşım",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(relatedPost?.content ?? "Paylaşım bulunamadı."),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onReject();
                      Navigator.pop(context);
                    },
                    child: const Text("Reddet"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final thread = onAccept();
                      Navigator.pop(context, thread);
                    },
                    child: const Text("Kabul Et"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OutgoingRequestPage extends StatelessWidget {
  final ChatRequest request;
  final AppUser receiver;
  final Post? relatedPost;

  const OutgoingRequestPage({
    super.key,
    required this.request,
    required this.receiver,
    required this.relatedPost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Gönderilen İstek"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UserAvatar(imagePath: receiver.profileImagePath, radius: 42),
            const SizedBox(height: 12),
            Text(
              receiver.nickname,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: genderCardDecoration(
                  receiver.gender, opacity: 0.18, radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("İlgili paylaşım",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(relatedPost?.content ?? "Paylaşım bulunamadı."),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sohbet isteğin gönderildi. Karşı tarafın yanıtı bekleniyor.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveChatPage extends StatefulWidget {
  final AppUser currentUser;
  final AppUser otherUser;
  final ChatThread thread;
  final void Function(ChatThread thread, String text) onSendMessage;

  const ActiveChatPage({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.thread,
    required this.onSendMessage,
  });

  @override
  State<ActiveChatPage> createState() => _ActiveChatPageState();
}

class _ActiveChatPageState extends State<ActiveChatPage> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    widget.thread.unreadCount = 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(imagePath: widget.otherUser.profileImagePath, radius: 18),
            const SizedBox(width: 10),
            Text(widget.otherUser.nickname),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.thread.messages.isEmpty
                ? const Center(
                    child: Text(
                      "Henüz mesaj yok.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.thread.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.thread.messages[index];
                      final isMine =
                          message.sender == widget.currentUser.nickname;

                      return Align(
                        alignment:
                            isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.white
                                : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isMine ? Colors.black : Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Mesaj yaz...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        widget.onSendMessage(widget.thread, text);
                        controller.clear();
                        setState(() {});
                      },
                      child: const Text("Gönder"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white10,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

class HelpPulseButton extends StatefulWidget {
  final VoidCallback onTap;

  const HelpPulseButton({super.key, required this.onTap});

  @override
  State<HelpPulseButton> createState() => _HelpPulseButtonState();
}

class _HelpPulseButtonState extends State<HelpPulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> scaleAnimation;
  late final Animation<double> opacityAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    opacityAnimation = Tween<double>(begin: 0.18, end: 0.34).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.redAccent.withOpacity(opacityAnimation.value),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text(
                      "?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final String? trailingCountText;

  const AnimatedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
    required this.textColor,
    this.trailingCountText,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> {
  double scale = 1.0;
  double bounce = 0.0;

  void handleTap() {
    widget.onTap();

    setState(() {
      scale = 0.90;
      bounce = -3;
    });

    Future.delayed(const Duration(milliseconds: 90), () {
      if (!mounted) return;
      setState(() {
        scale = 1.06;
        bounce = 0;
      });
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        scale = 1.0;
        bounce = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: Offset(0, bounce / 100),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: widget.iconColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.trailingCountText != null) ...[
                const SizedBox(width: 4),
                Text(
                  widget.trailingCountText!,
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white54;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
    );
  }
}

class UnreadCommentBadgeIcon extends StatelessWidget {
  final int count;

  const UnreadCommentBadgeIcon({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white54,
          size: 16,
        ),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class SharePreviewCard extends StatelessWidget {
  final Post post;
  final AppUser author;
  final List<Comment> comments;
  final GlobalKey repaintKey;

  const SharePreviewCard({
    super.key,
    required this.post,
    required this.author,
    required this.comments,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    final bgProvider = fileImageProvider(post.backgroundImagePath);

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        color: const Color(0xFF050505),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: genderCardDecoration(
                    author.gender,
                    opacity: 0.34,
                    radius: 28,
                  ),
                ),
              ),
              if (bgProvider != null)
                Positioned.fill(
                  child: Image(
                    image: bgProvider,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.08),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.04)),
              ),
              LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                            imagePath: author.profileImagePath,
                            radius: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              author.nickname,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Image.asset(
                            "assets/logo.png",
                            width: 36,
                            height: 36,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Spacer(flex: 2),
                            Text(
                              post.content,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Flexible(
                              flex: 4,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: comments.take(3).map((comment) {
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          comment.nickname,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.content,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
}