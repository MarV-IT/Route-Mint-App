import '../../app/app.dart';
import '../localization/app_strings.dart';

/// A screen or feature that has a "?" explanation.
///
/// [id] is what analytics records; it is spelled out so renaming an enum
/// value never splits the history of a topic.
enum HelpTopic {
  home('home'),
  trips('trips'),
  addTrip('add_trip'),
  platforms('platforms'),
  reports('reports'),
  charts('charts'),
  premium('premium');

  const HelpTopic(this.id);

  final String id;
}

class HelpEntry {
  const HelpEntry({required this.body, this.example});

  /// Two to four sentences: what it does, when to use it, what happens to
  /// the data. With [example], at most 60 words.
  final String body;
  final String? example;
}

/// The sheet title — the feature's own on-screen name, taken from
/// [AppStrings] so it can never drift from what the user just tapped next to.
String helpTitle(HelpTopic topic, AppStrings s) => switch (topic) {
  HelpTopic.home => s.home,
  HelpTopic.trips => s.trips,
  HelpTopic.addTrip => s.addTrip,
  HelpTopic.platforms => s.workMode,
  HelpTopic.reports => s.reports,
  HelpTopic.charts => s.platformOverview,
  // The Pro screen is titled with a call to action ("Go Pro"); the feature
  // itself is just Pro.
  HelpTopic.premium => 'Pro',
};

HelpEntry helpEntry(HelpTopic topic, AppLanguage language) =>
    helpCatalog[topic]![language]!;

