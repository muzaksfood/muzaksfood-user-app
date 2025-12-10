import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/cart_model.dart';
import 'package:flutter_grocery/common/models/product_model.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/utill/product_type.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/app_localization.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/common/providers/cart_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/utill/color_resources.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:flutter_grocery/common/widgets/custom_directionality_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_image_widget.dart';
import 'package:flutter_grocery/helper/custom_snackbar_helper.dart';
import 'package:flutter_grocery/common/widgets/on_hover_widget.dart';
import 'package:provider/provider.dart';

import 'wish_button_widget.dart';

class ProductWidget extends StatelessWidget {
  final Product product;
  final String productType;
  final bool isGrid;
  final bool isCenter;
  const ProductWidget({super.key, required this.product, this.productType = ProductType.dailyItem, this.isGrid = false, this.isCenter = false});


  @override
  Widget build(BuildContext context) {


    final discountValue = PriceConverterHelper.convertProductDiscount(
      price: product.price,
      discount: product.discount,
      discountType: product.discountType,
      categoryDiscount: product.categoryDiscount,
    );
    final double? priceWithDiscount = discountValue.discount;

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        double price = 0;
        int? stock = 0;
        bool isExistInCart = false;
        int? cardIndex;
        CartModel? cartModel;
        if(product.variations!.isNotEmpty) {

          for(int index=0; index<product.variations!.length; index++) {
            price = product.variations!.isNotEmpty ? (product.variations![index].price ?? 0) : (product.price ?? 0);
            stock = product.variations!.isNotEmpty ? product.variations![index].stock : product.totalStock;
            cartModel = CartModel(product.id, product.image!.isNotEmpty ? product.image![0] : '', product.name, price,
                discountValue.discount,
                1,
                product.variations!.isNotEmpty ? product.variations![index] : null,
                (price - (discountValue.discount ?? 0)),
                ((discountValue.discount ?? 0) - PriceConverterHelper.convertWithDiscount(discountValue.discount, product.tax, product.taxType)!),
                product.capacity,
                product.unit,
                stock,product
            );
            isExistInCart = cartProvider.isExistInCart(cartModel) != null;
            cardIndex = cartProvider.isExistInCart(cartModel);

            if(isExistInCart) {
              break;
            }
          }
        }else {
          price =  product.price ?? 0;
          stock = product.totalStock;
          cartModel = CartModel(
            product.id, (product.image?.isNotEmpty ?? false) ?  product.image![0] : '',
            product.name, price,
            discountValue.discount,
            1, null,
            (price - (discountValue.discount ?? 0)),
            ((discountValue.discount ?? 0) - PriceConverterHelper.convertWithDiscount(discountValue.discount, product.tax, product.taxType)!),
            product.capacity,
            product.unit,
            stock,product,
          );

          isExistInCart = cartProvider.isExistInCart(cartModel) != null;
          cardIndex = cartProvider.isExistInCart(cartModel);
        }

        final bool hasNotVariations = product.variations == null || (product.variations?.isEmpty ?? false);


        final bool hasVariations = product.variations != null && (product.variations?.isNotEmpty ?? false);

        return isGrid ? OnHoverWidget(isItem: true, child: _ProductGridWidget(
          cardIndex: cardIndex,
          isCenter: isCenter,
          isExistInCart: isExistInCart,
          priceWithDiscount: priceWithDiscount ?? 0,
          discountType: discountValue.type,
          product: product,
          productType: productType,
          cartModel: cartModel,
          stock: stock,
          cartProvider: cartProvider,
          hasVariations: hasVariations,
        )) : Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: InkWell(
            hoverColor: Colors.transparent,
            onTap: () => RouteHelper.getProductDetailsRoute(
              productId: product.id, formSearch: productType == ProductType.searchItem,
            ),

            child: OnHoverWidget(
              isItem: true,
              child: Container(
                height: 110,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 4), blurRadius: 7, spreadRadius: 0.1)],
                ),
                child: Row(children: [

                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CustomImageWidget(
                            image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls!.productImageUrl}/${
                                product.image!.isNotEmpty ? product.image![0] : ''}',
                            height: 110, width: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      product.price != discountValue.discount ? Positioned(
                        top: 5, left: 5,
                        child: _DiscountTag(product: product, discountType: discountValue.type),
                      ) : const SizedBox(),

                      Positioned(
                          top:  5,
                          right: 5,
                          bottom: null,
                        child: !isExistInCart || !hasNotVariations? Tooltip(
                          message: getTranslated('click_to_add_to_your_cart', context),
                          child: Stack(
                            children: [
                              InkWell(
                                onTap: () {
                                  if(product.variations == null || product.variations!.isEmpty) {
                                    if (isExistInCart) {
                                      showCustomSnackBarHelper('already_added'.tr);
                                    } else if (stock! < 1) {
                                      showCustomSnackBarHelper('${getTranslated('there_is_nt_enough_quantity_on_stock', context)} ${getTranslated('only', context)} $stock ${getTranslated('is_available', context)}', snackBarStatus: SnackBarStatus.info);
                                    } else {
                                      Provider.of<CartProvider>(context, listen: false).addToCart(cartModel!);
                                      showCustomSnackBarHelper('added_to_cart'.tr, isError: false);
                                    }
                                  }else {
                                    RouteHelper.getProductDetailsRoute(
                                      productId: product.id, formSearch:productType == ProductType.searchItem,
                                    );
                                  }
                                },
                                child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.05)),
                                    ),
                                    child: Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Theme.of(context).primaryColor,
                                      size: Dimensions.paddingSizeLarge,
                                    )
                                ),
                              ),

                              if(isExistInCart && !hasNotVariations) Positioned.fill(
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    transform: Matrix4.translationValues(5, -10, 0),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor),
                                    child: Text('${Provider.of<CartProvider>(context).getCartQuantityByProductId(product.id!)}',
                                        style: TextStyle(color: Theme.of(context).cardColor, fontSize: 10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ) : Consumer<CartProvider>(builder: (context, cart, child) => RotatedBox(
                          quarterTurns: 3,
                          child: Container(
                            padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            decoration: BoxDecoration(
                              border: Border.all(width: 1, color: Theme.of(context).primaryColor.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.80),
                            ),

                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              InkWell(
                                onTap: () {
                                  if (cart.cartList[cardIndex!].quantity! > 1) {
                                    Provider.of<CartProvider>(context, listen: false).setCartQuantity(false, cardIndex, context: context, showMessage: true);
                                  } else {
                                    Provider.of<CartProvider>(context, listen: false).removeItemFromCart(cardIndex, context);
                                  }
                                },
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        shape: BoxShape.circle
                                    ),
                                    child: Icon(
                                      Icons.remove, size: Dimensions.paddingSizeLarge,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ),

                              RotatedBox(
                                quarterTurns: 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                                  child: Text(
                                    cart.cartList[cardIndex!].quantity.toString(),
                                    style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                                  ),
                                ),
                              ),


                              InkWell(
                                onTap: () {
                                  if(cart.cartList[cardIndex!].product!.maximumOrderQuantity == null || cart.cartList[cardIndex].quantity! < cart.cartList[cardIndex].product!.maximumOrderQuantity!) {
                                    if(cart.cartList[cardIndex].quantity! < cart.cartList[cardIndex].stock!) {
                                      cart.setCartQuantity(true, cardIndex, showMessage: false, context: context);
                                    }else {
                                      showCustomSnackBarHelper('${getTranslated('there_is_nt_enough_quantity_on_stock', context)} ${getTranslated('only', context)} ${cart.cartList[cardIndex].stock} ${getTranslated('is_available', context)}', snackBarStatus: SnackBarStatus.info);
                                    }
                                  }else{
                                    showCustomSnackBarHelper('${getTranslated('you_cant_add_more_than', context)} ${(cart.cartList[cardIndex].product!.maximumOrderQuantity ?? 0)} '
                                        '${getTranslated((cart.cartList[cardIndex].product!.maximumOrderQuantity ?? 0) > 1 ? 'items' : 'item', context)}', snackBarStatus: SnackBarStatus.info);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      shape: BoxShape.circle
                                  ),
                                  child: Icon(Icons.add, size: Dimensions.paddingSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
                                ),
                              ),
                            ]),
                          ),
                        ),
                        ),
                      ),

                    ],
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            product.rating != null ? Row(mainAxisAlignment: isCenter ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
                              const Icon(Icons.star_rounded, color: ColorResources.ratingColor, size: 20),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                              Text(product.rating!.isNotEmpty ? product.rating![0].average!.toStringAsFixed(1) : '0.0', style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),

                            ]) : const SizedBox(),

                            Tooltip(message: product.name, child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Text(product.name ?? '',
                                style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),

                            Text('${product.capacity} ${product.unit}', style: poppinsMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),

                            Flexible(
                              child: Row(children: [
                                product.price! > priceWithDiscount! ? CustomDirectionalityWidget(child: Text(
                                  PriceConverterHelper.convertPrice(context, product.price),
                                  style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall, decoration: TextDecoration.lineThrough, color: Theme.of(context).disabledColor),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )) : const SizedBox(),

                                product.price! > priceWithDiscount ? const SizedBox(width: Dimensions.paddingSizeExtraSmall) : const SizedBox(),

                                CustomDirectionalityWidget(child: Text(
                                  PriceConverterHelper.convertPrice(context, priceWithDiscount),
                                  style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )),

                              ],),
                            ),
                          ]),
                    ),
                  ),

                  Align(
                    alignment: Alignment.topRight,
                    child: WishButtonWidget(product: product, edgeInset: const EdgeInsets.all(5)),
                  ),

                ]),
              ),
            ),
          ),
        );
      },
    );
  }


}


