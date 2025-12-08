import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/widgets/custom_button_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_pop_scope_widget.dart';
import 'package:flutter_grocery/features/menu/domain/models/custom_drawer_controller_model.dart';
import 'package:flutter_grocery/features/refer_and_earn/screens/refer_hint_widget.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/common/providers/cart_provider.dart';
import 'package:flutter_grocery/features/address/providers/location_provider.dart';
import 'package:flutter_grocery/features/profile/providers/profile_provider.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/common/providers/theme_provider.dart';
import 'package:flutter_grocery/utill/app_constants.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/images.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:flutter_grocery/common/widgets/third_party_chat_widget.dart';
import 'package:flutter_grocery/features/home/screens/home_screens.dart';
import 'package:provider/provider.dart';


class MainScreen extends StatefulWidget {
  final bool isReload;
  final bool fromIntro;
  final CustomDrawerController drawerController;
  const MainScreen({super.key, required this.drawerController, this.isReload = true, this.fromIntro = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool canExit = kIsWeb;

  @override
  void initState() {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    splashProvider.initializeScreenList();
    if (widget.isReload) {
      HomeScreen.loadData(true, context);
    }
    if(widget.fromIntro){
      WidgetsBinding.instance.addPostFrameCallback((_){
        _showBottomSheet(context);
      });
    }
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Provider.of<ThemeProvider>(context, listen: false).darkTheme;
    return Consumer<SplashProvider>(
      builder: (context, splash, child) {
        return CustomPopScopeWidget(
          child: Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                return Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) => InkWell(
                    onTap: (){
                      if(!ResponsiveHelper.isDesktop(context) && widget.drawerController.isOpen()) {
                        widget.drawerController.toggle();
                      }
                    },
                    child: Scaffold(
                      floatingActionButton: !ResponsiveHelper.isDesktop(context) ?
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50.0),
                        child: ThirdPartyChatWidget(configModel: splash.configModel),
                      ) :
                      null,
                      appBar: ResponsiveHelper.isDesktop(context) ?
                      null :
                      AppBar(
                        backgroundColor: Theme.of(context).cardColor,
                        leading: IconButton(
                          icon: Image.asset(Images.moreIcon, color: Theme.of(context).primaryColor, height: 30, width: 30),
                          onPressed: () {
                            widget.drawerController.toggle();
                          },
                        ),
                        title: splash.pageIndex == 0 ?
                        Row(children: [
                          Image.asset(Images.appLogo, width: 25),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Expanded(child: Text(
                            AppConstants.appName, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: poppinsMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                          )),
                        ]) :
                        Text(
                          getTranslated(splash.screenList[splash.pageIndex].title, context),
                          style: poppinsMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                        ),
                        elevation: 1,
                        actions: splash.screenList[splash.pageIndex].title == 'home' ? [
                          IconButton(
                            icon: Image.asset(Images.search, color: Theme.of(context).primaryColor, width: 20),
                            onPressed: () {
                              RouteHelper.getSearchProduct();
                            },
                          ),

                          IconButton(
                            icon: Stack(clipBehavior: Clip.none, children: [
                              Icon(Icons.shopping_cart, color: Theme.of(context).hintColor.withValues(alpha: isDarkTheme ? 0.9 : 0.4), size: 25),

                              Positioned(top: -7, right: -2, child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor),
                                child: Text(
                                  '${Provider.of<CartProvider>(context).getTotalCartQuantity()}',
                                  style: TextStyle(color: Theme.of(context).cardColor, fontSize: 10),
                                ),
                              )),
                            ]),
                            onPressed: () {
                              splash.setPageIndex(2);
                            },
                          ),
                        ] :
                        splash.screenList[splash.pageIndex].title == 'loyalty_point' ? [
                          IconButton(
                              onPressed: (){
                                ResponsiveHelper().showDialogOrBottomSheet(
                                  context,
                                    ReferHintWidget(hintList: profileProvider.hintList)
                                );
                              },
                              icon: Icon(Icons.info_outline)
                          )
                        ] :
                        null,
                      ),

                      body: splash.screenList[splash.pageIndex].screen,
                    ),
                  ),
                );
              }
          ),
        );
      },
    );
  }
}

void _showBottomSheet(BuildContext context){
  showModalBottomSheet(
      context: context,
      builder: (BuildContext context){
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius:  const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 25),

              Container(height: 5, width: 40, decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(25),
              )),

              InkWell(
                onTap: ()=> Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).hintColor.withValues(alpha: 0.1)
                  ),
                  padding: EdgeInsets.all(7),
                  child: Image.asset(Images.crossIcon, height: Dimensions.paddingSizeSmall, width: Dimensions.paddingSizeSmall),
                ),
              ),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Image.asset(Images.lockIcon, height: 60, width: 60),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text(getTranslated('you_are_almost_there', context), style: poppinsBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
            ), textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Text(getTranslated('log_in_or_sign_up_to_continue_and_enjoy', context), style: poppinsRegular.copyWith(
              fontSize: Dimensions.fontSizeLarge,
            ), textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 60),
              child: CustomButtonWidget(
                onPressed: ()=> RouteHelper.getLoginRoute(action: RouteAction.pushNamedAndRemoveUntil),
                buttonText: getTranslated('login_or_signup', context),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            if((Provider.of<SplashProvider>(context, listen: false).configModel?.isGuestCheckout ?? false))...[
              Center(child: TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(1, 40)),
                onPressed: () => Navigator.pop(context),
                child: RichText(text: TextSpan(children: [
                  TextSpan(
                    text: '${getTranslated('continue_as_a', context)} ',
                    style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor.withValues(alpha: 0.6)),
                  ),

                  TextSpan(text: getTranslated('guest', context), style: poppinsRegular.copyWith(color: Theme.of(context).primaryColor)),

                ])),
              )),

              const SizedBox(height: Dimensions.paddingSizeDefault),
            ]

          ]),
        );
      }
  );
}