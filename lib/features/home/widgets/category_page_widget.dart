import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/widgets/custom_image_widget.dart';
import 'package:flutter_grocery/features/category/providers/category_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

/// Horizontal category carousel (Zepto-style) - responsive design.
/// Mobile: 4 items visible, Desktop: 10+ items visible
class CategoryPillsWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const CategoryPillsWidget({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8)});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(builder: (context, categoryProvider, _) {
      final categories = categoryProvider.categoryList ?? [];
      if (categories.isEmpty) return const SizedBox();

      final screenWidth = MediaQuery.of(context).size.width;
      final isDesktop = ResponsiveHelper.isDesktop(context);
      final itemsPerView = isDesktop ? 10 : 4;
      final itemWidth = (screenWidth / itemsPerView) - 12;

      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final baseUrls = Provider.of<SplashProvider>(context, listen: false).baseUrls;
            return Container(
              width: itemWidth,
              margin: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => RouteHelper.getCategoryProductsRoute(categoryId: '${category.id}'),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomImageWidget(
                            image: baseUrls?.categoryImageUrl != null ? '${baseUrls?.categoryImageUrl}/${category.image}' : (category.image ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        category.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: poppinsMedium.copyWith(fontSize: 11, height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

/// Desktop category carousel (kept for compatibility).
class CategoryWebWidget extends StatelessWidget {
  final ScrollController scrollController;
  const CategoryWebWidget({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(builder: (context, categoryProvider, _) {
      final baseUrls = Provider.of<SplashProvider>(context, listen: false).baseUrls;
      final categories = categoryProvider.categoryList ?? [];
      if (categories.isEmpty) return const SizedBox();

      return SizedBox(
        height: 160,
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              margin: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
              child: InkWell(
                hoverColor: Colors.transparent,
                onTap: () => RouteHelper.getCategoryProductsRoute(categoryId: '${category.id}'),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: CustomImageWidget(
                          image: baseUrls?.categoryImageUrl != null ? '${baseUrls?.categoryImageUrl}/${category.image}' : (category.image ?? ''),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    SizedBox(
                      width: 100,
                      child: Text(
                        category.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: poppinsMedium.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
