import 'package:flutter/material.dart';

import '../entities/category.dart';
import '../entities/setting_route.dart';
import '../entities/setting_route_info.dart';

import '../resources/localizations.dart';

extension SettingRouteMapper on SettingRoute {
  SettingRouteInfo toInfo(BuildContext context) {
    switch (this) {
      case SettingRoute.main:
        throw UnsupportedError(
          'Vialer error: SettingPage.main has no SettingPageInfo',
        );
      case SettingRoute.troubleshooting:
        return SettingRouteInfo(
          item: this,
          order: 0,
          category: Category.advancedSettings,
          title: context
              .msg.main.settings.list.advancedSettings.troubleshooting.title,
          description: context.msg.main.settings.list.advancedSettings
              .troubleshooting.description,
        );
      case SettingRoute.webViewDialplan:
        return SettingRouteInfo(
          item: this,
          order: 0,
          category: Category.portalLinks,
          title: context.msg.main.settings.list.portalLinks.dialplan.title,
        );
      case SettingRoute.webViewStats:
        return SettingRouteInfo(
          item: this,
          order: 1,
          category: Category.portalLinks,
          title: context.msg.main.settings.list.portalLinks.stats.title,
        );
    }

    throw UnsupportedError('Vialer error: Unknown SettingPage: $this');
  }
}
