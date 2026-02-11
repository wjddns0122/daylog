import 'package:daylog/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthScaffold extends StatelessWidget {
  final List<Widget> children;
  final bool showBackButton;
  final double horizontalPadding;

  const AuthScaffold({
    super.key,
    required this.children,
    this.showBackButton = false,
    this.horizontalPadding = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (showBackButton)
              Positioned(
                top: 0,
                left: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
