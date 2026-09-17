import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing_report.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/moderation_ai_service.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({
    super.key,
    this.repository = const ListingRepository(),
    this.aiClient = const _DefaultModerationAiClient(),
  });

  final ListingRepository repository;
  final ModerationAiClient aiClient;

  Future<void> _resolveReport(
    BuildContext context,
    ListingReport report,
  ) async {
    final isSaved = await repository.resolveReport(report.id);
    if (!context.mounted) return;

    _showMessage(
      context,
      isSaved
          ? 'Bildirim incelendi olarak işaretlendi.'
          : 'Bildirim güncellenemedi.',
    );
  }

  Future<void> _deleteListing(
    BuildContext context,
    ListingReport report,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İlan kaldırılsın mı?'),
          content: Text(
            '${report.listingTitle} ilanı ve bağlı talepler kaldırılacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kaldır'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) return;

    final isDeleted = await repository.deleteReportedListing(report.listingId);
    if (!context.mounted) return;

    _showMessage(
      context,
      isDeleted ? 'İlan kaldırıldı.' : 'İlan kaldırılamadı.',
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderatör Paneli')),
      body: SafeArea(
        child: StreamBuilder<List<ListingReport>>(
          stream: repository.watchOpenReports(),
          builder: (context, snapshot) {
            final reports = snapshot.data ?? const [];

            if (reports.isEmpty) {
              return const _EmptyReports();
            }

            return ListView.separated(
              padding: responsivePagePadding(context, top: 20),
              itemCount: reports.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const ResponsiveContent(child: _AiModerationIntro());
                }

                final report = reports[index - 1];

                return ResponsiveContent(
                  child: _ReportCard(
                    report: report,
                    aiClient: aiClient,
                    onResolve: () => _resolveReport(context, report),
                    onDeleteListing: () => _deleteListing(context, report),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.report,
    required this.aiClient,
    required this.onResolve,
    required this.onDeleteListing,
  });

  final ListingReport report;
  final ModerationAiClient aiClient;
  final VoidCallback onResolve;
  final VoidCallback onDeleteListing;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  ModerationAssessment? _assessment;
  String? _aiError;
  bool _isAnalyzing = false;

  Future<void> _analyze() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _aiError = null;
    });

    try {
      final assessment = await widget.aiClient.analyze(widget.report);
      if (!mounted) return;
      setState(() => _assessment = assessment);
    } on ModerationAiException catch (error) {
      if (!mounted) return;
      setState(() => _aiError = error.message);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: colorScheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.report.listingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.report.listingAmount} • ${widget.report.listingLocation}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Chip(
              label: Text(
                widget.report.reason,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
              avatar: Icon(
                Icons.report_problem_outlined,
                size: 18,
                color: colorScheme.onErrorContainer,
              ),
              backgroundColor: colorScheme.errorContainer.withValues(
                alpha: 0.5,
              ),
              side: BorderSide.none,
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.report.reporterName} tarafından bildirildi.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.manage_search_outlined),
                label: Text(
                  _assessment == null ? 'Ön İnceleme Yap' : 'Tekrar İncele',
                ),
              ),
            ),
            if (_assessment case final assessment?) ...[
              const SizedBox(height: 12),
              _AiAssessmentCard(assessment: assessment),
            ],
            if (_aiError case final error?) ...[
              const SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onResolve,
                    icon: const Icon(Icons.done_outlined),
                    label: const Text('İncelendi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onDeleteListing,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('İlanı Kaldır'),
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

class _AiModerationIntro extends StatelessWidget {
  const _AiModerationIntro();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shield_outlined, color: colorScheme.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akıllı ön inceleme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bildirimi risk açısından değerlendirir. Son karar her zaman moderatöre aittir.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssessmentCard extends StatelessWidget {
  const _AiAssessmentCard({required this.assessment});

  final ModerationAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskColor = switch (assessment.risk) {
      ModerationRisk.low => colorScheme.primary,
      ModerationRisk.medium => const Color(0xFFB26A00),
      ModerationRisk.high => colorScheme.error,
    };
    final riskLabel = switch (assessment.risk) {
      ModerationRisk.low => 'Düşük risk',
      ModerationRisk.medium => 'Orta risk',
      ModerationRisk.high => 'Yüksek risk',
    };
    final recommendationLabel = switch (assessment.recommendation) {
      ModerationRecommendation.keep => 'Yayında tutulabilir',
      ModerationRecommendation.review => 'Manuel inceleme gerekli',
      ModerationRecommendation.considerRemoval =>
        'Kaldırılması değerlendirilmeli',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(Icons.shield_outlined, color: riskColor, size: 18),
                label: Text(riskLabel),
                side: BorderSide.none,
                backgroundColor: riskColor.withValues(alpha: 0.08),
              ),
              Chip(
                avatar: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(recommendationLabel),
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            assessment.summary,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
          ),
          const SizedBox(height: 5),
          Text(
            assessment.reason,
            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
          ),
          if (assessment.isLocalFallback) ...[
            const SizedBox(height: 8),
            Text(
              'Firebase AI kullanılamadığı için temel kurallarla değerlendirildi.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Otomatik değerlendirmedir; işlem kendiliğinden uygulanmaz.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultModerationAiClient implements ModerationAiClient {
  const _DefaultModerationAiClient();

  @override
  Future<ModerationAssessment> analyze(ListingReport report) {
    return ModerationAiService().analyze(report);
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 54, color: colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              'Bekleyen bildirim yok',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Kullanıcılar ilan bildirdiğinde burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
