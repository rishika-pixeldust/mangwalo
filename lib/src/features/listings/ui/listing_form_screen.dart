import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock.dart';
import '../../../core/images.dart';
import '../../../core/validation/privacy_scanner.dart';
import '../../../core/validation/sanitizer.dart';
import '../../../core/validation/validators.dart';
import '../../ai/local_ai_service.dart';
import '../../settings/application/settings_controller.dart';
import '../application/listing_providers.dart';
import '../application/listing_suggestion_controller.dart';
import '../domain/listing.dart';
import 'widgets/ai_helper_panel.dart';

/// Create/edit form. The on-device helper suggests, the user decides:
/// suggestions only ever fill a field through an explicit chip tap.
class ListingFormScreen extends ConsumerStatefulWidget {
  const ListingFormScreen({super.key, this.listingId});

  final String? listingId;

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();

  ListingType _type = ListingType.offer;
  Category? _category;
  String _subCategory = '';
  final Set<String> _conditionTags = {};
  int? _suggestedDurationDays;
  final List<String> _photos = [];
  bool _pickingPhoto = false;
  List<PrivacyWarning> _warnings = const [];
  Listing? _existing;

  @override
  void initState() {
    super.initState();
    final id = widget.listingId;
    if (id != null) {
      final existing = ref.read(listingByIdProvider(id));
      if (existing != null) {
        _existing = existing;
        _type = existing.type;
        _category = existing.category;
        _subCategory = existing.subCategory;
        _conditionTags.addAll(existing.conditionTags);
        _suggestedDurationDays = existing.suggestedDurationDays;
        _photos.addAll(existing.photos);
        _titleController.text = existing.title;
        _priceController.text = existing.pricePerDayInr.toString();
        _depositController.text = existing.depositInr?.toString() ?? '';
        _descriptionController.text = existing.description;
        _areaController.text = existing.area;
        _subCategoryController.text = existing.subCategory;
        // Prefilled text gets the same privacy screening as typed text.
        _warnings = _scanFreeText();
      }
    }
  }

