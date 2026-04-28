import '../../app/app.dart';

class AppStrings {
  final AppLanguage currentLanguage;

  const AppStrings(this.currentLanguage);

  // ─── Navigation ───────────────────────────────────────────────────────────

  String get today => _value(
        en: 'Today',        es: 'Hoy',             fr: "Aujourd'hui",
        ru: 'Сегодня',      uk: 'Сьогодні',        fa: 'امروز',
      );

  String get trips => _value(
        en: 'Trips',        es: 'Viajes',           fr: 'Trajets',
        ru: 'Поездки',      uk: 'Поїздки',          fa: 'سفرها',
      );

  String get add => _value(
        en: 'Add',          es: 'Añadir',           fr: 'Ajouter',
        ru: 'Добавить',     uk: 'Додати',           fa: 'افزودن',
      );

  String get reports => _value(
        en: 'Reports',      es: 'Informes',         fr: 'Rapports',
        ru: 'Отчёты',       uk: 'Звіти',            fa: 'گزارش‌ها',
      );

  String get profile => _value(
        en: 'Profile',      es: 'Perfil',           fr: 'Profil',
        ru: 'Профиль',      uk: 'Профіль',          fa: 'پروفایل',
      );

  // ─── Today screen ─────────────────────────────────────────────────────────

  String get todayDistance => _value(
        en: 'Today distance',       es: 'Distancia de hoy',
        fr: 'Distance du jour',     ru: 'Дистанция за сегодня',
        uk: 'Дистанція за сьогодні',fa: 'مسافت امروز',
      );

  String get tripsRecorded => _value(
        en: 'Trips recorded',       es: 'Viajes registrados',
        fr: 'Trajets enregistrés',  ru: 'Поездок записано',
        uk: 'Поїздок записано',     fa: 'سفرهای ثبت شده',
      );

  String get businessTrips => _value(
        en: 'Business trips',       es: 'Viajes de trabajo',
        fr: 'Trajets professionnels',ru: 'Рабочие поездки',
        uk: 'Робочі поїздки',       fa: 'سفرهای کاری',
      );

  String get tripsNeedReview => _value(
        en: '2 trips need review',  es: '2 viajes necesitan revisión',
        fr: '2 trajets à vérifier', ru: '2 поездки требуют проверки',
        uk: '2 поїздки треба перевірити', fa: '۲ سفر نیاز به بررسی دارند',
      );

  String get quickActions => _value(
        en: 'Quick actions',        es: 'Acciones rápidas',
        fr: 'Actions rapides',      ru: 'Быстрые действия',
        uk: 'Швидкі дії',           fa: 'اقدام‌های سریع',
      );

  String get startTrip => _value(
        en: 'Start trip',           es: 'Iniciar viaje',
        fr: 'Démarrer',             ru: 'Начать поездку',
        uk: 'Почати поїздку',       fa: 'شروع سفر',
      );

  String get addManually => _value(
        en: 'Add manually',         es: 'Añadir manualmente',
        fr: 'Ajouter manuellement', ru: 'Добавить вручную',
        uk: 'Додати вручну',        fa: 'افزودن دستی',
      );

  String get addExpense => _value(
        en: 'Add expense',          es: 'Añadir gasto',
        fr: 'Ajouter une dépense',  ru: 'Добавить расход',
        uk: 'Додати витрату',       fa: 'افزودن هزینه',
      );

  // ─── Add trip screen ──────────────────────────────────────────────────────

  String get addTrip => _value(
        en: 'Add Trip',             es: 'Añadir viaje',
        fr: 'Ajouter un trajet',    ru: 'Добавить поездку',
        uk: 'Додати поїздку',       fa: 'افزودن سفر',
      );

  String get from => _value(
        en: 'From',   es: 'Desde',  fr: 'De',
        ru: 'Откуда', uk: 'Звідки', fa: 'از',
      );

  String get to => _value(
        en: 'To',   es: 'Hasta',  fr: 'Vers',
        ru: 'Куда', uk: 'Куди',   fa: 'به',
      );

  String get distance => _value(
        en: 'Distance',     es: 'Distancia',    fr: 'Distance',
        ru: 'Дистанція',    uk: 'Дистанція',    fa: 'مسافت',
      );

  String get category => _value(
        en: 'Category',     es: 'Categoría',    fr: 'Catégorie',
        ru: 'Категория',    uk: 'Категорія',    fa: 'دسته‌بندی',
      );

  String get business => _value(
        en: 'Business',     es: 'Trabajo',      fr: 'Professionnel',
        ru: 'Рабочая',      uk: 'Робоча',       fa: 'کاری',
      );

  String get personal => _value(
        en: 'Personal',     es: 'Personal',     fr: 'Personnel',
        ru: 'Личная',       uk: 'Особиста',     fa: 'شخصی',
      );

  String get saveTripButton => _value(
        en: 'Save Trip',             es: 'Guardar viaje',
        fr: 'Enregistrer le trajet', ru: 'Сохранить поездку',
        uk: 'Зберегти поїздку',      fa: 'ذخیره سفر',
      );

