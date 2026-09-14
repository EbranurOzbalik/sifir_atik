import 'package:flutter/material.dart';

const double kPhoneContentMaxWidth = 720;
const double kFormContentMaxWidth = 640;
const double kAuthContentMaxWidth = 440;

double responsiveHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;

  if (width < 360) return 16;
  if (width < 600) return 20;
  return 24;
}

EdgeInsets responsivePagePadding(
  BuildContext context, {
  double top = 20,
  double bottom = 28,
}) {
  final horizontal = responsiveHorizontalPadding(context);

  return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = kPhoneContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
