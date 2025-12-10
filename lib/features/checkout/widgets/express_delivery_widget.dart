import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/widgets/custom_shadow_widget.dart';
import 'package:flutter_grocery/features/order/providers/order_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

class ExpressDeliveryWidget extends StatelessWidget {
  final bool selfPickup;
  
  const ExpressDeliveryWidget({
    super.key,
    required this.selfPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SplashProvider, OrderProvider>(
      builder: (context, splashProvider, orderProvider, child) {
        final expressDelivery = splashProvider.configModel?.expressDelivery;
        
        // Hide express delivery widget if not enabled or self-pickup
        if (expressDelivery == null || !(expressDelivery.status ?? false) || selfPickup) {
          return const SizedBox.shrink();
        }

        return CustomShadowWidget(
          margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Theme.of(context).primaryColor,
                    size: Dimensions.fontSizeOverLarge,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated('express_delivery', context),
                          style: poppinsSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                        Text(
                          '${getTranslated('delivered_in', context)} ${expressDelivery.slaMinutes} ${getTranslated('minutes', context)}',
                          style: poppinsRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: orderProvider.isExpressDelivery,
                    onChanged: (value) {
                      orderProvider.toggleExpressDelivery(value);
                    },
                    activeThumbColor: Theme.of(context).primaryColor,
                    activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
              
              if (orderProvider.isExpressDelivery) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: Dimensions.fontSizeLarge,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${getTranslated('express_fee', context)}: ${PriceConverterHelper.convertPrice(context, expressDelivery.fee)}',
                              style: poppinsMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                            Text(
                              '${getTranslated('available_within', context)} ${expressDelivery.radiusKm} ${getTranslated('km', context)}',
                              style: poppinsRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