  String get tripSaved => _value(
        en: 'Trip saved',            es: 'Viaje guardado',
        fr: 'Trajet enregistré',     ru: 'Поездка сохранена',
        uk: 'Поїздку збережено',     fa: 'سفر ذخیره شد',
      );

  String get saveTrip => tripSaved;

  String get editTrip => _value(
        en: 'Edit Trip',              es: 'Editar viaje',
        fr: 'Modifier le trajet',     ru: 'Изменить поездку',
        uk: 'Редагувати поїздку',     fa: 'ویرایش سفر',
      );

  String get updateTrip => _value(
        en: 'Update Trip',            es: 'Actualizar viaje',
        fr: 'Mettre à jour le trajet',ru: 'Обновить поездку',
        uk: 'Оновити поїздку',        fa: 'بروزرسانی سفر',
      );

  String get tripUpdated => _value(
        en: 'Trip updated',           es: 'Viaje actualizado',
        fr: 'Trajet mis à jour',      ru: 'Поездка обновлена',
        uk: 'Поїздку оновлено',       fa: 'سفر بروز شد',
      );

  String get deleteTrip => _value(
        en: 'Delete trip',            es: 'Eliminar viaje',
        fr: 'Supprimer le trajet',    ru: 'Удалить поездку',
        uk: 'Видалити поїздку',       fa: 'حذف سفر',
      );

  String get confirmDelete => _value(
        en: 'Delete this trip?',      es: '¿Eliminar este viaje?',
        fr: 'Supprimer ce trajet?',   ru: 'Удалить эту поездку?',
        uk: 'Видалити цю поїздку?',   fa: 'این سفر حذف شود؟',
      );

  String get deleteConfirmMessage => _value(
        en: 'This trip will be permanently deleted.',
        es: 'Este viaje será eliminado permanentemente.',
        fr: 'Ce trajet sera supprimé définitivement.',
        ru: 'Эта поездка будет удалена безвозвратно.',
        uk: 'Цю поїздку буде видалено назавжди.',
        fa: 'این سفر به طور دائمی حذف خواهد شد.',
      );

  String get businessPurpose => _value(
        en: 'Business purpose',     es: 'Propósito de negocio',
        fr: 'Objet professionnel',  ru: 'Цель поездки',
        uk: 'Мета поїздки',         fa: 'هدف تجاری',
      );

  String get notes => _value(
        en: 'Notes',        es: 'Notas',        fr: 'Notes',
        ru: 'Заметки',      uk: 'Нотатки',      fa: 'یادداشت‌ها',
      );

  // ─── Reports screen ───────────────────────────────────────────────────────

  String get thisMonth => _value(
        en: 'This month',   es: 'Este mes',     fr: 'Ce mois-ci',
        ru: 'Этот месяц',   uk: 'Цього місяця', fa: 'این ماه',
      );

  String get lastMonth => _value(
        en: 'Last month',   es: 'Mes pasado',   fr: 'Mois dernier',
        ru: 'Прошлый месяц', uk: 'Минулий місяць', fa: 'ماه گذشته',
      );

  String get customRange => _value(
        en: 'Custom',               es: 'Personalizado',
        fr: 'Personnalisé',         ru: 'Свой период',
        uk: 'Власний',              fa: 'سفارشی',
      );

  String get reportPeriod => _value(
        en: 'Report period',        es: 'Período del informe',
        fr: 'Période du rapport',   ru: 'Период отчёта',
        uk: 'Період звіту',         fa: 'دوره گزارش',
      );

  String get selectDateRange => _value(
        en: 'Select date range',    es: 'Seleccionar período',
        fr: 'Sélectionner la période', ru: 'Выбрать период',
        uk: 'Вибрати діапазон дат', fa: 'انتخاب بازه تاریخ',
      );

  String get periodLabel => _value(
        en: 'Period',   es: 'Período', fr: 'Période',
        ru: 'Период',   uk: 'Період',  fa: 'دوره',
      );

  String get fromDate => _value(
        en: 'From',     es: 'Desde',    fr: 'Du',
        ru: 'С',        uk: 'З',        fa: 'از تاریخ',
      );

  String get toDate => _value(
        en: 'To',       es: 'Hasta',    fr: 'Au',
        ru: 'По',       uk: 'По',       fa: 'تا تاریخ',
      );

  String get expenses => _value(
        en: 'Expenses',     es: 'Gastos',       fr: 'Dépenses',
        ru: 'Расходы',      uk: 'Витрати',      fa: 'هزینه‌ها',
      );

  String get fuelParkingTolls => _value(
        en: 'Fuel, parking, tolls',
        es: 'Combustible, parking, peajes',
        fr: 'Carburant, parking, péages',
        ru: 'Топливо, парковка, платные дороги',
        uk: 'Пальне, паркування, платні дороги',
        fa: 'سوخت، پارکینگ، عوارض',
      );

  String get exportReport => _value(
        en: 'Export Report',            es: 'Exportar informe',
        fr: 'Exporter le rapport',      ru: 'Экспорт отчёта',
        uk: 'Експорт звіту',            fa: 'خروجی گزارش',
      );

  String get exportSimplePdf => _value(
        en: 'Export Simple PDF',        es: 'Exportar PDF simple',
        fr: 'Exporter PDF simple',      ru: 'Экспорт простого PDF',
        uk: 'Експорт простого PDF',     fa: 'خروجی PDF ساده',
      );

