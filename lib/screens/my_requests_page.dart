import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';
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
                    padding: const EdgeInsets.all(20),
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      return _RequestCard(
                        request: request,
                        listingTitle: request.listingTitle,
                        listingInfo:
                            '${request.listingAmount} • ${request.listingLocation}',
                      );
                    },
                  );
                },
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusInfo.icon, color: statusInfo.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    listingTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              listingInfo,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(statusInfo.label),
              avatar: Icon(statusInfo.icon, size: 18),
              backgroundColor: statusInfo.color.withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
            if (request.status == ListingRequestStatus.accepted &&
                request.ownerContactInfo.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'İlan sahibinin telefonu: ${request.ownerContactInfo}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openPhone(context),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Ara'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openWhatsApp(context),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text("WhatsApp'tan yaz"),
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
