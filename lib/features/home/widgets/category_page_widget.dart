import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/widgets/custom_image_widget.dart';
import 'package:flutter_grocery/common/widgets/on_hover_widget.dart';
import 'package:flutter_grocery/common/widgets/text_hover_widget.dart';
import 'package:flutter_grocery/features/category/providers/category_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

/// Horizontal category pills (Zepto-style) to reduce navigation depth.
class CategoryPillsWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  const CategoryPillsWidget({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8)});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(builder: (context, categoryProvider, _) {
      final categories = categoryProvider.categoryList ?? [];
      if (categories.isEmpty) return const SizedBox();

      // Use grid on mobile for better space utilization (4 columns)
      if (!ResponsiveHelper.isDesktop(context)) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final baseUrls = Provider.of<SplashProvider>(context, listen: false).baseUrls;
            return InkWell(
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
                  Text(
                    category.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: poppinsMedium.copyWith(fontSize: 11, height: 1.2),
                  ),
                ],
              ),
            );
          },
        );
      }

      // Horizontal pills for desktop
      return SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: padding,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                selected: false,
                onSelected: (_) => RouteHelper.getCategoryProductsRoute(categoryId: '${category.id}'),
                backgroundColor: Theme.of(context).cardColor,
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                labelStyle: poppinsMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          },
        ),
      );
    });
  }
}

/// Desktop category carousel (kept for compatibility), now uses pill-like cards.
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
                child: TextHoverWidget(
                  builder: (hovered) {
                    return Column(
                      children: [
                        OnHoverWidget(
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
                            style: poppinsMedium.copyWith(
                              color: hovered ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