  String get exportDetailedPdf => _value(
        en: 'Export Detailed PDF',      es: 'Exportar PDF detallado',
        fr: 'Exporter PDF détaillé',    ru: 'Экспорт подробного PDF',
        uk: 'Експорт детального PDF',   fa: 'خروجی PDF مفصل',
      );

  String get accountantFriendlyReport => _value(
        en: 'Accountant-friendly mileage and expense report.',
        es: 'Informe de kilometraje y gastos para contadores.',
        fr: 'Rapport de kilométrage et de dépenses pour comptables.',
        ru: 'Отчёт о пробеге и расходах для бухгалтера.',
        uk: 'Звіт про пробіг і витрати для бухгалтера.',
        fa: 'گزارش کیلومتراژ و هزینه برای حسابدار.',
      );

  String get exporting => _value(
        en: 'Exporting…',      es: 'Exportando…',
        fr: 'Exportation…',    ru: 'Экспорт…',
        uk: 'Експортування…',  fa: 'در حال خروجی…',
      );

  String get exportFailed => _value(
        en: 'Export failed',        es: 'Error al exportar',
        fr: "Échec de l'export",    ru: 'Ошибка экспорта',
        uk: 'Помилка експорту',     fa: 'خروجی ناموفق',
      );

  String get exportCsv => _value(
        en: 'Export CSV',           es: 'Exportar CSV',
        fr: 'Exporter CSV',         ru: 'Экспорт CSV',
        uk: 'Експорт CSV',          fa: 'خروجی CSV',
      );

  String get csvExportFailed => _value(
        en: 'CSV export failed',        es: 'Error al exportar CSV',
        fr: "Échec de l'export CSV",    ru: 'Ошибка экспорта CSV',
        uk: 'Помилка експорту CSV',     fa: 'خروجی CSV ناموفق',
      );

  // ─── Backup / restore ─────────────────────────────────────────────────────

  String get dataBackup => _value(
        en: 'Data & Backup',            es: 'Datos y copia de seguridad',
        fr: 'Données et sauvegarde',    ru: 'Данные и резервная копия',
        uk: 'Дані та резервна копія',   fa: 'داده‌ها و پشتیبان',
      );

  String get exportBackup => _value(
        en: 'Export Backup',            es: 'Exportar copia de seguridad',
        fr: 'Exporter la sauvegarde',   ru: 'Экспорт резервной копии',
        uk: 'Експорт резервної копії',  fa: 'خروجی پشتیبان',
      );

  String get importBackup => _value(
        en: 'Import Backup',            es: 'Importar copia de seguridad',
        fr: 'Importer la sauvegarde',   ru: 'Импорт резервной копии',
        uk: 'Імпорт резервної копії',   fa: 'وارد کردن پشتیبان',
      );

  String get backupExported => _value(
        en: 'Backup ready to share',            es: 'Copia lista para compartir',
        fr: 'Sauvegarde prête à partager',      ru: 'Резервная копия готова',
        uk: 'Резервна копія готова до надсилання', fa: 'پشتیبان آماده اشتراک',
      );

  String get backupExportFailed => _value(
        en: 'Backup export failed',         es: 'Error al exportar copia',
        fr: 'Échec de l\'export sauvegarde',ru: 'Ошибка экспорта копии',
        uk: 'Помилка експорту копії',       fa: 'خروجی پشتیبان ناموفق',
      );

  String get backupImportConfirmTitle => _value(
        en: 'Import backup?',               es: '¿Importar copia de seguridad?',
        fr: 'Importer la sauvegarde?',      ru: 'Импортировать резервную копию?',
        uk: 'Імпортувати резервну копію?',  fa: 'وارد کردن پشتیبان؟',
      );

  String get backupImportConfirmMessage => _value(
        en: 'Importing a backup will replace all your current trips, preferences, and work mode settings.',
        es: 'Importar una copia reemplazará todos tus viajes, preferencias y configuración de modo trabajo.',
        fr: 'Importer une sauvegarde remplacera tous vos trajets, préférences et paramètres de travail.',
        ru: 'Импорт резервной копии заменит все поездки, настройки и параметры рабочего режима.',
        uk: 'Імпорт резервної копії замінить усі поїздки, налаштування та параметри робочого режиму.',
        fa: 'وارد کردن پشتیبان، تمام سفرها، تنظیمات و حالت کاری فعلی شما را جایگزین می‌کند.',
      );

  String get backupImported => _value(
        en: 'Backup restored successfully', es: 'Copia restaurada correctamente',
        fr: 'Sauvegarde restaurée',         ru: 'Резервная копия восстановлена',
        uk: 'Резервну копію відновлено',    fa: 'پشتیبان با موفقیت بازیابی شد',
      );

  String get backupImportFailed => _value(
        en: 'Backup import failed',         es: 'Error al importar copia',
        fr: 'Échec de l\'import sauvegarde',ru: 'Ошибка импорта копии',
        uk: 'Помилка імпорту копії',        fa: 'وارد کردن پشتیبان ناموفق',
      );

  // ─── Profile screen ───────────────────────────────────────────────────────

