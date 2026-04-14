import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_strings.dart';
import '../../models/scan_history_model.dart';
import '../../providers/history_provider.dart';
import '../../providers/scan_provider.dart';
import '../../services/local_cache_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/scan_history_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _searchMode = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Tap a history item → look up full medicine → open results screen.
  Future<void> _openItem(BuildContext ctx, ScanHistoryModel item) async {
    final scanProvider = ctx.read<ScanProvider>();

    // Try local SQLite first (fast, offline)
    var medicine = await LocalCacheService.instance.searchLocal(item.brandName);
    medicine ??= await LocalCacheService.instance.searchLocal(item.genericName);

    if (!ctx.mounted) return;

    if (medicine != null) {
      scanProvider.setManualMedicine(medicine);
    } else {
      // Fall back to a stub built from history metadata
      scanProvider.setManualMedicineFromHistory(item);
    }

    if (!ctx.mounted) return;
    Navigator.pushNamed(ctx, '/results', arguments: {'isInfoMode': true});
  }

  void _showFilterSheet(BuildContext ctx) {
    final tr = TranslationService.instance.tr;
    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        final provider = ctx.read<HistoryProvider>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: HistoryFilter.values.map((f) {
              final label = switch (f) {
                HistoryFilter.all => tr(AppStrings.filterAll),
                HistoryFilter.favourites => tr(AppStrings.filterFavourites),
                HistoryFilter.today => tr(AppStrings.filterToday),
                HistoryFilter.last7days => tr(AppStrings.filterLast7),
                HistoryFilter.last30days => tr(AppStrings.filterLast30),
              };
              return ListTile(
                title: Text(label),
                selected: provider.filter == f,
                selectedColor: AppColors.primaryBlue,
                onTap: () {
                  provider.setFilter(f);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _confirmDeleteAll(BuildContext ctx) {
    final tr = TranslationService.instance.tr;
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(tr(AppStrings.deleteAll)),
        content: Text(tr(AppStrings.deleteAllConfirm)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(AppStrings.cancel))),
          TextButton(
              onPressed: () {
                ctx.read<HistoryProvider>().deleteAll();
                Navigator.pop(ctx);
              },
              child: Text(tr(AppStrings.delete),
                  style: const TextStyle(color: AppColors.statusRed))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = TranslationService.instance.tr;
    final provider = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: _searchMode
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: tr(AppStrings.searchHint),
                    border: InputBorder.none),
                onChanged: provider.setSearch,
              )
            : Text(tr(AppStrings.historyTitle)),
        actions: [
          IconButton(
            icon: Icon(_searchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _searchMode = !_searchMode);
              if (!_searchMode) {
                _searchCtrl.clear();
                provider.setSearch('');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
          if (provider.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteAll(context),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history,
                          size: AppDimensions.iconXXL,
                          color: AppColors.textHintLight),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(tr(AppStrings.noHistory),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppDimensions.spaceSM),
                      Text(tr(AppStrings.noHistoryDesc),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.pagePadding),
                  itemCount: provider.items.length,
                  itemBuilder: (ctx, i) {
                    final item = provider.items[i];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.statusRed,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(
                            right: AppDimensions.pagePadding),
                        child: const Icon(Icons.delete,
                            color: AppColors.white),
                      ),
                      onDismissed: (_) => provider.deleteItem(item.id),
                      child: ScanHistoryCard(
                        item: item,
                        onTap: () => _openItem(ctx, item),
                        onFavourite: () => provider.toggleFavourite(item),
                      ),
                    );
                  },
                ),
    );
  }
}
