import 'package:flutter/material.dart';
import 'package:flutter_grocery/features/checkout/domain/models/saved_payment_method_model.dart';
import 'package:flutter_grocery/features/checkout/providers/payment_method_provider.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

class SavedPaymentMethodsWidget extends StatelessWidget {
  final Function(SavedPaymentMethod) onPaymentMethodSelected;

  const SavedPaymentMethodsWidget({
    super.key,
    required this.onPaymentMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentMethodProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
            ),
          );
        }

        if (provider.savedPaymentMethods.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslated('saved_payment_methods', context),
              style: poppinsBold.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.savedPaymentMethods
                    .map((method) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _SavedPaymentMethodCard(
                            method: method,
                            isSelected: provider.defaultPaymentMethod?.id == method.id,
                            onTap: () => onPaymentMethodSelected(method),
                            onDelete: () => provider.deletePaymentMethod(method.id),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _SavedPaymentMethodCard extends StatelessWidget {
  final SavedPaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedPaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    method.method,
                    style: poppinsMedium.copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (method.cardNumber != null)
              Text(
                '•••• ${method.cardNumber!.substring(method.cardNumber!.length - 4)}',
                style: poppinsRegular.copyWith(fontSize: 13),
              ),
            if (method.cardholderName != null) ...[
              const SizedBox(height: 4),
              Text(
                method.cardholderName!,
                style: poppinsRegular.copyWith(fontSize: 11, color: Theme.of(context).hintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (method.expiryDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Expires: ${method.expiryDate}',
                style: poppinsRegular.copyWith(fontSize: 10, color: Theme.of(context).hintColor),
              ),
            ],
            const SizedBox(height: 8),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  getTranslated('default', context),
                  style: poppinsRegular.copyWith(fontSize: 9, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
