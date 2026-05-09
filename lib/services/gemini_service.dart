import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_providers.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Daily cache helpers ─────────────────────────────────────────────────────

String _todayString() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

Future<String> _dailyCachedFetch({
  required String cacheKey,
  required Future<String> Function() fetchFn,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final lastFetchedDate = prefs.getString('${cacheKey}_date') ?? '';
  final today = _todayString();

  // If already fetched today, return cached text (or fall through if missing)
  if (lastFetchedDate == today) {
    final cached = prefs.getString('${cacheKey}_text');
    if (cached != null) return cached;
  }

  // Fetch fresh data
  final data = await fetchFn();

  // Persist both the result and today’s date
  await prefs.setString('${cacheKey}_date', today);
  await prefs.setString('${cacheKey}_text', data);
  return data;
}

// ─── 1. Dynamic Quote Provider ────────────────────────────────────────────

final dailyQuoteProvider = FutureProvider.autoDispose<String>((ref) async {
  return _dailyCachedFetch(
    cacheKey: 'daily_quote',
    fetchFn: () async {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        print("🚨 GEMINI ERROR: API Key is empty! Check your .env file and main.dart");
        return '"Action is the foundational key to all success." - Pablo Picasso';
      }

      try {
        print("🚀 Firing Gemini Quote API...");
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(temperature: 0.95),
        );

        final topics = ['discipline', 'extreme focus', 'resilience', 'time management', 'innovation'];
        final randomTopic = topics[Random().nextInt(topics.length)];

        final prompt = 'Provide one profound, hard-hitting quote about $randomTopic from a world-class leader. Format: "Quote" - Author.';

        final response = await model.generateContent([Content.text(prompt)]);
        print("✅ Gemini Quote Success!");
        return response.text?.trim() ?? '"Done is better than perfect." - Sheryl Sandberg';
      } catch (e) {
        print("❌ GEMINI QUOTE CRASH: $e");
        return '"Continuous improvement is better than delayed perfection." - Mark Twain';
      }
    },
  );
});

// ─── 2. THE KNOWLEDGE BOOSTER ─────────────────────────────────────────────

final dailyQuestionProvider = FutureProvider.autoDispose<String>((ref) async {
  return _dailyCachedFetch(
    cacheKey: 'daily_question',
    fetchFn: () async {
      final userProfile = ref.watch(userProfileProvider).value;

      List<String> categories = ['Software Engineering'];
      if (userProfile != null && userProfile['categories'] != null) {
        categories = List<String>.from(userProfile['categories']);
      }

      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) return "Tip: Use 'Leverage' instead of 'Use' in meetings.";

      try {
        print("🚀 Firing Gemini Knowledge API...");
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(temperature: 0.9),
        );

        final concepts = ['Caching', 'Load Balancing', 'Microservices', 'Database Indexing'];
        final randomConcept = concepts[Random().nextInt(concepts.length)];
        final isVocab = Random().nextBool();

        String prompt;
        if (isVocab) {
          prompt = 'Provide ONE highly advanced, C2-level vocabulary word used in corporate engineering. Provide the word, meaning, and a 1-sentence example. No greetings.';
        } else {
          prompt = 'Explain the system design concept of "$randomConcept" for a student focused on ${categories.join(', ')} in strictly 2-3 sentences. No greetings.';
        }

        final response = await model.generateContent([Content.text(prompt)]);
        print("✅ Gemini Knowledge Success!");
        return response.text?.trim() ?? "Architecture Tip: Microservices allow teams to scale parts of a system independently.";
      } catch (e) {
        print("❌ GEMINI KNOWLEDGE CRASH: $e");
        return "Vocabulary: 'Orthogonal' - Statistically independent. Example: The UI changes are orthogonal to the database schema.";
      }
    },
  );
});

// ─── 3. AI BEHAVIORAL ANALYST (also now cached daily) ─────────────────────

final productivityAnalysisProvider = FutureProvider.autoDispose<String>((ref) async {
  return _dailyCachedFetch(
    cacheKey: 'productivity_analysis',
    fetchFn: () async {
      final sessionsAsync = ref.watch(sessionsProvider);
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty || !sessionsAsync.hasValue) return "Consistency King - Keep tracking to see patterns.";

      try {
        final sessions = sessionsAsync.value!;
        if (sessions.isEmpty) return "Log some sessions to unlock your AI profile!";

        final timeData = sessions.take(10).map((s) {
          final d = (s.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (d == null) return '';
          return DateFormat('HH:mm').format(d.toDate());
        }).where((e) => e.isNotEmpty).join(', ');

        if (timeData.isEmpty) return "Keep tracking to see your patterns.";

        print("🚀 Firing Gemini Analyst API...");
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(temperature: 0.4),
        );

        final prompt = 'Analyze these study session times: $timeData. Label the user strictly as "Night Owl", "Early Bird", or "Mid-Day Warrior" and give a short 1-sentence productivity tip. Format: [Label] - [Tip]';

        final response = await model.generateContent([Content.text(prompt)]);
        print("✅ Gemini Analyst Success!");
        return response.text?.trim() ?? "Consistent - Your schedule looks balanced.";
      } catch (e) {
        print("❌ GEMINI ANALYST CRASH: $e");
        return "Keep grinding to unlock AI insights.";
      }
    },
  );
});