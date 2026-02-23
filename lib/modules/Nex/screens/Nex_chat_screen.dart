import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';
import '../models/Nex_message.dart';
import '../providers/Nex_assistant_provider.dart';
import 'Nex_settings_screen.dart';

/// Nex Chat Screen — embedded as a bottom navigation tab
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Critical Fix: Force initialization when screen loads
    // This prevents the "stuck on loading" bug
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
    // Cancel any in-progress generation to free resources quickly
    try {
      context.read<AIAssistantProvider>().cancelOngoingChat();
    } catch (_) {}

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
      body: SafeArea(
        child: Consumer<AIAssistantProvider>(
          builder: (context, provider, _) {
            // 1. Show loading if not initialized
            if (!provider.isInitialized) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Starting Nex...',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header
                _buildHeader(provider),

                // Messages or Welcome
                Expanded(
                  child: provider.currentConversation?.messages.isEmpty ?? true
                      ? (provider.isReady
                            ? _buildWelcomeScreen(provider)
                            : _buildSetupPrompt(provider))
                      : _buildMessageList(provider),
                ),

                // Quick Prompts (Only show if empty conversation & ready)
                if (provider.isReady &&
                    (provider.currentConversation?.messages.isEmpty ?? true))
                  _buildQuickPrompts(provider),

                // Input Area
                _buildInputArea(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────

  Widget _buildHeader(AIAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          // Nex Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nex',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (provider.isReady)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Gemma (Local) Active',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // New Chat
          if (provider.isReady)
            IconButton(
              icon: Icon(
                Icons.add_comment_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              tooltip: 'New Chat',
              onPressed: () => provider.startNewConversation(),
            ),
          // Settings
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NexSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SETUP (No API Key)
  // ──────────────────────────────────────────────

  Widget _buildSetupPrompt(AIAssistantProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hey there, Sir!',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'I\'m Nex — I see everything in your app. Transactions, debts, investments, all of it.\n\nLocal Gemma will be used when available.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NexSettingsScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Add API Key',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // WELCOME SCREEN (Has key, no messages)
  // ──────────────────────────────────────────────

  Widget _buildWelcomeScreen(AIAssistantProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ready when you are.',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'I can see all your accounts, transactions, debts, and investments. Ask me anything.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // MESSAGE LIST
  // ──────────────────────────────────────────────

  Widget _buildMessageList(AIAssistantProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (isUser) const SizedBox(width: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF6366F1)
                        : (message.isError
                              ? AppColors.error.withOpacity(0.2)
                              : AppColors.cardSurface),
                    borderRadius: isUser
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(4),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(18),
                          ),
                    border: message.isError
                        ? Border.all(color: AppColors.error, width: 1)
                        : null,
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: message.isError
                                  ? AppColors.error
                                  : Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            strong: TextStyle(
                              color: message.isError
                                  ? AppColors.error
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            em: TextStyle(
                              color: message.isError
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            code: TextStyle(
                              backgroundColor: AppColors.backgroundBlack,
                              color: const Color(0xFF6366F1),
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: AppColors.backgroundBlack,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          selectable: true,
                        ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickPrompts(AIAssistantProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPromptChip(
              'Monthly Summary',
              Icons.summarize,
              () => _sendMessage(
                'Give me a quick summary of my finances this month. How am I doing?',
                provider,
              ),
            ),
            _buildPromptChip(
              'Roast My Spending',
              Icons.local_fire_department,
              () => _sendMessage(
                'Roast my spending habits. Be brutally honest but funny.',
                provider,
              ),
            ),
            _buildPromptChip(
              'Debt Strategy',
              Icons.trending_down,
              () => _sendMessage(
                'What\'s the smartest way to tackle my debts? Give me a plan.',
                provider,
              ),
            ),
            _buildPromptChip(
              'Upcoming Bills',
              Icons.calendar_today,
              () => _sendMessage(
                'What bills and payments do I have coming up in the next 2 weeks?',
                provider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(AIAssistantProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 80, // Adjust for bottom nav bar
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask Nex anything...',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) =>
                    _sendMessage(_messageController.text, provider),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
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
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String message, AIAssistantProvider provider) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    _messageController.clear();
    provider.sendMessage(trimmedMessage);
  }
}
