/// Witty responses when user hasn't added an API key
/// Escalates from funny to stubborn
library;

class NoKeyResponses {
  /// Witty responses asking user to add API key
  /// Index increases with each attempt
  static const List<String> _wittyResponses = [
    // First attempt - Charming
    '''
Ah, I see you're trying to chat without an API key. Bold move, Sir!

It's like trying to start a car without keys — technically you *could* hotwire it, but why not just... you know... get the keys? 🔑

  **Quick setup:**
1. Tap the ⚙️ Settings icon above
2. Get a free API key from your chosen AI provider
3. Paste it in and we're golden!

The whole process takes about 60 seconds. Less time than it took you to read this message. Let's do this! 🚀
''',

    // Second attempt - Playful
    '''
Back again! I admire the persistence, I really do.

But here's the thing — without an API key, I'm basically a really expensive paperweight with a nice gradient icon. 

Phil's-osophy: *"You can't make an omelette without breaking eggs, and you can't get financial advice without an API key."*

Come on, the free API key is literally FREE. Zero rupees. Nada. Go grab one! ⚡
''',

    // Third attempt - Getting impatient
    '''
Okay, so we're doing this dance again? 💃

Listen, I want to help you. I REALLY do. I've got access to all your financial data, years of training, and enough confidence to make Barney Stinson jealous.

But without that API key, I'm just... *gestures vaguely* ... this.

**The situation:**
- You: Have financial questions
- Me: Have all the answers
- Between us: One missing API key

This is not legendary, bro. This is tragic. Let's fix it? 🔧
''',

    // Fourth attempt - Dramatic
    '''
*Dramatic sigh*

You know, in another timeline, we're already having an amazing conversation about optimizing your investments and I'm making killer dad jokes about compound interest.

But in THIS timeline? We're stuck in API key limbo. 

I'm starting to think you're doing this on purpose just to see what I'll say. (Okay, that's actually kind of funny. Respect.)

But seriously — **Settings → Get API Key → Paste → Done**

Less than a minute. I believe in you! 💪
''',

    // Fifth and final - Stubborn mode activated
    '''
Alright, I see how it is. You're being stubborn.

Well, guess what? I can be stubborn too. Let's see who wins. 😤

I'll wait right here. You know where to find me when you're ready with that API key.

*crosses arms*

*waits*

*still waiting*

...

Add an API key first.
''',
  ];

  /// Get response for attempt number (0-indexed)
  static String getResponse(int attemptCount) {
    if (attemptCount >= _wittyResponses.length) {
      // After all witty responses, just return the stubborn final message
      return '''
*stares blankly*

Add an API key first.

I told you I could be stubborn. 🙂
''';
    }
    return _wittyResponses[attemptCount];
  }

  /// Check if we've reached the stubborn phase
  static bool isStubborn(int attemptCount) {
    return attemptCount >= _wittyResponses.length - 1;
  }

  /// Get total number of unique responses
  static int get totalResponses => _wittyResponses.length;
}
