import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sifir_atik/models/listing_report.dart';

enum ModerationRisk { low, medium, high }

enum ModerationRecommendation { keep, review, considerRemoval }

class ModerationAssessment {
  const ModerationAssessment({
    required this.risk,
    required this.recommendation,
    required this.summary,
    required this.reason,
    this.isLocalFallback = false,
  });

  final ModerationRisk risk;
  final ModerationRecommendation recommendation;
  final String summary;
  final String reason;
  final bool isLocalFallback;

  factory ModerationAssessment.fromJson(Map<String, dynamic> json) {
    return ModerationAssessment(
      risk: ModerationRisk.values.firstWhere(
        (value) => value.name == json['risk'],
        orElse: () => ModerationRisk.medium,
      ),
      recommendation: ModerationRecommendation.values.firstWhere(
        (value) => value.name == json['recommendation'],
        orElse: () => ModerationRecommendation.review,
      ),
      summary: json['summary'] as String? ?? 'İlan manuel incelenmeli.',
      reason: json['reason'] as String? ?? 'Yeterli değerlendirme üretilemedi.',
    );
  }
}

abstract interface class ModerationAiClient {
  Future<ModerationAssessment> analyze(ListingReport report);
}

class ModerationAiService implements ModerationAiClient {
  ModerationAiService({GenerativeModel? model}) : _providedModel = model;

  final GenerativeModel? _providedModel;
  GenerativeModel? _model;

  GenerativeModel get _moderationModel {
    return _providedModel ??
        (_model ??= FirebaseAI.googleAI().generativeModel(
          model: 'gemini-3.8-flash',
          generationConfig: GenerationConfig(
            temperature: 0.15,
            maxOutputTokens: 300,
            responseMimeType: 'application/json',
            responseSchema: Schema.object(
              properties: {
                'risk': Schema.enumString(
                  enumValues: ['low', 'medium', 'high'],
                ),
                'recommendation': Schema.enumString(
                  enumValues: ['keep', 'review', 'considerRemoval'],
                ),
                'summary': Schema.string(),
                'reason': Schema.string(),
              },
              propertyOrdering: ['risk', 'recommendation', 'summary', 'reason'],
            ),
          ),
          systemInstruction: Content.text(
            'Sen Sıfır Atık uygulamasındaki moderatör yardımcısısın. '
            'Yalnızca bildirilen ilanı ve bildirim nedenini değerlendir. '
            'Yanlış kategori, yanıltıcı içerik, kişisel veri, dolandırıcılık, '
            'tehlikeli atık ve uygunsuz dil risklerini kontrol et. '
            'Kesin karar verdiğini söyleme; kısa ve tarafsız bir ön inceleme sun. '
            'İlan kaldırma işlemini otomatik olarak uygulama. Türkçe yanıt ver.',
          ),
        ));
  }

  @override
  Future<ModerationAssessment> analyze(ListingReport report) async {
    if (Firebase.apps.isEmpty) {
      return _localAssessment(report);
    }

    final prompt =
        '''
İlan başlığı: ${report.listingTitle}
Kategori: ${report.listingCategory.isEmpty ? 'Belirtilmemiş' : report.listingCategory}
Miktar: ${report.listingAmount}
Konum: ${report.listingLocation}
Açıklama: ${report.listingDescription.isEmpty ? 'Belirtilmemiş' : report.listingDescription}
Bildirim nedeni: ${report.reason}

Bu bildirimi moderatör için ön incele.
''';

    try {
      final response = await _moderationModel.generateContent([
        Content.text(prompt),
      ]);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        throw const ModerationAiException(
          'AI ön incelemesi şu anda oluşturulamadı.',
        );
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const ModerationAiException('AI yanıtı okunamadı.');
      }

      return ModerationAssessment.fromJson(decoded);
    } on ModerationAiException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Moderation AI request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _localAssessment(report);
    }
  }

  ModerationAssessment _localAssessment(ListingReport report) {
    final content = [
      report.listingTitle,
      report.listingCategory,
      report.listingDescription,
      report.reason,
    ].join(' ').toLowerCase();
    final compactContent = content.replaceAll(RegExp(r'[^0-9]'), '');

    final hasContactOrPaymentRisk =
        [
          'iban',
          'kapora',
          'ödeme gönder',
          'whatsapp',
          'telegram',
        ].any(content.contains) ||
        compactContent.length >= 10;
    final hasSafetyRisk = [
      'tıbbi atık',
      'kimyasal',
      'patlayıcı',
      'zehirli',
      'ilaç atığı',
    ].any(content.contains);
    final needsCategoryReview = content.contains('yanlış kategori');

    if (hasContactOrPaymentRisk || hasSafetyRisk) {
      return const ModerationAssessment(
        risk: ModerationRisk.high,
        recommendation: ModerationRecommendation.considerRemoval,
        summary: 'İlan ayrıntılı olarak incelenmeli.',
        reason:
            'İçerikte ödeme, kişisel iletişim veya güvenlik riski oluşturabilecek ifadeler bulunuyor.',
        isLocalFallback: true,
      );
    }

    if (needsCategoryReview || report.listingDescription.trim().isEmpty) {
      return const ModerationAssessment(
        risk: ModerationRisk.medium,
        recommendation: ModerationRecommendation.review,
        summary: 'Kategori ve ilan içeriği karşılaştırılmalı.',
        reason:
            'Bildirim nedeni veya eksik açıklama, moderatörün ilanı manuel olarak kontrol etmesini gerektiriyor.',
        isLocalFallback: true,
      );
    }

    return const ModerationAssessment(
      risk: ModerationRisk.low,
      recommendation: ModerationRecommendation.keep,
      summary: 'Belirgin bir risk işareti bulunamadı.',
      reason:
          'Temel içerik kontrollerinde kişisel veri, ödeme veya güvenlik riski tespit edilmedi.',
      isLocalFallback: true,
    );
  }
}

class ModerationAiException implements Exception {
  const ModerationAiException(this.message);

  final String message;
}
