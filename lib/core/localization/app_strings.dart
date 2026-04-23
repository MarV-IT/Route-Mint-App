import '../../app/app.dart';

class AppStrings {
  final AppLanguage currentLanguage;

  const AppStrings(this.currentLanguage);

  String get today => _value(
        en: 'Today',
        es: 'Hoy',
        fr: "Aujourd'hui",
        ru: 'Сегодня',
        uk: 'Сьогодні',
        fa: 'امروز',
      );

  String get trips => _value(
        en: 'Trips',
        es: 'Viajes',
        fr: 'Trajets',
        ru: 'Поездки',
        uk: 'Поїздки',
        fa: 'سفرها',
      );

  String get add => _value(
        en: 'Add',
        es: 'Añadir',
        fr: 'Ajouter',
        ru: 'Добавить',
        uk: 'Додати',
        fa: 'افزودن',
      );

  String get reports => _value(
        en: 'Reports',
        es: 'Informes',
        fr: 'Rapports',
        ru: 'Отчёты',
        uk: 'Звіти',
        fa: 'گزارش‌ها',
      );

  String get profile => _value(
        en: 'Profile',
        es: 'Perfil',
        fr: 'Profil',
        ru: 'Профиль',
        uk: 'Профіль',
        fa: 'پروفایل',
      );

  String get todayDistance => _value(
        en: 'Today distance',
        es: 'Distancia de hoy',
        fr: 'Distance du jour',
        ru: 'Дистанция за сегодня',
        uk: 'Дистанція за сьогодні',
        fa: 'مسافت امروز',
      );

  String get tripsRecorded => _value(
        en: '3 trips recorded',
        es: '3 viajes registrados',
        fr: '3 trajets enregistrés',
        ru: '3 поездки записаны',
        uk: 'Записано 3 поїздки',
        fa: '۳ سفر ثبت شده',
      );

  String get businessTrips => _value(
        en: 'Business trips',
        es: 'Viajes de trabajo',
        fr: 'Trajets professionnels',
        ru: 'Рабочие поездки',
        uk: 'Робочі поїздки',
        fa: 'سفرهای کاری',
      );

  String get tripsNeedReview => _value(
        en: '2 trips need review',
        es: '2 viajes necesitan revisión',
        fr: '2 trajets à vérifier',
        ru: '2 поездки требуют проверки',
        uk: '2 поїздки треба перевірити',
        fa: '۲ سفر نیاز به بررسی دارند',
      );

  String get quickActions => _value(
        en: 'Quick actions',
        es: 'Acciones rápidas',
        fr: 'Actions rapides',
        ru: 'Быстрые действия',
        uk: 'Швидкі дії',
        fa: 'اقدام‌های سریع',
      );

  String get startTrip => _value(
        en: 'Start trip',
        es: 'Iniciar viaje',
        fr: 'Démarrer',
        ru: 'Начать поездку',
        uk: 'Почати поїздку',
        fa: 'شروع سفر',
      );

  String get addManually => _value(
        en: 'Add manually',
        es: 'Añadir manualmente',
        fr: 'Ajouter manuellement',
        ru: 'Добавить вручную',
        uk: 'Додати вручну',
        fa: 'افزودن دستی',
      );

  String get addExpense => _value(
        en: 'Add expense',
        es: 'Añadir gasto',
        fr: 'Ajouter une dépense',
        ru: 'Добавить расход',
        uk: 'Додати витрату',
        fa: 'افزودن هزینه',
      );

  String get addTrip => _value(
        en: 'Add Trip',
        es: 'Añadir viaje',
        fr: 'Ajouter un trajet',
        ru: 'Добавить поездку',
        uk: 'Додати поїздку',
        fa: 'افزودن سفر',
      );

  String get from => _value(
        en: 'From',
        es: 'Desde',
        fr: 'De',
        ru: 'Откуда',
        uk: 'Звідки',
        fa: 'از',
      );

  String get to => _value(
        en: 'To',
        es: 'Hasta',
        fr: 'Vers',
        ru: 'Куда',
        uk: 'Куди',
        fa: 'به',
      );

  String get distance => _value(
        en: 'Distance',
        es: 'Distancia',
        fr: 'Distance',
        ru: 'Дистанция',
        uk: 'Дистанція',
        fa: 'مسافت',
      );

  String get category => _value(
        en: 'Category',
        es: 'Categoría',
        fr: 'Catégorie',
        ru: 'Категория',
        uk: 'Категорія',
        fa: 'دسته‌بندی',
      );