/// Every explanation in every language, in one place so texts are easy to
/// edit and translate. Bundled with the app: no network, and a text change
/// ships with an app update.
///
/// Rules for editing: no marketing, never restate the button's name, check
/// facts against the code (a hint that lies is worse than none). If a text
/// has to be read twice, it is too long. help_catalog_test enforces the word
/// and sentence limits for every language.
const Map<HelpTopic, Map<AppLanguage, HelpEntry>> helpCatalog = {
  HelpTopic.home: {
    AppLanguage.english: HelpEntry(
      body:
          'See your mileage and tax deduction for today, this week, this month '
          'or this year. Start recording a trip yourself here, or turn on auto '
          'detection (Pro): it saves a trip by itself once you have been '
          'stopped for 3 minutes. Trips saved that way wait for review on the '
          'Trips tab.',
    ),
    AppLanguage.spanish: HelpEntry(
      body:
          'Aquí ves la distancia recorrida y la deducción fiscal de hoy, esta '
          'semana, este mes o este año. Desde aquí puedes grabar un viaje tú '
          'mismo o activar la detección automática (Pro): guarda el viaje por '
          'sí sola cuando llevas 3 minutos detenido. Esos viajes esperan '
          'revisión en la pestaña Viajes.',
    ),
    AppLanguage.french: HelpEntry(
      body:
          "Vous voyez ici la distance parcourue et la déduction fiscale "
          "d'aujourd'hui, de la semaine, du mois ou de l'année. Lancez ici "
          "l'enregistrement d'un trajet vous-même, ou activez la détection "
          "automatique (Pro) : elle enregistre le trajet seule après 3 minutes "
          "d'arrêt. Ces trajets attendent une vérification dans l'onglet "
          "Trajets.",
    ),
    AppLanguage.russian: HelpEntry(
      body:
          'Здесь виден пробег и налоговый вычет за сегодня, неделю, месяц или '
          'год. Отсюда можно самому начать запись поездки или включить '
          'автоопределение (Pro): оно само сохранит поездку после остановки '
          'дольше 3 минут. Такие поездки ждут проверки во вкладке «Поездки».',
    ),
    AppLanguage.ukrainian: HelpEntry(
      body:
          'Тут видно пробіг і податкове відрахування за сьогодні, тиждень, '
          'місяць або рік. Звідси можна самому почати запис поїздки або '
          'ввімкнути авто-виявлення (Pro): воно саме збереже поїздку після '
          'зупинки довше 3 хвилин. Такі поїздки чекають на перевірку у '
          'вкладці «Поїздки».',
    ),
    AppLanguage.dari: HelpEntry(
      body:
          'اینجا مسافت پیموده‌شده و کسر مالیاتی امروز، این هفته، این ماه یا '
          'امسال را می‌بینید. از اینجا می‌توانید ثبت سفر را خودتان شروع کنید '
          'یا تشخیص خودکار (Pro) را روشن کنید: پس از ۳ دقیقه توقف، سفر را '
          'خودش ذخیره می‌کند. این سفرها در زبانه «سفرها» منتظر بررسی '
          'می‌مانند.',
    ),
  },
  HelpTopic.trips: {
    AppLanguage.english: HelpEntry(
      body:
          'All your trips are here, both GPS-recorded and added by hand. New '
          'automatic ones are marked “Needs review”: confirm whether each was '
          'work or personal. If a stop split one trip in two, merge it with the '
          'trip next to it. Tap a trip to change its addresses, distance or '
          'expenses.',
    ),
    AppLanguage.spanish: HelpEntry(
      body:
          'Aquí están todos tus viajes, grabados por GPS y añadidos a mano. Los '
          'automáticos nuevos llevan la marca «Requiere revisión»: confirma si '
          'fueron de trabajo o personales. Si una parada partió un viaje en '
          'dos, únelo con el viaje contiguo. Toca un viaje para cambiar '
          'direcciones, distancia o gastos.',
    ),
    AppLanguage.french: HelpEntry(
      body:
          'Tous vos trajets sont ici, enregistrés par GPS ou ajoutés à la main. '
          'Les nouveaux trajets automatiques portent la mention « À vérifier » '
          ": confirmez s'ils étaient professionnels ou personnels. Si un arrêt "
          'a coupé un trajet en deux, fusionnez-le avec le trajet voisin. '
          'Touchez un trajet pour modifier adresses, distance ou frais.',
    ),
    AppLanguage.russian: HelpEntry(
      body:
          'Здесь все ваши поездки — записанные GPS и добавленные вручную. Новые '
          'автоматические помечены «Требует проверки»: подтвердите, рабочая '
          'это поездка или личная. Если остановка разорвала поездку надвое, '
          'объедините её с соседней. Нажмите на поездку, чтобы изменить '
          'адреса, расстояние или расходы.',
    ),
    AppLanguage.ukrainian: HelpEntry(
      body:
          'Тут усі ваші поїздки — записані GPS і додані вручну. Нові '
          'автоматичні мають позначку «Потребує перевірки»: підтвердіть, '
          'робоча це поїздка чи особиста. Якщо зупинка розірвала поїздку на '
          'дві, обʼєднайте її із сусідньою. Торкніться поїздки, щоб змінити '
          'адреси, відстань чи витрати.',
    ),
    AppLanguage.dari: HelpEntry(
      body:
          'همه سفرهای شما اینجاست؛ چه با GPS ثبت شده و چه دستی اضافه شده '
          'باشد. سفرهای خودکار جدید برچسب «نیاز به بررسی» دارند: تأیید کنید که '
          'کاری بوده یا شخصی. اگر توقفی یک سفر را دو تکه کرده، آن را با سفر '
          'کناری ادغام کنید. برای تغییر نشانی، مسافت یا هزینه‌ها روی سفر '
          'بزنید.',
    ),
  },
  HelpTopic.addTrip: {
    AppLanguage.english: HelpEntry(
      body:
          "Add a trip GPS didn't record: start, destination, distance and "
          'category. For a work trip, pick the platform so it appears in report '
          'breakdowns. It gets the current date and time. If a Work Mode shift '
          "is running now, it is saved as Business on that shift's platform.",
      example: 'Uber, 12 mi, Business.',
    ),
    AppLanguage.spanish: HelpEntry(
      body:
          'Añade un viaje que el GPS no grabó: origen, destino, distancia y '
          'categoría. En un viaje de trabajo, elige la plataforma para que '
          'salga en el desglose. Se guarda con la fecha y hora actuales. Si '
          'ahora hay un turno activo en Modo trabajo, se guarda como Trabajo en '
          'la plataforma de ese turno.',
      example: 'Uber, 12 mi, Trabajo.',
    ),
    AppLanguage.french: HelpEntry(
      body:
          "Ajoutez un trajet que le GPS n'a pas enregistré : départ, arrivée, "
          'distance et catégorie. Pour un trajet professionnel, indiquez la '
          "plateforme : elle apparaîtra dans les rapports. Il prend la date et "
          "l'heure actuelles. Si un quart du Mode travail est en cours, il est "
          'enregistré en Professionnel sur la plateforme de ce quart.',
      example: 'Uber, 12 km, Professionnel.',
    ),
    AppLanguage.russian: HelpEntry(
      body:
          'Добавьте поездку, которую не записал GPS: откуда, куда, расстояние '
          'и категорию. Для рабочей поездки укажите платформу, чтобы она '
          'попала в разбивку отчётов. Поездка получит текущие дату и время. '
          'Если сейчас идёт смена из рабочего режима, поездка сохранится как '
          'рабочая на платформе этой смены.',
      example: 'Uber, 12 км, категория «Рабочая».',
    ),
    AppLanguage.ukrainian: HelpEntry(
      body:
          'Додайте поїздку, яку не записав GPS: звідки, куди, відстань і '
          'категорію. Для робочої поїздки вкажіть платформу, щоб вона '
          'потрапила в розбивку звітів. Поїздка отримає поточні дату й час. '
          'Якщо зараз триває зміна з робочого режиму, поїздка збережеться як '
          'робоча на платформі цієї зміни.',
      example: 'Uber, 12 км, категорія «Робоча».',
    ),
    AppLanguage.dari: HelpEntry(
      body:
          'سفری را که GPS ثبت نکرده اضافه کنید: مبدأ، مقصد، مسافت و '
          'دسته‌بندی. برای سفر کاری، پلتفرم را انتخاب کنید تا در تفکیک '
          'گزارش‌ها بیاید. سفر با تاریخ و ساعت فعلی ذخیره می‌شود. اگر الان '
          'شیفتی از حالت کاری در جریان باشد، سفر به‌عنوان کاری با پلتفرم همان '
          'شیفت ذخیره می‌شود.',
      example: 'Uber، 12 کیلومتر، کاری.',
    ),
  },
  HelpTopic.platforms: {
    AppLanguage.english: HelpEntry(
      body:
          'Set which platforms you work on and during which hours. While Work '
          'Mode is on, any trip that starts inside a shift becomes Business on '
          "that shift's platform, whether GPS recorded it or you added it. "
          'Shifts apply every day, and overnight shifts work too.',
      example: 'Uber from 6:00 PM to 2:00 AM.',
    ),
    AppLanguage.spanish: HelpEntry(
      body:
          'Indica en qué plataformas trabajas y en qué horario. Con el Modo '
          'trabajo activo, cada viaje que empiece dentro de un turno pasa a ser '
          'de Trabajo en la plataforma de ese turno, lo grabe el GPS o lo '
          'añadas tú. Los turnos valen todos los días, también los nocturnos.',
      example: 'Uber de 18:00 a 02:00.',
    ),
    AppLanguage.french: HelpEntry(
      body:
          'Indiquez sur quelles plateformes et à quelles heures vous '
          'travaillez. Quand le Mode travail est actif, chaque trajet qui '
          'commence pendant un quart devient Professionnel sur la plateforme '
          "de ce quart, qu'il soit enregistré par GPS ou ajouté à la main. Les "
          "quarts s'appliquent chaque jour, y compris de nuit.",
      example: 'Uber de 18 h à 2 h.',
    ),
    AppLanguage.russian: HelpEntry(
      body:
          'Здесь вы указываете, на каких платформах и в какие часы работаете. '
          'Пока режим включён, каждая поездка, начатая в пределах смены, '
          'становится рабочей с платформой этой смены — и записанная GPS, и '
          'добавленная вручную. Смены действуют каждый день, и ночная смена '
          'через полночь тоже работает.',
      example: 'Uber с 18:00 до 02:00.',
    ),
    AppLanguage.ukrainian: HelpEntry(
      body:
          'Тут ви вказуєте, на яких платформах і в які години працюєте. Поки '
          'режим увімкнено, кожна поїздка, що почалася в межах зміни, стає '
          'робочою з платформою цієї зміни — і записана GPS, і додана вручну. '
          'Зміни діють щодня, і нічна зміна через північ теж працює.',
      example: 'Uber з 18:00 до 02:00.',
    ),
    AppLanguage.dari: HelpEntry(
      body:
          'اینجا مشخص می‌کنید روی کدام پلتفرم‌ها و در چه ساعت‌هایی کار '
          'می‌کنید. تا وقتی این حالت روشن است، هر سفری که در بازه یک شیفت '
          'شروع شود، کاری و با پلتفرم همان شیفت ثبت می‌شود، چه با GPS و چه '
          'دستی. شیفت‌ها هر روز اعمال می‌شوند و شیفت شبانه هم کار می‌کند.',
      example: 'Uber از 18:00 تا 02:00.',
    ),
  },
  HelpTopic.reports: {
    AppLanguage.english: HelpEntry(
      body:
          'Reports total your overall and work mileage and expenses for the '
          'chosen month or a custom range. From here you can save a PDF with '
          'the tax deduction for your accountant, or a CSV spreadsheet; '
          'exporting is a Pro feature. Trips marked “Needs review” are included '
          'too, so check them first.',
    ),
    AppLanguage.spanish: HelpEntry(
      body:
          'Los informes suman la distancia total y de trabajo y los gastos del '
          'mes elegido o de un periodo propio. Desde aquí guardas un PDF con la '
          'deducción fiscal para tu contador o una hoja CSV; exportar es una '
          'función Pro. Los viajes marcados «Requiere revisión» también entran '
          'en el informe, así que revísalos antes.',
    ),
    AppLanguage.french: HelpEntry(
      body:
          'Les rapports totalisent la distance totale et professionnelle et '
          "les frais du mois choisi ou d'une période personnalisée. D'ici, vous "
          'enregistrez un PDF avec la déduction fiscale pour votre comptable, '
          "ou un tableau CSV ; l'export est une fonction Pro. Les trajets « À "
          "vérifier » sont aussi inclus, vérifiez-les d'abord.",
    ),
    AppLanguage.russian: HelpEntry(
      body:
          'Отчёты подводят итог общего и рабочего пробега и расходов за '
          'выбранный месяц или свой период. Отсюда сохраняется PDF с налоговым '
          'вычетом для бухгалтера или CSV-таблица — это функция Pro. Поездки с '
          'пометкой «Требует проверки» тоже попадают в отчёт, поэтому сначала '
          'проверьте их.',
    ),
    AppLanguage.ukrainian: HelpEntry(
      body:
          'Звіти підсумовують загальний і робочий пробіг та витрати за обраний '
          'місяць або свій період. Звідси зберігається PDF із податковим '
          'відрахуванням для бухгалтера або CSV-таблиця — це функція Pro. '
          'Поїздки з позначкою «Потребує перевірки» теж потрапляють у звіт, '
          'тож спершу перегляньте їх.',
    ),
    AppLanguage.dari: HelpEntry(
      body:
          'گزارش‌ها مسافت کل و کاری و هزینه‌های ماه انتخاب‌شده یا بازه دلخواه '
          'را جمع می‌زنند. از اینجا یک PDF با کسر مالیاتی برای حسابدار یا یک '
          'جدول CSV ذخیره می‌کنید؛ خروجی گرفتن از امکانات Pro است. سفرهای '
          '«نیاز به بررسی» هم در گزارش می‌آیند، پس اول آن‌ها را بررسی کنید.',
    ),
  },
  HelpTopic.charts: {
    AppLanguage.english: HelpEntry(
      body:
          "The ring shows each platform's share of the period's trips; the "
          'three most used get their own color, the rest go into “Other '
          'work”. The bars show spending by type: fuel from the fuel log, '
          'service and repair from expenses, parking and tolls from trips and '
          'expenses. The button below makes a PDF for this period.',
    ),
    AppLanguage.spanish: HelpEntry(
      body:
          'El anillo muestra qué parte de los viajes hizo cada plataforma; las '
          'tres más usadas tienen color propio y el resto va a «Otro '
          'trabajo». Las barras muestran los gastos por tipo: combustible del '
          'registro de combustible, servicio y reparación de los gastos, '
          'estacionamiento y peajes de viajes y gastos. El botón crea un PDF '
          'de este periodo.',
    ),
    AppLanguage.french: HelpEntry(
      body:
          "L'anneau montre la part de chaque plateforme dans les trajets ; "
          'les trois plus utilisées ont leur couleur, les autres vont dans '
          '« Autre travail ». Les barres montrent les dépenses par type : '
          'carburant du journal de carburant, service et réparation des '
          'dépenses, stationnement et péages des trajets et des dépenses. Le '
          'bouton dessous crée un PDF pour cette période.',
    ),
    AppLanguage.russian: HelpEntry(
      body:
          'Кольцо показывает, какую долю поездок за период дала каждая '
          'платформа; свой цвет есть у трёх самых частых, остальные идут в '
          '«Другую работу». Полосы показывают расходы по видам: топливо из '
          'журнала топлива, сервис и ремонт из расходов, парковка и платные '
          'дороги из поездок и расходов. Кнопка под диаграммами создаёт PDF '
          'именно за этот период.',
    ),
    AppLanguage.ukrainian: HelpEntry(
      body:
          'Кільце показує, яку частку поїздок за період дала кожна платформа; '
          'свій колір мають три найчастіші, решта йде в «Іншу роботу». Смуги '
          'показують витрати за видами: пальне з журналу пального, сервіс і '
          'ремонт із витрат, паркування й платні дороги з поїздок і витрат. '
          'Кнопка під діаграмами створює PDF саме за цей період.',
    ),
    AppLanguage.dari: HelpEntry(
      body:
          'حلقه نشان می‌دهد هر پلتفرم چه سهمی از سفرهای این بازه داشته است؛ '
          'سه پلتفرم پرکاربرد رنگ خود را دارند و بقیه در «کار دیگر» می‌آیند. '
          'نوارها هزینه‌ها را بر اساس نوع نشان می‌دهند: سوخت از ثبت سوخت، '
          'سرویس و تعمیر از هزینه‌ها، پارکینگ و عوارض از سفرها و هزینه‌ها. '
          'دکمه پایین برای همین بازه PDF می‌سازد.',
    ),
  },
  HelpTopic.premium: {
    AppLanguage.english: HelpEntry(
      body:
          'Pro unlocks PDF and CSV report export, cloud backup, automatic trip '
          'detection, fuel summaries, the month-end checklist and maintenance '
          "reminders. Payments aren't available yet. Without Pro, auto "
          'detection stays off, but all your trips and records remain on your '
          'device.',
    ),
    AppLanguage.spanish: HelpEntry(
      body:
          'Pro desbloquea exportar informes en PDF y CSV, copia en la nube, '
          'detección automática de viajes, resúmenes de combustible, lista de '
          'cierre mensual y recordatorios de mantenimiento. Los pagos aún no '
          'están disponibles. Sin Pro, la detección automática queda apagada, '
          'pero tus viajes y registros siguen en el dispositivo.',
    ),
    AppLanguage.french: HelpEntry(
      body:
          "Pro débloque l'export des rapports en PDF et CSV, la sauvegarde "
          'cloud, la détection automatique des trajets, les résumés carburant, '
          "la liste de clôture du mois et les rappels d'entretien. Le paiement "
          "n'est pas encore disponible. Sans Pro, la détection automatique "
          "reste coupée, mais vos trajets et données restent sur l'appareil.",
    ),
    AppLanguage.russian: HelpEntry(
      body:
          'Pro открывает экспорт отчётов в PDF и CSV, облачную резервную '
          'копию, автоопределение поездок, сводки по топливу, чек-лист '
          'закрытия месяца и напоминания об обслуживании. Оплата пока '
          'недоступна. Без Pro автоопределение выключено, но все поездки и '
          'записи остаются на устройстве.',
    ),
    AppLanguage.ukrainian: HelpEntry(
      body:
          'Pro відкриває експорт звітів у PDF і CSV, хмарну резервну копію, '
          'авто-виявлення поїздок, підсумки по пальному, чек-лист закриття '
          'місяця й нагадування про обслуговування. Оплата поки недоступна. '
          'Без Pro авто-виявлення вимкнене, але всі поїздки й записи '
          'залишаються на пристрої.',
    ),
    AppLanguage.dari: HelpEntry(
      body:
          'Pro خروجی گزارش PDF و CSV، پشتیبان ابری، تشخیص خودکار سفر، خلاصه '
          'سوخت، چک‌لیست پایان ماه و یادآور سرویس را فعال می‌کند. پرداخت هنوز '
          'در دسترس نیست. بدون Pro تشخیص خودکار خاموش می‌ماند، اما همه سفرها و '
          'داده‌هایتان روی دستگاه باقی می‌مانند.',
    ),
  },
};
