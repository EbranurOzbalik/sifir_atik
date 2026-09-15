import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing_report.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({
    super.key,
    this.repository = const ListingRepository(),
  });

  final ListingRepository repository;

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
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];

                return ResponsiveContent(
                  child: _ReportCard(
                    report: report,
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onResolve,
    required this.onDeleteListing,
  });

  final ListingReport report;
  final VoidCallback onResolve;
  final VoidCallback onDeleteListing;

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
                    report.listingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${report.listingAmount} • ${report.listingLocation}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Chip(
              label: Text(report.reason),
              avatar: const Icon(Icons.report_problem_outlined, size: 18),
              backgroundColor: colorScheme.errorContainer.withValues(
                alpha: 0.5,
              ),
              side: BorderSide.none,
            ),
            const SizedBox(height: 6),
            Text(
              '${report.reporterName} tarafından bildirildi.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.done_outlined),
                    label: const Text('İncelendi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDeleteListing,
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
