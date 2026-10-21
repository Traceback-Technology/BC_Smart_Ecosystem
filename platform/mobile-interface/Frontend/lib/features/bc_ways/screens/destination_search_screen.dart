import '../../../shared/widgets/campus_logo.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/destination.dart';
import '../models/filter_category.dart';
import '../widgets/bc_bottom_navigation_bar.dart';

class DestinationTravelInfo {
  final double distanceMeters;
  final int minutes;

  const DestinationTravelInfo({
    required this.distanceMeters,
    required this.minutes,
  });
}

class DestinationSearchScreen
    extends StatefulWidget {
  final List<Destination> destinations;

  final List<FilterCategory> categories;

  final DestinationTravelInfo? Function(
    Destination destination,
  ) travelInfoFor;

  const DestinationSearchScreen({
    super.key,
    required this.destinations,
    required this.categories,
    required this.travelInfoFor,
  });

  @override
  State<DestinationSearchScreen>
      createState() =>
          _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends State<DestinationSearchScreen> {
  final Set<String> _expandedCategoryIds = {};
  final TextEditingController
      _searchController =
      TextEditingController();

  String _query = '';

  String? _selectedCategoryId;

  void _onBottomNavTap(int index) {
    // Home
    if (index == 0) {
      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
      return;
    }

    // Map
    if (index == 1) {
      Navigator.of(context).pop();
      return;
    }

    // Orders / Profile
    if (index == 2 || index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${index == 2 ? 'Orders' : 'Profile'} '
            'is not connected yet.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // FILTERING
  // ---------------------------------------------------------------------------

  List<Destination>
      get _filteredDestinations {
    final query =
        _query.trim().toLowerCase();

    FilterCategory?
        selectedCategory;

    if (_selectedCategoryId != null) {
      for (final category
          in widget.categories) {
        if (category.id ==
            _selectedCategoryId) {
          selectedCategory =
              category;

          break;
        }
      }
    }

    final results =
        widget.destinations.where(
      (destination) {
        final matchesSearch =
            query.isEmpty ||
            destination.name
                .toLowerCase()
                .contains(query) ||
            destination.category
                .toLowerCase()
                .contains(query);

        final matchesCategory =
            selectedCategory ==
                null ||
            selectedCategory
                .matchesDestinationCategory(
              destination.category,
            );

        return matchesSearch &&
            matchesCategory;
      },
    ).toList();

    results.sort(
      (a, b) =>
          a.name.compareTo(b.name),
    );

    return results;
  }

  // ---------------------------------------------------------------------------
  // ALL DESTINATIONS
  // ---------------------------------------------------------------------------

  Map<String, List<Destination>>
      get _destinationsByCategory {
    final grouped =
        <String, List<Destination>>{};

    for (final destination
        in _filteredDestinations) {
      grouped
          .putIfAbsent(
            destination.category,
            () => [],
          )
          .add(destination);
    }

    return grouped;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          context.cardBg,

      bottomNavigationBar: BcBottomNavigationBar(
        selectedIndex: 1,
        onTap: _onBottomNavTap,
      ),

      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildHeader(),
                _buildSearch(),
                _buildCategories(),
                _buildAllDestinations(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        18,
        10,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pop();
            },
            icon: const Icon(
              Icons.arrow_back,
              size: 28,
            ),
          ),

          const CampusLogo(width: 30, height: 30),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'BC',
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            BcColors.primary,
                      ),
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Text(
                      'WAYS',
                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            context
                                .textPrimary,
                      ),
                    ),
                  ],
                ),

                Text(
                  'Find Your Destination',
                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        context
                            .textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Stack(
            clipBehavior:
                Clip.none,
            children: [
              const Icon(
                Icons
                    .notifications_none,
                size: 29,
              ),

              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment:
                      Alignment.center,
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(
                      0xFFE31B23,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Text(
                    '3',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  Widget _buildSearch() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        4,
        18,
        10,
      ),
      child: TextField(
        controller:
            _searchController,
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        decoration:
            InputDecoration(
          hintText:
              'Search building, classroom or location',

          prefixIcon:
              const Icon(
            Icons.search,
          ),

          suffixIcon:
              _query.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _query = '';
                        });
                      },
                      icon:
                          const Icon(
                        Icons.close,
                      ),
                    )
                  : const Icon(
                      Icons.tune,
                    ),

          filled: true,

          fillColor:
              context.cardBg,

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            borderSide:
                BorderSide(
              color:
                  context
                      .subtleBorder,
            ),
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            borderSide:
                BorderSide(
              color:
                  context
                      .subtleBorder,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES
  // ---------------------------------------------------------------------------

  Widget _buildCategories() {
    return SizedBox(
      height: 32 + MediaQuery.textScalerOf(context).scale(16),
      child: ListView(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        children: [
          _categoryChip(
            id: null,
            label: 'All',
          ),

          ...widget.categories.map(
            (category) =>
                _categoryChip(
              id: category.id,
              label:
                  category.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String? id,
    required String label,
  }) {
    final selected =
        _selectedCategoryId == id;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) {
          setState(() {
            _selectedCategoryId =
                id;
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ALL DESTINATIONS
  // ---------------------------------------------------------------------------

  Widget _buildAllDestinations() {
    final grouped =
        _destinationsByCategory;

    if (grouped.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Center(
          child: Text(
            'No destinations found.',
            style:
                TextStyle(
              color:
                  context
                      .textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children:
          grouped.entries.map(
        (entry) {
          return _buildCategorySection(
            context,
            entry.key,
            entry.value,
          );
        },
      ).toList(),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String categoryName,
    List<Destination> items,
  ) {
    // Make a copy so we don't modify the original list.
    final sortedItems =
        List<Destination>.from(items);

    // Sort destinations from closest to furthest.
    sortedItems.sort((a, b) {
      final aInfo =
          widget.travelInfoFor(a);

      final bInfo =
          widget.travelInfoFor(b);

      final aDistance =
          aInfo?.distanceMeters ??
          double.infinity;

      final bDistance =
          bInfo?.distanceMeters ??
          double.infinity;

      return aDistance.compareTo(
        bDistance,
      );
    });

    final hasMoreThanFour =
        sortedItems.length > 4;

    final isExpanded =
        _expandedCategoryIds.contains(
      categoryName,
    );

    final visibleItems =
        hasMoreThanFour &&
                !isExpanded
            ? sortedItems.take(4).toList()
            : sortedItems;

    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // CATEGORY HEADER
          // -------------------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      fontSize: 16,
                      color:
                          context.textPrimary,
                    ),
                  ),
                ),

                // Only show "See all" when there are more than 4.
                if (hasMoreThanFour)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategoryIds
                              .remove(
                            categoryName,
                          );
                        } else {
                          _expandedCategoryIds
                              .add(
                            categoryName,
                          );
                        }
                      });
                    },
                    child: Text(
                      isExpanded
                          ? 'Show less'
                          : 'See all',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // -------------------------------------------------------------
          // DESTINATIONS
          // -------------------------------------------------------------

          for (final destination
              in visibleItems)
            _destinationTile(
              destination,
            ),
        ],
      ),
    );
  }

  Widget _destinationTile(
    Destination destination,
  ) {
    final info =
        widget.travelInfoFor(
      destination,
    );

    final color =
        _colorForCategory(
      destination.category,
    );

    return InkWell(
      onTap: () => Navigator.of(context).pop(destination),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconForCategory(destination.category),
              color: context.readableAccent(color), size: 29),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destination.name, style: TextStyle(
                  color: context.textPrimary, fontWeight: FontWeight.w700)),
                Text(destination.category, style: TextStyle(color: context.textSecondary)),
                if (info != null) ...[
                  const SizedBox(height: 4),
                  Text('${info.minutes} min · ${_formatDistance(info.distanceMeters)}',
                    style: TextStyle(color: context.readableAccent(color), fontSize: 13)),
                ],
              ],
            )),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _formatDistance(
    double meters,
  ) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return '${meters.round()} m';
  }

  IconData _iconForCategory(
    String category,
  ) {
    final value =
        category.toLowerCase();

    if (value.contains(
      'classroom',
    )) {
      return Icons.school_outlined;
    }

    if (value.contains(
      'residence',
    )) {
      return Icons.apartment;
    }

    if (value.contains(
      'parking',
    )) {
      return Icons.local_parking;
    }

    if (value.contains(
      'cafeteria',
    )) {
      return Icons.restaurant;
    }

    if (value.contains(
      'library',
    )) {
      return Icons.menu_book;
    }

    if (value.contains(
      'study',
    )) {
      return Icons.auto_stories;
    }

    if (value.contains(
      'office',
    )) {
      return Icons.badge_outlined;
    }

    return Icons.location_on_outlined;
  }

  Color _colorForCategory(
    String destinationCategory,
  ) {
    for (final category
        in widget.categories) {
      if (category
          .matchesDestinationCategory(
        destinationCategory,
      )) {
        return category.color;
      }
    }

    return Theme.of(context)
        .colorScheme
        .onSurface;
  }
}