  String get driverName => _value(
        en: 'Driver name',          es: 'Nombre del conductor',
        fr: 'Nom du conducteur',    ru: 'Имя водителя',
        uk: "Ім'я водія",           fa: 'نام راننده',
      );

  String get businessName => _value(
        en: 'Business name',        es: 'Nombre del negocio',
        fr: "Nom de l'entreprise",  ru: 'Название компании',
        uk: 'Назва компанії',       fa: 'نام کسب‌وکار',
      );

  String get vehicle => _value(
        en: 'Vehicle',      es: 'Vehículo',     fr: 'Véhicule',
        ru: 'Автомобиль',   uk: 'Авто',         fa: 'وسیله نقلیه',
      );

  String get editProfileInfo => _value(
        en: 'Report identity',              es: 'Identidad del informe',
        fr: 'Identité du rapport',          ru: 'Данные отчёта',
        uk: 'Дані звіту',                   fa: 'هویت گزارش',
      );

  String get save => _value(
        en: 'Save',     es: 'Guardar',  fr: 'Enregistrer',
        ru: 'Сохранить',uk: 'Зберегти', fa: 'ذخیره',
      );

  String get profileSaved => _value(
        en: 'Profile saved',            es: 'Perfil guardado',
        fr: 'Profil enregistré',        ru: 'Профиль сохранён',
        uk: 'Профіль збережено',        fa: 'پروفایل ذخیره شد',
      );

  String get units => _value(
        en: 'Units',        es: 'Unidades',     fr: 'Unités',
        ru: 'Единицы',      uk: 'Одиниці',      fa: 'واحدها',
      );

  String get kilometers => _value(
        en: 'Kilometers',   es: 'Kilómetros',   fr: 'Kilomètres',
        ru: 'Километры',    uk: 'Кілометри',    fa: 'کیلومتر',
      );

  String get miles => _value(
        en: 'Miles',        es: 'Millas',       fr: 'Miles',
        ru: 'Мили',         uk: 'Милі',         fa: 'مایل',
      );

  String get languageLabel => _value(
        en: 'Language',     es: 'Idioma',       fr: 'Langue',
        ru: 'Язык',         uk: 'Мова',         fa: 'زبان',
      );

  String get reimbursementRate => _value(
        en: 'Reimbursement rate',       es: 'Tarifa de reembolso',
        fr: 'Taux de remboursement',    ru: 'Ставка компенсации',
        uk: 'Ставка компенсації',       fa: 'نرخ بازپرداخت',
      );

  String get currencyLabel => _value(
        en: 'Currency',     es: 'Moneda',       fr: 'Devise',
        ru: 'Валюта',       uk: 'Валюта',       fa: 'ارز',
      );

  String get autoClassifyTrips => _value(
        en: 'Auto-classify trips by shift',
        es: 'Clasificar viajes automáticamente',
        fr: 'Classer les trajets automatiquement',
        ru: 'Авто-классификация поездок по смене',
        uk: 'Авто-класифікація поїздок за зміною',
        fa: 'طبقه‌بندی خودکار سفرها بر اساس شیفت',
      );

  // ─── Work Mode screen ─────────────────────────────────────────────────────

  String get workMode => _value(
        en: 'Work Mode',            es: 'Modo trabajo',
        fr: 'Mode travail',         ru: 'Рабочий режим',
        uk: 'Робочий режим',        fa: 'حالت کاری',
      );

  String get enableWorkMode => _value(
        en: 'Enable Work Mode',     es: 'Activar modo trabajo',
        fr: 'Activer mode travail', ru: 'Включить рабочий режим',
        uk: 'Увімкнути робочий режим', fa: 'فعال کردن حالت کاری',
      );

  String get tripsDuringShiftsAutoClassified => _value(
        en: 'Trips during shifts are auto-classified',
        es: 'Los viajes durante los turnos se clasifican automáticamente',
        fr: 'Les trajets pendant les quarts sont classés automatiquement',
        ru: 'Поездки во время смен классифицируются автоматически',
        uk: 'Поїздки під час змін класифікуються автоматично',
        fa: 'سفرها در طول شیفت به صورت خودکار طبقه‌بندی می‌شوند',
      );

  String get allTripsClassifiedManually => _value(
        en: 'All trips will be classified manually',
        es: 'Todos los viajes se clasificarán manualmente',
        fr: 'Tous les trajets seront classés manuellement',
        ru: 'Все поездки будут классифицированы вручную',
        uk: 'Усі поїздки будуть класифіковані вручну',
        fa: 'همه سفرها به صورت دستی طبقه‌بندی می‌شوند',
      );

  String get workShifts => _value(
        en: 'Work Shifts',          es: 'Turnos de trabajo',
        fr: 'Quarts de travail',    ru: 'Рабочие смены',
        uk: 'Робочі зміни',         fa: 'شیفت‌های کاری',
      );

  /// Used in the counter label: "3 configured"
  String get configured => _value(
        en: 'configured',       es: 'configurados',
        fr: 'configurés',       ru: 'настроено',
        uk: 'налаштовано',      fa: 'پیکربندی شده',
      );

