import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/product_model.dart';
import 'package:flutter_grocery/common/widgets/custom_image_widget.dart';
import 'package:flutter_grocery/features/search/providers/search_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

class InstantSearchDropdownWidget extends StatelessWidget {
  final List<Product> results;
  final bool isSearching;
  final String query;
  final VoidCallback onViewAll;

  const InstantSearchDropdownWidget({
    super.key,
    required this.results,
    required this.isSearching,
    required this.query,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty || (results.isEmpty && !isSearching)) {
      return const SizedBox();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 400),
      child: isSearching
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            )
          : results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      getTranslated('no_product_found', context),
                      style: poppinsMedium.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length + 1,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    if (index == results.length) {
                      return InkWell(
                        onTap: onViewAll,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            getTranslated('view_all_results', context),
                            style: poppinsSemiBold.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final product = results[index];
                    final baseUrls = Provider.of<SplashProvider>(context, listen: false).baseUrls;
                    final imagePath = (product.image?.isNotEmpty ?? false) ? product.image![0] : '';
                    final imageUrl = baseUrls?.productImageUrl != null
                        ? '${baseUrls?.productImageUrl}/$imagePath'
                        : imagePath;

                    return InkWell(
                      onTap: () => RouteHelper.getProductDetailsRoute(productId: product.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 50,
                                width: 50,
                                child: CustomImageWidget(
                                  image: imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: poppinsMedium.copyWith(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    PriceConverterHelper.convertPrice(
                                      context,
                                      product.price ?? 0,
                                    ),
                                    style: poppinsRegular.copyWith(
                                      fontSize: 11,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
