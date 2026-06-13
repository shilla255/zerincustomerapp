import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/svg_image_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/config_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/body_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';

class VerificationScreen extends StatefulWidget {
  final String number;
  final bool fromOtpLogin;
  final String? session;
  const VerificationScreen({super.key,required this.number,  this.fromOtpLogin = false, this.session});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  Timer? _timer;
  int? _seconds = 0;
  String errorText = '';

  @override
  void initState() {
    super.initState();
    Get.find<AuthController>().updateVerificationCode('',isUpdate: false);
    _startTimer();
  }

  void _startTimer() {
    _seconds = Get.find<ConfigController>().config!.otpResendTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds! - 1;
      if(_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: BodyWidget(
          appBar: AppBarWidget(title: 'verification'.tr, showBackButton: true, centerTitle: true),
          body: Center(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal:Dimensions.paddingSizeLarge),
            child: GetBuilder<AuthController>(builder: (authController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                  FutureBuilder<String>(
                      future: loadSvgAndChangeColors(Images.verificationGraphics, Theme.of(context).primaryColor),
                      builder: (context, snapshot){
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          return SvgPicture.string(
                              snapshot.data!
                          );
                        }
                        return SvgPicture.asset(Images.verificationGraphics);
                      }
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Text(
                    'verification'.tr,
                    style: textBold.copyWith(fontSize: Dimensions.fontSizeTwenty),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Text(
                    '${'we_have_send_a_varification_code_to'.tr} ${widget.number.substring(0, 5)}*****${widget.number.substring(widget.number.length - 3, widget.number.length)}',
                    style: textMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),fontSize: Dimensions.fontSizeSmall),
                    maxLines: 2,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSignUp),

                  (Get.find<ConfigController>().config?.isDemo ?? true) ?
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall).copyWith(
                      bottom: Dimensions.paddingSizeOverLarge,
                    ),
                    child: Text('for_demo_purpose_use'.tr, style: textSemiBold.copyWith(
                      color: Theme.of(context).disabledColor,
                    )),
                  ) :
                  const SizedBox(height:  Dimensions.paddingSizeDefault),

                  SizedBox(
                    width: Get.width - 60,
                    child: TextField(
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: textSemiBold.copyWith(fontSize: 20, letterSpacing: 10),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '• • • • • •',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                        ),
                      ),
                      onChanged: (query) {
                        errorText = '';
                        authController.updateVerificationCode(query);
                      },
                    ),
                  ),

                  if(errorText.isNotEmpty)
                    Center(child: Text(errorText, style: textRegular.copyWith(color: Theme.of(context).colorScheme.error))),

                  !authController.otpVerifying ?
                  Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    child: ButtonWidget(
                      buttonText: 'verify'.tr,
                      radius: 50,
                      textColor: authController.verificationCode.length == 6 ? Theme.of(context).cardColor : Theme.of(context).textTheme.bodyMedium?.color,
                      onPressed: authController.verificationCode.length == 6 ? () {
                        authController.otpVerification(
                            widget.number, authController.verificationCode, accountVerification: widget.fromOtpLogin,
                            session: widget.session
                        ).then((value){
                          if(value.statusCode != 200){
                            errorText = 'incorrect_otp'.tr;
                          }
                        });
                      } : null,
                    ),
                  ) :
                  SpinKitCircle(color: Theme.of(context).primaryColor, size: 40.0),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('did_not_receive_the_code'.tr,style: textMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha:.6))),

                      _seconds! <= 0 ?
                      TextButton(
                        onPressed: () async {
                          if(Get.find<ConfigController>().config?.isFirebaseOtpVerification ?? false){

                            await authController.firebaseOtpSend(widget.number,canRoute: false);
                            showCustomSnackBar('otp_sent_successfully'.tr, isError: false);

                            _startTimer();

                          }else if(Get.find<ConfigController>().config?.isSmsGateway ?? false){
                            authController.sendOtp(widget.number).then((value){
                              if(value.statusCode == 200) {
                                _startTimer();
                              }
                            });
                          }else{
                            showCustomSnackBar('sms_gateway_not_integrate'.tr);
                          }
                        },
                        child: Text('resend_code'.tr,style: textBold.copyWith(color: Theme.of(context).primaryColorDark.withValues(alpha:.6)),
                            textAlign: TextAlign.end),
                      ) :
                      Row(children: [
                        Text(
                          '${'resend_it'.tr} ',
                        ),

                        Text('(${_seconds}s)', style: textRegular.copyWith(color: Theme.of(context).primaryColor)),
                      ])
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                ],
              );
            }),
          )),
        ),
      ),
    );
  }
}