class _ProductGridWidget extends StatelessWidget {
  final bool isExistInCart;
  final int? stock;
  final CartModel? cartModel;
  final int? cardIndex;
  final double priceWithDiscount;
  final DiscountType? discountType;
  final Product product;
  final String productType;
  final bool isCenter;
  final CartProvider cartProvider;
  final bool hasVariations;

  const _ProductGridWidget({
    required this.isExistInCart,
    this.stock,
    this.cartModel,
    required this.cardIndex,
    required this.priceWithDiscount,
    required this.product,
    required this.productType,
    required this.isCenter,
    required this.discountType,
    required this.cartProvider,
    required this.hasVariations,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      borderRadius: BorderRadius.circular(Dimensions.radiusSizeTen),
      onTap: () => RouteHelper.getProductDetailsRoute(
        productId: product.id,
        formSearch: productType == ProductType.searchItem,
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 200, minHeight: 250),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSizeTen),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 3),
              blurRadius: 8,
              spreadRadius: 0.1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSizeTen),
                    child: CustomImageWidget(
                      fit: BoxFit.cover,
                      image:
                          '${Provider.of<SplashProvider>(context, listen: false).baseUrls!.productImageUrl}/${(product.image?.isNotEmpty ?? false) ? product.image![0] : ''}',
                    ),
                  ),
                ),

                if (product.price != priceWithDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _DiscountTag(product: product, discountType: discountType!),
                  ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: WishButtonWidget(product: product, edgeInset: const EdgeInsets.all(5.0)),
                ),

                Positioned(
                  top: 10,
                  right: 46,
                  child: _FloatingCartIcon(
                    product: product,
                    productType: productType,
                    isExistInCart: isExistInCart,
                    stock: stock,
                    cartModel: cartModel,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (product.rating != null)
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: ColorResources.ratingColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.rating!.isNotEmpty ? product.rating![0].average!.toStringAsFixed(1) : '0.0',
                    style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                  ),
                ],
              ),

            const SizedBox(height: 4),

            Tooltip(
              message: product.name ?? '',
              child: Text(
                product.name ?? '',
                style: poppinsMedium.copyWith(fontSize: Dimensions.fontSizeDefault, height: 1.25),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '${product.capacity ?? ''} ${product.unit ?? ''}'.trim(),
                    style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomDirectionalityWidget(
                  child: Text(
                    PriceConverterHelper.convertPrice(context, priceWithDiscount),
                    style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  ),
                ),
                const SizedBox(width: 6),
                if ((product.price ?? 0) > priceWithDiscount)
                  CustomDirectionalityWidget(
                    child: Text(
                      PriceConverterHelper.convertPrice(context, product.price),
                      style: poppinsRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            _GridCta(
              hasVariations: hasVariations,
              isExistInCart: isExistInCart,
              cartProvider: cartProvider,
              cartModel: cartModel,
              cardIndex: cardIndex,
              stock: stock,
              product: product,
              productType: productType,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCartIcon extends StatelessWidget {
  final Product product;
  final String productType;
  final bool isExistInCart;
  final int? stock;
  final CartModel? cartModel;

  const _FloatingCartIcon({
    required this.product,
    required this.productType,
    required this.isExistInCart,
    required this.stock,
    required this.cartModel,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: getTranslated('click_to_add_to_your_cart', context),
      child: InkWell(
        onTap: () {
          if (product.variations == null || product.variations!.isEmpty) {
            if (isExistInCart) {
              showCustomSnackBarHelper('already_added'.tr);
            } else if ((stock ?? 0) < 1) {
              showCustomSnackBarHelper(
                '${getTranslated('there_is_nt_enough_quantity_on_stock', context)} ${getTranslated('only', context)} $stock ${getTranslated('is_available', context)}',
                snackBarStatus: SnackBarStatus.info,
              );
            } else {
              Provider.of<CartProvider>(context, listen: false).addToCart(cartModel!);
              showCustomSnackBarHelper('added_to_cart'.tr, isError: false);
            }
          } else {
            RouteHelper.getProductDetailsRoute(
              productId: product.id,
              formSearch: productType == ProductType.searchItem,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.08)),
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            color: Theme.of(context).primaryColor,
            size: Dimensions.paddingSizeLarge,
          ),
        ),
      ),
    );
  }
}

class _GridCta extends StatelessWidget {
  final bool hasVariations;
  final bool isExistInCart;
  final CartProvider cartProvider;
  final CartModel? cartModel;
  final int? cardIndex;
  final int? stock;
  final Product product;
  final String productType;

  const _GridCta({
    required this.hasVariations,
    required this.isExistInCart,
    required this.cartProvider,
    required this.cartModel,
    required this.cardIndex,
    required this.stock,
    required this.product,
    required this.productType,
  });

  @override
  Widget build(BuildContext context) {
    if (hasVariations) {
      return _TinyAddButton(
        label: getTranslated('add', context),
        onTap: () => RouteHelper.getProductDetailsRoute(
          productId: product.id,
          formSearch: productType == ProductType.searchItem,
        ),
      );
    }

    if (isExistInCart && cardIndex != null) {
      return _TinyStepper(
        cartIndex: cardIndex!,
        cartProvider: cartProvider,
        stock: stock,
      );
    }

    return _TinyAddButton(
      label: getTranslated('add', context),
      onTap: () {
        if ((stock ?? 0) < 1) {
          showCustomSnackBarHelper(getTranslated('out_of_stock', context), snackBarStatus: SnackBarStatus.info);
          return;
        }
        cartProvider.addToCart(cartModel!);
        showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);
      },
    );
  }
}

class _TinyAddButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _TinyAddButton({required this.label, required this.onTap});

  @override
  State<_TinyAddButton> createState() => _TinyAddButtonState();
}

class _TinyAddButtonState extends State<_TinyAddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 34,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: _pressed
                ? [const Color(0xFF00A374), const Color(0xFF009366)]
                : [const Color(0xFF00C897), const Color(0xFF00B383)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF00B383).withValues(alpha: 0.25),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.label.toUpperCase(),
            style: poppinsBold.copyWith(fontSize: 12, color: Colors.white, letterSpacing: 0.4),
          ),
        ),
      ),
    );
  }
}