  String get noShiftsConfigured => _value(
        en: 'No shifts configured',
        es: 'No hay turnos configurados',
        fr: 'Aucun quart configuré',
        ru: 'Нет настроенных смен',
        uk: 'Немає налаштованих змін',
        fa: 'هیچ شیفتی پیکربندی نشده',
      );

  String get addShiftToEnableAutoClassification => _value(
        en: 'Add a shift to enable auto-classification',
        es: 'Añade un turno para activar la clasificación automática',
        fr: 'Ajoutez un quart pour activer la classification automatique',
        ru: 'Добавьте смену для включения авто-классификации',
        uk: 'Додайте зміну для увімкнення авто-класифікації',
        fa: 'یک شیفت اضافه کنید تا طبقه‌بندی خودکار فعال شود',
      );

  String get removeShift => _value(
        en: 'Remove shift',         es: 'Eliminar turno',
        fr: 'Supprimer le quart',   ru: 'Удалить смену',
        uk: 'Видалити зміну',       fa: 'حذف شیفت',
      );

  String get addShift => _value(
        en: 'Add Shift',            es: 'Añadir turno',
        fr: 'Ajouter un quart',     ru: 'Добавить смену',
        uk: 'Додати зміну',         fa: 'افزودن شیفت',
      );

  String get addWorkShift => _value(
        en: 'Add Work Shift',       es: 'Añadir turno de trabajo',
        fr: 'Ajouter un quart de travail', ru: 'Добавить рабочую смену',
        uk: 'Додати робочу зміну',  fa: 'افزودن شیفت کاری',
      );

  String get platform => _value(
        en: 'Platform',     es: 'Plataforma',   fr: 'Plateforme',
        ru: 'Платформа',    uk: 'Платформа',    fa: 'پلتفرم',
      );

  String get chooseFromPresets => _value(
        en: '← Choose from presets',
        es: '← Elegir de opciones',
        fr: '← Choisir parmi les options',
        ru: '← Выбрать из вариантов',
        uk: '← Обрати з варіантів',
        fa: '← انتخاب از پیش‌تنظیمات',
      );

  String get customPlatform => _value(
        en: '+ Custom platform',        es: '+ Plataforma personalizada',
        fr: '+ Plateforme personnalisée',ru: '+ Своя платформа',
        uk: '+ Власна платформа',        fa: '+ پلتفرم سفارشی',
      );

  String get shiftHours => _value(
        en: 'Shift hours',          es: 'Horas de turno',
        fr: 'Heures de quart',      ru: 'Часы смены',
        uk: 'Години зміни',         fa: 'ساعات شیفت',
      );

  String get start => _value(
        en: 'Start',    es: 'Inicio',   fr: 'Début',
        ru: 'Начало',   uk: 'Початок',  fa: 'شروع',
      );

  String get end => _value(
        en: 'End',      es: 'Fin',      fr: 'Fin',
        ru: 'Конец',    uk: 'Кінець',   fa: 'پایان',
      );

  String get expensesOptional => _value(
        en: 'Expenses (optional)',       es: 'Gastos (opcional)',
        fr: 'Dépenses (facultatif)',     ru: 'Расходы (необязательно)',
        uk: 'Витрати (необов\'язково)',  fa: 'هزینه‌ها (اختیاری)',
      );

  String get saveShift => _value(
        en: 'Save Shift',           es: 'Guardar turno',
        fr: 'Enregistrer le quart', ru: 'Сохранить смену',
        uk: 'Зберегти зміну',       fa: 'ذخیره شیفت',
      );

  String get workModeActiveTripBusiness => _value(
        en: 'Work Mode is active. This trip will be saved as Business.',
        es: 'Modo trabajo activo. Este viaje se guardará como Trabajo.',
        fr: 'Mode travail actif. Ce trajet sera enregistré comme Professionnel.',
        ru: 'Рабочий режим активен. Поездка будет сохранена как Рабочая.',
        uk: 'Робочий режим активний. Поїздка буде збережена як Робоча.',
        fa: 'حالت کاری فعال است. این سفر به عنوان کاری ذخیره خواهد شد.',
      );

  // ─── Automation / Auto Trip Detection ────────────────────────────────────

  String get automation => _value(
        en: 'Automation',           es: 'Automatización',
        fr: 'Automatisation',       ru: 'Автоматизация',
        uk: 'Автоматизація',        fa: 'اتوماسیون',
      );

  String get autoTripDetection => _value(
        en: 'Auto Trip Detection',          es: 'Detección automática de viajes',
        fr: 'Détection automatique',        ru: 'Авто-определение поездок',
        uk: 'Авто-виявлення поїздок',       fa: 'تشخیص خودکار سفر',
      );

  String get autoTripDetectionDescription => _value(
        en: 'Route Mint can detect potential trips and ask you to review them.',
        es: 'Route Mint puede detectar viajes potenciales y pedirte que los revises.',
        fr: 'Route Mint peut détecter des trajets potentiels et vous demander de les examiner.',
        ru: 'Route Mint может обнаруживать возможные поездки и предлагать вам их проверить.',
        uk: 'Route Mint може виявляти можливі поїздки та пропонувати вам їх перевірити.',
        fa: 'Route Mint می‌تواند سفرهای احتمالی را شناسایی کرده و از شما بخواهد آن‌ها را بررسی کنید.',
      );

