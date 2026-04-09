import 'package:flutter/material.dart';

/// Reusable app bar widget for the UPSC Architect app.
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const AppBarWidget({
    super.key,
    this.title = 'UPSC Architect',
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Lexend',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Color(0xFF191C1E),
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleSpacing: leading == null ? 24 : 0,
    );
  }
}

