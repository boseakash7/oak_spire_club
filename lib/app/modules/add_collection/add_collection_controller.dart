import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/bluebook_model.dart';
import '../../data/repositories/bluebook_repository.dart';
import '../../data/repositories/collection_repository.dart';

class AddCollectionController extends GetxController {
  AddCollectionController({
    required BluebookRepository bluebookRepo,
    required CollectionRepository collectionRepo,
  })  : _bluebookRepo = bluebookRepo,
        _collectionRepo = collectionRepo;

  final BluebookRepository _bluebookRepo;
  final CollectionRepository _collectionRepo;

  final searchCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');

  final isSearching = false.obs;
  final isSubmitting = false.obs;
  final results = <BluebookModel>[].obs;
  final selected = Rxn<BluebookModel>();

  final fillPercent = 100.0.obs;

  int _page = 1;
  bool _hasMore = true;
  Timer? _debounce;

  static const int _limit = 25;

  @override
  void onInit() {
    super.onInit();
    searchCtrl.addListener(_onKeywordChanged);
    _fetch(reset: true);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
    super.onClose();
  }

  void _onKeywordChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetch(reset: true);
    });
  }

  Future<void> _fetch({required bool reset}) async {
    if (isSearching.value) return;

    if (reset) {
      _page = 1;
      _hasMore = true;
      results.clear();
    } else {
      if (!_hasMore) return;
      _page += 1;
    }

    isSearching.value = true;
    try {
      final list = await _bluebookRepo.search(
        page: _page,
        limit: _limit,
        keyword: searchCtrl.text,
      );
      if (list.isEmpty) {
        _hasMore = false;
      } else {
        results.addAll(list);
      }
    } catch (e) {
      if (reset) {
        results.clear();
      }
      await AppSnackbar.error(e.toString());
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> loadMore() => _fetch(reset: false);

  void pick(BluebookModel b) {
    selected.value = b;
    // Pre-fill price with average when available.
    final avg = b.average?.toString();
    if (avg != null && avg.trim().isNotEmpty && avg != 'null') {
      priceCtrl.text = avg;
    }
  }

  void clearSelection() {
    selected.value = null;
    fillPercent.value = 100;
    priceCtrl.clear();
    qtyCtrl.text = '1';
  }

  Future<void> createCustomBottle() async {
    final userId = AppStorage.userId;
    if (userId == null || userId.isEmpty) {
      await AppSnackbar.error('Please sign in again.');
      return;
    }

    final name = searchCtrl.text.trim();
    final price = priceCtrl.text.trim();
    if (name.isEmpty) {
      await AppSnackbar.error('Enter bottle name first.');
      return;
    }
    if (price.isEmpty) {
      await AppSnackbar.error('Enter price first.');
      return;
    }

    isSubmitting.value = true;
    try {
      final b = await _bluebookRepo.create(
        bottleName: name,
        bottlePrice: price,
        userId: userId,
      );
      pick(b);
      await AppSnackbar.success('Bottle created.');
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> submit() async {
    final b = selected.value;
    if (b == null) {
      await AppSnackbar.error('Select a bottle first.');
      return;
    }

    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final fill = fillPercent.value.toInt().clamp(0, 100);

    isSubmitting.value = true;
    try {
      await _collectionRepo.addToCollection(
        bottleId: b.id,
        quantity: qty <= 0 ? 1 : qty,
        fill: fill,
        pricePaid: price,
        image: b.image,
      );
      await AppSnackbar.success('Added to collection.');
      Get.back(result: true);
    } catch (e) {
      await AppSnackbar.error(e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}

