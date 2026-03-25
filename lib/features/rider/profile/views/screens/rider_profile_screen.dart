import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_profile_providers.dart';

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riderProfileProvider);
    final user = state.user;
    final double width = MediaQuery.sizeOf(context).width;

    Future<void> inviteFriends() async {
      try {
        final name = user?.name ?? '';
        final text =
            '$name is inviting you to download BagyesRUSH-> Tap to download now!';
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Invite!'),
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Copy'),
              ),
            ],
          ),
        );
      } catch (_) {}
    }

    void showLogoutDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('You sure want to logout?', style: headingStyle),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: width / 3.5,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('Cancel', style: buttonBlackTextStyle),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(riderProfileProvider.notifier)
                            .logout();
                        if (!context.mounted) return;
                        context.go(AppRoutes.login);
                      },
                      child: Container(
                        width: width / 3.5,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child:
                            Text('Log out', style: wbuttonWhiteTextStyle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: whiteColor,
        elevation: 0,
        title: Text('Profile', style: bigHeadingStyle),
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.editProfile),
            child: Container(
              width: width,
              padding: EdgeInsets.all(fixPadding),
              color: whiteColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          image: user?.selfie != null && user!.selfie!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.selfie!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey[200],
                        ),
                        child: user?.selfie == null || user!.selfie!.isEmpty
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                      widthSpace,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '', style: headingStyle),
                          heightSpace,
                          Text(user?.phone ?? '', style: lightGreyStyle),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(fixPadding),
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
            child: Column(
              children: [
                InkWell(
                  onTap: inviteFriends,
                  child: _getTile(
                    Icon(Icons.group_add,
                        color: Colors.grey.withValues(alpha: 0.6)),
                    'Invite Friends',
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: _getTile(
                    Icon(Icons.headset_mic,
                        color: Colors.grey.withValues(alpha: 0.6)),
                    'Support',
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(fixPadding),
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
            child: Column(
              children: [
                InkWell(
                  onTap: showLogoutDialog,
                  child: _getTile(
                    Icon(Icons.exit_to_app,
                        color: Colors.grey.withValues(alpha: 0.6)),
                    'Logout',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTile(Icon icon, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: Center(child: icon),
            ),
            widthSpace,
            Text(title, style: listItemTitleStyle),
          ],
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}
