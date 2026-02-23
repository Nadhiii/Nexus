import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';
import '../models/Nex_message.dart';
import '../providers/Nex_assistant_provider.dart';

/// Nex Chat Screen — embedded as a bottom navigation tab
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _hasInitialized = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AIAssistantProvider>().initialize();
        }
      });
    }
  }

  @override
  void dispose() {
    try {
      context.read<AIAssistantProvider>().cancelOngoingChat();
    } catch (_) {}
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(AppAnimations.extraFast, () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: AppAnimations.slow,
            curve: AppAnimations.fadeOutCurve,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Consumer<AIAssistantProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: _buildNexAvatar(size: 60, iconSize: 30),
              ),
            );
          }

          return Stack(
            children: [
              // Main Chat Area
              Column(
                children: [
                  const SizedBox(height: 100), // Space for glass header
                  Expanded(
                    child:
                        provider.currentConversation?.messages.isEmpty ?? true
                        ? (provider.isReady
                              ? _buildWelcomeScreen(provider)
                              : _buildSetupPrompt(provider))
                        : _buildMessageList(provider),
                  ),
                  // Space for floating input
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
                ],
              ),

              // Glassmorphic Header (Top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildGlassHeader(provider),
              ),

              // Floating Input Area (Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildFloatingInputArea(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HEADER (FROSTED GLASS)
  // ──────────────────────────────────────────────

  Widget _buildGlassHeader(AIAssistantProvider provider) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            bottom: 16,
            left: 20,
            right: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundBlack.withOpacity(0.6),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              _buildNexAvatar(size: 40, iconSize: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nex AI',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (provider.isReady)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gemma Local Active',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (provider.isReady)
                IconButton(
                  icon: const Icon(Icons.maps_ugc_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'New Chat',
                  onPressed: () => provider.startNewConversation(),
                ),
              // Removed invalid Settings navigation button
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // EMPTY STATES
  // ──────────────────────────────────────────────

  Widget _buildSetupPrompt(AIAssistantProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: _buildNexAvatar(size: 80, iconSize: 40),
            ),
            const SizedBox(height: 32),
            Text(
              'Awaken Nex.',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'I am ready to analyze your transactions, tear apart your spending, and build your wealth. Just give me the key.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            // Removed invalid Configure API Key navigation button
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(AIAssistantProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildNexAvatar(size: 60, iconSize: 30),
          const SizedBox(height: 24),
          Text(
            'Ready to dominate\nyour finances, Sir?',
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'I have full access to your ledger, budgets, and debts. Tell me what to analyze.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'SUGGESTED ACTIONS',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickPromptsGrid(provider),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsGrid(AIAssistantProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPromptCard(
                'Roast My Spending',
                Icons.local_fire_department_rounded,
                AppColors.error,
                'Brutally honest financial check.',
                () => _sendMessage(
                  'Roast my spending habits. Be brutally honest but witty.',
                  provider,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPromptCard(
                'Debt Strategy',
                Icons.trending_down_rounded,
                AppColors.accentTeal,
                'Smartest way to pay it off.',
                () => _sendMessage(
                  'Analyze my debts and give me the smartest payoff strategy.',
                  provider,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPromptCard(
                'Monthly Summary',
                Icons.pie_chart_rounded,
                AppColors.primaryBlue,
                'How am I doing this month?',
                () => _sendMessage(
                  'Give me a quick and simple summary of my finances this month.',
                  provider,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPromptCard(
                'Upcoming Bills',
                Icons.calendar_month_rounded,
                AppColors.accentOrange,
                'What is due next?',
                () => _sendMessage(
                  'What bills and subscriptions do I have coming up in the next 2 weeks?',
                  provider,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptCard(
    String title,
    IconData icon,
    Color accentColor,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MESSAGES
  // ──────────────────────────────────────────────

  Widget _buildMessageList(AIAssistantProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      itemCount:
          provider.currentConversation!.messages.length +
          (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.currentConversation!.messages.length) {
          return _buildTypingIndicator();
        }
        final message = provider.currentConversation!.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildNexAvatar(size: 32, iconSize: 16),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : AppColors.cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: !isUser
                    ? Border.all(
                        color: message.isError
                            ? AppColors.error
                            : Colors.white.withOpacity(0.05),
                      )
                    : null,
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: message.isError
                              ? AppColors.error
                              : Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        h1: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        h2: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        h3: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        strong: TextStyle(
                          color: message.isError
                              ? AppColors.error
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        code: TextStyle(
                          backgroundColor: AppColors.backgroundBlack,
                          color: const Color(0xFFA78BFA),
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.backgroundBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        listBullet: const TextStyle(color: Color(0xFFA78BFA)),
                      ),
                      selectable: true,
                    ),
            ),
          ),
          if (!isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNexAvatar(size: 32, iconSize: 16),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPulseDot(0),
                const SizedBox(width: 6),
                _buildPulseDot(1),
                const SizedBox(width: 6),
                _buildPulseDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        // Subtle looping effect achieved via parent rebuilding or provider state
      },
    );
  }

  // ──────────────────────────────────────────────
  // FLOATING INPUT AREA
  // ──────────────────────────────────────────────

  Widget _buildFloatingInputArea(AIAssistantProvider provider) {
    // We add extra padding at the bottom to sit above the bottom navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: bottomPadding,
            top: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundBlack.withOpacity(0.0),
                AppColors.backgroundBlack.withOpacity(0.8),
                AppColors.backgroundBlack,
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Command Nex...',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) =>
                        _sendMessage(_messageController.text, provider),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: GestureDetector(
                    onTap: provider.isLoading
                        ? null
                        : () => _sendMessage(_messageController.text, provider),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage(String message, AIAssistantProvider provider) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus(); // Drops the keyboard nicely
    provider.sendMessage(trimmedMessage);
  }

  // Helper for consistently styled Nex Avatar
  Widget _buildNexAvatar({required double size, required double iconSize}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: size / 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: iconSize,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic, // Adds a slight futuristic lean
          ),
        ),
      ),
    );
  }
}
