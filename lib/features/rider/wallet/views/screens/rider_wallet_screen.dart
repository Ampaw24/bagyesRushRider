import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_wallet_providers.dart';

class RiderWalletScreen extends ConsumerStatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  ConsumerState<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends ConsumerState<RiderWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderWalletProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderWalletProvider);
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final total = state.wallet?.total ?? '0';
    final earnings = state.wallet?.earnings ?? [];

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBar(
              backgroundColor: primaryColor,
              automaticallyImplyLeading: false,
              centerTitle: true,
              elevation: 0,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Earning', style: bigWhiteHeadingStyle),
                  heightSpace,
                  Text('GHS$total', style: whiteHeadingStyle),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: width,
        height: height,
        color: primaryColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              topLeft: Radius.circular(10),
            ),
            color: scaffoldBgColor,
          ),
          child: state.status == WalletStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(riderWalletProvider.notifier).load(),
                  child: ListView.builder(
                    itemCount: earnings.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = earnings[index];
                      return Container(
                        padding: index == 0
                            ? EdgeInsets.only(
                                right: fixPadding,
                                left: fixPadding,
                                bottom: fixPadding,
                                top: fixPadding * 2,
                              )
                            : EdgeInsets.only(
                                right: fixPadding,
                                left: fixPadding,
                                bottom: fixPadding,
                              ),
                        child: Container(
                          padding: EdgeInsets.all(fixPadding),
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 1.5,
                                spreadRadius: 1.5,
                                color: Colors.grey.shade200,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fastfood,
                                      size: 25, color: primaryColor),
                                  widthSpace,
                                  Text(item.description ?? '',
                                      style: headingStyle),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(total, style: greyHeadingStyle),
                                  const SizedBox(height: 5),
                                  Text('Earning', style: appbarHeadingStyle),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
