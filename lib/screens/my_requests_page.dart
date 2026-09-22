import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/models/listing_request.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/theme/app_theme.dart';
import 'package:sifir_atik/widgets/listing_preview_card.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';

enum _RequestFilter { all, accepted, pending }

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({
    super.key,
    this.repository = const ListingRepository(),
    this.currentUserId,
    this.isFirebaseReady,
    this.embedded = false,
  });

  final ListingRepository repository;
  final String? currentUserId;
  final bool? isFirebaseReady;
  final bool embedded;

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  _RequestFilter _filter = _RequestFilter.all;

  bool get _hasFirebase => widget.isFirebaseReady ?? Firebase.apps.isNotEmpty;

  User? get _user => _hasFirebase && Firebase.apps.isNotEmpty
      ? FirebaseAuth.instance.currentUser
      : null;

  String? get _userId => widget.currentUserId ?? _user?.uid;

  List<ListingRequest> _filteredRequests(List<ListingRequest> requests) {
    return switch (_filter) {
      _RequestFilter.all => requests,
      _RequestFilter.accepted =>
        requests
            .where((request) => request.status == ListingRequestStatus.accepted)
            .toList(),
      _RequestFilter.pending =>
        requests
            .where((request) => request.status == ListingRequestStatus.pending)
            .toList(),
    };
  }

  Widget _buildBody(BuildContext context) {
    final userId = _userId;

    if (userId == null) {
      return const _EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Giriş bulunamadı',
        message: 'Taleplerinizi görmek için giriş yapmalısınız.',
      );
    }

    return StreamBuilder<List<ListingRequest>>(
      stream: widget.repository.watchRequestsByRequester(userId),
      builder: (context, requestsSnapshot) {
        final requests = requestsSnapshot.data ?? const [];

        if (requests.isEmpty) {
          return const _EmptyState(
            icon: Icons.handshake_outlined,
            title: 'Henüz talebim yok',
            message: 'Bir ilana talep gönderdiğinizde burada görünecek.',
          );
        }

        final filteredRequests = _filteredRequests(requests);

        return CustomScrollView(
          key: const PageStorageKey('my-requests-scroll'),
          slivers: [
            SliverPadding(
              padding: responsivePagePadding(context, top: 20, bottom: 0),
              sliver: SliverToBoxAdapter(
                child: ResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.embedded) ...[
                        Text(
                          'Taleplerim',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gönderdiğin talepleri ve iletişim durumunu takip et.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      _RequestsSummaryCard(requests: requests),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Tümü',
                              selected: _filter == _RequestFilter.all,
                              onSelected: () {
                                setState(() => _filter = _RequestFilter.all);
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Kabul edilen',
                              selected: _filter == _RequestFilter.accepted,
                              onSelected: () {
                                setState(
                                  () => _filter = _RequestFilter.accepted,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Beklemede',
                              selected: _filter == _RequestFilter.pending,
                              onSelected: () {
                                setState(
                                  () => _filter = _RequestFilter.pending,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (filteredRequests.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Bu durumda talep yok',
                  message:
                      'Başka bir filtre seçerek taleplerine göz atabilirsin.',
                ),
              )
            else
              SliverPadding(
                padding: responsivePagePadding(context, top: 16),
                sliver: SliverList.separated(
                  itemCount: filteredRequests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return ResponsiveContent(
                      child: _RequestCard(request: filteredRequests[index]),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(child: _buildBody(context));
    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Taleplerim')),
      body: content,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: selected,
      onSelected: (_) => onSelected(),
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(11),
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
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
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
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ListingRequest request;

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
      'Merhaba, Sıfır Atık uygulamasındaki "${request.listingTitle}" ilanınız için yazıyorum.',
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
        const SnackBar(content: Text('İletişim uygulaması açılamadı.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = requestStatusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_statusIcon(request.status), color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.listingTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${request.listingAmount} • ${request.listingLocation}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  requestStatusLabel(request.status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Talep gönderildi: ${_formatRequestDate(request.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (request.status == ListingRequestStatus.pending) ...[
            const SizedBox(height: 12),
            Text(
              'İlan sahibinin yanıtı bekleniyor.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (request.status == ListingRequestStatus.accepted &&
              request.ownerContactInfo.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 9),
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
                            const SizedBox(height: 2),
                            Text(
                              request.ownerContactInfo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openPhone(context),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Ara'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => _openWhatsApp(context),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text(
                            "WhatsApp'tan yaz",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
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
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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

IconData _statusIcon(ListingRequestStatus status) {
  return switch (status) {
    ListingRequestStatus.accepted => Icons.check_circle_outline_rounded,
    ListingRequestStatus.rejected => Icons.cancel_outlined,
    ListingRequestStatus.pending => Icons.hourglass_top_rounded,
  };
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
