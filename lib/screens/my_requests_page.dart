import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({
    super.key,
    this.repository = const ListingRepository(),
    this.currentUserId,
    this.isFirebaseReady,
  });

  final ListingRepository repository;
  final String? currentUserId;
  final bool? isFirebaseReady;

  bool get _hasFirebase => isFirebaseReady ?? Firebase.apps.isNotEmpty;

  User? get _user => _hasFirebase && Firebase.apps.isNotEmpty
      ? FirebaseAuth.instance.currentUser
      : null;

  String? get _userId => currentUserId ?? _user?.uid;

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Taleplerim')),
      body: SafeArea(
        child: userId == null
            ? const _EmptyState(
                icon: Icons.lock_outline,
                title: 'Giriş bulunamadı',
                message: 'Taleplerinizi görmek için giriş yapmalısınız.',
              )
            : StreamBuilder<List<ListingRequest>>(
                stream: repository.watchRequestsByRequester(userId),
                builder: (context, requestsSnapshot) {
                  final requests = requestsSnapshot.data ?? const [];

                  if (requests.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.handshake_outlined,
                      title: 'Henüz talebim yok',
                      message:
                          'Bir ilana ilgileniyorum dediğinizde burada görünecek.',
                    );
                  }

                  return ListView.separated(
                    padding: responsivePagePadding(context, top: 20),
                    itemCount: requests.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ResponsiveContent(
                          child: _RequestsSummaryCard(requests: requests),
                        );
                      }

                      final request = requests[index - 1];

                      return ResponsiveContent(
                        child: _RequestCard(
                          request: request,
                          listingTitle: request.listingTitle,
                          listingInfo:
                              '${request.listingAmount} • ${request.listingLocation}',
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

class _RequestsSummaryCard extends StatelessWidget {
  const _RequestsSummaryCard({required this.requests});

  final List<ListingRequest> requests;

  int get _acceptedCount => requests
      .where((request) => request.status == ListingRequestStatus.accepted)
      .length;

  int get _pendingCount => requests
      .where((request) => request.status == ListingRequestStatus.pending)
      .length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.handshake_outlined,
                color: colorScheme.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taleplerinin durumu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_acceptedCount kabul edildi · $_pendingCount bekliyor',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.listingTitle,
    required this.listingInfo,
  });

  final ListingRequest request;
  final String listingTitle;
  final String listingInfo;

  String get _phoneForLink {
    final phone = request.ownerContactInfo.trim().replaceAll(
      RegExp(r'[\s()-]'),
      '',
    );

    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+90${phone.substring(1)}';
    if (phone.startsWith('5')) return '+90$phone';

    return phone;
  }

  Future<void> _openPhone(BuildContext context) async {
    await _openUrl(
      ScaffoldMessenger.of(context),
      Uri(scheme: 'tel', path: _phoneForLink),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = _phoneForLink.replaceFirst('+', '');
    final message = Uri.encodeComponent(
      'Merhaba, Sıfır Atık uygulamasındaki "$listingTitle" ilanınız için yazıyorum.',
    );

    final whatsappUri = Uri.parse('whatsapp://send?phone=$phone&text=$message');
    final webUri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(whatsappUri)) {
      final opened = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    }

    await _openUrl(messenger, webUri);
  }

  Future<void> _openUrl(ScaffoldMessengerState messenger, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (opened) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('İletişim uygulaması açılamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusInfo = _statusInfo(request.status);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    listingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo.icon, size: 17, color: statusInfo.color),
                      const SizedBox(width: 6),
                      Text(
                        statusInfo.label,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: statusInfo.color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _RequestMeta(icon: Icons.scale_outlined, text: listingInfo),
                _RequestMeta(
                  icon: Icons.calendar_today_outlined,
                  text:
                      'Talep gönderildi: ${_formatRequestDate(request.createdAt)}',
                ),
              ],
            ),
            if (request.status == ListingRequestStatus.pending) ...[
              const SizedBox(height: 14),
              Text(
                'İlan sahibinin yanıtı bekleniyor.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (request.status == ListingRequestStatus.accepted &&
                request.ownerContactInfo.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İletişim bilgisi açıldı',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'İlan sahibinin telefonu',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                request.ownerContactInfo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () => _openPhone(context),
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Ara'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: () => _openWhatsApp(context),
                            icon: const Icon(Icons.chat_outlined),
                            label: Text(
                              "WhatsApp'tan yaz",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestMeta extends StatelessWidget {
  const _RequestMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

String _formatRequestDate(DateTime date) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  return '${date.day} ${months[date.month - 1]}';
}

class _StatusInfo {
  const _StatusInfo(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

_StatusInfo _statusInfo(ListingRequestStatus status) {
  return switch (status) {
    ListingRequestStatus.accepted => const _StatusInfo(
      'Kabul edildi',
      Icons.check_circle_outline,
      Color(0xFF2E7D32),
    ),
    ListingRequestStatus.rejected => const _StatusInfo(
      'Reddedildi',
      Icons.cancel_outlined,
      Color(0xFFC62828),
    ),
    ListingRequestStatus.pending => const _StatusInfo(
      'Beklemede',
      Icons.hourglass_top_outlined,
      Color(0xFFF57C00),
    ),
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
