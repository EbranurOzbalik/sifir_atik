import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sifir_atik/data/turkey_locations.dart';
import 'package:sifir_atik/data/waste_categories.dart';
import 'package:sifir_atik/models/listing.dart';
import 'package:sifir_atik/models/user_profile.dart';
import 'package:sifir_atik/services/listing_repository.dart';
import 'package:sifir_atik/services/location_service.dart';
import 'package:sifir_atik/services/photo_storage_service.dart';
import 'package:sifir_atik/services/user_profile_repository.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({
    super.key,
    this.listing,
    this.profileRepository = const UserProfileRepository(),
    this.locationClient = const DeviceLocationService(),
  });

  final Listing? listing;
  final UserProfileRepository profileRepository;
  final LocationClient locationClient;

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  static const _categories = wasteCategories;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _contactController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _listingRepository = const ListingRepository();
  final _photoStorageService = const PhotoStorageService();
  final _imagePicker = ImagePicker();

  String? _selectedCategory;
  XFile? _selectedPhoto;
  String? _verificationId;
  String? _verifiedPhone;
  int? _resendToken;
  bool _removeExistingPhoto = false;
  bool _isSaving = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isGettingLocation = false;
  String? _phoneAuthMessage;
  double? _listingLatitude;
  double? _listingLongitude;

  bool get _isEditing => widget.listing != null;
  bool get _isPhoneVerified =>
      _verifiedPhone != null &&
      _verifiedPhone == _normalizedPhone(_contactController.text);

  @override
  void initState() {
    super.initState();

    final listing = widget.listing;
    if (listing != null) {
      _titleController.text = listing.title;
      _amountController.text = listing.amount;
      _descriptionController.text = listing.description;
      _locationController.text = listing.location;
      _setInitialLocation(listing.location);
      _contactController.text = listing.contactInfo;
      _selectedCategory = listing.category;
      _verifiedPhone = _normalizedPhone(listing.contactInfo);
      _listingLatitude = listing.latitude;
      _listingLongitude = listing.longitude;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _contactController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _setInitialLocation(String location) {
    final parts = location
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      _districtController.text = parts.first;
      _cityController.text = parts.last;
      return;
    }

    if (parts.length == 1) {
      final value = parts.first;
      if (turkeyCities.contains(value)) {
        _cityController.text = value;
      } else {
        _districtController.text = value;
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan boş bırakılamaz.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;

    final phone = _normalizedPhone(value!);
    final isValid = RegExp(r'^\+905\d{9}$').hasMatch(phone);

    if (!isValid) {
      return 'Geçerli bir telefon numarası girin.';
    }

    return null;
  }

  String _normalizedPhone(String value) {
    final phone = value.trim().replaceAll(RegExp(r'[\s()-]'), '');

    if (phone.startsWith('+90')) return phone;
    if (phone.startsWith('05')) return '+90${phone.substring(1)}';
    if (phone.startsWith('5')) return '+90$phone';

    return phone;
  }

  String? _locationValidator() {
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();
    final districts = turkeyDistrictsByCity[city] ?? const <String>[];

    if (city.isEmpty) return 'Lütfen şehir seçin.';
    if (!turkeyCities.contains(city)) {
      return 'Listeden geçerli bir şehir seçin.';
    }
    if (districts.isNotEmpty && district.isEmpty) {
      return 'Lütfen ilçe seçin.';
    }
    if (district.isNotEmpty &&
        districts.isNotEmpty &&
        !districts.contains(district)) {
      return 'Listeden geçerli bir ilçe seçin.';
    }

    return null;
  }

  void _syncLocation() {
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();

    _locationController.text = district.isEmpty ? city : '$district, $city';
    _listingLatitude = null;
    _listingLongitude = null;
  }

  void _onContactChanged(String value) {
    final phone = _normalizedPhone(value);
    if (_verifiedPhone == null || _verifiedPhone == phone) return;

    setState(() {
      _verifiedPhone = null;
      _verificationId = null;
      _smsCodeController.clear();
      _phoneAuthMessage = 'Numara değiştiği için tekrar doğrulama gerekiyor.';
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _captureListingLocation() async {
    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);
    try {
      final location = (await widget.locationClient.getCurrentLocation())
          .rounded();
      if (!mounted) return;
      setState(() {
        _listingLatitude = location.latitude;
        _listingLongitude = location.longitude;
      });
      _showMessage('Yaklaşık konum ilana eklendi.');
    } on LocationServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Konum alınamadı. Biraz sonra tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _removeListingLocation() {
    setState(() {
      _listingLatitude = null;
      _listingLongitude = null;
    });
  }

  Future<void> _sendSmsCode() async {
    final phoneError = _phoneValidator(_contactController.text);
    if (phoneError != null) {
      setState(() => _phoneAuthMessage = phoneError);
      return;
    }

    if (Firebase.apps.isEmpty) {
      setState(() {
        _phoneAuthMessage = 'Firebase bağlantısı hazır değil.';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _phoneAuthMessage = 'Telefon doğrulamak için giriş yapmalısınız.';
      });
      return;
    }

    final phone = _normalizedPhone(_contactController.text);
    if (user.phoneNumber == phone) {
      setState(() {
        _verifiedPhone = phone;
        _phoneAuthMessage = 'Bu numara zaten doğrulanmış.';
      });
      return;
    }

    setState(() {
      _isSendingCode = true;
      _phoneAuthMessage = 'SMS kodu gönderiliyor...';
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      verificationCompleted: (credential) async {
        await _confirmPhoneCredential(credential, phone);
      },
      verificationFailed: (error) {
        if (!mounted) return;

        debugPrint(
          'Telefon doğrulama hatası: ${error.code} - ${error.message}',
        );

        setState(() {
          _isSendingCode = false;
          _phoneAuthMessage = _phoneAuthMessageForError(error);
        });
      },
      codeSent: (verificationId, resendToken) {
        if (!mounted) return;

        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isSendingCode = false;
          _phoneAuthMessage = 'SMS kodu gönderildi. Gelen kodu yazın.';
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifySmsCode() async {
    final verificationId = _verificationId;
    final smsCode = _smsCodeController.text.trim();

    if (verificationId == null) {
      setState(() {
        _phoneAuthMessage = 'Önce SMS kodu gönderin.';
      });
      return;
    }

    if (smsCode.length < 6) {
      setState(() {
        _phoneAuthMessage = 'SMS kodunu eksiksiz girin.';
      });
      return;
    }

    setState(() {
      _isVerifyingCode = true;
      _phoneAuthMessage = 'Kod kontrol ediliyor...';
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    await _confirmPhoneCredential(
      credential,
      _normalizedPhone(_contactController.text),
    );
  }

  Future<void> _confirmPhoneCredential(
    PhoneAuthCredential credential,
    String phone,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isSendingCode = false;
        _isVerifyingCode = false;
        _phoneAuthMessage = 'Telefon doğrulamak için giriş yapmalısınız.';
      });
      return;
    }

    try {
      if (user.phoneNumber == phone) {
        await user.reload();
      } else if (user.phoneNumber == null) {
        await user.linkWithCredential(credential);
      } else {
        await user.updatePhoneNumber(credential);
      }

      if (!mounted) return;

      setState(() {
        _verifiedPhone = phone;
        _isSendingCode = false;
        _isVerifyingCode = false;
        _phoneAuthMessage = 'Telefon numarası doğrulandı.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      debugPrint('SMS kodu onaylama hatası: ${error.code} - ${error.message}');

      setState(() {
        _isSendingCode = false;
        _isVerifyingCode = false;
        _phoneAuthMessage = _phoneAuthMessageForError(error);
      });
    }
  }

  String _phoneAuthMessageForError(FirebaseAuthException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (error.code == 'operation-not-allowed' ||
        error.code == '17006' ||
        message.contains('operation is not allowed') ||
        message.contains('provider is disabled')) {
      return 'Firebase Phone giriş yöntemi bu proje için aktif görünmüyor.';
    }

    if (error.code == 'app-not-authorized' ||
        message.contains('app is not authorized') ||
        message.contains('invalid app info') ||
        message.contains('play_integrity_token')) {
      return 'Emülatörde uygulama doğrulaması tamamlanamadı. Gerçek SMS için fiziksel Android cihaz kullanın.';
    }

    return switch (error.code) {
      'invalid-phone-number' => 'Geçerli bir telefon numarası girin.',
      'invalid-verification-code' => 'SMS kodu hatalı.',
      'credential-already-in-use' =>
        'Bu telefon başka bir hesapta kullanılıyor.',
      'too-many-requests' => 'Çok fazla deneme yapıldı, biraz sonra deneyin.',
      'quota-exceeded' => 'SMS kotası dolmuş görünüyor.',
      'network-request-failed' => 'İnternet bağlantısını kontrol edin.',
      'requires-recent-login' =>
        'Telefonu güncellemek için tekrar giriş yapın.',
      _ => 'Telefon doğrulaması tamamlanamadı.',
    };
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1400,
    );

    if (photo == null || !mounted) return;

    setState(() {
      _selectedPhoto = photo;
      _removeExistingPhoto = false;
    });
  }

  void _removePhoto() {
    setState(() {
      if (_selectedPhoto != null) {
        _selectedPhoto = null;
      } else {
        _removeExistingPhoto = true;
      }
    });
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

  String _ownerNameFor(User? user, UserProfile? profile) {
    final profileName = profile?.displayName.trim();
    if (profileName?.isNotEmpty == true) return profileName!;

    final displayName = user?.displayName?.trim();

    return displayName?.isNotEmpty == true ? displayName! : 'Kullanıcı';
  }

  Future<UserProfile?> _profileFor(User? user) async {
    if (user == null) return null;

    try {
      return await widget.profileRepository.getProfile(user.uid);
    } catch (error) {
      debugPrint('Profil bilgisi okunamadı: $error');
      return null;
    }
  }

  Future<void> _submitDraft() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (Firebase.apps.isNotEmpty && !_isPhoneVerified) {
      setState(() {
        _phoneAuthMessage = 'İlan açmak için telefon numarasını doğrulayın.';
      });
      _showMessage('İlan açmak için telefon numarasını doğrulayın.');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final oldListing = widget.listing;
    final listingId = oldListing?.id ?? 'listing-${now.millisecondsSinceEpoch}';
    final ownerId = oldListing?.ownerId ?? user?.uid ?? 'local-user';
    final ownerProfile = oldListing == null ? await _profileFor(user) : null;
    String? imageUrl;
    var photoUploadFailed = false;
    var oldPhotoCleanupFailed = false;

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
            ownerName: _ownerNameFor(user, ownerProfile),
            createdAt: now,
            imageAsset: listingImageForCategory(_selectedCategory!),
            contactInfo: _contactController.text.trim(),
            imageUrl: imageUrl,
            ownerAccountType:
                ownerProfile?.accountType ?? AccountType.individual,
            isOwnerVerified:
                ownerProfile?.accountType == AccountType.organization &&
                ownerProfile?.isOrganizationVerified == true,
            latitude: _listingLatitude,
            longitude: _listingLongitude,
          )
        : oldListing.copyWith(
            title: _titleController.text.trim(),
            category: _selectedCategory!,
            location: _locationController.text.trim(),
            amount: _amountController.text.trim(),
            description: _descriptionController.text.trim(),
            imageAsset: listingImageForCategory(_selectedCategory!),
            contactInfo: _contactController.text.trim(),
            imageUrl: imageUrl,
            clearImageUrl: _removeExistingPhoto,
            latitude: _listingLatitude,
            longitude: _listingLongitude,
            clearCoordinates:
                _listingLatitude == null || _listingLongitude == null,
          );

    final isSaved = _isEditing
        ? await _listingRepository.updateListing(listing)
        : await _listingRepository.addListing(listing);

    if (isSaved &&
        oldListing?.imageUrl?.isNotEmpty == true &&
        (imageUrl != null || _removeExistingPhoto)) {
      oldPhotoCleanupFailed = !await _photoStorageService.deleteListingPhoto(
        oldListing!.imageUrl,
      );
    }

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
          content: Text('İlan kaydedilemedi, lütfen tekrar deneyin.'),
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
    } else if (oldPhotoCleanupFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan kaydedildi ama eski fotoğraf silinemedi.'),
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
          padding: responsivePagePadding(context, top: 20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ResponsiveContent(
            maxWidth: kFormContentMaxWidth,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing
                        ? 'İlan bilgilerini düzenle'
                        : 'Yeni ilan oluştur',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    imageUrl: _removeExistingPhoto
                        ? null
                        : widget.listing?.imageUrl,
                    onTap: _showPhotoOptions,
                    onRemove:
                        _selectedPhoto == null &&
                            (widget.listing?.imageUrl == null ||
                                widget.listing!.imageUrl!.isEmpty ||
                                _removeExistingPhoto)
                        ? null
                        : _removePhoto,
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
                  FormField<void>(
                    validator: (_) => _locationValidator(),
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LocationAutocompleteField(
                            labelText: 'Şehir',
                            hintText: 'Şehir ara',
                            icon: Icons.location_city_outlined,
                            controller: _cityController,
                            options: turkeyCities,
                            onChanged: (value) {
                              setState(() {
                                _cityController.text = value;
                                _districtController.clear();
                                _syncLocation();
                              });
                              field.didChange(null);
                            },
                            onSelected: (value) {
                              setState(() {
                                _cityController.text = value;
                                _districtController.clear();
                                _syncLocation();
                              });
                              field.didChange(null);
                            },
                          ),
                          const SizedBox(height: 12),
                          _LocationAutocompleteField(
                            labelText: 'İlçe',
                            hintText: _cityController.text.trim().isEmpty
                                ? 'Önce şehir seçin'
                                : 'İlçe ara',
                            icon: Icons.place_outlined,
                            controller: _districtController,
                            options:
                                turkeyDistrictsByCity[_cityController.text
                                    .trim()] ??
                                const [],
                            enabled: _cityController.text.trim().isNotEmpty,
                            onChanged: (value) {
                              setState(() {
                                _districtController.text = value;
                                _syncLocation();
                              });
                              field.didChange(null);
                            },
                            onSelected: (value) {
                              setState(() {
                                _districtController.text = value;
                                _syncLocation();
                              });
                              field.didChange(null);
                            },
                          ),
                          if (field.hasError) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _listingLatitude == null
                                ? Icons.near_me_outlined
                                : Icons.near_me_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _listingLatitude == null
                                    ? 'Yakındaki ilanlarda görün'
                                    : 'Yaklaşık konum eklendi',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _listingLatitude == null
                                    ? 'İlanın mesafeye göre bulunabilmesi için cihaz konumunu ekleyin.'
                                    : 'Tam adresiniz gösterilmez; konum yalnızca mesafe hesabında kullanılır.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _isGettingLocation
                                        ? null
                                        : _captureListingLocation,
                                    icon: _isGettingLocation
                                        ? const SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.my_location_rounded),
                                    label: Text(
                                      _listingLatitude == null
                                          ? 'Konumumu ekle'
                                          : 'Konumu güncelle',
                                    ),
                                  ),
                                  if (_listingLatitude != null)
                                    TextButton(
                                      onPressed: _removeListingLocation,
                                      child: const Text('Konumu kaldır'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _contactController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    validator: _phoneValidator,
                    onChanged: _onContactChanged,
                    decoration: const InputDecoration(
                      labelText: 'Telefon numarası',
                      hintText: 'Örn. 0555 111 22 33',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PhoneVerificationCard(
                    isVerified: _isPhoneVerified,
                    isSendingCode: _isSendingCode,
                    isVerifyingCode: _isVerifyingCode,
                    verificationId: _verificationId,
                    message: _phoneAuthMessage,
                    smsCodeController: _smsCodeController,
                    onSendCode: _sendSmsCode,
                    onVerifyCode: _verifySmsCode,
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
    );
  }
}

class _PhoneVerificationCard extends StatelessWidget {
  const _PhoneVerificationCard({
    required this.isVerified,
    required this.isSendingCode,
    required this.isVerifyingCode,
    required this.verificationId,
    required this.message,
    required this.smsCodeController,
    required this.onSendCode,
    required this.onVerifyCode,
  });

  final bool isVerified;
  final bool isSendingCode;
  final bool isVerifyingCode;
  final String? verificationId;
  final String? message;
  final TextEditingController smsCodeController;
  final VoidCallback onSendCode;
  final VoidCallback onVerifyCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isVerified
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified_user_outlined : Icons.sms_outlined,
                color: isVerified ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isVerified
                      ? 'Telefon doğrulandı'
                      : 'İlan için SMS doğrulaması',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isVerified
                ? 'Talep kabul edilince bu numara karşı tarafa gösterilir.'
                : 'Numaranıza gelen kod onaylanmadan ilan yayınlanmaz.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (isVerified)
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu numara ilan için hazır.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: isSendingCode || isVerifyingCode ? null : onSendCode,
              icon: isSendingCode
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_to_mobile_outlined),
              label: Text(
                verificationId == null
                    ? 'SMS Kodu Gönder'
                    : 'Kodu Tekrar Gönder',
              ),
            ),
          if (verificationId != null && !isVerified) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: smsCodeController,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'SMS kodu',
                hintText: '6 haneli kod',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: isSendingCode || isVerifyingCode ? null : onVerifyCode,
              icon: isVerifyingCode
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Kodu Onayla'),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isVerified ? colorScheme.primary : colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationAutocompleteField extends StatelessWidget {
  const _LocationAutocompleteField({
    required this.labelText,
    required this.hintText,
    required this.icon,
    required this.controller,
    required this.options,
    required this.onChanged,
    required this.onSelected,
    this.enabled = true,
  });

  final String labelText;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        final query = _normalizeSearchText(textEditingValue.text);
        if (query.isEmpty) return options;

        return options.where((option) {
          return _normalizeSearchText(option).contains(query);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            if (textEditingController.text != controller.text) {
              textEditingController.text = controller.text;
            }

            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
                prefixIcon: Icon(icon),
                suffixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                controller.text = value;
                onChanged(value);
              },
              onFieldSubmitted: (_) => onFieldSubmitted(),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);

                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

String _normalizeSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
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
                              errorBuilder: (context, error, stackTrace) {
                                return _PhotoPlaceholder(
                                  colorScheme: colorScheme,
                                  message: 'Fotoğraf yüklenemedi',
                                );
                              },
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.colorScheme, required this.message});

  final ColorScheme colorScheme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