  /// Privacy-scan every free-text field the user could leak PII through.
  List<PrivacyWarning> _scanFreeText() => PrivacyScanner.scan(
      '${_titleController.text}\n${_descriptionController.text}');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _subCategoryController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= kMaxListingPhotos) return;
    setState(() => _pickingPhoto = true);
    try {
      final encoded = await pickAndEncodeListingPhoto();
      if (encoded != null && mounted) {
        setState(() => _photos.add(encoded));
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _onDescriptionChanged(String text) {
    setState(() => _warnings = _scanFreeText());
    ref
        .read(listingSuggestionProvider.notifier)
        .onDescriptionChanged(text, listingType: _type);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = ref.read(nowProvider)();
    final neighborhood = ref.read(settingsProvider).neighborhood ?? '';
    final repo = ref.read(listingRepositoryProvider);

    final title = sanitize(_titleController.text, maxLength: Validators.titleMax);
    final description = sanitize(_descriptionController.text,
        maxLength: Validators.descriptionMax, multiline: true);
    final area = sanitize(_areaController.text, maxLength: Validators.areaMax);
    final category = _category ?? Category.other;
    // "Others" takes a typed label; the preset categories take a picked one.
    final subCategory = category.takesCustomSubCategory
        ? sanitize(_subCategoryController.text,
            maxLength: kMaxSubCategoryLength)
        : _subCategory;
    final tags = _conditionTags.toList()..sort();
    final price =
        int.parse(sanitize(_priceController.text).replaceAll(',', ''));
    final depositText = sanitize(_depositController.text).replaceAll(',', '');
    final deposit = depositText.isEmpty ? null : int.parse(depositText);

    final existing = _existing;
    final listing = existing != null
        ? existing.copyWith(
            type: _type,
            title: title,
            description: description,
            category: category,
            subCategory: subCategory,
            conditionTags: tags,
            area: area,
            pricePerDayInr: price,
            depositInr: deposit,
            suggestedDurationDays: _suggestedDurationDays,
            photos: List.unmodifiable(_photos),
            updatedAt: now,
          )
        : Listing(
            id: const Uuid().v4(),
            type: _type,
            title: title,
            description: description,
            category: category,
            subCategory: subCategory,
            conditionTags: tags,
            area: area,
            neighborhood: neighborhood,
            pricePerDayInr: price,
            depositInr: deposit,
            suggestedDurationDays: _suggestedDurationDays,
            photos: List.unmodifiable(_photos),
            createdAt: now,
            updatedAt: now,
            isMine: true,
          );

    await repo.put(listing);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(existing == null
                ? 'Listing added to your noticeboard'
                : 'Listing updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = ref.watch(listingSuggestionProvider);
    final engineInfo = ref.watch(localAiServiceProvider).engineInfo;

    // Announce new suggestions to assistive tech — but only when the set
    // materially changes, never per keystroke.
    ref.listen(listingSuggestionProvider, (previous, next) {
      if (previous != next && !next.isEmpty) {
        SemanticsService.sendAnnouncement(
            View.of(context),
            'Suggestions available below the description field',
            TextDirection.ltr);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listingId == null ? 'New listing' : 'Edit listing'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // The type is fixed once posted: a "Rent out" listing carries
            // rental state and reviews that make no sense on a request, so
            // editing shows what it is rather than offering to switch it.
            if (_existing == null) ...[
              Text('What kind of listing?', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<ListingType>(
                  segments: const [
                    ButtonSegment(
                      value: ListingType.offer,
                      label: Text('Rent out'),
                      icon: Icon(Icons.volunteer_activism_outlined),
                    ),
                    ButtonSegment(
                      value: ListingType.request,
                      label: Text('Looking for'),
                      icon: Icon(Icons.front_hand_outlined),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    setState(() => _type = selection.first);
                    // Re-run suggestions: title phrasing depends on the type.
                    _onDescriptionChanged(_descriptionController.text);
                  },
                ),
              ),
            ] else
              Row(
                children: [
                  Icon(
                    _type == ListingType.offer
                        ? Icons.volunteer_activism_outlined
                        : Icons.front_hand_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _type == ListingType.offer
                        ? 'Renting this out'
                        : 'Looking for this',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              onChanged: _onDescriptionChanged,
              validator: Validators.description,
              maxLength: Validators.descriptionMax,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Chanel flap bag, barely used, with dust '
                    'bag. Weekends only.',
                helperText: 'Describe the item — suggestions appear as '
                    'you type.',
                helperMaxLines: 2,
              ),
            ),
            for (final warning in _warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                // liveRegion: assistive tech announces the warning the
                // moment it appears — safety messages must not be
                // visual-only (WCAG 4.1.3).
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.privacy_tip_outlined,
                          size: 18,
                          color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${warning.message} (found "${warning.matchedText}")',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            AiHelperPanel(
              suggestion: suggestion,
              engineInfo: engineInfo,
              titleApplied:
                  _titleController.text == suggestion.suggestedTitle,
              categoryApplied: _category != null &&
                  _category == suggestion.suggestedCategory,
              subCategoryApplied: _subCategory.isNotEmpty &&
                  _subCategory == suggestion.suggestedSubCategory,
              appliedTags: {
                for (final tag in suggestion.conditionTags)
                  if (_conditionTags.contains(tag.label)) tag,
              },
              durationApplied: _suggestedDurationDays != null &&
                  _suggestedDurationDays ==
                      suggestion.suggestedLoanDuration?.days,
              priceApplied: _priceController.text ==
                  suggestion.suggestedPricePerDayInr?.toString(),
              onApplyPrice: (price) =>
                  setState(() => _priceController.text = price.toString()),
              onApplyTitle: (title) =>
                  setState(() => _titleController.text = title),
              // Applying a category clears any stale sub-category; applying a
              // sub-category also sets its parent, so one tap is enough.
              onApplyCategory: () => setState(() {
                _category = suggestion.suggestedCategory;
                _subCategory = '';
                _subCategoryController.clear();
              }),
              onApplySubCategory: (sub) => setState(() {
                _category ??= suggestion.suggestedCategory;
                _subCategory = sub;
              }),
              onToggleTag: (tag) => setState(() {
                if (!_conditionTags.remove(tag.label)) {
                  _conditionTags.add(tag.label);
                }
              }),
              onApplyDuration: () => setState(() => _suggestedDurationDays =
                  suggestion.suggestedLoanDuration?.days),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              validator: Validators.title,
              maxLength: Validators.titleMax,
              onChanged: (_) => setState(() => _warnings = _scanFreeText()),
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Short and clear, e.g. "Chanel Classic Flap bag"',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              // Recreate the field when a suggestion chip changes _category:
              // FormField state doesn't re-read initialValue on rebuild, and
              // a stale null value would fail validation despite the visible
              // selection.
              key: ValueKey(_category),
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in Category.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              validator: (value) =>
                  value == null ? 'Pick a category.' : null,
              // Switching category invalidates any sub-category picked under
              // the old one, so clear it rather than keep a nonsense pair.
              onChanged: (value) => setState(() {
                _category = value;
                _subCategory = '';
                _subCategoryController.clear();
              }),
            ),
            // Second level: picked from a preset list, or typed when the
            // category is "Others". Optional either way.
            if (_category != null) ...[
              const SizedBox(height: 12),
              if (_category!.takesCustomSubCategory)
                TextFormField(
                  controller: _subCategoryController,
                  maxLength: kMaxSubCategoryLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'What kind of item? (optional)',
                    hintText: 'e.g. Telescope, Drone, Camera lens',
                    counterText: '',
                    helperText: 'Helps neighbours find it in search.',
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('sub-${_category!.name}-$_subCategory'),
                  initialValue: _subCategory.isEmpty ? null : _subCategory,
                  decoration: const InputDecoration(
                    labelText: 'Sub-category (optional)',
                  ),
                  items: [
                    for (final s in _category!.subCategories)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (value) =>
                      setState(() => _subCategory = value ?? ''),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    validator: Validators.pricePerDay,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText:
                          _type == ListingType.request ? 'Budget (₹/day)' : 'Rate (₹/day)',
                      hintText: 'e.g. 2500',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    validator: Validators.deposit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Deposit (optional)',
                      hintText: 'e.g. 15000',
                      prefixText: '₹ ',
                      helperText: 'Refundable.',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _areaController,
              validator: Validators.area,
              maxLength: Validators.areaMax,
              decoration: const InputDecoration(
                labelText: 'Nearby landmark',
                hintText: 'e.g. Near Joggers Park gate',
                helperText: 'Landmark only — never an exact address. '
                    'Exact locations stay private.',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text('Photos (up to $kMaxListingPhotos)',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_photos.isNotEmpty) ...[
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Semantics(
                          label:
                              'Photo ${i + 1} of ${_photos.length}'
                              '${i == 0 ? ' — cover' : ''}',
                          image: true,
                          child: Image.memory(
                            base64Decode(_photos[i]),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Semantics(
                          label: 'Remove photo ${i + 1}',
                          button: true,
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: ExcludeSemantics(
                            child: IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () =>
                                  setState(() => _photos.removeAt(i)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: (_pickingPhoto || _photos.length >= kMaxListingPhotos)
                  ? null
                  : _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(_pickingPhoto
                  ? 'Preparing photo…'
                  : _photos.length >= kMaxListingPhotos
                      ? 'Gallery full ($kMaxListingPhotos/$kMaxListingPhotos)'
                      : 'Add photo (${_photos.length}/$kMaxListingPhotos)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'First photo becomes the cover. Downscaled and stored only '
              'on this device.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(
                  widget.listingId == null ? 'Add to noticeboard' : 'Save'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
