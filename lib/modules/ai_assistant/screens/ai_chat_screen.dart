import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/ai_message.dart';
import '../models/ai_settings.dart';
import '../providers/ai_assistant_provider.dart';
import 'ai_settings_screen.dart';

/// AI Chat Screen
/// Main interface for chatting with Nex
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AIAssistantProvider>();
      if (!provider.isInitialized) {
        provider.initialize();
      }
      if (provider.currentConversation == null && provider.isReady) {
        provider.startNewConversation();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildAppBar(),
      body: Consumer<AIAssistantProvider>(
        builder: (context, provider, _) {
          // Always allow interaction - witty responses handle no-key case
          return Column(
            children: [
              // Messages or Setup/Welcome
              Expanded(
                child: provider.currentConversation?.messages.isEmpty ?? true
                    ? (provider.isReady
                          ? _buildWelcomeScreen(provider)
                          : _buildSetupPrompt(provider))
                    : _buildMessageList(provider),
              ),

              // Quick Prompts (only when ready and no messages)
              if (provider.isReady &&
                  (provider.currentConversation?.messages.isEmpty ?? true))
                _buildQuickPrompts(provider),

              // Input - always show so user can try and get witty responses
              _buildInputArea(provider),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundBlack,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer<AIAssistantProvider>(
        builder: (context, provider, _) {
          return Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nex',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    provider.isReady
                        ? provider.activeModelName
                        : 'Not configured',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        // New Chat
        Consumer<AIAssistantProvider>(
          builder: (context, provider, _) {
            if (!provider.isReady) return const SizedBox();
            return IconButton(
              icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
              tooltip: 'New Chat',
              onPressed: () => provider.startNewConversation(),
            );
          },
        ),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          tooltip: 'Settings',
          onPressed: () async {
            try {
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AISettingsScreen()),
              );
            } catch (e) {
              debugPrint('Error navigating to settings: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error opening settings: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildSetupPrompt(AIAssistantProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600.withOpacity(0.2),
                    Colors.purple.shade600.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 64),
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
              'I\'m Nex, your personal finance AI. To get started, I\'ll need an API key — it\'s like giving me clearance to operate.\n\n🆓 Good news: Gemini is FREE!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AISettingsScreen()),
                  );
                } catch (e) {
                  debugPrint('Error navigating to settings: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening settings: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.key),
              label: const Text('Get Free API Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(AIAssistantProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600.withOpacity(0.15),
                  Colors.purple.shade600.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'At your service, Sir',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about your finances. I have access to your accounts, transactions, debts, investments, and more.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Model indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: provider.settings.activeModel == AIModel.gemini
                  ? AppColors.info.withOpacity(0.2)
                  : AppColors.premiumAmber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.settings.activeModel == AIModel.gemini
                      ? Icons.auto_awesome
                      : Icons.psychology,
                  size: 16,
                  color: provider.settings.activeModel == AIModel.gemini
                      ? AppColors.info
                      : AppColors.premiumAmber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Powered by ${provider.activeModelName}',
                  style: AppTypography.bodySmall.copyWith(
                    color: provider.settings.activeModel == AIModel.gemini
                        ? AppColors.info
                        : AppColors.premiumAmber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AIAssistantProvider provider) {
    final messages = provider.currentConversation?.messages ?? [];

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && provider.isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.purple.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryBlue.withOpacity(0.2)
                    : message.isError
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                border: message.isError
                    ? Border.all(color: AppColors.error.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      message.content,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        strong: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        code: TextStyle(
                          fontFamily: 'monospace',
                          backgroundColor: AppColors.backgroundBlack,
                          color: AppColors.primaryBlue,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.backgroundBlack,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      selectable: true,
                    ),
                  if (!isUser && message.metadata != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      message.metadata!['model'] ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 44), // Balance for avatar space
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
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
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.3 + (0.7 * value)),
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
            _buildQuickPromptChip(
              icon: Icons.summarize,
              label: 'Monthly Summary',
              onTap: () => provider.sendQuickPrompt('summary'),
            ),
            _buildQuickPromptChip(
              icon: Icons.local_fire_department,
              label: 'Roast My Spending',
              onTap: () => provider.sendQuickPrompt('roast'),
            ),
            _buildQuickPromptChip(
              icon: Icons.savings,
              label: 'Where Can I Save?',
              onTap: () => provider.sendQuickPrompt('save'),
            ),
            _buildQuickPromptChip(
              icon: Icons.calendar_today,
              label: 'Upcoming Bills',
              onTap: () => provider.sendQuickPrompt('upcoming'),
            ),
            _buildQuickPromptChip(
              icon: Icons.trending_down,
              label: 'Debt Strategy',
              onTap: () => provider.sendQuickPrompt('debt_strategy'),
            ),
            _buildQuickPromptChip(
              icon: Icons.health_and_safety,
              label: 'Health Check',
              onTap: () => provider.sendQuickPrompt('health_check'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPromptChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.primaryBlue),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.cardSurface,
        labelStyle: AppTypography.bodySmall.copyWith(color: Colors.white),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildInputArea(AIAssistantProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundBlack,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
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
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask Nex anything...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(provider),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: provider.isLoading
                  ? null
                  : () => _sendMessage(provider),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(AIAssistantProvider provider) {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    provider.sendMessage(message);
  }
}
