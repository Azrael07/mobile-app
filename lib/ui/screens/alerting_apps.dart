import 'dart:math';

import 'package:cobble/domain/package_details.dart';
import 'package:cobble/infrastructure/datasources/preferences.dart';
import 'package:cobble/ui/common/components/cobble_sheet.dart';
import 'package:cobble/ui/common/components/cobble_tile.dart';
import 'package:cobble/ui/common/icons/fonts/rebble_icons.dart';
import 'package:cobble/ui/router/cobble_scaffold.dart';
import 'package:cobble/ui/router/cobble_screen.dart';
import 'package:cobble/ui/screens/alerting_app_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:hooks_riverpod/all.dart';
import 'package:cobble/infrastructure/pigeons/pigeons.g.dart';

import './alerting_apps/sheet.dart';

class AlertingApp {
  final String name;
  final bool enabled;
  final String packageId;

  AlertingApp(this.name, this.enabled, this.packageId);
}

class AlertingApps extends HookWidget implements CobbleScreen {
  final packageDetails = useProvider(packageDetailsProvider).getPackageList();

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final filter = useState(SheetOnChanged.initial);

    final sheet = CobbleSheet.useInline();
    final mutedPackages = useProvider(notificationsMutedPackagesProvider);
    final preferences = useProvider(preferencesProvider);

    return CobbleScaffold.tab(
        title: 'Choose which apps can alert',
        subtitle: '8 alerted, 5 muted today',
        actions: [
          Builder(
            builder: (context) => IconButton(
              padding: EdgeInsets.all(16),
              icon: Icon(RebbleIcons.search),
              onPressed: () {
                if (sheet.shown) {
                  sheet.close();
                } else {
                  sheet.show(
                    context: context,
                    builder: (context) {
                      return Sheet(
                        onClose: () {
                          filter.value = SheetOnChanged.initial;
                          sheet.close();
                        },
                        initialFilter: filter.value,
                        onChanged: (value) {
                          filter.value = value;
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
        child: FutureBuilder(
            future: packageDetails,
            builder: (BuildContext context,
                AsyncSnapshot<AppEntriesPigeon> snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                List<AlertingApp> apps = [];
                for (int i = 0; i < snapshot.data!.packageId.length; i++) {
                  final enabled = (mutedPackages.data?.value ?? []).firstWhere(
                          (element) => element == snapshot.data!.packageId[i],
                          orElse: () => null) ==
                      null;
                  apps.add(AlertingApp(snapshot.data!.appName[i] as String, enabled,
                      snapshot.data!.packageId[i] as String));
                }

                return ListView(
                  children: apps
                      .where(
                        (app) => app.name.toLowerCase().contains(
                              filter.value.query?.toLowerCase() ?? '',
                            ),
                      )
                      .map(
                        (app) => CobbleTile.appNavigation(
                          leading: Svg('images/temp_alerting_app.svg'),
                          title: app.name,
                          subtitle:
                              '${random.nextInt(8)} ${app.enabled ? 'alerted' : 'muted'} today',
                          navigateTo: AlertingAppDetails(app),
                        ),
                      )
                      .toList(),
                );
              } else {
                return CircularProgressIndicator();
              }
            }));
  }
}
