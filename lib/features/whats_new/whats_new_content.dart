import 'package:flutter/material.dart';

import '../../app/app.dart';

/// The version these notes describe. Must match the version name in
/// pubspec.yaml (a test checks it): when it changes, everyone who updates
/// sees the new notes once.
const whatsNewVersion = '1.0.3';

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
  Icons.workspace_premium_outlined,
  Icons.star_outline,
  Icons.account_circle_outlined,
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
      'MarV Route Pro',
      'View monthly and yearly plans, restore a purchase and check your subscription in Profile. Test payments are clearly labelled.',
    ),
    (
      'Rate the app',
      'After using the app, a rating request may appear at a quiet moment. You can turn requests off in Profile.',
    ),
    (
      'Your account, your data',
      'Trips, preferences and Pro status stay with their account, including when you switch accounts during a pending operation.',
    ),
  ],
  AppLanguage.spanish: [
    (
      'MarV Route Pro',
      'Consulta planes mensuales y anuales, restaura una compra y revisa tu suscripción en Perfil. Los pagos de prueba están identificados.',
    ),
    (
      'Valorar la aplicación',
      'Después de usar la aplicación, puede aparecer una solicitud de valoración en un momento tranquilo. Puedes desactivarla en Perfil.',
    ),
    (
      'Tu cuenta, tus datos',
      'Los viajes, preferencias y estado Pro permanecen en su cuenta, incluso al cambiar de cuenta durante una operación pendiente.',
    ),
  ],
  AppLanguage.french: [
    (
      'MarV Route Pro',
      'Consultez les forfaits mensuels et annuels, restaurez un achat et consultez votre abonnement dans Profil. Les paiements de test sont signalés.',
    ),
    (
      'Noter l’application',
      'Après utilisation, une demande de note peut apparaître à un moment calme. Vous pouvez la désactiver dans Profil.',
    ),
    (
      'Votre compte, vos données',
      'Trajets, préférences et statut Pro restent liés à leur compte, même lors d’un changement de compte pendant une opération en cours.',
    ),
  ],
  AppLanguage.russian: [
    (
      'MarV Route Pro',
      'Месячный и годовой планы, восстановление покупки и состояние подписки в Профиле. Тестовые платежи отмечены отдельно.',
    ),
    (
      'Оценка приложения',
      'После использования запрос оценки может появиться в спокойный момент. Запросы можно отключить в Профиле.',
    ),
    (
      'Ваш аккаунт, ваши данные',
      'Поездки, настройки и статус Pro остаются в своём аккаунте, даже при смене аккаунта во время незавершённой операции.',
    ),
  ],
  AppLanguage.ukrainian: [
    (
      'MarV Route Pro',
      'Місячний і річний плани, відновлення покупки та стан підписки у Профілі. Тестові платежі позначено окремо.',
    ),
    (
      'Оцінювання додатку',
      'Після використання запит оцінки може з’явитися у спокійний момент. Запити можна вимкнути у Профілі.',
    ),
    (
      'Ваш акаунт, ваші дані',
      'Поїздки, налаштування та статус Pro залишаються у своєму акаунті, навіть при зміні акаунта під час незавершеної операції.',
    ),
  ],
  AppLanguage.dari: [
    (
      'MarV Route Pro',
      'طرح‌های ماهانه و سالانه، بازیابی خرید و وضعیت اشتراک در پروفایل در دسترس‌اند. پرداخت‌های آزمایشی مشخص شده‌اند.',
    ),
    (
      'امتیاز دادن به برنامه',
      'پس از استفاده، درخواست امتیاز ممکن است در زمانی آرام نمایش داده شود. می‌توانید درخواست‌ها را در پروفایل خاموش کنید.',
    ),
    (
      'حساب شما، داده‌های شما',
      'سفرها، تنظیمات و وضعیت Pro در حساب خود باقی می‌مانند، حتی هنگام تغییر حساب در جریان یک عملیات.',
    ),
  ],
};
