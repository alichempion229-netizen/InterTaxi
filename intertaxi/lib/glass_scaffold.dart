import 'package:flutter/material.dart';

class GlassScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          // 1. РџР°СЃРјР°РЅР·Р°СЂРё СЏРіРѕРЅР°Рё РіСЂР°РґРёРµРЅС‚РёРё РєР°Р±СѓРґ Р±Р°СЂРѕРё С‚Р°РјРѕРјРё Р±Р°СЂРЅРѕРјР°
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. РљРѕРЅС‚РµРЅС‚Рё Р°СЃР»РёРё СЃР°ТіРёС„Р°
          SafeArea(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
