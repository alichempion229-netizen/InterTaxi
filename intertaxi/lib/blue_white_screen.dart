import 'package:intertaxi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'blue_white_glass.dart'; // РРјРїРѕСЂС‚Рё С„Р°Р№Р»Рё Р°РІРІР°Р»Р°

class BlueWhiteScreen extends StatelessWidget {
  const BlueWhiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. РџР°СЃРјР°РЅР·Р°СЂРё РєР°Р±СѓРґ (Gradient Background)
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

          // 2. Р’РёТ·РµС‚ТіРѕРё С€РёС€Р°РіУЈ РґР°СЂ Р±РѕР»РѕРё РїР°СЃРјР°РЅР·Р°СЂ
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.translate(
                      'Мӯҳтавои Барнома',
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // РќР°РјСѓРЅР°Рё РёСЃС‚РёС„РѕРґР°Рё РєР°СЂС‚РѕС‡РєР°Рё С€РёС€Р°РіУЈ
                  FastBlueWhiteGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate('Блоки шишагӣ'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.translate(
                            'Дар ин ҷо метавонед дилхоҳ текст, тугма ё рӯйхатро ҷойгир кунед.',
                          ),
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
