import 'package:flutter/material.dart';

import 'package:map_awareness/utils/helpers.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';

/// A unified PremiumCard with ExpansionTile for collapsible content.
class PremiumExpansionTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry? childrenPadding;
  final Key? expansionKey; // For PageStorageKey
  final ValueChanged<bool>? onExpansionChanged;

  const PremiumExpansionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.children = const [],
    this.initiallyExpanded = false,
    this.tilePadding,
    this.childrenPadding,
    this.expansionKey,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: expansionKey,
          initiallyExpanded: initiallyExpanded,
          tilePadding: tilePadding ?? const EdgeInsets.fromLTRB(16, 12, 16, 12),
          childrenPadding: childrenPadding ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          shape: const Border(),
          collapsedShape: const Border(),
          onExpansionChanged: (expanded) {
            if (expanded) Haptics.select();
            onExpansionChanged?.call(expanded);
          },
          children: children,
        ),
      ),
    );
  }
}
