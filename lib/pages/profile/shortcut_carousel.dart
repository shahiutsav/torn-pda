import 'dart:math';

import 'package:flutter/material.dart';

class ShortcutCarousel extends StatefulWidget {
  final List<dynamic> shortcuts;
  final bool showEditIcon;
  final Widget Function(dynamic) shortcutTileBuilder;
  final Widget Function({required double width, required double height})
      editTileBuilder;

  const ShortcutCarousel({
    super.key,
    required this.shortcuts,
    required this.showEditIcon,
    required this.shortcutTileBuilder,
    required this.editTileBuilder,
  });

  @override
  State<ShortcutCarousel> createState() => _ShortcutCarouselState();
}

class _ShortcutCarouselState extends State<ShortcutCarousel> {
  static const int rowCount = 2;
  static const double itemHeight = 56;
  static const double itemWidth = 72;
  static const int itemsPerPage = 10;

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _rebuildPages();
    _pageController = PageController();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void didUpdateWidget(ShortcutCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortcuts != widget.shortcuts ||
        oldWidget.showEditIcon != widget.showEditIcon) {
      setState(() {
        _rebuildPages();
        // Clamp page in case last page was removed
        _currentPage = _currentPage.clamp(0, _pages.length - 1);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  late List<List<dynamic>> _pages;

  void _rebuildPages() {
    final allItems = [
      ...widget.shortcuts,
      if (widget.showEditIcon) null,
    ];

    final pages = <List<dynamic>>[];
    for (int i = 0; i < allItems.length; i += itemsPerPage) {
      pages.add(allItems.sublist(i, min(i + itemsPerPage, allItems.length)));
    }
    if (pages.isEmpty) pages.add([]);
    _pages = pages;
  }

  int _rowsForPage(int pageIndex) {
    if (pageIndex >= _pages.length) return 1;
    final int totalItems = _pages[pageIndex].length;
    if (totalItems == 0) return 1;
    final int maxColumns = itemsPerPage ~/ rowCount;
    return totalItems <= maxColumns ? 1 : rowCount;
  }

  @override
  Widget build(BuildContext context) {
    // Clamp current page in case items were removed
    final int safePage = _currentPage.clamp(0, _pages.length - 1);
    final int activeRows = _rowsForPage(safePage);
    final double cardHeight = itemHeight * activeRows;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: cardHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, pageIndex) {
                  // Build all items for this page (shortcuts + optional edit tile)
                  final allItems = _pages[pageIndex];

                  final int columnCount =
                      min(allItems.length, itemsPerPage ~/ rowCount);
                  final int pageActiveRows = _rowsForPage(pageIndex);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(columnCount, (colIndex) {
                      final bottomIndex = columnCount + colIndex;

                      Widget buildItem(int itemIndex, List<dynamic> allItems) {
                        if (itemIndex >= allItems.length) {
                          return const SizedBox(
                              width: itemWidth, height: itemHeight);
                        }
                        final item = allItems[itemIndex];
                        if (item == null) {
                          return widget.editTileBuilder(
                              width: itemWidth, height: itemHeight);
                        }
                        return SizedBox(
                          height: itemHeight,
                          width: itemWidth,
                          child: Semantics(
                            label: "Shortcut to ${item.name}",
                            child: ExcludeSemantics(
                                child: widget.shortcutTileBuilder(item)),
                          ),
                        );
                      }

                      return SizedBox(
                        height: itemHeight * pageActiveRows,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildItem(colIndex, allItems),
                            if (pageActiveRows > 1 &&
                                bottomIndex < allItems.length)
                              buildItem(bottomIndex, allItems),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            if (_pages.length > 1) ...[
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final bool active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
