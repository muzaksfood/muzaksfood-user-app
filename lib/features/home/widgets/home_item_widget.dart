import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/product_model.dart';
import 'package:flutter_grocery/common/widgets/custom_slider_list_widget.dart';
import 'package:flutter_grocery/utill/product_type.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/features/home/providers/flash_deal_provider.dart';
import 'package:flutter_grocery/common/providers/product_provider.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/common/widgets/product_widget.dart';
import 'package:flutter_grocery/features/home/widgets/zepto_style_product_card.dart';
import 'package:flutter_grocery/common/widgets/web_product_shimmer_widget.dart';
import 'package:provider/provider.dart';

class HomeItemWidget extends StatefulWidget {
  final List<Product>? productList;
  final bool isFlashDeal;
  final bool isFeaturedItem;
  final bool useZeptoStyle;

  const HomeItemWidget({super.key, this.productList, this.isFlashDeal = false, this.isFeaturedItem = false, this.useZeptoStyle = false});

  @override
  State<HomeItemWidget> createState() => _HomeItemWidgetState();
}

class _HomeItemWidgetState extends State<HomeItemWidget> {
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetCount = ResponsiveHelper.isDesktop(context) ? 8 : 3.5;
    final double computedWidth = (screenWidth / targetCount) - 12;
    final double cardWidth = computedWidth.clamp(150, 200);
    final double cardHeight = widget.isFeaturedItem ? 340 : 360;

    return Consumer<FlashDealProvider>(builder: (context, flashDealProvider, child) {
        return Consumer<ProductProvider>(builder: (context, productProvider, child) {


          return widget.productList != null ? Column(children: [
              widget.isFlashDeal ? SizedBox(
              height: cardHeight + 30,
              child: CarouselSlider.builder(
                itemCount: widget.productList!.length,
                options: CarouselOptions(
                  height: cardHeight + 30,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  viewportFraction: 0.6,
                  enlargeFactor: 0.2,
                  onPageChanged: (index, reason) {
                    flashDealProvider.setCurrentIndex(index);
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                    return widget.useZeptoStyle
                        ? ZeptoStyleProductCard(product: widget.productList![index])
                        : ProductWidget(
                          isGrid: true,
                          product: widget.productList![index],
                          productType: ProductType.flashSale,
                        );
                },
              )) : SizedBox(
                height: cardHeight + 30,
                child: CustomSliderListWidget(
                  controller: scrollController,
                  verticalPosition: widget.isFeaturedItem ? 60 :  120,
                  isShowForwardButton: (widget.productList?.length ?? 0) > 3,
                  child: ListView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeSmall),
                    itemCount: widget.productList?.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Container(
                        width: cardWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: widget.useZeptoStyle
                            ? ZeptoStyleProductCard(product: widget.productList![index])
                            : ProductWidget(
                              isGrid: widget.isFeaturedItem ? false : true,
                              product: widget.productList![index],
                              productType: ProductType.dailyItem,
                            ),
                      );
                      },
                  ),
                ),
              ),
          ]) : SizedBox(
            height: 250,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              itemCount: 10,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  width: 195,
                  padding: const EdgeInsets.all(5),
                  child: const WebProductShimmerWidget(isEnabled: true),
                );
              },
            ),
          );
        });
      }
    );
  }
}



