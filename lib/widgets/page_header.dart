import 'package:favorite_places/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Big page title with a quiet subtitle and an optional round action on the
/// right: "My places / 3 favorite places".
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.page,
        AppSpace.sm,
        AppSpace.page,
        AppSpace.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading()),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppText.meta().copyWith(height: 1.4),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// Bottom padding that clears the floating glass tab bar.
double bottomBarClearance(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + AppSpace.xxl;
