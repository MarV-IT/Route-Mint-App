import 'package:flutter/material.dart';

import '../../app/app.dart';

/// One step of the first-run feature guide.
class GuideStep {
  const GuideStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const _icons = [
  Icons.speed_outlined,
  Icons.route_outlined,
  Icons.work_outline,
  Icons.local_gas_station_outlined,
  Icons.insert_chart_outlined,
  Icons.directions_car_outlined,
];

/// The guide in [language], one entry per step, in the order shown.
List<GuideStep> guideSteps(AppLanguage language) {
  final texts = _texts[language] ?? _texts[AppLanguage.english]!;
  return [
    for (var i = 0; i < texts.length; i++)
      GuideStep(icon: _icons[i], title: texts[i].$1, body: texts[i].$2),
  ];
}

/// Title and body per step. Bodies stay at two short sentences so a step
/// still fits a small phone at large text sizes; screen names match the
/// app's own labels.
const Map<AppLanguage, List<(String, String)>> _texts = {
  AppLanguage.english: [
    (
      'Your mileage at a glance',
      'Home shows your mileage for today, this week, month or year and, in '
          'the US, an estimated deduction. Start recording a trip with GPS '
          'right from here.',
    ),
    (
      'Every trip in one place',
      'Trips holds what GPS recorded and what you added by hand. Trips found '
          'automatically are marked “Needs review”: confirm whether each was '
          'work or personal.',
    ),
    (
      'Work Mode does the sorting',
      'Set the platforms you drive for and your hours. Any trip that starts '
          'during a shift is saved as Business on that platform.',
    ),
    (
      'Fuel and expenses',
      'Log fuel, parking, tolls, service and repairs from Home. They show up '
          'in your reports and charts.',
    ),
    (
      'Reports for tax time',
      'See trips by platform and spending by type, then save a PDF for your '
          'accountant — with an estimated deduction at the IRS rate for the '
          'US — or a CSV (Pro).',
    ),
    (
      'Your vehicle and help',
      'Profile keeps your vehicle and insurance details, maintenance '
          'reminders and backups. Unsure about a screen? Tap “?” at the top '
          'for a short explanation.',
    ),
  ],
  AppLanguage.spanish: [
    (
      'Tu kilometraje de un vistazo',
      'Inicio muestra tu kilometraje de hoy, la semana, el mes o el año y, '
          'en Estados Unidos, una deducción estimada. Desde aquí también '
          'empiezas a grabar un viaje con GPS.',
    ),
    (
      'Todos tus viajes en un lugar',
      'En Viajes está lo que grabó el GPS y lo que añadiste a mano. Los viajes '
          'detectados automáticamente se marcan «Requiere revisión»: confirma '
          'si fueron de trabajo o personales.',
    ),
    (
      'El Modo trabajo los clasifica',
      'Indica las plataformas con las que trabajas y tus horarios. Cada viaje '
          'que empiece durante un turno se guarda como de trabajo en esa '
          'plataforma.',
    ),
    (
      'Combustible y gastos',
      'Registra combustible, estacionamiento, peajes, servicio y reparaciones '
          'desde Inicio. Aparecerán en tus informes y gráficos.',
    ),
    (
      'Informes para los impuestos',
      'Mira los viajes por plataforma y los gastos por tipo, y guarda un PDF '
          'para tu contador —con una deducción estimada a la tarifa del IRS '
          'para Estados Unidos— o un CSV (Pro).',
    ),
    (
      'Tu vehículo y ayuda',
      'En Perfil están los datos del vehículo y del seguro, los recordatorios '
          'de mantenimiento y las copias de seguridad. ¿Dudas en una pantalla? '
          'Toca «?» arriba para ver una explicación breve.',
    ),
  ],
  AppLanguage.french: [
    (
      "Votre kilométrage d'un coup d'œil",
      "L'accueil affiche votre kilométrage du jour, de la semaine, du mois ou "
          "de l'année et, aux États-Unis, une déduction estimée. C'est aussi "
          'ici que vous lancez un trajet enregistré par GPS.',
    ),
    (
      'Tous vos trajets au même endroit',
      'Trajets regroupe ce que le GPS a enregistré et ce que vous avez ajouté '
          'à la main. Les trajets détectés automatiquement sont marqués « À '
          "vérifier » : confirmez s'ils étaient professionnels ou personnels.",
    ),
    (
      'Le mode travail trie pour vous',
      'Indiquez les plateformes pour lesquelles vous roulez et vos horaires. '
          'Tout trajet commencé pendant un quart est enregistré comme '
          'professionnel sur cette plateforme.',
    ),
    (
      'Carburant et dépenses',
      "Notez carburant, stationnement, péages, entretien et réparations depuis "
          "l'accueil. Ils apparaissent dans vos rapports et graphiques.",
    ),
    (
      'Des rapports pour les impôts',
      'Voyez les trajets par plateforme et les dépenses par type, puis '
          'enregistrez un PDF pour votre comptable — avec une déduction '
          "estimée au taux de l'IRS pour les États-Unis — ou un CSV (Pro).",
    ),
    (
      "Votre véhicule et de l'aide",
      "Le profil réunit les infos du véhicule et de l'assurance, les rappels "
          "d'entretien et les sauvegardes. Un doute sur un écran ? Touchez « ? "
          '» en haut pour une courte explication.',
    ),
  ],
  AppLanguage.russian: [
    (
      'Пробег с первого взгляда',
      'На главной виден пробег за сегодня, неделю, месяц или год, а для США '
          '— ещё и оценка вычета. Отсюда же можно начать запись поездки по '
          'GPS.',
    ),
    (
      'Все поездки в одном месте',
      'В «Поездках» всё, что записал GPS и что вы добавили вручную. Найденные '
          'автоматически поездки помечены «Требует проверки»: подтвердите, '
          'рабочая это поездка или личная.',
    ),
    (
      'Рабочий режим сортирует за вас',
      'Укажите платформы, на которых работаете, и часы смен. Каждая поездка, '
          'начатая во время смены, сохранится как рабочая на этой платформе.',
    ),
    (
      'Топливо и расходы',
      'Записывайте топливо, парковку, платные дороги, сервис и ремонт прямо с '
          'главной. Всё это попадёт в отчёты и диаграммы.',
    ),
    (
      'Отчёты для налогов',
      'Смотрите поездки по платформам и расходы по видам, а затем сохраните '
          'PDF для бухгалтера (для США — с оценкой вычета по ставке IRS) либо '
          'CSV-таблицу (Pro).',
    ),
    (
      'Авто и подсказки',
      'В Профиле — данные авто и страховки, напоминания об обслуживании и '
          'резервные копии. Что-то непонятно? Нажмите «?» вверху экрана, и '
          'появится короткое пояснение.',
    ),
  ],
  AppLanguage.ukrainian: [
    (
      'Пробіг з першого погляду',
      'На головній видно пробіг за сьогодні, тиждень, місяць або рік, а для '
          'США — ще й орієнтовне відрахування. Звідси ж можна почати запис '
          'поїздки з GPS.',
    ),
    (
      'Усі поїздки в одному місці',
      'У «Поїздках» усе, що записав GPS і що ви додали вручну. Автоматично '
          'знайдені поїздки позначені «Потребує перевірки»: підтвердіть, '
          'робоча це поїздка чи особиста.',
    ),
    (
      'Робочий режим сортує за вас',
      'Вкажіть платформи, на яких працюєте, і години змін. Кожна поїздка, що '
          'почалася під час зміни, збережеться як робоча на цій платформі.',
    ),
    (
      'Пальне й витрати',
      'Записуйте пальне, паркування, платні дороги, сервіс і ремонт прямо з '
          'головної. Усе це потрапить у звіти й діаграми.',
    ),
    (
      'Звіти для податків',
      'Дивіться поїздки за платформами й витрати за видами, а потім збережіть '
          'PDF для бухгалтера (для США — з орієнтовним відрахуванням за '
          'ставкою IRS) чи CSV-таблицю (Pro).',
    ),
    (
      'Авто й підказки',
      'У Профілі — дані авто й страховки, нагадування про обслуговування та '
          'резервні копії. Щось незрозуміло? Натисніть «?» угорі екрана, і '
          'зʼявиться коротке пояснення.',
    ),
  ],
  AppLanguage.dari: [
    (
      'مسافت شما در یک نگاه',
      'صفحه «خانه» مسافت امروز، این هفته، این ماه یا امسال و، در ایالات '
          'متحده، برآورد کسر مالیاتی را نشان می‌دهد. ثبت سفر با GPS را هم از '
          'همین‌جا شروع می‌کنید.',
    ),
    (
      'همه سفرها در یک جا',
      'در «سفرها» هر چه GPS ثبت کرده و هر چه دستی افزوده‌اید هست. سفرهایی که '
          'خودکار پیدا شده‌اند «نیاز به بررسی» دارند؛ تأیید کنید کاری بوده یا '
          'شخصی.',
    ),
    (
      'حالت کاری دسته‌بندی می‌کند',
      'پلتفرم‌هایی که با آن‌ها کار می‌کنید و ساعت‌های کاری را تعیین کنید. هر '
          'سفری که در زمان شیفت شروع شود، کاری و با همان پلتفرم ثبت می‌شود.',
    ),
    (
      'سوخت و هزینه‌ها',
      'سوخت، پارکینگ، عوارض، سرویس و تعمیر را از صفحه «خانه» ثبت کنید. این‌ها '
          'در گزارش‌ها و نمودارها می‌آیند.',
    ),
    (
      'گزارش برای مالیات',
      'سفرها را بر اساس پلتفرم و هزینه‌ها را بر اساس نوع ببینید، سپس یک PDF '
          'برای حسابدار (برای ایالات متحده با برآورد کسر به نرخ IRS) یا یک CSV '
          'ذخیره کنید (Pro).',
    ),
    (
      'خودرو و راهنما',
      'در پروفایل، اطلاعات خودرو و بیمه، یادآورهای نگهداری و پشتیبان‌ها هست. '
          'جایی را متوجه نشدید؟ روی «؟» در بالای صفحه بزنید تا توضیح کوتاهی '
          'ببینید.',
    ),
  ],
};
