import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sifir_atik/data/turkey_locations.dart';
import 'package:sifir_atik/models/user_profile.dart';
import 'package:sifir_atik/services/user_profile_repository.dart';
import 'package:sifir_atik/widgets/responsive_layout.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.profile,
    this.repository = const UserProfileRepository(),
    this.updateAuthDisplayName,
  });

  final UserProfile profile;
  final UserProfileRepository repository;
  final Future<void> Function(String displayName)? updateAuthDisplayName;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _cityFocusNode = FocusNode();
  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _contactPersonController;
  late OrganizationType _organizationType;
  bool _isSaving = false;

  bool get _isOrganization =>
      widget.profile.accountType == AccountType.organization;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _cityController = TextEditingController(text: widget.profile.city);
    _contactPersonController = TextEditingController(
      text: widget.profile.contactPersonName,
    );
    _organizationType =
        widget.profile.organizationType ?? OrganizationType.other;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _cityController.dispose();
    _contactPersonController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  String? _validateDisplayName(String? value) {
    if ((value?.trim().length ?? 0) < 2) {
      return _isOrganization
          ? 'Şirket veya kurum adını yazın.'
          : 'Adınızı ve soyadınızı yazın.';
    }
    return null;
  }

  String? _validateCity(String? value) {
    final city = value?.trim() ?? '';
    if (city.isEmpty) return null;
    if (!turkeyCities.contains(city)) {
      return 'Listeden geçerli bir şehir seçin.';
    }
    return null;
  }

  String? _validateContactPerson(String? value) {
    if (!_isOrganization) return null;
    if ((value?.trim().length ?? 0) < 2) {
      return 'Yetkili kişinin adını yazın.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final displayName = _displayNameController.text.trim();

    try {
      await widget.repository.updateProfile(
        uid: widget.profile.uid,
        displayName: displayName,
        city: _cityController.text.trim(),
        contactPersonName: _contactPersonController.text.trim(),
        accountType: widget.profile.accountType,
        organizationType: _isOrganization ? _organizationType : null,
      );

      if (widget.updateAuthDisplayName != null) {
        await widget.updateAuthDisplayName!(displayName);
      } else if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Profil bilgileri şu anda güncellenemedi.');
    } catch (_) {
      _showMessage('Profil bilgileri şu anda güncellenemedi.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil bilgileri')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: responsivePagePadding(context, top: 20),
            children: [
              ResponsiveContent(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOrganization
                            ? Icons.apartment_rounded
                            : Icons.person_outline_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.profile.accountType.profileLabel,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.profile.email,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ResponsiveContent(
                child: TextFormField(
                  controller: _displayNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _validateDisplayName,
                  decoration: InputDecoration(
                    labelText: _isOrganization
                        ? 'Şirket / kurum adı'
                        : 'Ad soyad',
                    prefixIcon: Icon(
                      _isOrganization
                          ? Icons.apartment_outlined
                          : Icons.person_outline_rounded,
                    ),
                  ),
                ),
              ),
              if (_isOrganization) ...[
                const SizedBox(height: 16),
                ResponsiveContent(
                  child: DropdownButtonFormField<OrganizationType>(
                    initialValue: _organizationType,
                    decoration: const InputDecoration(
                      labelText: 'Kurum türü',
                      prefixIcon: Icon(Icons.domain_outlined),
                    ),
                    items: OrganizationType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _organizationType = value);
                            }
                          },
                  ),
                ),
                const SizedBox(height: 16),
                ResponsiveContent(
                  child: TextFormField(
                    controller: _contactPersonController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _validateContactPerson,
                    decoration: const InputDecoration(
                      labelText: 'Yetkili kişi',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ResponsiveContent(
                child: RawAutocomplete<String>(
                  textEditingController: _cityController,
                  focusNode: _cityFocusNode,
                  displayStringForOption: (option) => option,
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) return turkeyCities;
                    return turkeyCities.where(
                      (city) => city.toLowerCase().contains(query),
                    );
                  },
                  onSelected: (city) {
                    _cityController.text = city;
                    _cityController.selection = TextSelection.collapsed(
                      offset: city.length,
                    );
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          validator: _validateCity,
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                          decoration: const InputDecoration(
                            labelText: 'Şehir',
                            hintText: 'Yazarak şehir ara',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    final cities = options.toList();
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 520,
                            maxHeight: 240,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: cities.length,
                            itemBuilder: (context, index) {
                              final city = cities[index];
                              return ListTile(
                                title: Text(city),
                                onTap: () => onSelected(city),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ResponsiveContent(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Kaydediliyor' : 'Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