  String get needsReview => _value(
        en: 'Needs review',         es: 'Requiere revisión',
        fr: 'À vérifier',          ru: 'Требует проверки',
        uk: 'Потребує перевірки',   fa: 'نیاز به بررسی',
      );

  String get reviewed => _value(
        en: 'Reviewed',             es: 'Revisado',
        fr: 'Vérifié',             ru: 'Проверено',
        uk: 'Перевірено',          fa: 'بررسی شده',
      );

  String get detectionMode => _value(
        en: 'Detection mode',       es: 'Modo de detección',
        fr: 'Mode de détection',    ru: 'Режим определения',
        uk: 'Режим виявлення',      fa: 'حالت تشخیص',
      );

  String get manual => _value(
        en: 'Manual',               es: 'Manual',
        fr: 'Manuel',               ru: 'Вручную',
        uk: 'Вручну',               fa: 'دستی',
      );

  String get automatic => _value(
        en: 'Automatic',            es: 'Automático',
        fr: 'Automatique',          ru: 'Автоматически',
        uk: 'Автоматично',          fa: 'خودکار',
      );

  // ─── Foreground Auto Tracking ─────────────────────────────────────────────

  String get foregroundTracking => _value(
        en: 'Foreground Auto Tracking',
        es: 'Seguimiento automático',
        fr: 'Suivi automatique',
        ru: 'Авто-отслеживание',
        uk: 'Авто-відстеження',
        fa: 'ردیابی خودکار',
      );

  String get startTracking => _value(
        en: 'Start Tracking',
        es: 'Iniciar seguimiento',
        fr: 'Démarrer le suivi',
        ru: 'Начать отслеживание',
        uk: 'Почати відстеження',
        fa: 'شروع ردیابی',
      );

  String get stopTracking => _value(
        en: 'Stop Tracking',
        es: 'Detener seguimiento',
        fr: 'Arrêter le suivi',
        ru: 'Остановить',
        uk: 'Зупинити',
        fa: 'توقف ردیابی',
      );

  String get trackingKeepAppOpen => _value(
        en: 'Tracking… keep the app open',
        es: 'Rastreando… mantén la app abierta',
        fr: "Suivi… gardez l'app ouverte",
        ru: 'Отслеживание… держите приложение открытым',
        uk: 'Відстеження… тримайте додаток відкритим',
        fa: 'در حال ردیابی… برنامه را باز نگه دارید',
      );

  String get notTracking => _value(
        en: 'Not tracking',
        es: 'Sin rastreo',
        fr: 'Pas de suivi',
        ru: 'Не отслеживается',
        uk: 'Не відстежується',
        fa: 'بدون ردیابی',
      );

  String get locationPermissionRequired => _value(
        en: 'Location permission required',
        es: 'Se requiere permiso de ubicación',
        fr: 'Permission de localisation requise',
        ru: 'Требуется разрешение на геолокацию',
        uk: 'Потрібен дозвіл на геолокацію',
        fa: 'مجوز موقعیت مکانی لازم است',
      );

  String get locationServicesDisabled => _value(
        en: 'Location services disabled',
        es: 'Servicios de ubicación desactivados',
        fr: 'Services de localisation désactivés',
        ru: 'Службы геолокации отключены',
        uk: 'Служби геолокації вимкнено',
        fa: 'سرویس‌های موقعیت‌یابی غیرفعال است',
      );

  String get notEnoughMovementDetected => _value(
        en: 'Not enough movement detected',
        es: 'Movimiento insuficiente detectado',
        fr: 'Mouvement insuffisant détecté',
        ru: 'Недостаточно движения',
        uk: 'Недостатньо руху',
        fa: 'حرکت کافی شناسایی نشد',
      );

  String get detectedTripSavedForReview => _value(
        en: 'Detected trip saved for review',
        es: 'Viaje detectado guardado para revisión',
        fr: 'Trajet détecté enregistré pour vérification',
        ru: 'Обнаруженная поездка сохранена для проверки',
        uk: 'Виявлену поїздку збережено для перевірки',
        fa: 'سفر شناسایی شده برای بررسی ذخیره شد',
      );

  String get enableAutoDetectionFirst => _value(
        en: 'Enable Auto Trip Detection in Profile first',
        es: 'Activa la detección automática en Perfil primero',
        fr: "Activez la détection automatique dans Profil d'abord",
        ru: 'Сначала включите Авто-определение поездок в Профиле',
        uk: 'Спочатку увімкніть Авто-виявлення поїздок у Профілі',
        fa: 'ابتدا تشخیص خودکار سفر را در پروفایل فعال کنید',
      );

  String get detectedStart => _value(
        en: 'Detected start',
        es: 'Inicio detectado',
        fr: 'Départ détecté',
        ru: 'Определённое начало',
        uk: 'Виявлений старт',
        fa: 'شروع شناسایی شده',
      );

  String get detectedEnd => _value(
        en: 'Detected end',
        es: 'Fin detectado',
        fr: 'Arrivée détectée',
        ru: 'Определённый конец',
        uk: 'Виявлений кінець',
        fa: 'پایان شناسایی شده',
      );

