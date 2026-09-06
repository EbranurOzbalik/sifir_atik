import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.amount,
    required this.description,
    required this.ownerName,
    required this.createdAt,
    required this.imageAsset,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final String amount;
  final String description;
  final String ownerName;
  final DateTime createdAt;
  final String imageAsset;

  factory Listing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAtValue = data['createdAt'];

    return Listing(
      id: doc.id,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? 'Diğer',
      location: data['location'] as String? ?? '',
      amount: data['amount'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'İlan sahibi',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
      imageAsset:
          data['imageAsset'] as String? ?? listingImageForCategory('Diğer'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'category': category,
      'location': location,
      'amount': amount,
      'description': description,
      'ownerName': ownerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageAsset': imageAsset,
    };
  }
}

String listingImageForCategory(String category) {
  switch (category) {
    case 'Kağıt':
      return 'assets/images/cardboard_boxes.svg';
    case 'Cam':
      return 'assets/images/glass_jars.svg';
    case 'Elektronik':
      return 'assets/images/electronics_parts.svg';
    default:
      return 'assets/images/zero_waste_hero.svg';
  }
}

final sampleListings = [
  Listing(
    id: 'listing-cardboard-boxes',
    title: 'Temiz karton kutular',
    category: 'Kağıt',
    location: 'Kadıköy, İstanbul',
    amount: '10 kg',
    description:
        'Taşınmadan kalan temiz karton kutular. Katlanmış şekilde teslim edilebilir.',
    ownerName: 'Ebranur',
    createdAt: DateTime(2026, 9, 1),
    imageAsset: 'assets/images/cardboard_boxes.svg',
  ),
  Listing(
    id: 'listing-glass-jars',
    title: 'Cam kavanoz ve şişeler',
    category: 'Cam',
    location: 'Üsküdar, İstanbul',
    amount: '18 adet',
    description:
        'Etiketleri sökülmüş, yıkanmış kavanoz ve cam şişeler. Geri kullanım için uygundur.',
    ownerName: 'Zeynep',
    createdAt: DateTime(2026, 9, 1),
    imageAsset: 'assets/images/glass_jars.svg',
  ),
  Listing(
    id: 'listing-electronic-parts',
    title: 'Kullanılabilir elektronik parçalar',
    category: 'Elektronik',
    location: 'Ataşehir, İstanbul',
    amount: '1 kutu',
    description:
        'Eski cihazlardan ayrılmış kablo, adaptör ve küçük elektronik parçalar.',
    ownerName: 'Mert',
    createdAt: DateTime(2026, 9, 2),
    imageAsset: 'assets/images/electronics_parts.svg',
  ),
];
