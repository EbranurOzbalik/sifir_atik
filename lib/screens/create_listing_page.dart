import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/photo_storage_service.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key, this.listing});

  final Listing? listing;

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  static const _categories = [
    'Kağıt',
    'Plastik',
    'Cam',
    'Metal',
    'Elektronik',
    'Diğer',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _listingRepository = const ListingRepository();
  final _photoStorageService = const PhotoStorageService();
  final _imagePicker = ImagePicker();

  String? _selectedCategory;
  XFile? _selectedPhoto;
  bool _isSaving = false;

  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();

    final listing = widget.listing;
    if (listing != null) {
      _titleController.text = listing.title;
      _amountController.text = listing.amount;
      _descriptionController.text = listing.description;
      _locationController.text = listing.location;
      _selectedCategory = listing.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan boş bırakılamaz.';
    }
    return null;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1400,
    );

    if (photo == null || !mounted) return;

    setState(() => _selectedPhoto = photo);
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitDraft() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final oldListing = widget.listing;
    final listingId = oldListing?.id ?? 'listing-${now.millisecondsSinceEpoch}';
    final ownerId = oldListing?.ownerId ?? user?.uid ?? 'local-user';
    String? imageUrl;
    var photoUploadFailed = false;

    if (_selectedPhoto != null && Firebase.apps.isNotEmpty && user != null) {
      try {
        imageUrl = await _photoStorageService.uploadListingPhoto(
          photo: File(_selectedPhoto!.path),
          ownerId: ownerId,
          listingId: listingId,
        );
      } catch (error) {
        debugPrint('Fotoğraf yükleme hatası: $error');
        photoUploadFailed = true;
      }
    }

    final listing = oldListing == null
        ? Listing(
            id: listingId,
            title: _titleController.text.trim(),
            category: _selectedCategory!,
            location: _locationController.text.trim(),
            amount: _amountController.text.trim(),
            description: _descriptionController.text.trim(),
            ownerId: ownerId,
            ownerName: user?.displayName ?? user?.email ?? 'Ebranur',
            createdAt: now,
            imageAsset: listingImageForCategory(_selectedCategory!),
            imageUrl: imageUrl,
          )
        : oldListing.copyWith(
            title: _titleController.text.trim(),
            category: _selectedCategory!,
            location: _locationController.text.trim(),
            amount: _amountController.text.trim(),
            description: _descriptionController.text.trim(),
            imageAsset: listingImageForCategory(_selectedCategory!),
            imageUrl: imageUrl ?? oldListing.imageUrl,
          );

    final isSaved = _isEditing
        ? await _listingRepository.updateListing(listing)
        : await _listingRepository.addListing(listing);

    if (!mounted) return;

    setState(() => _isSaving = false);

    final message = isSaved
        ? (_isEditing ? 'İlan güncellendi.' : 'İlan kaydedildi.')
        : (_isEditing ? 'İlan güncellenemedi.' : 'İlan taslak olarak kaldı.');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

    if (!isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Database bağlantısı yoksa ilan örnek veri olarak kalır.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (photoUploadFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan kaydedildi ama fotoğraf yüklenemedi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (isSaved && _isEditing && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'İlanı Düzenle' : 'Atık İlanı Ver'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing
                          ? 'İlan bilgilerini düzenle'
                          : 'Yeni ilan oluştur',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'İlanınızın görünen bilgilerini buradan değiştirebilirsiniz.'
                          : 'Atığınızla ilgili temel bilgileri ekleyin.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    _PhotoPickerCard(
                      colorScheme: colorScheme,
                      selectedPhoto: _selectedPhoto,
                      imageUrl: widget.listing?.imageUrl,
                      onTap: _showPhotoOptions,
                      onRemove: _selectedPhoto == null
                          ? null
                          : () => setState(() => _selectedPhoto = null),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'İlan başlığı',
                        hintText: 'Örn. Temiz karton kutular',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) =>
                          value == null ? 'Lütfen bir kategori seçin.' : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _amountController,
                      textInputAction: TextInputAction.next,
                      validator: _requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Miktar',
                        hintText: 'Örn. 10 kg veya 18 adet',
                        prefixIcon: Icon(Icons.scale_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      validator: _requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        hintText: 'Miktar, durum ve teslim bilgilerini yazın.',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _locationController,
                      textInputAction: TextInputAction.done,
                      validator: _requiredValidator,
                      decoration: const InputDecoration(
                        labelText: 'Konum',
                        hintText: 'İlçe veya mahalle',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submitDraft,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSaving
                            ? 'Kaydediliyor...'
                            : (_isEditing
                                  ? 'Değişiklikleri Kaydet'
                                  : 'İlanı Oluştur'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({
    required this.colorScheme,
    required this.selectedPhoto,
    required this.imageUrl,
    required this.onTap,
    required this.onRemove,
  });

  final ColorScheme colorScheme;
  final XFile? selectedPhoto;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              selectedPhoto == null && (imageUrl == null || imageUrl!.isEmpty)
              ? Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fotoğraf Ekle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galeriden seçebilir veya kamerayla çekebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: selectedPhoto == null
                          ? Image.network(
                              imageUrl!,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(selectedPhoto!.path),
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedPhoto == null
                                ? 'Mevcut fotoğraf'
                                : 'Fotoğraf seçildi',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Kaldır'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
