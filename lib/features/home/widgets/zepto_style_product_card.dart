import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/cart_model.dart';
import 'package:flutter_grocery/common/models/product_model.dart';
import 'package:flutter_grocery/common/providers/cart_provider.dart';
import 'package:flutter_grocery/common/widgets/custom_directionality_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_image_widget.dart';
import 'package:flutter_grocery/common/widgets/wish_button_widget.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/custom_snackbar_helper.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/color_resources.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

/// Zepto-inspired compact product card with CTA-first layout.
class ZeptoStyleProductCard extends StatelessWidget {
  final Product product;

  const ZeptoStyleProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final discountValue = PriceConverterHelper.convertProductDiscount(
      price: product.price,
      discount: product.discount,
      discountType: product.discountType,
      categoryDiscount: product.categoryDiscount,
    );

    final bool hasVariations = product.variations != null && (product.variations?.isNotEmpty ?? false);

    return Consumer<CartProvider>(builder: (context, cartProvider, _) {
      final baseUrls = Provider.of<SplashProvider>(context, listen: false).baseUrls;
      final imagePath = (product.image?.isNotEmpty ?? false) ? product.image![0] : '';
      final imageUrl = baseUrls?.productImageUrl != null ? '${baseUrls?.productImageUrl}/$imagePath' : imagePath;

      // Build base cart model for quick-add (no variations).
      CartModel? cartModel;
      int? cartIndex;
      bool isInCart = false;
      int? stock = product.totalStock;
      double unitPrice = product.price ?? 0;

      if (!hasVariations) {
        cartModel = CartModel(
          product.id,
          (product.image?.isNotEmpty ?? false) ? product.image![0] : '',
          product.name,
          unitPrice,
          discountValue.discount,
          1,
          null,
          (unitPrice - (discountValue.discount ?? 0)),
          ((discountValue.discount ?? 0) - PriceConverterHelper.convertWithDiscount(discountValue.discount, product.tax, product.taxType)!),
          product.capacity,
          product.unit,
          stock,
          product,
        );
        cartIndex = cartProvider.isExistInCart(cartModel);
        isInCart = cartIndex != null;
      }

      return Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => RouteHelper.getProductDetailsRoute(productId: product.id),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image + discount badge + vertical wishlist/cart icons
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AspectRatio(
                        aspectRatio: 1.05,
                        child: CustomImageWidget(
                          image: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if ((product.price ?? 0) > (discountValue.discount ?? product.price ?? 0))
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          height: 30,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Text(
                                  product.discountType == 'percent'
                                      ? '-${product.discount?.toStringAsFixed(0) ?? ''}%'
                                      : '-${PriceConverterHelper.convertPrice(context, product.discount)}',
                                  style: poppinsRegular.copyWith(fontSize: 10, color: Theme.of(context).cardColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WishButtonWidget(product: product, edgeInset: const EdgeInsets.all(5)),
                          const SizedBox(height: 4),
                          _CartQuickIcon(product: product, isInCart: isInCart, stock: stock, cartModel: cartModel, hasVariations: hasVariations),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // CTA-first: add button or stepper
                hasVariations
                    ? _AddButton(
                        label: getTranslated('add', context),
                        onTap: () => RouteHelper.getProductDetailsRoute(productId: product.id),
                      )
                    : isInCart
                        ? _QuantityStepper(cartIndex: cartIndex!, stock: stock, product: product)
                        : _AddButton(
                            label: getTranslated('add', context),
                            onTap: () {
                              if ((stock ?? 0) < 1) {
                                showCustomSnackBarHelper(getTranslated('out_of_stock', context), snackBarStatus: SnackBarStatus.info);
                                return;
                              }
                              cartProvider.addToCart(cartModel!);
                              showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);
                            },
                          ),

                const SizedBox(height: 8),

                // Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: CustomDirectionalityWidget(
                        child: Text(
                          PriceConverterHelper.convertPrice(context, discountValue.discount ?? (product.price ?? 0)),
                          style: poppinsBold.copyWith(fontSize: 15, color: Theme.of(context).primaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if ((product.price ?? 0) > (discountValue.discount ?? product.price ?? 0))
                      Flexible(
                        child: CustomDirectionalityWidget(
                          child: Text(
                            PriceConverterHelper.convertPrice(context, product.price),
                            style: poppinsRegular.copyWith(
                              fontSize: 11,
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Name
                Text(
                  product.name ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsMedium.copyWith(fontSize: 13, height: 1.3),
                ),

                const SizedBox(height: 4),

                // Meta row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${product.capacity ?? ''} ${product.unit ?? ''}'.trim(),
                        style: poppinsRegular.copyWith(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((product.rating?.isNotEmpty ?? false) && product.rating![0].average != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: ColorResources.ratingColor),
                          const SizedBox(width: 2),
                          Text(
                            product.rating![0].average!.toStringAsFixed(1),
                            style: poppinsMedium.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _AddButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isPressed
                ? [
                    const Color(0xFF00A374),
                    const Color(0xFF009366),
                  ]
                : [
                    const Color(0xFF00C897),
                    const Color(0xFF00B383),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF00B383).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.label.toUpperCase(),
            style: poppinsBold.copyWith(
              fontSize: 13,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int cartIndex;
  final int? stock;
  final Product product;

  const _QuantityStepper({required this.cartIndex, required this.stock, required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cart, _) {
      final quantity = cart.cartList[cartIndex].quantity ?? 1;
      final maxQty = cart.cartList[cartIndex].product?.maximumOrderQuantity;

      return Container(
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.12),
              Theme.of(context).primaryColor.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          children: [
            _stepButton(context, icon: Icons.remove, onTap: () {
              if (quantity > 1) {
                cart.setCartQuantity(false, cartIndex, context: context, showMessage: true);
              } else {
                cart.removeItemFromCart(cartIndex, context);
              }
            }),
            Expanded(
              child: Center(
                child: Text(
                  '$quantity',
                  style: poppinsBold.copyWith(fontSize: 14, color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            _stepButton(context, icon: Icons.add, onTap: () {
              if ((maxQty != null && quantity >= maxQty) || (stock != null && quantity >= (stock ?? 0))) {
                showCustomSnackBarHelper(getTranslated('there_is_nt_enough_quantity_on_stock', context), snackBarStatus: SnackBarStatus.info);
                return;
              }
              cart.setCartQuantity(true, cartIndex, showMessage: false, context: context);
            }),
          ],
        ),
      );
    });
  }

  Widget _stepButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
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

class _CartQuickIcon extends StatelessWidget {
  final Product product;
  final bool isInCart;
  final int? stock;
  final CartModel? cartModel;
  final bool hasVariations;

  const _CartQuickIcon({
    required this.product,
    required this.isInCart,
    required this.stock,
    required this.cartModel,
    required this.hasVariations,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: getTranslated('click_to_add_to_your_cart', context),
      child: InkWell(
        onTap: () {
          if (hasVariations) {
            RouteHelper.getProductDetailsRoute(productId: product.id);
            return;
          }
          if (isInCart) {
            showCustomSnackBarHelper(getTranslated('already_added', context));
          } else if ((stock ?? 0) < 1) {
            showCustomSnackBarHelper(
              '${getTranslated('there_is_nt_enough_quantity_on_stock', context)} ${getTranslated('only', context)} $stock ${getTranslated('is_available', context)}',
              snackBarStatus: SnackBarStatus.info,
            );
          } else {
            Provider.of<CartProvider>(context, listen: false).addToCart(cartModel!);
            showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(5),
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
