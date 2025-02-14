import 'package:example/views/widgets/search_result_overlay.dart';
import 'package:flutter/material.dart';
import 'package:example/models/post.dart';
import 'package:example/views/view_models/home_view_model.dart';
import 'package:example/views/view_models/search_view_model.dart';
import 'package:example/views/widgets/comment_text_field.dart';
import 'package:example/views/widgets/post_widget.dart';
import 'package:fluttertagger/fluttertagger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterTagger Demo',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.redAccent.withOpacity(.3),
        ),
        primarySwatch: Colors.red,
      ),
      home: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  double overlayHeight = 300;

  late final homeViewModel = HomeViewModel();
  late final _controller = FlutterTaggerController();
  late final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var insets = MediaQuery.of(context).viewInsets;
    return GestureDetector(
      onTap: _focusNode.unfocus,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          title: const Text("The Squad"),
        ),
        bottomNavigationBar: FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: _controller,
          animationController: _animationController,
          onSearch: (query, triggerChar) {
            if (triggerChar == "@") {
              searchViewModel.searchUser(query);
            }
            if (triggerChar == "#") {
              searchViewModel.searchHashtag(query);
            }
          },
          triggerCharacterAndStyles: const {
            "@": TextStyle(color: Colors.pinkAccent),
            "#": TextStyle(color: Colors.blueAccent),
          },
          tagTextFormatter: (id, tag, triggerCharacter) {
            final formatted = "$triggerCharacter$id#$tag#";
            debugPrint("MAIN FILE Formatted Tag: $formatted"); // Print each tag format
            return formatted;
          },
          overlayHeight: overlayHeight,
          overlay: SearchResultOverlay(
            animation: _animation,
            tagController: _controller,
          ),
          builder: (context, containerKey) {
            return CommentTextField(
              focusNode: _focusNode,
              containerKey: containerKey,
              insets: insets,
              controller: _controller,
              onSend: () {
                FocusScope.of(context).unfocus();
                homeViewModel.addPost(_controller.formattedText);
                debugPrint(_controller.tags.toString());

                debugPrint("Before Sending Message:");
                debugPrint("Formatted Text: ${_controller.formattedText}");
                debugPrint(
                    "Extracted Tagged IDs: ${RegExp(r'@(\w+)#').allMatches(_controller.formattedText).map((match) => match.group(1)).toSet().toList()}");


                final taggedIds = RegExp(r'@(\w+)#')
                    .allMatches(_controller.formattedText)
                    .map((match) => match.group(1))
                    .toSet()
                    .toList();
                debugPrint('-------Tagged IDs:------- $taggedIds');

                _controller.clear();
              },
            );
          },
        ),
        body: ValueListenableBuilder<List<Post>>(
          valueListenable: homeViewModel.posts,
          builder: (_, posts, __) {
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (_, index) {
                return PostWidget(post: posts[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