  String get workModeOverridesCategory => _value(
        en: 'Work Mode overrides your category selection.',
        es: 'El modo trabajo reemplaza tu selección de categoría.',
        fr: 'Le mode travail remplace votre sélection de catégorie.',
        ru: 'Рабочий режим заменяет выбранную категорию.',
        uk: 'Робочий режим замінює обрану категорію.',
        fa: 'حالت کاری انتخاب دسته‌بندی شما را نادیده می‌گیرد.',
      );

  // ─── Shared / common ──────────────────────────────────────────────────────

  String get fuel => _value(
        en: 'Fuel',         es: 'Combustible',  fr: 'Carburant',
        ru: 'Топливо',      uk: 'Пальне',       fa: 'سوخت',
      );

  String get parking => _value(
        en: 'Parking',      es: 'Estacionamiento', fr: 'Stationnement',
        ru: 'Парковка',     uk: 'Паркування',      fa: 'پارکینگ',
      );

  String get tolls => _value(
        en: 'Tolls',                es: 'Peajes',
        fr: 'Péages',               ru: 'Платные дороги',
        uk: 'Платні дороги',        fa: 'عوارض',
      );

  String get totalExpenses => _value(
        en: 'Total expenses',       es: 'Gastos totales',
        fr: 'Dépenses totales',     ru: 'Итого расходов',
        uk: 'Загальні витрати',     fa: 'مجموع هزینه‌ها',
      );

  String get optional => _value(
        en: 'optional',         es: 'opcional',
        fr: 'facultatif',       ru: 'необязательно',
        uk: "необов'язково",    fa: 'اختیاری',
      );

  String get fillRequiredFields => _value(
        en: 'Please fill in all required fields',
        es: 'Por favor completa todos los campos requeridos',
        fr: 'Veuillez remplir tous les champs obligatoires',
        ru: 'Пожалуйста, заполните все обязательные поля',
        uk: "Будь ласка, заповніть усі обов'язкові поля",
        fa: 'لطفاً تمام فیلدهای الزامی را پر کنید',
      );

  String get distanceMustBePositive => _value(
        en: 'Distance must be greater than 0',
        es: 'La distancia debe ser mayor que 0',
        fr: 'La distance doit être supérieure à 0',
        ru: 'Расстояние должно быть больше 0',
        uk: 'Відстань має бути більше 0',
        fa: 'مسافت باید بیشتر از ۰ باشد',
      );

  String get cancel => _value(
        en: 'Cancel',   es: 'Cancelar', fr: 'Annuler',
        ru: 'Отмена',   uk: 'Скасувати',fa: 'لغو',
      );

  String get delete => _value(
        en: 'Delete',   es: 'Eliminar', fr: 'Supprimer',
        ru: 'Удалить',  uk: 'Видалити', fa: 'حذف',
      );

  String get all => _value(
        en: 'All',      es: 'Todos',    fr: 'Tout',
        ru: 'Все',      uk: 'Усі',      fa: 'همه',
      );

  String get edit => _value(
        en: 'Edit',     es: 'Editar',   fr: 'Modifier',
        ru: 'Изменить', uk: 'Редагувати',fa: 'ویرایش',
      );

  String get noTripsFound => _value(
        en: 'No trips found',               es: 'No se encontraron viajes',
        fr: 'Aucun trajet trouvé',          ru: 'Поездок не найдено',
        uk: 'Поїздок не знайдено',          fa: 'سفری یافت نشد',
      );

  String get tryChangingFilters => _value(
        en: 'Try changing the filters',     es: 'Intenta cambiar los filtros',
        fr: 'Essayez de modifier les filtres', ru: 'Попробуйте изменить фильтры',
        uk: 'Спробуйте змінити фільтри',    fa: 'فیلترها را تغییر دهید',
      );


  // ─── Onboarding ───────────────────────────────────────────────────────────

  String get welcomeToRouteMint => _value(
        en: 'Welcome to Route Mint',
        es: 'Bienvenido a Route Mint',
        fr: 'Bienvenue sur Route Mint',
        ru: 'Добро пожаловать в Route Mint',
        uk: 'Ласкаво просимо до Route Mint',
        fa: 'به Route Mint خوش آمدید',
      );

  String get chooseYourCountry => _value(
        en: 'Choose your country',
        es: 'Elige tu país',
        fr: 'Choisissez votre pays',
        ru: 'Выберите страну',
        uk: 'Оберіть країну',
        fa: 'کشور خود را انتخاب کنید',
      );

  String get unitedStates => _value(
        en: 'United States',
        es: 'Estados Unidos',
        fr: 'États-Unis',
        ru: 'США',
        uk: 'США',
        fa: 'ایالات متحده',
      );

  String get canada => _value(
        en: 'Canada',
        es: 'Canadá',
        fr: 'Canada',
        ru: 'Канада',
        uk: 'Канада',
        fa: 'کانادا',
      );

  String get chooseDistanceUnit => _value(
        en: 'Choose distance unit',
        es: 'Elige la unidad de distancia',
        fr: "Choisissez l'unité de distance",
        ru: 'Выберите единицу расстояния',
        uk: 'Оберіть одиницю відстані',
        fa: 'واحد مسافت را انتخاب کنید',
      );

