import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_providers.dart';

// --- HELPER LOGIC: CACHING & FALLBACKS ---

String _getTodayKey() {
  final now = DateTime.now();
  return "${now.year}-${now.month}-${now.day}";
}

Future<String> _fetchWithFallback({
  required String cacheKey,
  required String fallback,
  required Future<String> Function() apiCall,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final today = _getTodayKey();
  
  final lastDate = prefs.getString('${cacheKey}_date') ?? '';
  final lastData = prefs.getString('${cacheKey}_text');

  if (lastDate == today && lastData != null) {
    return lastData; // Return today's cached success immediately
  }

  try {
    final freshData = await apiCall();
    
    // Save successful API fetch
    await prefs.setString('${cacheKey}_date', today);
    await prefs.setString('${cacheKey}_text', freshData);
    return freshData;
  } catch (e) {
    // Return yesterday's data, or the hardcoded fallback if memory is empty
    return lastData ?? fallback;
  }
}

// --- GEMINI API PROVIDERS ---

final dailyQuoteProvider = FutureProvider.autoDispose<String>((ref) async {
  return _fetchWithFallback(
    cacheKey: 'quote',
    fallback: '"Action is the foundational key to all success." - Pablo Picasso',
    apiCall: () async {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('API Key missing');

      final model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.9),
      );

      final topics = ['discipline', 'resilience', 'grit', 'focus'];
      final topic = topics[Random().nextInt(topics.length)];
      final response = await model.generateContent([
        Content.text('Provide one profound quote about $topic from a world leader. Format: "Quote" - Author.')
      ]);
      
      final resultText = response.text?.trim();
      if (resultText == null || resultText.isEmpty) {
        throw Exception('Empty Response');
      }
      return resultText;
    },
  );
});

final dailyQuestionProvider = FutureProvider.autoDispose<String>((ref) async {
  return _fetchWithFallback(
    cacheKey: 'knowledge',
    fallback: "Perplexity AI is a conversational search engine that answers queries using natural language predictive text. It acts as a powerful alternative to traditional search engines by citing its sources and providing concise summaries.",
    apiCall: () async {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('API Key missing');

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.95),
      );

      String prompt = 'Provide exactly two things in a very short response:\n'
          '1. A new AI tool/website. Tell me: What it is, why it is efficient, and if it is free/paid. (1 short sentence)\n'
          '2. One rare vocabulary word. Format: Word - 1-2 word meaning. 1 short simple sentence.\n'
          'Keep the entire response extremely brief. DO NOT use markdown, asterisks, or bolding.';

      final response = await model.generateContent([Content.text(prompt)]);
      
      final resultText = response.text?.trim();
      if (resultText == null || resultText.isEmpty) {
        throw Exception('Empty Response');
      }
      return resultText;
    },
  );
});

final productivityAnalysisProvider = FutureProvider.autoDispose<String>((ref) async {
  return _fetchWithFallback(
    cacheKey: 'analysis',
    fallback: "Consistency King - Keep tracking to see your patterns.",
    apiCall: () async {
      final sessionsAsync = ref.watch(sessionsProvider);
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (!sessionsAsync.hasValue || sessionsAsync.value!.isEmpty) {
        return "Log some sessions to unlock your AI profile!";
      }

      final timeData = sessionsAsync.value!.take(10).map((s) {
        final d = (s.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
        return d != null ? DateFormat('HH:mm').format(d.toDate()) : '';
      }).where((e) => e.isNotEmpty).join(', ');

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.4),
      );

      final response = await model.generateContent([
        Content.text('Analyze these session times: $timeData. Label as "Night Owl", "Early Bird", or "Mid-Day Warrior" + 1 tip. Format: [Label] - [Tip]')
      ]);
      
      final resultText = response.text?.trim();
      if (resultText == null || resultText.isEmpty) {
        throw Exception('Empty Response');
      }
      return resultText;
    },
  );
});