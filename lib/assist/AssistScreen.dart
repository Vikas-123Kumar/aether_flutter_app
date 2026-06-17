import 'package:flutter/material.dart';
class AssistScreen extends StatefulWidget {
  const AssistScreen({super.key});

  @override
  State<AssistScreen> createState() => _AetherChatScreenState();
}

class _AetherChatScreenState extends State<AssistScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

  // Replicate the suggested prompts from the image
  final List<String> _suggestedPrompts = [
    'Heat pump shows error E03',
    'Compressor not starting on boost',
    'How do I rebalance flow temp?',
    'Wi-Fi keeps dropping after pairing',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend([String? text]) {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add(Message(text: messageText, isUser: true));
      _textController.clear();
      // Add simple mock AI response for interaction
      _messages.add(Message(text: 'Mock response to: "$messageText"', isUser: false));
    });

    // Scroll to the bottom after sending
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

  void _handlePromptTap(String prompt) {
    _textController.text = prompt;
    _handleSend(prompt); // Automatically send the prompt
  }

  @override
  Widget build(BuildContext context) {
    // Determine counts for different item types
    int cardCount = 1; // Always show welcome card
    int messageCount = _messages.length;
    int promptCount = _suggestedPrompts.isNotEmpty ? 1 : 0; // Show prompts block if not empty

    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: const _AetherHeader(),
      ),
      body: Column(
        children: [
          // 1. Unified Scrollable Content Area - EVERYTHING above input bar
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              // Calculate total item count for different content types
              itemCount: cardCount + messageCount + promptCount,
              itemBuilder: (context, index) {
                // Determine item type based on index
                if (index < cardCount) { // Index 0: Welcome Card
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16.0), // Spacing after card
                    child: _AetherWelcomeCard(),
                  );
                } else if (index < cardCount + messageCount) { // Indices 1 to messageCount: Messages
                  final messageIndex = index - cardCount;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch bubbles/columns
                    children: [
                      // Separator only AFTER first message in this list
                      if (messageIndex > 0) const SizedBox(height: 16),
                      _ChatBubble(message: _messages[messageIndex]),
                    ],
                  );
                } else if (index < cardCount + messageCount + promptCount) { // Last index (if prompts exist): Prompts
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0), // Spacing around prompts
                    child: _SuggestedPromptsWrap(prompts: _suggestedPrompts, onPromptTap: _handlePromptTap),
                  );
                } else {
                  return const SizedBox.shrink(); // Safety fallback
                }
              },
            ),
          ),

          // 2. Fixed Bottom Input Bar - Below the full scrolling list
          _BottomInputBar(
            controller: _textController,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _AetherHeader extends StatelessWidget {
  const _AetherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Blue icon in rounded box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Sightly darker box
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.build, color: Colors.blue, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Aether Assist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // 'AI' badge like in image
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
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
          // Close button
          const Icon(Icons.close, color: Color(0xFFA1A1AA), size: 24),
        ],
      ),
    );
  }
}

class _AetherWelcomeCard extends StatelessWidget {
  const _AetherWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Removed outer margin for ListView inclusion
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2C), // Subtle darker box for whole message
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue avatar (replicated icon from image)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF1E40AF), // Dark blue for avatar background
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.build_circle, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          // Text bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF253147), // Distinct darker blue/gray bubble
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'G\'day — I\'m ',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    TextSpan(
                      text: 'Aether Assist',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: '. Ask me about install errors, commissioning, or controller settings and I\'ll point you to the fix.',
                      style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;

  const _ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!message.isUser) // AI Avatar for AI messages
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF1E40AF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat, color: Colors.white, size: 18),
          ),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.blue : const Color(0xFF253147),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                bottomRight: Radius.circular(message.isUser ? 4 : 16),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestedPromptsWrap extends StatelessWidget {
  final List<String> prompts;
  final Function(String) onPromptTap;

  const _SuggestedPromptsWrap({super.key, required this.prompts, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Removed outer padding for ListView inclusion
      padding: EdgeInsets.zero, // Padding handled around the item in ListView builder
      child: Wrap(
        spacing: 12, // Horizontal space between chips
        runSpacing: 12, // Vertical space between wrapped rows
        children: prompts.map((prompt) {
          return InkWell(
            onTap: () => onPromptTap(prompt),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark box color
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF334155), // Subtle border
                ),
              ),
              child: Text(
                prompt,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9), // Light color for prompt text
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BottomInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _BottomInputBar({super.key, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Original padding with keyboard height handling still relevant for input bar itself
      padding:  EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      color: Colors.transparent, // Maintain full depth
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask Aether Assist...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF111827), // Darker text field
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Send button in circular box (like in image)
          InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.near_me, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}