  String get addYourFirstShift => _value(
        en: 'Add your first shift',
        es: 'Añade tu primer turno',
        fr: 'Ajoutez votre premier quart',
        ru: 'Добавьте первую смену',
        uk: 'Додайте першу зміну',
        fa: 'اولین شیفت خود را اضافه کنید',
      );

  String get addShiftDescription => _value(
        en: 'Set up your work schedule to auto-classify trips.',
        es: 'Configura tu horario de trabajo para clasificar viajes automáticamente.',
        fr: 'Configurez votre horaire pour classer les trajets automatiquement.',
        ru: 'Настройте расписание для автоматической классификации поездок.',
        uk: 'Налаштуйте розклад для автоматичної класифікації поїздок.',
        fa: 'برنامه کاری خود را تنظیم کنید تا سفرها به‌طور خودکار طبقه‌بندی شوند.',
      );

  String get skipForNow => _value(
        en: 'Skip for now',
        es: 'Omitir por ahora',
        fr: "Ignorer pour l'instant",
        ru: 'Пропустить',
        uk: 'Пропустити',
        fa: 'فعلاً رد کنید',
      );

  String get next => _value(
        en: 'Next',
        es: 'Siguiente',
        fr: 'Suivant',
        ru: 'Далее',
        uk: 'Далі',
        fa: 'بعدی',
      );

  String get getStarted => _value(
        en: 'Get Started',
        es: 'Comenzar',
        fr: 'Commencer',
        ru: 'Начать',
        uk: 'Розпочати',
        fa: 'شروع کنید',
      );

  String get countryLabel => _value(
        en: 'Country',
        es: 'País',
        fr: 'Pays',
        ru: 'Страна',
        uk: 'Країна',
        fa: 'کشور',
      );

  String get usdCurrency => _value(
        en: 'USD – US Dollar',
        es: 'USD – Dólar estadounidense',
        fr: 'USD – Dollar américain',
        ru: 'USD – Доллар США',
        uk: 'USD – Долар США',
        fa: 'USD – دلار آمریکا',
      );

  String get recommendedByCountry => _value(
        en: 'Recommended based on your country. You can change this anytime.',
        es: 'Recomendado según tu país. Puedes cambiarlo en cualquier momento.',
        fr: 'Recommandé selon votre pays. Vous pouvez le modifier à tout moment.',
        ru: 'Рекомендуется для вашей страны. Вы можете изменить это в любое время.',
        uk: 'Рекомендовано для вашої країни. Ви можете змінити це будь-коли.',
        fa: 'بر اساس کشور شما توصیه می‌شود. می‌توانید آن را هر زمان تغییر دهید.',
      );

  String get cadCurrency => _value(
        en: 'CAD – Canadian Dollar',
        es: 'CAD – Dólar canadiense',
        fr: 'CAD – Dollar canadien',
        ru: 'CAD – Канадский доллар',
        uk: 'CAD – Канадський долар',
        fa: 'CAD – دلار کانادا',
      );

  String get usaRate => _value(
        en: 'USA rate',       es: 'Tasa EE.UU.',
        fr: 'Taux USA',       ru: 'Ставка США',
        uk: 'Ставка США',     fa: 'نرخ آمریکا',
      );

  String get canadaRate => _value(
        en: 'Canada rate',    es: 'Tasa Canadá',
        fr: 'Taux Canada',    ru: 'Ставка Канады',
        uk: 'Ставка Канади',  fa: 'نرخ کانادا',
      );

  String get tripsLabel => _value(
        en: 'trips',          es: 'viajes',
        fr: 'trajets',        ru: 'поездок',
        uk: 'поїздок',        fa: 'سفر',
      );

  String get taxSavingsToday => _value(
        en: 'Tax savings today',             es: 'Ahorro fiscal hoy',
        fr: "Économies fiscales aujourd'hui", ru: 'Налоговая экономия сегодня',
        uk: 'Податкова економія сьогодні',   fa: 'صرفه‌جویی مالیاتی امروز',
      );

  String get errorLoadingTrips => _value(
        en: 'Error loading trips',           es: 'Error al cargar viajes',
        fr: 'Erreur de chargement',          ru: 'Ошибка загрузки поездок',
        uk: 'Помилка завантаження поїздок',  fa: 'خطا در بارگذاری سفرها',
      );

  String get noTripsYet => _value(
        en: 'No trips yet',                  es: 'Sin viajes aún',
        fr: "Aucun trajet pour l'instant",   ru: 'Поездок пока нет',
        uk: 'Поїздок ще немає',              fa: 'هنوز سفری وجود ندارد',
      );

  // ─── Internal ─────────────────────────────────────────────────────────────

  String _value({
    required String en, required String es, required String fr,
    required String ru, required String uk, required String fa,
  }) {
    switch (currentLanguage) {
      case AppLanguage.english:   return en;
      case AppLanguage.spanish:   return es;
      case AppLanguage.french:    return fr;
      case AppLanguage.russian:   return ru;
      case AppLanguage.ukrainian: return uk;
      case AppLanguage.dari:      return fa;
    }
  }
}
