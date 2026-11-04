import 'package:flutter/material.dart';

import '../../app/app.dart';

/// The version these notes describe. Must match the version name in
/// pubspec.yaml (a test checks it): when it changes, everyone who updates
/// sees the new notes once.
const whatsNewVersion = '1.0.1';

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
  Icons.login,
  Icons.directions_car_outlined,
  Icons.calculate_outlined,
  Icons.tour_outlined,
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
      'Sign in with Google',
      'You can now sign in with your Google account, no separate password '
          'needed.',
    ),
    (
      'Vehicle section',
      'Profile now keeps make, model, year, license plate and insurance '
          'details in one place.',
    ),
    (
      'Updated mileage rates',
      'Each trip is valued at the rate in force on its date. In the US that '
          'is 76¢ a mile from July 1, 2026.',
    ),
    ('App tour', 'A short overview of what the app can do: Profile → Help.'),
  ],
  AppLanguage.spanish: [
    (
      'Inicio de sesión con Google',
      'Ahora puedes entrar con tu cuenta de Google, sin otra contraseña.',
    ),
    (
      'Sección Vehículo',
      'En Perfil tienes marca, modelo, año, placa y datos del seguro en un '
          'solo lugar.',
    ),
    (
      'Tarifas por kilometraje actualizadas',
      'Cada viaje se calcula con la tarifa vigente en su fecha. En EE. UU. '
          'son 76 ¢ por milla desde el 1 de julio de 2026.',
    ),
    (
      'Recorrido por la app',
      'Un resumen breve de lo que hace la app: Perfil → Ayuda.',
    ),
  ],
  AppLanguage.french: [
    (
      'Connexion avec Google',
      'Vous pouvez maintenant vous connecter avec votre compte Google, sans '
          'autre mot de passe.',
    ),
    (
      'Section Véhicule',
      "Le profil réunit marque, modèle, année, plaque et assurance au même "
          'endroit.',
    ),
    (
      'Taux kilométriques à jour',
      'Chaque trajet est calculé au taux en vigueur à sa date. Aux '
          'États-Unis : 76 ¢ par mille depuis le 1er juillet 2026.',
    ),
    (
      "Visite de l'app",
      "Un aperçu rapide de ce que fait l'app : Profil → Aide.",
    ),
  ],
  AppLanguage.russian: [
    (
      'Вход через Google',
      'Теперь можно войти через свой аккаунт Google — без отдельного пароля.',
    ),
    (
      'Раздел «Автомобиль»',
      'В Профиле — марка, модель, год, номерной знак и данные страховки в '
          'одном месте.',
    ),
    (
      'Новые ставки вычета',
      'Каждая поездка считается по ставке на её дату. Для США с 1 июля 2026 '
          'года — 76 центов за милю.',
    ),
    (
      'Обзор функций',
      'Короткий обзор возможностей приложения: Профиль → Помощь.',
    ),
  ],
  AppLanguage.ukrainian: [
    (
      'Вхід через Google',
      'Тепер можна ввійти через свій акаунт Google — без окремого пароля.',
    ),
    (
      'Розділ «Автомобіль»',
      'У Профілі — марка, модель, рік, номерний знак і дані страхування в '
          'одному місці.',
    ),
    (
      'Нові ставки відрахування',
      'Кожна поїздка рахується за ставкою на свою дату. Для США з 1 липня '
          '2026 року — 76 центів за милю.',
    ),
    (
      'Гайд по функціях',
      'Короткий огляд можливостей додатка: Профіль → Допомога.',
    ),
  ],
  AppLanguage.dari: [
    (
      'ورود با Google',
      'اکنون می‌توانید با حساب Google خود وارد شوید، بدون رمز جداگانه.',
    ),
    (
      'بخش «خودرو»',
      'در پروفایل، سازنده، مدل، سال، پلاک و اطلاعات بیمه در یک جا هستند.',
    ),
    (
      'نرخ‌های جدید کسر',
      'هر سفر با نرخ تاریخ خودش حساب می‌شود. برای آمریکا از 1 جولای 2026، '
          '76 سنت برای هر مایل.',
    ),
    ('آشنایی با برنامه', 'مروری کوتاه بر امکانات برنامه: پروفایل ← راهنما.'),
  ],
};