class _TinyStepper extends StatelessWidget {
  final int cartIndex;
  final CartProvider cartProvider;
  final int? stock;

  const _TinyStepper({required this.cartIndex, required this.cartProvider, required this.stock});

  @override
  Widget build(BuildContext context) {
    final quantity = cartProvider.cartList[cartIndex].quantity ?? 1;
    final maxQty = cartProvider.cartList[cartIndex].product?.maximumOrderQuantity;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          _stepBtn(context, icon: Icons.remove, onTap: () {
            if (quantity > 1) {
              cartProvider.setCartQuantity(false, cartIndex, context: context, showMessage: true);
            } else {
              cartProvider.removeItemFromCart(cartIndex, context);
            }
          }),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: poppinsBold.copyWith(fontSize: 13, color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          _stepBtn(context, icon: Icons.add, onTap: () {
            if ((maxQty != null && quantity >= maxQty) || (stock != null && quantity >= (stock ?? 0))) {
              showCustomSnackBarHelper(getTranslated('there_is_nt_enough_quantity_on_stock', context), snackBarStatus: SnackBarStatus.info);
              return;
            }
            cartProvider.setCartQuantity(true, cartIndex, showMessage: false, context: context);
          }),
        ],
      ),
    );
  }

  Widget _stepBtn(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}


class _DiscountTag extends StatelessWidget {
  const _DiscountTag({required this.product, required this.discountType,});

  final Product product;
  final DiscountType discountType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(Dimensions.radiusSizeTen),
          bottomLeft: Radius.circular(Dimensions.radiusSizeTen),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              discountType == DiscountType.productDiscount
                  ? product.discountType == 'percent'
                  ? '-${product.discount} %'
                  : '-${PriceConverterHelper.convertPrice(context, product.discount)}'
                  : product.categoryDiscount?.discountType == 'percent'
                  ? '-${product.categoryDiscount?.discountAmount} %'
                  : '-${PriceConverterHelper.convertPrice(context, product.categoryDiscount?.discountAmount)}',
              style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).cardColor),
            ),
          ),
        ],
      ),
    );
  }
}