  String get business => _value(
        en: 'Business',
        es: 'Trabajo',
        fr: 'Professionnel',
        ru: 'Рабочая',
        uk: 'Робоча',
        fa: 'کاری',
      );

  String get personal => _value(
        en: 'Personal',
        es: 'Personal',
        fr: 'Personnel',
        ru: 'Личная',
        uk: 'Особиста',
        fa: 'شخصی',
      );

  String get saveTrip => _value(
        en: 'Save Trip',
        es: 'Guardar viaje',
        fr: 'Enregistrer',
        ru: 'Сохранить поездку',
        uk: 'Зберегти поїздку',
        fa: 'ذخیره سفر',
      );

  String get thisMonth => _value(
        en: 'This month',
        es: 'Este mes',
        fr: 'Ce mois-ci',
        ru: 'Этот месяц',
        uk: 'Цього місяця',
        fa: 'این ماه',
      );

  String get expenses => _value(
        en: 'Expenses',
        es: 'Gastos',
        fr: 'Dépenses',
        ru: 'Расходы',
        uk: 'Витрати',
        fa: 'هزینه‌ها',
      );

  String get fuelParkingTolls => _value(
        en: 'Fuel, parking, tolls',
        es: 'Combustible, parking, peajes',
        fr: 'Carburant, parking, péages',
        ru: 'Топливо, парковка, платные дороги',
        uk: 'Пальне, паркування, платні дороги',
        fa: 'سوخت، پارکینگ، عوارض',
      );

  String get vehicle => _value(
        en: 'Vehicle',
        es: 'Vehículo',
        fr: 'Véhicule',
        ru: 'Автомобиль',
        uk: 'Авто',
        fa: 'وسیله نقلیه',
      );

  String get units => _value(
        en: 'Units',
        es: 'Unidades',
        fr: 'Unités',
        ru: 'Единицы',
        uk: 'Одиниці',
        fa: 'واحدها',
      );

  String get kilometers => _value(
        en: 'Kilometers',
        es: 'Kilómetros',
        fr: 'Kilomètres',
        ru: 'Километры',
        uk: 'Кілометри',
        fa: 'کیلومتر',
      );

  String get miles => _value(
        en: 'Miles',
        es: 'Millas',
        fr: 'Miles',
        ru: 'Мили',
        uk: 'Милі',
        fa: 'مایل',
      );

  String get languageLabel => _value(
        en: 'Language',
        es: 'Idioma',
        fr: 'Langue',
        ru: 'Язык',
        uk: 'Мова',
        fa: 'زبان',
      );

  String get reimbursementRate => _value(
        en: 'Reimbursement rate',
        es: 'Tarifa de reembolso',
        fr: 'Taux de remboursement',
        ru: 'Ставка компенсации',
        uk: 'Ставка компенсації',
        fa: 'نرخ بازپرداخت',
      );

  String get workShifts => _value(
        en: 'Work Shifts',
        es: 'Turnos de trabajo',
        fr: 'Créneaux de travail',
        ru: 'Рабочие смены',
        uk: 'Робочі зміни',
        fa: 'شیفت‌های کاری',
      );

  String get addShift => _value(
        en: 'Add Shift',
        es: 'Añadir turno',
        fr: 'Ajouter un créneau',
        ru: 'Добавить смену',
        uk: 'Додати зміну',
        fa: 'افزودن شیفت',
      );

  String get noShiftsConfigured => _value(
        en: 'No shifts configured',
        es: 'No hay turnos configurados',
        fr: 'Aucun créneau configuré',
        ru: 'Смены не настроены',
        uk: 'Зміни не налаштовані',
        fa: 'هیچ شیفتی تنظیم نشده',
      );

  String get addShiftToEnableAutoClassification => _value(
        en: 'Add a shift to enable auto-classification',
        es: 'Añade un turno para activar la clasificación automática',
        fr: 'Ajoutez un créneau pour activer la classification automatique',
        ru: 'Добавьте смену, чтобы включить автоклассификацию',
        uk: 'Додайте зміну, щоб увімкнути автоматичну класифікацію',
        fa: 'برای فعال‌سازی دسته‌بندی خودکار یک شیفت اضافه کنید',
      );

  String get enableWorkMode => _value(
        en: 'Enable Work Mode',
        es: 'Activar modo de trabajo',
        fr: 'Activer le mode de travail',
        ru: 'Включить рабочий режим',
        uk: 'Увімкнути робочий режим',
        fa: 'فعال‌سازی حالت کاری',
      );

