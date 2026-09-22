import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/app_storage.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/limit_exceeded_exception.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/dispose_after_detach.dart';
import '../../core/utils/price_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../routes/app_routes.dart';
import '../collection/collection_controller.dart';
import '../home/home_controller.dart';
import '../navigation/bottom_nav_controller.dart';

class AddCollectionController extends GetxController {
  AddCollectionController({
    required BluebookRepository bluebookRepo,
    required CollectionRepository collectionRepo,
  }) : _bluebookRepo = bluebookRepo,
       _collectionRepo = collectionRepo;

  final BluebookRepository _bluebookRepo;
  final CollectionRepository _collectionRepo;

  final bottleNameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final fillCtrl = TextEditingController(text: '100');
  final dateAcquiredCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final isSubmitting = false.obs;
  final selected = Rxn<BluebookModel>();
  final isEditMode = false.obs;

  final bottleNameError = RxnString();
  final qtyError = RxnString();
  final priceError = RxnString();
  final dateAcquiredError = RxnString();
  final fillError = RxnString();

  final previewImageUrl = ''.obs;
  final customImageFile = Rxn<File>();

  DateTime? dateAcquired;
  String? _originalBottleId;

  /// Set from route prefill — stays true for own-bottle flow even after bluebook create.
  bool _isCustomBottleFlow = true;

  bool _navigateToCollectionOnSuccess = true;
  bool _popBenchmarkDetailOnSuccess = false;

  static final _imagePicker = ImagePicker();

  /// True when adding a user-defined bottle (not picked from catalog/list).
  bool get isCustomBottle => _isCustomBottleFlow;

  @override
  void onInit() {
    super.onInit();
    _applyPrefill(Get.arguments);
    _ensureDefaultDate();
  }

  @override
  void onClose() {
    unfocusSafely();
    disposeAfterDetach([
      bottleNameCtrl,
      priceCtrl,
      qtyCtrl,
      fillCtrl,
      dateAcquiredCtrl,
      notesCtrl,
    ]);
    super.onClose();
  }

