import 'package:flutter/material.dart';
import 'package:flutter_grocery/features/home/providers/filter_analytics_provider.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

class ProductFilterBottomSheetWidget extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final Function(double, double)? onPriceRangeChanged;
  final Function(double?)? onRatingChanged;
  final double? selectedMinPrice;
  final double? selectedMaxPrice;
  final double? selectedRating;

  const ProductFilterBottomSheetWidget({
    super.key,
    this.minPrice,
    this.maxPrice,
    this.onPriceRangeChanged,
    this.onRatingChanged,
    this.selectedMinPrice,
    this.selectedMaxPrice,
    this.selectedRating,
  });

  @override
  State<ProductFilterBottomSheetWidget> createState() => _ProductFilterBottomSheetWidgetState();
}

class _ProductFilterBottomSheetWidgetState extends State<ProductFilterBottomSheetWidget> {
  late double _localMinPrice;
  late double _localMaxPrice;
  double? _selectedRating;

  @override
  void initState() {
    super.initState();
    _localMinPrice = widget.selectedMinPrice ?? (widget.minPrice ?? 0);
    _localMaxPrice = widget.selectedMaxPrice ?? (widget.maxPrice ?? 100000);
    _selectedRating = widget.selectedRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated('filters', context),
                style: poppinsBold.copyWith(fontSize: 18),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(
            getTranslated('price', context),
            style: poppinsSemiBold.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated('min', context),
                      style: poppinsRegular.copyWith(fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: _localMinPrice.toStringAsFixed(0)),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: poppinsRegular.copyWith(fontSize: 12),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _localMinPrice = double.tryParse(value) ?? _localMinPrice;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated('max', context),
                      style: poppinsRegular.copyWith(fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: _localMaxPrice.toStringAsFixed(0)),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '100000',
                          hintStyle: poppinsRegular.copyWith(fontSize: 12),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _localMaxPrice = double.tryParse(value) ?? _localMaxPrice;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          Text(
            getTranslated('rating', context),
            style: poppinsSemiBold.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...[null, 5.0, 4.0, 3.0, 2.0, 1.0].map((rating) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedRating = _selectedRating == rating ? null : rating),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedRating == rating ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                        border: Border.all(
                          color: _selectedRating == rating ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (rating != null)
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: _selectedRating == rating ? Colors.white : Theme.of(context).primaryColor,
                            )
                          else
                            Text(
                              getTranslated('all', context),
                              style: poppinsMedium.copyWith(
                                fontSize: 12,
                                color: _selectedRating == null ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          if (rating != null) const SizedBox(width: 4),
                          if (rating != null)
                            Text(
                              rating.toStringAsFixed(1),
                              style: poppinsMedium.copyWith(
                                fontSize: 12,
                                color: _selectedRating == rating ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _localMinPrice = widget.minPrice ?? 0;
                      _localMaxPrice = widget.maxPrice ?? 100000;
                      _selectedRating = null;
                    });
                  },
                  child: Text(
                    getTranslated('reset', context),
                    style: poppinsMedium.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final analyticsProvider = Provider.of<FilterAnalyticsProvider>(context, listen: false);
                    analyticsProvider.trackFilterUsage(
                      filterType: 'price_and_rating',
                      minPrice: _localMinPrice,
                      maxPrice: _localMaxPrice,
                      rating: _selectedRating,
                    );

                    if (widget.onPriceRangeChanged != null) {
                      widget.onPriceRangeChanged!(_localMinPrice, _localMaxPrice);
                    }
                    if (widget.onRatingChanged != null) {
                      widget.onRatingChanged!(_selectedRating);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    getTranslated('apply_filters', context),
                    style: poppinsMedium.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
