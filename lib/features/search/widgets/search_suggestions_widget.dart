import 'package:flutter/material.dart';
import 'package:flutter_grocery/features/search/providers/search_history_provider.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  final Function(String) onSuggestionTapped;
  final bool showTrending;

  const SearchSuggestionsWidget({
    super.key,
    required this.onSuggestionTapped,
    this.showTrending = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchHistoryProvider>(
      builder: (context, historyProvider, _) {
        final hasHistory = historyProvider.searchHistory.isNotEmpty;
        final hasTrending = historyProvider.trendingSearches.isNotEmpty;

        if (!hasHistory && !hasTrending) {
          return const SizedBox();
        }

        return Container(
          color: Theme.of(context).cardColor,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasHistory) ...[
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          getTranslated('recent_searches', context),
                          style: poppinsSemiBold.copyWith(fontSize: 14),
                        ),
                        InkWell(
                          onTap: () => historyProvider.clearHistory(),
                          child: Text(
                            getTranslated('clear_all', context),
                            style: poppinsRegular.copyWith(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...historyProvider.searchHistory.take(5).map((query) => InkWell(
                    onTap: () => onSuggestionTapped(query),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeMedium,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: poppinsRegular.copyWith(fontSize: 13),
                            ),
                          ),
                          InkWell(
                            onTap: () => historyProvider.removeFromHistory(query),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: Dimensions.paddingSizeMedium),
                ],
                if (showTrending && hasTrending) ...[
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
                    child: Text(
                      getTranslated('trending', context),
                      style: poppinsSemiBold.copyWith(fontSize: 14),
                    ),
                  ),
                  ...historyProvider.trendingSearches.take(5).map((query) => InkWell(
                    onTap: () => onSuggestionTapped(query),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeMedium,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: poppinsRegular.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: Dimensions.paddingSizeMedium),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
