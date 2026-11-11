import 'package:flutter/material.dart';

import '../../app/app.dart';

/// The version these notes describe. Must match the version name in
/// pubspec.yaml (a test checks it): when it changes, everyone who updates
/// sees the new notes once.
const whatsNewVersion = '1.0.2';

class WhatsNewItem {
  const WhatsNewItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const _icons = [
  Icons.calculate_outlined,
  Icons.policy_outlined,
  Icons.location_on_outlined,
];

/// What changed in [whatsNewVersion], in [language].
List<WhatsNewItem> whatsNewItems(AppLanguage language) {
  final texts = _texts[language] ?? _texts[AppLanguage.english]!;
  return [
    for (var i = 0; i < texts.length; i++)
      WhatsNewItem(icon: _icons[i], title: texts[i].$1, body: texts[i].$2),
  ];
}

const Map<AppLanguage, List<(String, String)>> _texts = {
  AppLanguage.english: [
    (
      'Clearer mileage reports',
      'US deductions are labelled as estimates using the IRS rate for each trip date. Canada shows a kilometer log without a deduction amount.',
    ),
    (
      'Terms and privacy',
      'Open the Terms of Service and Privacy Policy from sign-in or Profile. Open-source licenses are in Profile → About.',
    ),
    (
      'Location explained',
      'Before asking for location access, the app explains how tracking works. You can decline without opening the system prompt.',
    ),
  ],
  AppLanguage.spanish: [
    (
      'Informes de kilometraje más claros',
      'Las deducciones de EE. UU. son estimaciones con la tarifa del IRS de cada fecha. Canadá muestra un registro de kilómetros sin importe de deducción.',
    ),
    (
      'Condiciones y privacidad',
      'Abre los Términos del servicio y la Política de privacidad desde el acceso o Perfil. Las licencias están en Perfil → Acerca de.',
    ),
    (
      'Uso de ubicación explicado',
      'Antes de pedir acceso a la ubicación, la app explica el seguimiento. Puedes rechazarlo sin abrir la solicitud del sistema.',
    ),
  ],
  AppLanguage.french: [
    (
      'Des rapports kilométriques plus clairs',
      "Les déductions américaines sont des estimations au taux IRS de chaque trajet. Au Canada, un registre kilométrique remplace le montant de déduction.",
    ),
    (
      'Conditions et confidentialité',
      "Ouvrez les conditions et la politique de confidentialité depuis la connexion ou le profil. Les licences sont dans Profil → À propos.",
    ),
    (
      'La localisation expliquée',
      "Avant de demander la localisation, l'application explique le suivi. Vous pouvez refuser sans ouvrir la demande du système.",
    ),
  ],
  AppLanguage.russian: [
    (
      'Понятные отчёты о пробеге',
      'Для США показана оценка вычета по ставке IRS на дату поездки. Для Канады — журнал километров без суммы вычета.',
    ),
    (
      'Условия и конфиденциальность',
      'Условия использования и политика конфиденциальности доступны при входе и в Профиле. Лицензии — в Профиль → О приложении.',
    ),
    (
      'Пояснение о геолокации',
      'Перед запросом доступа приложение объясняет работу отслеживания. Можно отказаться, не открывая системный запрос.',
    ),
  ],
  AppLanguage.ukrainian: [
    (
      'Зрозумілі звіти про пробіг',
      'Для США показано орієнтовне відрахування за ставкою IRS на дату поїздки. Для Канади — журнал кілометрів без суми відрахування.',
    ),
    (
      'Умови й конфіденційність',
      'Умови використання та політика конфіденційності доступні при вході й у Профілі. Ліцензії — у Профіль → Про додаток.',
    ),
    (
      'Пояснення про геолокацію',
      'Перед запитом доступу додаток пояснює роботу відстеження. Можна відмовитися, не відкриваючи системний запит.',
    ),
  ],
  AppLanguage.dari: [
    (
      'گزارش مسافت روشن‌تر',
      'کسر آمریکا برآوردی با نرخ IRS در تاریخ هر سفر است. برای کانادا، گزارش کیلومتر بدون مبلغ کسر نمایش داده می‌شود.',
    ),
    (
      'شرایط و حریم خصوصی',
      'شرایط استفاده و سیاست حریم خصوصی از صفحه ورود یا پروفایل باز می‌شوند. مجوزها در پروفایل ← درباره برنامه هستند.',
    ),
    (
      'توضیح موقعیت مکانی',
      'پیش از درخواست دسترسی به موقعیت، برنامه ردیابی را توضیح می‌دهد. می‌توانید بدون باز شدن درخواست سیستم آن را رد کنید.',
    ),
  ],
};