  void _applyPrefill(dynamic args) {
    if (args is! Map) return;
    final map = Map<String, dynamic>.from(args);
    final prefillRaw = map['prefill'];
    _navigateToCollectionOnSuccess = map['navigateToCollectionOnSuccess'] == true;
    _popBenchmarkDetailOnSuccess = map['popBenchmarkDetailOnSuccess'] == true;
    isEditMode.value = map['editMode'] == true;
    final originalBottleIdRaw = map['originalBottleId']?.toString();
    if (originalBottleIdRaw != null &&
        originalBottleIdRaw.isNotEmpty &&
        originalBottleIdRaw != 'null') {
      _originalBottleId = originalBottleIdRaw;
    }
    if (prefillRaw is! Map) return;
    final prefill = Map<String, dynamic>.from(prefillRaw);

    final id = prefill['id']?.toString();
    final name = prefill['name']?.toString() ?? '';
    final average = prefill['average']?.toString();
    final image = prefill['image']?.toString();
    final fill = double.tryParse(prefill['fill']?.toString() ?? '');
    final qty = int.tryParse(prefill['quantity']?.toString() ?? '');
    final notes = prefill['notes']?.toString() ?? '';
    final dateAcquiredRaw = prefill['date_acquired']?.toString() ?? '';

    bottleNameCtrl.text = name;
    if (average != null && average.trim().isNotEmpty && average != 'null') {
      _setFormattedPrice(average);
    }
    if (qty != null && qty > 0) qtyCtrl.text = qty.toString();
    if (fill != null) {
      final normalized = fill.round().clamp(1, 100);
      fillCtrl.text = normalized.toString();
    }
    if (notes.isNotEmpty) notesCtrl.text = notes;
    if (dateAcquiredRaw.isNotEmpty && dateAcquiredRaw != 'null') {
      dateAcquiredCtrl.text = dateAcquiredRaw;
      final parsed = DateTime.tryParse(dateAcquiredRaw);
      if (parsed != null) {
        dateAcquired = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    if (image != null && image.isNotEmpty && image != 'null') {
      previewImageUrl.value = image;
    }

    if (id != null && id.isNotEmpty && id != 'null') {
      _isCustomBottleFlow = false;
      selected.value = BluebookModel(
        id: id,
        bottleName: name,
        average: average,
        image: image,
      );
    }
  }

  void _setFormattedPrice(String value) {
    final normalized = PriceFormatter.normalizeForApi(value);
    if (normalized == null) {
      priceCtrl.clear();
      return;
    }
    priceCtrl.text = PriceFormatter.format(normalized, withSymbol: false);
  }

  void _ensureDefaultDate() {
    if (dateAcquiredCtrl.text.trim().isNotEmpty) return;
    final now = DateTime.now();
    dateAcquired = DateTime(now.year, now.month, now.day);
    dateAcquiredCtrl.text = _formatDate(dateAcquired!);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _digitsOnly(String value) {
    return PriceFormatter.normalizeForApi(value) ?? '';
  }

  Future<void> pickCustomImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 88,
      );
      if (picked == null) return;
      customImageFile.value = File(picked.path);
    } catch (e) {
      await AppSnackbar.error('Could not pick image. Please try again.');
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 2),
      initialDate: dateAcquired ?? now,
    );
    if (picked == null) return;
    dateAcquired = picked;
    dateAcquiredCtrl.text = _formatDate(picked);
    dateAcquiredError.value = null;
  }

  void clearBottleNameError(String _) => bottleNameError.value = null;
  void clearQtyError(String _) => qtyError.value = null;
  void clearPriceError(String _) => priceError.value = null;
  void clearDateAcquiredError(String _) => dateAcquiredError.value = null;
  void clearFillError(String _) => fillError.value = null;

  bool _validateForm() {
    bottleNameError.value = Validators.requiredText(
      bottleNameCtrl.text,
      message: 'Enter bottle name.',
    );
    qtyError.value = Validators.positiveQuantity(qtyCtrl.text);
    priceError.value = Validators.positivePrice(priceCtrl.text);
    dateAcquiredError.value = Validators.dateAcquired(dateAcquiredCtrl.text);
    fillError.value = Validators.fillPercent(fillCtrl.text);

    return bottleNameError.value == null &&
        qtyError.value == null &&
        priceError.value == null &&
        dateAcquiredError.value == null &&
        fillError.value == null;
  }

  Future<void> submit() async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) {
      await AppSnackbar.error('Please sign in again.');
      return;
    }

    if (!_validateForm()) {
      await AppSnackbar.error('Please fix the highlighted fields.');
      return;
    }

    final name = bottleNameCtrl.text.trim();
    final qty = int.parse(qtyCtrl.text.trim());
    final priceRaw = _digitsOnly(priceCtrl.text.trim());
    final price = double.parse(priceRaw);
    final fill = int.parse(fillCtrl.text.trim());
    final normalizedFill = fill.clamp(1, 100);

    isSubmitting.value = true;
    try {
      // Capture before bluebook create — [isCustomBottle] would flip false once id exists.
      final imageFile = _isCustomBottleFlow ? customImageFile.value : null;
      final imageUrlForCatalog = imageFile == null && !_isCustomBottleFlow
          ? selected.value?.image
          : null;

      var b = selected.value;
      if (b == null) {
        final created = await _bluebookRepo.create(
          bottleName: name,
          bottlePrice: priceRaw,
          userId: userId,
        );
        b = created;
        selected.value = created;
      }

      final resolvedQty = qty <= 0 ? 1 : qty;
      final imageUrl = imageFile == null
          ? (imageUrlForCatalog ?? b.image)
          : null;

      if (isEditMode.value &&
          _originalBottleId != null &&
          _originalBottleId!.isNotEmpty) {
        await _collectionRepo.replaceCollectionItem(
          originalBottleId: _originalBottleId!,
          bottleId: b.id,
          quantity: resolvedQty,
          fill: normalizedFill,
          pricePaid: price,
          imageFile: imageFile,
          image: imageUrl,
          notes: notesCtrl.text.trim(),
          dateAcquired: dateAcquiredCtrl.text.trim(),
        );
      } else {
        await _collectionRepo.addToCollection(
          bottleId: b.id,
          quantity: resolvedQty,
          fill: normalizedFill,
          pricePaid: price,
          imageFile: imageFile,
          image: imageUrl,
          notes: notesCtrl.text.trim(),
          dateAcquired: dateAcquiredCtrl.text.trim(),
        );
      }
      await AppSnackbar.success('Added to collection.');

      // Prevent a visible "flash" of the previous route by preparing the destination
      // (Collection tab) before closing this screen.
      if (_navigateToCollectionOnSuccess && Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().setIndex(1);
      }
      if (Get.isRegistered<HomeController>()) {
        unawaited(Get.find<HomeController>().fetchHomeData(forceRefresh: false));
      }
      if (Get.isRegistered<CollectionController>()) {
        unawaited(Get.find<CollectionController>().forceReload());
      }

      // If caller wants to land on Collection, pop straight back to Shell so any
      // intermediate opener route (Search, Benchmark Detail, etc.) never flashes.
      if (_navigateToCollectionOnSuccess || _popBenchmarkDetailOnSuccess) {
        Get.until((route) => route.settings.name == AppRoutes.shell);
        return;
      }

      Get.back(result: true);
    } on LimitExceededException {
      // [SubscriptionLimitNavigation] already opened IAP with the API message.
    } on ApiException catch (e) {
      await AppSnackbar.error(e.message);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