  String get workModeEnabledDescription => _value(
        en: 'Trips during shifts are auto-classified',
        es: 'Los viajes durante los turnos se clasifican automáticamente',
        fr: 'Les trajets pendant les créneaux sont classés automatiquement',
        ru: 'Поездки во время смен классифицируются автоматически',
        uk: 'Поїздки під час змін класифікуються автоматично',
        fa: 'سفرها در زمان شیفت به‌صورت خودکار دسته‌بندی می‌شوند',
      );

  String get workModeDisabledDescription => _value(
        en: 'All trips will be classified manually',
        es: 'Todos los viajes se clasificarán manualmente',
        fr: 'Tous les trajets seront classés manuellement',
        ru: 'Все поездки будут классифицироваться вручную',
        uk: 'Усі поїздки класифікуватимуться вручну',
        fa: 'همه سفرها به‌صورت دستی دسته‌بندی می‌شوند',
      );

  String get platform => _value(
        en: 'Platform',
        es: 'Plataforma',
        fr: 'Plateforme',
        ru: 'Платформа',
        uk: 'Платформа',
        fa: 'پلتفرم',
      );

  String get shiftHours => _value(
        en: 'Shift hours',
        es: 'Horas del turno',
        fr: 'Heures du créneau',
        ru: 'Часы смены',
        uk: 'Години зміни',
        fa: 'ساعات شیفت',
      );

  String get start => _value(
        en: 'Start',
        es: 'Inicio',
        fr: 'Début',
        ru: 'Начало',
        uk: 'Початок',
        fa: 'شروع',
      );

  String get end => _value(
        en: 'End',
        es: 'Fin',
        fr: 'Fin',
        ru: 'Конец',
        uk: 'Кінець',
        fa: 'پایان',
      );

  String get saveShift => _value(
        en: 'Save Shift',
        es: 'Guardar turno',
        fr: 'Enregistrer le créneau',
        ru: 'Сохранить смену',
        uk: 'Зберегти зміну',
        fa: 'ذخیره شیفت',
      );

  String get customPlatform => _value(
        en: 'Custom platform',
        es: 'Plataforma personalizada',
        fr: 'Plateforme personnalisée',
        ru: 'Своя платформа',
        uk: 'Власна платформа',
        fa: 'پلتفرم سفارشی',
      );

  String get chooseFromPresets => _value(
        en: 'Choose from presets',
        es: 'Elegir de la lista',
        fr: 'Choisir parmi les options',
        ru: 'Выбрать из списка',
        uk: 'Вибрати зі списку',
        fa: 'انتخاب از فهرست',
      );

  String get enterPlatformName => _value(
        en: 'Enter platform name',
        es: 'Introduce el nombre de la plataforma',
        fr: 'Entrez le nom de la plateforme',
        ru: 'Введите название платформы',
        uk: 'Введіть назву платформи',
        fa: 'نام پلتفرم را وارد کنید',
      );

  String get sameStartEndTimeError => _value(
        en: 'Start and end time cannot be the same',
        es: 'La hora de inicio y fin no pueden ser iguales',
        fr: 'L’heure de début et de fin ne peuvent pas être identiques',
        ru: 'Время начала и конца не может совпадать',
        uk: 'Час початку і завершення не може збігатися',
        fa: 'زمان شروع و پایان نمی‌تواند یکسان باشد',
      );

  String _value({
    required String en,
    required String es,
    required String fr,
    required String ru,
    required String uk,
    required String fa,
  }) {
    switch (currentLanguage) {
      case AppLanguage.english:
        return en;
      case AppLanguage.spanish:
        return es;
      case AppLanguage.french:
        return fr;
      case AppLanguage.russian:
        return ru;
      case AppLanguage.ukrainian:
        return uk;
      case AppLanguage.dari:
        return fa;
    }
  }

  String get workMode => _value(
    en: 'Work Mode',
    es: 'Modo de trabajo',
    fr: 'Mode de travail',
    ru: 'Рабочий режим',
    uk: 'Робочий режим',
    fa: 'حالت کاری',
  );

  String get workModeDescription => _value(
    en: 'Auto-classify trips by shift',
    es: 'Clasificación automática por turno',
    fr: 'Classification automatique par horaire',
    ru: 'Авто-классификация поездок по сменам',
    uk: 'Автоматична класифікація поїздок за змінами',
    fa: 'دسته‌بندی خودکار سفرها بر اساس شیفت',
  );
}
