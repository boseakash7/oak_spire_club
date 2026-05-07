class PagedResult<T> {
  PagedResult({
    required this.totalItems,
    required this.limit,
    required this.currentPage,
    required this.offset,
    required this.totalPages,
    required this.items,
  });

  final int totalItems;
  final int limit;
  final int currentPage;
  final int offset;
  final int totalPages;
  final List<T> items;
}

