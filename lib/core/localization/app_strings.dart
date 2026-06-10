import '../../app/app.dart';

class AppStrings {
  final AppLanguage currentLanguage;

  const AppStrings(this.currentLanguage);

  // ─── Navigation ───────────────────────────────────────────────────────────

  String get today => _value(
    en: 'Today',
    es: 'Hoy',
    fr: "Aujourd'hui",
    ru: 'Сегодня',
    uk: 'Сьогодні',
    fa: 'امروز',
  );

  String get home => _value(
    en: 'Home',
    es: 'Inicio',
    fr: 'Accueil',
    ru: 'Главная',
    uk: 'Головна',
    fa: 'خانه',
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

  // ─── Today screen ─────────────────────────────────────────────────────────

  String get todayDistance => _value(
    en: 'Today distance',
    es: 'Distancia de hoy',
    fr: 'Distance du jour',
    ru: 'Дистанция за сегодня',
    uk: 'Дистанція за сьогодні',
    fa: 'مسافت امروز',
  );

  String get tripsRecorded => _value(
    en: 'Trips recorded',
    es: 'Viajes registrados',
    fr: 'Trajets enregistrés',
    ru: 'Поездок записано',
    uk: 'Поїздок записано',
    fa: 'سفرهای ثبت شده',
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

  String get expenseType => _value(
    en: 'Expense type',
    es: 'Tipo de gasto',
    fr: 'Type de dépense',
    ru: 'Тип расхода',
    uk: 'Тип витрати',
    fa: 'نوع هزینه',
  );

  String get amount => _value(
    en: 'Amount',
    es: 'Importe',
    fr: 'Montant',
    ru: 'Сумма',
    uk: 'Сума',
    fa: 'مبلغ',
  );

  String get vendor => _value(
    en: 'Vendor',
    es: 'Proveedor',
    fr: 'Fournisseur',
    ru: 'Продавец',
    uk: 'Продавець',
    fa: 'فروشنده',
  );

  String get repair => _value(
    en: 'Repair',
    es: 'Reparación',
    fr: 'Réparation',
    ru: 'Ремонт',
    uk: 'Ремонт',
    fa: 'تعمیر',
  );

  String get serviceExpense => _value(
    en: 'Service',
    es: 'Servicio',
    fr: 'Service',
    ru: 'Сервис',
    uk: 'Сервіс',
    fa: 'سرویس',
  );

  String get saveExpense => _value(
    en: 'Save expense',
    es: 'Guardar gasto',
    fr: 'Enregistrer la dépense',
    ru: 'Сохранить расход',
    uk: 'Зберегти витрату',
    fa: 'ذخیره هزینه',
  );

  String get expenseSaved => _value(
    en: 'Expense saved',
    es: 'Gasto guardado',
    fr: 'Dépense enregistrée',
    ru: 'Расход сохранён',
    uk: 'Витрату збережено',
    fa: 'هزینه ذخیره شد',
  );

  String get recentExpenses => _value(
    en: 'Recent expenses',
    es: 'Gastos recientes',
    fr: 'Dépenses récentes',
    ru: 'Недавние расходы',
    uk: 'Останні витрати',
    fa: 'هزینه‌های اخیر',
  );

  String get noExpenses => _value(
    en: 'No expenses yet',
    es: 'Aún no hay gastos',
    fr: 'Aucune dépense pour le moment',
    ru: 'Расходов пока нет',
    uk: 'Витрат ще немає',
    fa: 'هنوز هزینه‌ای وجود ندارد',
  );

  String get expenseAmountMustBePositive => _value(
    en: 'Expense amount must be greater than 0',
    es: 'El importe debe ser mayor que 0',
    fr: 'Le montant doit être supérieur à 0',
    ru: 'Сумма расхода должна быть больше 0',
    uk: 'Сума витрати має бути більшою за 0',
    fa: 'مبلغ هزینه باید بیشتر از ۰ باشد',
  );

  // ─── Add trip screen ──────────────────────────────────────────────────────

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
    ru: 'Дистанція',
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

  String get saveTripButton => _value(
    en: 'Save Trip',
    es: 'Guardar viaje',
    fr: 'Enregistrer le trajet',
    ru: 'Сохранить поездку',
    uk: 'Зберегти поїздку',
    fa: 'ذخیره سفر',
  );

  String get tripSaved => _value(
    en: 'Trip saved',
    es: 'Viaje guardado',
    fr: 'Trajet enregistré',
    ru: 'Поездка сохранена',
    uk: 'Поїздку збережено',
    fa: 'سفر ذخیره شد',
  );

  String get saveTrip => tripSaved;

  String get editTrip => _value(
    en: 'Edit Trip',
    es: 'Editar viaje',
    fr: 'Modifier le trajet',
    ru: 'Изменить поездку',
    uk: 'Редагувати поїздку',
    fa: 'ویرایش سفر',
  );

  String get updateTrip => _value(
    en: 'Update Trip',
    es: 'Actualizar viaje',
    fr: 'Mettre à jour le trajet',
    ru: 'Обновить поездку',
    uk: 'Оновити поїздку',
    fa: 'بروزرسانی سفر',
  );

  String get tripUpdated => _value(
    en: 'Trip updated',
    es: 'Viaje actualizado',
    fr: 'Trajet mis à jour',
    ru: 'Поездка обновлена',
    uk: 'Поїздку оновлено',
    fa: 'سفر بروز شد',
  );

  String get deleteTrip => _value(
    en: 'Delete trip',
    es: 'Eliminar viaje',
    fr: 'Supprimer le trajet',
    ru: 'Удалить поездку',
    uk: 'Видалити поїздку',
    fa: 'حذف سفر',
  );

  String get confirmDelete => _value(
    en: 'Delete this trip?',
    es: '¿Eliminar este viaje?',
    fr: 'Supprimer ce trajet?',
    ru: 'Удалить эту поездку?',
    uk: 'Видалити цю поїздку?',
    fa: 'این سفر حذف شود؟',
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
    en: 'Business purpose',
    es: 'Propósito de negocio',
    fr: 'Objet professionnel',
    ru: 'Цель поездки',
    uk: 'Мета поїздки',
    fa: 'هدف تجاری',
  );

  String get notes => _value(
    en: 'Notes',
    es: 'Notas',
    fr: 'Notes',
    ru: 'Заметки',
    uk: 'Нотатки',
    fa: 'یادداشت‌ها',
  );

  // ─── Reports screen ───────────────────────────────────────────────────────

  String get thisMonth => _value(
    en: 'This month',
    es: 'Este mes',
    fr: 'Ce mois-ci',
    ru: 'Этот месяц',
    uk: 'Цього місяця',
    fa: 'این ماه',
  );

  String get thisWeek => _value(
    en: 'This week',
    es: 'Esta semana',
    fr: 'Cette semaine',
    ru: 'Эта неделя',
    uk: 'Цього тижня',
    fa: 'این هفته',
  );

  String get thisYear => _value(
    en: 'This year',
    es: 'Este año',
    fr: 'Cette année',
    ru: 'Этот год',
    uk: 'Цього року',
    fa: 'این سال',
  );

  String get lastMonth => _value(
    en: 'Last month',
    es: 'Mes pasado',
    fr: 'Mois dernier',
    ru: 'Прошлый месяц',
    uk: 'Минулий місяць',
    fa: 'ماه گذشته',
  );

  String get customRange => _value(
    en: 'Custom',
    es: 'Personalizado',
    fr: 'Personnalisé',
    ru: 'Свой период',
    uk: 'Власний',
    fa: 'سفارشی',
  );

  String get reportPeriod => _value(
    en: 'Report period',
    es: 'Período del informe',
    fr: 'Période du rapport',
    ru: 'Период отчёта',
    uk: 'Період звіту',
    fa: 'دوره گزارش',
  );

  String get selectDateRange => _value(
    en: 'Select date range',
    es: 'Seleccionar período',
    fr: 'Sélectionner la période',
    ru: 'Выбрать период',
    uk: 'Вибрати діапазон дат',
    fa: 'انتخاب بازه تاریخ',
  );

  String get periodLabel => _value(
    en: 'Period',
    es: 'Período',
    fr: 'Période',
    ru: 'Период',
    uk: 'Період',
    fa: 'دوره',
  );

  String get fromDate => _value(
    en: 'From',
    es: 'Desde',
    fr: 'Du',
    ru: 'С',
    uk: 'З',
    fa: 'از تاریخ',
  );

  String get toDate => _value(
    en: 'To',
    es: 'Hasta',
    fr: 'Au',
    ru: 'По',
    uk: 'По',
    fa: 'تا تاریخ',
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

  String get exportReport => _value(
    en: 'Export Report',
    es: 'Exportar informe',
    fr: 'Exporter le rapport',
    ru: 'Экспорт отчёта',
    uk: 'Експорт звіту',
    fa: 'خروجی گزارش',
  );

  String get exportSimplePdf => _value(
    en: 'Export Simple PDF',
    es: 'Exportar PDF simple',
    fr: 'Exporter PDF simple',
    ru: 'Экспорт простого PDF',
    uk: 'Експорт простого PDF',
    fa: 'خروجی PDF ساده',
  );

  String get exportDetailedPdf => _value(
    en: 'Export Detailed PDF',
    es: 'Exportar PDF detallado',
    fr: 'Exporter PDF détaillé',
    ru: 'Экспорт подробного PDF',
    uk: 'Експорт детального PDF',
    fa: 'خروجی PDF مفصل',
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
    en: 'Exporting…',
    es: 'Exportando…',
    fr: 'Exportation…',
    ru: 'Экспорт…',
    uk: 'Експортування…',
    fa: 'در حال خروجی…',
  );

  String get exportFailed => _value(
    en: 'Export failed',
    es: 'Error al exportar',
    fr: "Échec de l'export",
    ru: 'Ошибка экспорта',
    uk: 'Помилка експорту',
    fa: 'خروجی ناموفق',
  );

  String get exportCsv => _value(
    en: 'Export CSV',
    es: 'Exportar CSV',
    fr: 'Exporter CSV',
    ru: 'Экспорт CSV',
    uk: 'Експорт CSV',
    fa: 'خروجی CSV',
  );

  String get csvExportFailed => _value(
    en: 'CSV export failed',
    es: 'Error al exportar CSV',
    fr: "Échec de l'export CSV",
    ru: 'Ошибка экспорта CSV',
    uk: 'Помилка експорту CSV',
    fa: 'خروجی CSV ناموفق',
  );

  // ─── Backup / restore ─────────────────────────────────────────────────────

  String get dataBackup => _value(
    en: 'Data & Backup',
    es: 'Datos y copia de seguridad',
    fr: 'Données et sauvegarde',
    ru: 'Данные и резервная копия',
    uk: 'Дані та резервна копія',
    fa: 'داده‌ها و پشتیبان',
  );

  String get exportBackup => _value(
    en: 'Export Backup',
    es: 'Exportar copia de seguridad',
    fr: 'Exporter la sauvegarde',
    ru: 'Экспорт резервной копии',
    uk: 'Експорт резервної копії',
    fa: 'خروجی پشتیبان',
  );

  String get importBackup => _value(
    en: 'Import Backup',
    es: 'Importar copia de seguridad',
    fr: 'Importer la sauvegarde',
    ru: 'Импорт резервной копии',
    uk: 'Імпорт резервної копії',
    fa: 'وارد کردن پشتیبان',
  );

  String get backupExported => _value(
    en: 'Backup ready to share',
    es: 'Copia lista para compartir',
    fr: 'Sauvegarde prête à partager',
    ru: 'Резервная копия готова',
    uk: 'Резервна копія готова до надсилання',
    fa: 'پشتیبان آماده اشتراک',
  );

  String get backupExportFailed => _value(
    en: 'Backup export failed',
    es: 'Error al exportar copia',
    fr: 'Échec de l\'export sauvegarde',
    ru: 'Ошибка экспорта копии',
    uk: 'Помилка експорту копії',
    fa: 'خروجی پشتیبان ناموفق',
  );

  String get backupImportConfirmTitle => _value(
    en: 'Import backup?',
    es: '¿Importar copia de seguridad?',
    fr: 'Importer la sauvegarde?',
    ru: 'Импортировать резервную копию?',
    uk: 'Імпортувати резервну копію?',
    fa: 'وارد کردن پشتیبان؟',
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
    en: 'Backup restored successfully',
    es: 'Copia restaurada correctamente',
    fr: 'Sauvegarde restaurée',
    ru: 'Резервная копия восстановлена',
    uk: 'Резервну копію відновлено',
    fa: 'پشتیبان با موفقیت بازیابی شد',
  );

  String get backupImportFailed => _value(
    en: 'Backup import failed',
    es: 'Error al importar copia',
    fr: 'Échec de l\'import sauvegarde',
    ru: 'Ошибка импорта копии',
    uk: 'Помилка імпорту копії',
    fa: 'وارد کردن پشتیبان ناموفق',
  );

  // ─── Profile screen ───────────────────────────────────────────────────────

  String get driverName => _value(
    en: 'Driver name',
    es: 'Nombre del conductor',
    fr: 'Nom du conducteur',
    ru: 'Имя водителя',
    uk: "Ім'я водія",
    fa: 'نام راننده',
  );

  String get businessName => _value(
    en: 'Business name',
    es: 'Nombre del negocio',
    fr: "Nom de l'entreprise",
    ru: 'Название компании',
    uk: 'Назва компанії',
    fa: 'نام کسب‌وکار',
  );

  String get vehicle => _value(
    en: 'Vehicle',
    es: 'Vehículo',
    fr: 'Véhicule',
    ru: 'Автомобиль',
    uk: 'Авто',
    fa: 'وسیله نقلیه',
  );

  String get editProfileInfo => _value(
    en: 'Report identity',
    es: 'Identidad del informe',
    fr: 'Identité du rapport',
    ru: 'Данные отчёта',
    uk: 'Дані звіту',
    fa: 'هویت گزارش',
  );

  String get save => _value(
    en: 'Save',
    es: 'Guardar',
    fr: 'Enregistrer',
    ru: 'Сохранить',
    uk: 'Зберегти',
    fa: 'ذخیره',
  );

  String get profileSaved => _value(
    en: 'Profile saved',
    es: 'Perfil guardado',
    fr: 'Profil enregistré',
    ru: 'Профиль сохранён',
    uk: 'Профіль збережено',
    fa: 'پروفایل ذخیره شد',
  );

  String get about => _value(
    en: 'About',
    es: 'Acerca de',
    fr: 'À propos',
    ru: 'О приложении',
    uk: 'Про додаток',
    fa: 'درباره',
  );

  String get appVersion => _value(
    en: 'Version',
    es: 'Versión',
    fr: 'Version',
    ru: 'Версия',
    uk: 'Версія',
    fa: 'نسخه',
  );

  String get buildNumber => _value(
    en: 'Build number',
    es: 'Número de compilación',
    fr: 'Numéro de build',
    ru: 'Номер сборки',
    uk: 'Номер збірки',
    fa: 'شماره ساخت',
  );

  String get testerBuild => _value(
    en: 'Tester build',
    es: 'Versión de prueba',
    fr: 'Version de test',
    ru: 'Тестовая сборка',
    uk: 'Тестова збірка',
    fa: 'نسخه آزمایشی',
  );

  String get subscription => _value(
    en: 'Subscription',
    es: 'Suscripción',
    fr: 'Abonnement',
    ru: 'Подписка',
    uk: 'Підписка',
    fa: 'اشتراک',
  );

  String get pro =>
      _value(en: 'PRO', es: 'PRO', fr: 'PRO', ru: 'PRO', uk: 'PRO', fa: 'PRO');

  String get goPro => _value(
    en: 'Go Pro',
    es: 'Pasar a Pro',
    fr: 'Passer Pro',
    ru: 'Перейти на Pro',
    uk: 'Перейти на Pro',
    fa: 'ارتقا به Pro',
  );

  String get freePlan => _value(
    en: 'Free plan',
    es: 'Plan gratis',
    fr: 'Formule gratuite',
    ru: 'Бесплатный план',
    uk: 'Безкоштовний план',
    fa: 'طرح رایگان',
  );

  String get proActive => _value(
    en: 'Pro active',
    es: 'Pro activo',
    fr: 'Pro actif',
    ru: 'Pro активен',
    uk: 'Pro активний',
    fa: 'Pro فعال است',
  );

  String get testerProEnabled => _value(
    en: 'Tester Pro is enabled',
    es: 'Tester Pro está activado',
    fr: 'Tester Pro est activé',
    ru: 'Tester Pro включён',
    uk: 'Tester Pro увімкнено',
    fa: 'Tester Pro فعال است',
  );

  String get enableTesterPro => _value(
    en: 'Enable tester Pro',
    es: 'Activar Tester Pro',
    fr: 'Activer Tester Pro',
    ru: 'Включить Tester Pro',
    uk: 'Увімкнути Tester Pro',
    fa: 'فعال کردن Tester Pro',
  );

  String get enableTesterProSubtitle => _value(
    en: 'Temporary switch for testing Pro features before payments are connected.',
    es: 'Interruptor temporal para probar funciones Pro antes de conectar pagos.',
    fr: 'Option temporaire pour tester les fonctions Pro avant les paiements.',
    ru: 'Временный переключатель для тестирования Pro-функций до подключения платежей.',
    uk: 'Тимчасовий перемикач для тестування Pro-функцій до підключення платежів.',
    fa: 'کلید موقت برای آزمایش قابلیت‌های Pro پیش از اتصال پرداخت‌ها.',
  );

  String get unlockProTitle => _value(
    en: 'Unlock MarV Route Pro',
    es: 'Desbloquea MarV Route Pro',
    fr: 'Débloquer MarV Route Pro',
    ru: 'Откройте MarV Route Pro',
    uk: 'Розблокуйте MarV Route Pro',
    fa: 'MarV Route Pro را فعال کنید',
  );

  String get unlockProBody => _value(
    en: 'Prepare cleaner mileage reports, protect your data, and track driving costs with Pro tools.',
    es: 'Prepara informes de millaje más limpios, protege tus datos y controla costos con herramientas Pro.',
    fr: 'Préparez de meilleurs rapports, protégez vos données et suivez vos coûts avec les outils Pro.',
    ru: 'Готовьте более чистые отчёты, защищайте данные и отслеживайте расходы с Pro-инструментами.',
    uk: 'Готуйте чистіші звіти, захищайте дані та відстежуйте витрати з Pro-інструментами.',
    fa: 'با ابزارهای Pro گزارش‌های بهتر بسازید، داده‌ها را محافظت کنید و هزینه‌ها را پیگیری کنید.',
  );

  String get proUnlimitedReports => _value(
    en: 'Unlimited PDF and CSV reports',
    es: 'Informes PDF y CSV ilimitados',
    fr: 'Rapports PDF et CSV illimités',
    ru: 'Неограниченные PDF и CSV отчёты',
    uk: 'Необмежені PDF та CSV звіти',
    fa: 'گزارش‌های PDF و CSV نامحدود',
  );

  String get proCloudBackup => _value(
    en: 'Cloud backup',
    es: 'Copia en la nube',
    fr: 'Sauvegarde cloud',
    ru: 'Облачная резервная копия',
    uk: 'Cloud backup',
    fa: 'پشتیبان ابری',
  );

  String get proFuelSummaries => _value(
    en: 'Fuel summaries in reports',
    es: 'Resumen de combustible en informes',
    fr: 'Résumé carburant dans les rapports',
    ru: 'Сводки топлива в отчётах',
    uk: 'Підсумки пального у звітах',
    fa: 'خلاصه سوخت در گزارش‌ها',
  );

  String get proMonthlyCloseChecklist => _value(
    en: 'Monthly close checklist',
    es: 'Lista de cierre mensual',
    fr: 'Liste de clôture mensuelle',
    ru: 'Чек-лист закрытия месяца',
    uk: 'Чекліст закриття місяця',
    fa: 'فهرست بستن ماهانه',
  );

  String get proAutoDetection => _value(
    en: 'Auto trip detection',
    es: 'Detección automática de viajes',
    fr: 'Détection automatique des trajets',
    ru: 'Авто-обнаружение поездок',
    uk: 'Авто-виявлення поїздок',
    fa: 'شناسایی خودکار سفر',
  );

  String get proMaintenanceReminders => _value(
    en: 'Maintenance reminders',
    es: 'Recordatorios de mantenimiento',
    fr: 'Rappels d’entretien',
    ru: 'Напоминания об обслуживании',
    uk: 'Нагадування про обслуговування',
    fa: 'یادآوری‌های نگهداری',
  );

  String get paymentsComingSoon => _value(
    en: 'Payments coming soon',
    es: 'Pagos próximamente',
    fr: 'Paiements bientôt disponibles',
    ru: 'Платежи скоро',
    uk: 'Платежі скоро',
    fa: 'پرداخت به‌زودی',
  );

  String get testerProHint => _value(
    en: 'Use the tester Pro switch in Profile to preview these features.',
    es: 'Usa el interruptor Tester Pro en Perfil para probar estas funciones.',
    fr: 'Utilisez Tester Pro dans Profil pour prévisualiser ces fonctions.',
    ru: 'Используйте переключатель Tester Pro в профиле для предпросмотра функций.',
    uk: 'Використовуйте перемикач Tester Pro у профілі для перегляду цих функцій.',
    fa: 'برای پیش‌نمایش این قابلیت‌ها از کلید Tester Pro در پروفایل استفاده کنید.',
  );

  String get help => _value(
    en: 'Help',
    es: 'Ayuda',
    fr: 'Aide',
    ru: 'Помощь',
    uk: 'Допомога',
    fa: 'راهنما',
  );

  String get howItWorks => _value(
    en: 'Help / How it works',
    es: 'Ayuda / Cómo funciona',
    fr: 'Aide / Fonctionnement',
    ru: 'Помощь / Как это работает',
    uk: 'Допомога / Як це працює',
    fa: 'راهنما / چگونه کار می‌کند',
  );

  String get helpTrackTripsTitle => _value(
    en: 'Track trips',
    es: 'Registrar viajes',
    fr: 'Suivre les trajets',
    ru: 'Отслеживание поездок',
    uk: 'Відстеження поїздок',
    fa: 'ثبت سفرها',
  );

  String get helpTrackTripsBody => _value(
    en: 'Add trips manually or use auto detection to record mileage.',
    es: 'Añade viajes manualmente o usa la detección automática para registrar millaje.',
    fr: 'Ajoutez des trajets manuellement ou utilisez la détection automatique pour enregistrer le kilométrage.',
    ru: 'Добавляйте поездки вручную или используйте авто-обнаружение для записи пробега.',
    uk: 'Додавайте поїздки вручну або використовуйте авто-виявлення для запису пробігу.',
    fa: 'سفرها را دستی اضافه کنید یا از شناسایی خودکار برای ثبت مسافت استفاده کنید.',
  );

  String get helpAutoDetectionTitle => _value(
    en: 'Auto detection',
    es: 'Detección automática',
    fr: 'Détection automatique',
    ru: 'Авто-обнаружение',
    uk: 'Авто-виявлення',
    fa: 'شناسایی خودکار',
  );

  String get helpAutoDetectionBody => _value(
    en: 'Auto detection watches for movement and saves detected trips for review.',
    es: 'La detección automática observa el movimiento y guarda los viajes detectados para revisión.',
    fr: 'La détection automatique surveille les mouvements et enregistre les trajets détectés pour vérification.',
    ru: 'Авто-обнаружение отслеживает движение и сохраняет найденные поездки для проверки.',
    uk: 'Авто-виявлення стежить за рухом і зберігає виявлені поїздки для перевірки.',
    fa: 'شناسایی خودکار حرکت را دنبال می‌کند و سفرهای شناسایی‌شده را برای بررسی ذخیره می‌کند.',
  );

  String get helpReviewTripsTitle => _value(
    en: 'Review detected trips',
    es: 'Revisar viajes detectados',
    fr: 'Vérifier les trajets détectés',
    ru: 'Проверка найденных поездок',
    uk: 'Перевірка виявлених поїздок',
    fa: 'بررسی سفرهای شناسایی‌شده',
  );

  String get helpReviewTripsBody => _value(
    en: 'Detected trips are marked Needs review. Confirm category, platform, purpose, and expenses before exporting reports.',
    es: 'Los viajes detectados se marcan como Necesitan revisión. Confirma categoría, plataforma, propósito y gastos antes de exportar informes.',
    fr: 'Les trajets détectés sont marqués À vérifier. Confirmez la catégorie, la plateforme, l’objectif et les dépenses avant d’exporter.',
    ru: 'Обнаруженные поездки помечаются как Требуют проверки. Подтвердите категорию, платформу, цель и расходы перед экспортом.',
    uk: 'Виявлені поїздки позначаються як Потребують перевірки. Підтвердьте категорію, платформу, мету та витрати перед експортом.',
    fa: 'سفرهای شناسایی‌شده با نیاز به بررسی علامت می‌خورند. پیش از صدور گزارش، دسته، پلتفرم، هدف و هزینه‌ها را تأیید کنید.',
  );

  String get helpExpensesFuelTitle => _value(
    en: 'Add expenses and fuel',
    es: 'Añadir gastos y combustible',
    fr: 'Ajouter dépenses et carburant',
    ru: 'Добавление расходов и топлива',
    uk: 'Додавання витрат і пального',
    fa: 'افزودن هزینه‌ها و سوخت',
  );

  String get helpExpensesFuelBody => _value(
    en: 'Record parking, tolls, and fuel purchases to understand your driving costs.',
    es: 'Registra parking, peajes y compras de combustible para entender tus costos de conducción.',
    fr: 'Enregistrez le stationnement, les péages et les achats de carburant pour comprendre vos coûts.',
    ru: 'Записывайте парковку, платные дороги и покупки топлива, чтобы понимать расходы на вождение.',
    uk: 'Записуйте паркування, платні дороги та покупки пального, щоб розуміти витрати на поїздки.',
    fa: 'پارکینگ، عوارض و خرید سوخت را ثبت کنید تا هزینه‌های رانندگی خود را بهتر بفهمید.',
  );

  String get helpExportReportsTitle => _value(
    en: 'Export reports',
    es: 'Exportar informes',
    fr: 'Exporter les rapports',
    ru: 'Экспорт отчётов',
    uk: 'Експорт звітів',
    fa: 'صدور گزارش‌ها',
  );

  String get helpExportReportsBody => _value(
    en: 'Export Simple PDF, Detailed PDF, or CSV for your records or accountant.',
    es: 'Exporta PDF simple, PDF detallado o CSV para tus registros o contador.',
    fr: 'Exportez un PDF simple, un PDF détaillé ou un CSV pour vos dossiers ou votre comptable.',
    ru: 'Экспортируйте Simple PDF, Detailed PDF или CSV для себя или бухгалтера.',
    uk: 'Експортуйте Simple PDF, Detailed PDF або CSV для себе чи бухгалтера.',
    fa: 'برای سوابق خود یا حسابدار، PDF ساده، PDF کامل یا CSV صادر کنید.',
  );

  String get helpBackupAccountTitle => _value(
    en: 'Backup and account',
    es: 'Copia y cuenta',
    fr: 'Sauvegarde et compte',
    ru: 'Резервная копия и аккаунт',
    uk: 'Резервна копія та акаунт',
    fa: 'پشتیبان و حساب',
  );

  String get helpBackupAccountBody => _value(
    en: 'Use local backup or sign in to save a cloud backup to your account.',
    es: 'Usa copia local o inicia sesión para guardar una copia en la nube en tu cuenta.',
    fr: 'Utilisez une sauvegarde locale ou connectez-vous pour enregistrer une sauvegarde cloud.',
    ru: 'Используйте локальную копию или войдите, чтобы сохранить облачную копию в аккаунте.',
    uk: 'Використовуйте локальну копію або увійдіть, щоб зберегти cloud backup в акаунті.',
    fa: 'از پشتیبان محلی استفاده کنید یا وارد شوید تا پشتیبان ابری در حساب شما ذخیره شود.',
  );

  String get helpVehicleMaintenanceTitle => _value(
    en: 'Vehicle maintenance',
    es: 'Mantenimiento del vehículo',
    fr: 'Entretien du véhicule',
    ru: 'Обслуживание автомобиля',
    uk: 'Технічне обслуговування авто',
    fa: 'نگهداری خودرو',
  );

  String get helpVehicleMaintenanceBody => _value(
    en: 'Track odometer and oil change reminders.',
    es: 'Controla el odómetro y recordatorios de cambio de aceite.',
    fr: 'Suivez le compteur et les rappels de vidange.',
    ru: 'Отслеживайте одометр и напоминания о замене масла.',
    uk: 'Відстежуйте одометр і нагадування про заміну масла.',
    fa: 'کیلومترشمار و یادآوری تعویض روغن را پیگیری کنید.',
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

  String get appearance => _value(
    en: 'Appearance',
    es: 'Apariencia',
    fr: 'Apparence',
    ru: 'Внешний вид',
    uk: 'Зовнішній вигляд',
    fa: 'ظاهر',
  );

  String get systemTheme => _value(
    en: 'System',
    es: 'Sistema',
    fr: 'Système',
    ru: 'Системная',
    uk: 'Системна',
    fa: 'سیستم',
  );

  String get lightTheme => _value(
    en: 'Light',
    es: 'Claro',
    fr: 'Clair',
    ru: 'Светлая',
    uk: 'Світла',
    fa: 'روشن',
  );

  String get darkTheme => _value(
    en: 'Dark',
    es: 'Oscuro',
    fr: 'Sombre',
    ru: 'Тёмная',
    uk: 'Темна',
    fa: 'تاریک',
  );

  String get accountant => _value(
    en: 'Accountant',
    es: 'Contador',
    fr: 'Comptable',
    ru: 'Бухгалтер',
    uk: 'Бухгалтер',
    fa: 'حسابدار',
  );

  String get accountantName => _value(
    en: 'Accountant name',
    es: 'Nombre del contador',
    fr: 'Nom du comptable',
    ru: 'Имя бухгалтера',
    uk: "Ім'я бухгалтера",
    fa: 'نام حسابدار',
  );

  String get accountantPhone => _value(
    en: 'Phone number',
    es: 'Número de teléfono',
    fr: 'Numéro de téléphone',
    ru: 'Номер телефона',
    uk: 'Номер телефону',
    fa: 'شماره تلفن',
  );

  String get accountantAddress => _value(
    en: 'Address',
    es: 'Dirección',
    fr: 'Adresse',
    ru: 'Адрес',
    uk: 'Адреса',
    fa: 'آدرس',
  );

  String get saveAccountantInfo => _value(
    en: 'Save Accountant Info',
    es: 'Guardar info del contador',
    fr: 'Enregistrer info comptable',
    ru: 'Сохранить данные бухгалтера',
    uk: 'Зберегти дані бухгалтера',
    fa: 'ذخیره اطلاعات حسابدار',
  );

  String get insurance => _value(
    en: 'Insurance',
    es: 'Seguro',
    fr: 'Assurance',
    ru: 'Страховка',
    uk: 'Страхування',
    fa: 'بیمه',
  );

  String get insuranceCompanyName => _value(
    en: 'Insurance company',
    es: 'Compañía de seguros',
    fr: 'Compagnie d\'assurance',
    ru: 'Страховая компания',
    uk: 'Страхова компанія',
    fa: 'شرکت بیمه',
  );

  String get insurancePolicyNumber => _value(
    en: 'Policy number',
    es: 'Número de póliza',
    fr: 'Numéro de police',
    ru: 'Номер полиса',
    uk: 'Номер поліса',
    fa: 'شماره بیمه‌نامه',
  );

  String get insuranceCompanyContact => _value(
    en: 'Company contacts',
    es: 'Contactos de la compañía',
    fr: 'Contacts de la compagnie',
    ru: 'Контакты компании',
    uk: 'Контакти компанії',
    fa: 'اطلاعات تماس شرکت',
  );

  String get saveInsuranceInfo => _value(
    en: 'Save Insurance Info',
    es: 'Guardar seguro',
    fr: 'Enregistrer assurance',
    ru: 'Сохранить данные страховки',
    uk: 'Зберегти дані страхування',
    fa: 'ذخیره اطلاعات بیمه',
  );

  String get reimbursementRate => _value(
    en: 'Reimbursement rate',
    es: 'Tarifa de reembolso',
    fr: 'Taux de remboursement',
    ru: 'Ставка компенсации',
    uk: 'Ставка компенсації',
    fa: 'نرخ بازپرداخت',
  );

  String get currencyLabel => _value(
    en: 'Currency',
    es: 'Moneda',
    fr: 'Devise',
    ru: 'Валюта',
    uk: 'Валюта',
    fa: 'ارز',
  );

  String get autoClassifyTrips => _value(
    en: 'Auto-classify trips by shift',
    es: 'Clasificar viajes automáticamente',
    fr: 'Classer les trajets automatiquement',
    ru: 'Авто-классификация поездок по смене',
    uk: 'Авто-класифікація поїздок за зміною',
    fa: 'طبقه‌بندی خودکار سفرها بر اساس شیفت',
  );

  // ─── Vehicle Maintenance ──────────────────────────────────────────────────

  String get vehicleMaintenance => _value(
    en: 'Vehicle Maintenance',
    es: 'Mantenimiento del vehículo',
    fr: 'Entretien du véhicule',
    ru: 'Обслуживание автомобиля',
    uk: 'Технічне обслуговування',
    fa: 'نگهداری خودرو',
  );

  String get currentOdometer => _value(
    en: 'Current odometer',
    es: 'Odómetro actual',
    fr: 'Kilométrage actuel',
    ru: 'Текущий одометр',
    uk: 'Поточний одометр',
    fa: 'کیلومتراژ فعلی',
  );

  String get lastOilChangeOdometer => _value(
    en: 'Last oil change odometer',
    es: 'Odómetro del último cambio',
    fr: 'Km du dernier vidange',
    ru: 'Одометр при последней замене',
    uk: 'Одометр останньої заміни',
    fa: 'کیلومتراژ آخرین تعویض روغن',
  );

  String get oilChangeInterval => _value(
    en: 'Oil change interval',
    es: 'Intervalo de cambio de aceite',
    fr: 'Intervalle de vidange',
    ru: 'Интервал замены масла',
    uk: 'Інтервал заміни масла',
    fa: 'فاصله تعویض روغن',
  );

  String get oilChangeReminderThreshold => _value(
    en: 'Reminder before due',
    es: 'Recordatorio antes del vencimiento',
    fr: 'Rappel avant échéance',
    ru: 'Напомнить за',
    uk: 'Нагадати до строку',
    fa: 'یادآوری قبل از موعد',
  );

  String get saveMaintenanceInfo => _value(
    en: 'Save Maintenance Info',
    es: 'Guardar mantenimiento',
    fr: 'Enregistrer l\'entretien',
    ru: 'Сохранить данные обслуживания',
    uk: 'Зберегти дані обслуговування',
    fa: 'ذخیره اطلاعات نگهداری',
  );

  String get oilChange => _value(
    en: 'Oil change',
    es: 'Cambio de aceite',
    fr: 'Vidange',
    ru: 'Замена масла',
    uk: 'Заміна масла',
    fa: 'تعویض روغن',
  );

  String get oilChangeDue => _value(
    en: 'Oil change due',
    es: 'Cambio de aceite vencido',
    fr: 'Vidange à faire',
    ru: 'Замена масла просрочена',
    uk: 'Заміна масла прострочена',
    fa: 'تعویض روغن سررسید شده',
  );

  String get oilChangeDueNow => _value(
    en: 'Your oil change is due now.',
    es: 'Tu cambio de aceite está vencido.',
    fr: 'Votre vidange est à faire.',
    ru: 'Замена масла просрочена.',
    uk: 'Заміна масла прострочена.',
    fa: 'زمان تعویض روغن فرا رسیده است.',
  );

  String get oilChangeSoon => _value(
    en: 'Oil change soon',
    es: 'Cambio de aceite próximo',
    fr: 'Vidange bientôt',
    ru: 'Скоро замена масла',
    uk: 'Незабаром заміна масла',
    fa: 'تعویض روغن نزدیک است',
  );

  String get oilChangeDueIn => _value(
    en: 'Due in',
    es: 'Vence en',
    fr: 'Dans',
    ru: 'Через',
    uk: 'Через',
    fa: 'سررسید در',
  );

  String get lastBrakePadChangeOdometer => _value(
    en: 'Last brake pad change odometer',
    es: 'Odómetro del último cambio de pastillas',
    fr: 'Km du dernier changement de plaquettes',
    ru: 'Одометр при последней замене колодок',
    uk: 'Одометр останньої заміни колодок',
    fa: 'کیلومتر آخرین تعویض لنت ترمز',
  );

  String get brakePadChangeInterval => _value(
    en: 'Brake pad change interval',
    es: 'Intervalo de cambio de pastillas',
    fr: 'Intervalle de changement des plaquettes',
    ru: 'Интервал замены колодок',
    uk: 'Інтервал заміни гальмівних колодок',
    fa: 'فاصله تعویض لنت ترمز',
  );

  String get brakePadReminderThreshold => _value(
    en: 'Brake pad reminder before due',
    es: 'Recordatorio de pastillas antes del vencimiento',
    fr: 'Rappel plaquettes avant échéance',
    ru: 'Напомнить о колодках за',
    uk: 'Нагадати про колодки до строку',
    fa: 'یادآوری لنت ترمز قبل از موعد',
  );

  String get brakePadChange => _value(
    en: 'Brake pads',
    es: 'Pastillas de freno',
    fr: 'Plaquettes de frein',
    ru: 'Тормозные колодки',
    uk: 'Гальмівні колодки',
    fa: 'لنت ترمز',
  );

  String get brakePadChangeDue => _value(
    en: 'Brake pads due',
    es: 'Pastillas vencidas',
    fr: 'Plaquettes à remplacer',
    ru: 'Пора менять колодки',
    uk: 'Пора замінити колодки',
    fa: 'زمان تعویض لنت ترمز',
  );

  String get brakePadChangeDueNow => _value(
    en: 'Your brake pads are due now.',
    es: 'Tus pastillas de freno deben cambiarse.',
    fr: 'Vos plaquettes de frein sont à remplacer.',
    ru: 'Пора заменить тормозные колодки.',
    uk: 'Пора замінити гальмівні колодки.',
    fa: 'زمان تعویض لنت ترمز فرا رسیده است.',
  );

  String get brakePadChangeSoon => _value(
    en: 'Brake pads soon',
    es: 'Pastillas pronto',
    fr: 'Plaquettes bientôt',
    ru: 'Скоро замена колодок',
    uk: 'Незабаром заміна колодок',
    fa: 'تعویض لنت ترمز نزدیک است',
  );

  String get odometerCannotBeNegative => _value(
    en: 'Odometer cannot be negative',
    es: 'El odómetro no puede ser negativo',
    fr: 'Le kilométrage ne peut pas être négatif',
    ru: 'Одометр не может быть отрицательным',
    uk: 'Одометр не може бути від\'ємним',
    fa: 'کیلومتراژ نمی‌تواند منفی باشد',
  );

  String get intervalMustBePositive => _value(
    en: 'Interval must be greater than 0',
    es: 'El intervalo debe ser mayor que 0',
    fr: 'L\'intervalle doit être supérieur à 0',
    ru: 'Интервал должен быть больше 0',
    uk: 'Інтервал має бути більше 0',
    fa: 'فاصله باید بیشتر از ۰ باشد',
  );

  String get lastOilChangeCannotExceedCurrent => _value(
    en: 'Last oil change cannot exceed current odometer',
    es: 'El último cambio no puede superar el odómetro actual',
    fr: 'Le dernier vidange ne peut pas dépasser le kilométrage actuel',
    ru: 'Последняя замена не может превышать текущий одометр',
    uk: 'Остання заміна не може перевищувати поточний одометр',
    fa: 'آخرین تعویض روغن نمی‌تواند از کیلومتراژ فعلی بیشتر باشد',
  );

  // ─── Work Mode screen ─────────────────────────────────────────────────────

  String get workMode => _value(
    en: 'Work Mode',
    es: 'Modo trabajo',
    fr: 'Mode travail',
    ru: 'Рабочий режим',
    uk: 'Робочий режим',
    fa: 'حالت کاری',
  );

  String get enableWorkMode => _value(
    en: 'Enable Work Mode',
    es: 'Activar modo trabajo',
    fr: 'Activer mode travail',
    ru: 'Включить рабочий режим',
    uk: 'Увімкнути робочий режим',
    fa: 'فعال کردن حالت کاری',
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
    en: 'Work Shifts',
    es: 'Turnos de trabajo',
    fr: 'Quarts de travail',
    ru: 'Рабочие смены',
    uk: 'Робочі зміни',
    fa: 'شیفت‌های کاری',
  );

  /// Used in the counter label: "3 configured"
  String get configured => _value(
    en: 'configured',
    es: 'configurados',
    fr: 'configurés',
    ru: 'настроено',
    uk: 'налаштовано',
    fa: 'پیکربندی شده',
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
    en: 'Remove shift',
    es: 'Eliminar turno',
    fr: 'Supprimer le quart',
    ru: 'Удалить смену',
    uk: 'Видалити зміну',
    fa: 'حذف شیفت',
  );

  String get addShift => _value(
    en: 'Add Shift',
    es: 'Añadir turno',
    fr: 'Ajouter un quart',
    ru: 'Добавить смену',
    uk: 'Додати зміну',
    fa: 'افزودن شیفت',
  );

  String get addWorkShift => _value(
    en: 'Add Work Shift',
    es: 'Añadir turno de trabajo',
    fr: 'Ajouter un quart de travail',
    ru: 'Добавить рабочую смену',
    uk: 'Додати робочу зміну',
    fa: 'افزودن شیفت کاری',
  );

  String get platform => _value(
    en: 'Platform',
    es: 'Plataforma',
    fr: 'Plateforme',
    ru: 'Платформа',
    uk: 'Платформа',
    fa: 'پلتفرم',
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
    en: '+ Custom platform',
    es: '+ Plataforma personalizada',
    fr: '+ Plateforme personnalisée',
    ru: '+ Своя платформа',
    uk: '+ Власна платформа',
    fa: '+ پلتفرم سفارشی',
  );

  String get shiftHours => _value(
    en: 'Shift hours',
    es: 'Horas de turno',
    fr: 'Heures de quart',
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

  String get expensesOptional => _value(
    en: 'Expenses (optional)',
    es: 'Gastos (opcional)',
    fr: 'Dépenses (facultatif)',
    ru: 'Расходы (необязательно)',
    uk: 'Витрати (необов\'язково)',
    fa: 'هزینه‌ها (اختیاری)',
  );

  String get saveShift => _value(
    en: 'Save Shift',
    es: 'Guardar turno',
    fr: 'Enregistrer le quart',
    ru: 'Сохранить смену',
    uk: 'Зберегти зміну',
    fa: 'ذخیره شیفت',
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
    en: 'Automation',
    es: 'Automatización',
    fr: 'Automatisation',
    ru: 'Автоматизация',
    uk: 'Автоматизація',
    fa: 'اتوماسیون',
  );

  String get autoTripDetection => _value(
    en: 'Auto Trip Detection',
    es: 'Detección automática de viajes',
    fr: 'Détection automatique',
    ru: 'Авто-определение поездок',
    uk: 'Авто-виявлення поїздок',
    fa: 'تشخیص خودکار سفر',
  );

  String get liveTripMap => _value(
    en: 'Live trip map',
    es: 'Mapa del viaje en vivo',
    fr: 'Carte du trajet en direct',
    ru: 'Карта поездки',
    uk: 'Карта поїздки наживо',
    fa: 'نقشه زنده سفر',
  );

  String get autoTripDetectionDescription => _value(
    en: 'MarV Route can detect potential trips and ask you to review them.',
    es: 'MarV Route puede detectar viajes potenciales y pedirte que los revises.',
    fr: 'MarV Route peut détecter des trajets potentiels et vous demander de les examiner.',
    ru: 'MarV Route может обнаруживать возможные поездки и предлагать вам их проверить.',
    uk: 'MarV Route може виявляти можливі поїздки та пропонувати вам їх перевірити.',
    fa: 'MarV Route می‌تواند سفرهای احتمالی را شناسایی کرده و از شما بخواهد آن‌ها را بررسی کنید.',
  );

  String get needsReview => _value(
    en: 'Needs review',
    es: 'Requiere revisión',
    fr: 'À vérifier',
    ru: 'Требует проверки',
    uk: 'Потребує перевірки',
    fa: 'نیاز به بررسی',
  );

  String get reviewed => _value(
    en: 'Reviewed',
    es: 'Revisado',
    fr: 'Vérifié',
    ru: 'Проверено',
    uk: 'Перевірено',
    fa: 'بررسی شده',
  );

  String get detectionMode => _value(
    en: 'Detection mode',
    es: 'Modo de detección',
    fr: 'Mode de détection',
    ru: 'Режим определения',
    uk: 'Режим виявлення',
    fa: 'حالت تشخیص',
  );

  String get manual => _value(
    en: 'Manual',
    es: 'Manual',
    fr: 'Manuel',
    ru: 'Вручную',
    uk: 'Вручну',
    fa: 'دستی',
  );

  String get automatic => _value(
    en: 'Automatic',
    es: 'Automático',
    fr: 'Automatique',
    ru: 'Автоматически',
    uk: 'Автоматично',
    fa: 'خودکار',
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

  String get trackingActiveTitle => _value(
    en: 'Tracking is active',
    es: 'Rastreo activo',
    fr: 'Suivi actif',
    ru: 'Отслеживание активно',
    uk: 'Відстеження активне',
    fa: 'ردیابی فعال است',
  );

  String get trackingActiveMessage => _value(
    en: 'Stop tracking when your trip ends. Tracking continues while screen is off.',
    es: 'Detén el rastreo cuando tu viaje termine. El rastreo continúa con la pantalla apagada.',
    fr: "Arrêtez le suivi quand votre trajet se termine. Le suivi continue écran éteint.",
    ru: 'Остановите отслеживание, когда поездка закончится. Отслеживание продолжается при выключенном экране.',
    uk: 'Зупиніть відстеження, коли поїздка закінчиться. Відстеження триває при вимкненому екрані.',
    fa: 'وقتی سفر تمام شد، ردیابی را متوقف کنید. ردیابی با خاموشی صفحه ادامه می‌یابد.',
  );

  String get trackingContinuesScreenOff => _value(
    en: 'Tracking continues while your screen is off. A notification will be shown.',
    es: 'El rastreo continúa con la pantalla apagada. Se mostrará una notificación.',
    fr: "Le suivi continue écran éteint. Une notification sera affichée.",
    ru: 'Отслеживание продолжается при выключенном экране. Будет показано уведомление.',
    uk: 'Відстеження триває при вимкненому екрані. Буде показано сповіщення.',
    fa: 'ردیابی با خاموشی صفحه ادامه می‌یابد. یک اعلان نمایش داده خواهد شد.',
  );

  String get trackingNotificationTitle => _value(
    en: 'MarV Route is tracking your trip',
    es: 'MarV Route está rastreando tu viaje',
    fr: 'MarV Route suit votre trajet',
    ru: 'MarV Route отслеживает вашу поездку',
    uk: 'MarV Route відстежує вашу поїздку',
    fa: 'MarV Route در حال ردیابی سفر شما است',
  );

  String get trackingNotificationText => _value(
    en: 'Tracking continues while your screen is off.',
    es: 'El rastreo continúa con la pantalla apagada.',
    fr: 'Le suivi continue écran éteint.',
    ru: 'Отслеживание продолжается при выключенном экране.',
    uk: 'Відстеження триває при вимкненому екрані.',
    fa: 'ردیابی با خاموشی صفحه ادامه می‌یابد.',
  );

  String get foregroundOnlyTracking => _value(
    en: 'Foreground only — tracking stops when the app is closed.',
    es: 'Solo en primer plano — el rastreo se detiene al cerrar la app.',
    fr: "Premier plan uniquement — le suivi s'arrête à la fermeture de l'app.",
    ru: 'Только на переднем плане — отслеживание останавливается при закрытии приложения.',
    uk: 'Лише на передньому плані — відстеження зупиняється при закритті додатку.',
    fa: 'فقط در پیش‌زمینه — ردیابی با بستن برنامه متوقف می‌شود.',
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

  String get noGpsPointsRecorded => _value(
    en: 'No GPS points recorded. Check that Location Services are enabled.',
    es: 'No se grabaron puntos GPS. Comprueba que los Servicios de ubicación estén habilitados.',
    fr: 'Aucun point GPS enregistré. Vérifiez que les Services de localisation sont activés.',
    ru: 'GPS-точки не записаны. Проверьте, что службы геолокации включены.',
    uk: 'Точки GPS не записано. Перевірте, чи увімкнено служби геолокації.',
    fa: 'هیچ نقطه GPS ثبت نشد. بررسی کنید که خدمات موقعیت‌یابی فعال باشند.',
  );

  String get gpsAccuracyTooLow => _value(
    en: 'GPS accuracy was too low. Try tracking outdoors for a better signal.',
    es: 'La precisión del GPS fue demasiado baja. Intenta rastrear al aire libre para mejor señal.',
    fr: 'La précision GPS était trop faible. Essayez de suivre en extérieur pour un meilleur signal.',
    ru: 'Точность GPS слишком низкая. Попробуйте отслеживать на открытом воздухе.',
    uk: 'Точність GPS занадто низька. Спробуйте відстежувати на вулиці для кращого сигналу.',
    fa: 'دقت GPS خیلی پایین بود. برای سیگنال بهتر در فضای باز ردیابی کنید.',
  );

  String get detectedTripSavedForReview => _value(
    en: 'Detected trip saved for review',
    es: 'Viaje detectado guardado para revisión',
    fr: 'Trajet détecté enregistré pour vérification',
    ru: 'Обнаруженная поездка сохранена для проверки',
    uk: 'Виявлену поїздку збережено для перевірки',
    fa: 'سفر شناسایی شده برای بررسی ذخیره شد',
  );

  String get trackingError => _value(
    en: 'Tracking error. Please try again.',
    es: 'Error de rastreo. Por favor, inténtalo de nuevo.',
    fr: 'Erreur de suivi. Veuillez réessayer.',
    ru: 'Ошибка отслеживания. Повторите попытку.',
    uk: 'Помилка відстеження. Спробуйте ще раз.',
    fa: 'خطا در ردیابی. لطفاً دوباره امتحان کنید.',
  );

  String get autoDetectionOff => _value(
    en: 'Off — tap to start watching for trips',
    es: 'Apagado — toca para empezar a detectar viajes',
    fr: 'Désactivé — appuyez pour surveiller les trajets',
    ru: 'Выключено — нажмите, чтобы начать отслеживание',
    uk: 'Вимкнено — натисніть, щоб почати стеження',
    fa: 'خاموش — برای شروع نظارت بر سفرها ضربه بزنید',
  );

  String get watchingForMovement => _value(
    en: 'Watching for movement…',
    es: 'Vigilando el movimiento…',
    fr: 'Surveillance des mouvements…',
    ru: 'Ожидание движения…',
    uk: 'Стеження за рухом…',
    fa: 'در انتظار حرکت…',
  );

  String get tripDetectedTracking => _value(
    en: 'Trip detected — tracking',
    es: 'Viaje detectado — rastreando',
    fr: 'Trajet détecté — suivi en cours',
    ru: 'Поездка обнаружена — отслеживание',
    uk: 'Поїздку виявлено — відстеження',
    fa: 'سفر شناسایی شد — در حال ردیابی',
  );

  String get startAutoDetection => _value(
    en: 'Start Auto Detection',
    es: 'Iniciar detección automática',
    fr: 'Démarrer la détection auto',
    ru: 'Запустить авто-определение',
    uk: 'Запустити авто-виявлення',
    fa: 'شروع تشخیص خودکار',
  );

  String get stopAutoDetection => _value(
    en: 'Stop Auto Detection',
    es: 'Detener detección automática',
    fr: 'Arrêter la détection auto',
    ru: 'Остановить авто-определение',
    uk: 'Зупинити авто-виявлення',
    fa: 'توقف تشخیص خودکار',
  );

  String get autoDetectionActive => _value(
    en: 'Auto detection is active',
    es: 'La detección automática está activa',
    fr: 'La détection automatique est active',
    ru: 'Авто-определение активно',
    uk: 'Авто-виявлення активне',
    fa: 'تشخیص خودکار فعال است',
  );

  String get marvRouteWatchingForTrips => _value(
    en: 'MarV Route is watching for trips',
    es: 'MarV Route está vigilando tus viajes',
    fr: 'MarV Route surveille vos trajets',
    ru: 'MarV Route ожидает поездок',
    uk: 'MarV Route стежить за поїздками',
    fa: 'MarV Route در انتظار سفرهای شما است',
  );

  String get tripDetectionNotificationText => _value(
    en: 'Trip detection is active. A notification is shown while monitoring.',
    es: 'La detección de viajes está activa. Se muestra una notificación.',
    fr: 'Détection de trajet active. Une notification est affichée.',
    ru: 'Обнаружение поездок активно. Отображается уведомление.',
    uk: 'Виявлення поїздок активне. Відображається сповіщення.',
    fa: 'تشخیص سفر فعال است. یک اعلان در حین نظارت نمایش داده می‌شود.',
  );

  String get enableAutoDetectionFirst => _value(
    en: 'Enable Auto Trip Detection in Profile first',
    es: 'Activa la detección automática en Perfil primero',
    fr: "Activez la détection automatique dans Profil d'abord",
    ru: 'Сначала включите Авто-определение поездок в Профиле',
    uk: 'Спочатку увімкніть Авто-виявлення поїздок у Профілі',
    fa: 'ابتدا تشخیص خودکار سفر را در پروفایل فعال کنید',
  );

  String get resolvingAddresses => _value(
    en: 'Resolving addresses…',
    es: 'Resolviendo direcciones…',
    fr: 'Résolution des adresses…',
    ru: 'Определение адресов…',
    uk: 'Визначення адрес…',
    fa: 'در حال یافتن آدرس‌ها…',
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

  String get detectedRoute => _value(
    en: 'Detected route',
    es: 'Ruta detectada',
    fr: 'Trajet détecté',
    ru: 'Обнаруженный маршрут',
    uk: 'Виявлений маршрут',
    fa: 'مسیر شناسایی شده',
  );

  String get detectedTripNeedsReview => _value(
    en: 'This detected trip needs review',
    es: 'Este viaje detectado requiere revisión',
    fr: 'Ce trajet détecté nécessite une vérification',
    ru: 'Эта обнаруженная поездка требует проверки',
    uk: 'Ця виявлена поїздка потребує перевірки',
    fa: 'این سفر شناسایی شده نیاز به بررسی دارد',
  );

  String get confirmDetailsAndMarkReviewed => _value(
    en: 'Confirm the details and mark it reviewed.',
    es: 'Confirma los detalles y márcalo como revisado.',
    fr: 'Confirmez les détails et marquez-le comme vérifié.',
    ru: 'Проверьте данные и пометьте как проверено.',
    uk: 'Підтвердьте деталі та позначте як перевірено.',
    fa: 'جزئیات را تأیید کرده و آن را بررسی شده علامت بزنید.',
  );

  String get saveAndMarkReviewed => _value(
    en: 'Save & Mark Reviewed',
    es: 'Guardar y marcar revisado',
    fr: 'Enregistrer et marquer vérifié',
    ru: 'Сохранить и отметить проверенным',
    uk: 'Зберегти та позначити перевіреним',
    fa: 'ذخیره و علامت‌گذاری بررسی شده',
  );

  String get tapToReview => _value(
    en: 'Tap to review',
    es: 'Toca para revisar',
    fr: 'Appuyez pour vérifier',
    ru: 'Нажмите для проверки',
    uk: 'Натисніть для перевірки',
    fa: 'برای بررسی ضربه بزنید',
  );

  String tripsNeedReviewCount(int count) {
    final label = _value(
      en: 'trips need review',
      es: 'viajes requieren revisión',
      fr: 'trajets à vérifier',
      ru: 'поездок требуют проверки',
      uk: 'поїздок потребують перевірки',
      fa: 'سفر نیاز به بررسی دارند',
    );
    return '$count $label';
  }

  String get reviewDetectedTripsBeforeExport => _value(
    en: 'Review detected trips before exporting reports.',
    es: 'Revisa los viajes detectados antes de exportar informes.',
    fr: 'Vérifiez les trajets détectés avant d\'exporter les rapports.',
    ru: 'Проверьте обнаруженные поездки перед экспортом отчётов.',
    uk: 'Перегляньте виявлені поїздки перед експортом звітів.',
    fa: 'قبل از صدور گزارش‌ها، سفرهای شناسایی شده را بررسی کنید.',
  );

  String get monthlyCloseChecklist => _value(
    en: 'Monthly close checklist',
    es: 'Lista de cierre mensual',
    fr: 'Liste de clôture mensuelle',
    ru: 'Чек-лист закрытия месяца',
    uk: 'Чекліст закриття місяця',
    fa: 'فهرست بستن ماهانه',
  );

  String get reviewDetectedTrips => _value(
    en: 'Review detected trips',
    es: 'Revisar viajes detectados',
    fr: 'Vérifier les trajets détectés',
    ru: 'Проверить обнаруженные поездки',
    uk: 'Переглянути виявлені поїздки',
    fa: 'بررسی سفرهای شناسایی‌شده',
  );

  String get checkCategories => _value(
    en: 'Check business/personal categories',
    es: 'Revisar categorías de negocio/personales',
    fr: 'Vérifier les catégories pro/personnelles',
    ru: 'Проверить категории бизнес/личные',
    uk: 'Перевірити категорії бізнес/особисті',
    fa: 'بررسی دسته‌های کاری/شخصی',
  );

  String get checkFuelEntries => _value(
    en: 'Check fuel entries',
    es: 'Revisar registros de combustible',
    fr: 'Vérifier les entrées carburant',
    ru: 'Проверить записи топлива',
    uk: 'Перевірити записи пального',
    fa: 'بررسی ثبت‌های سوخت',
  );

  String get checkParkingAndTolls => _value(
    en: 'Check parking and tolls',
    es: 'Revisar parking y peajes',
    fr: 'Vérifier parking et péages',
    ru: 'Проверить парковку и платные дороги',
    uk: 'Перевірити паркування та платні дороги',
    fa: 'بررسی پارکینگ و عوارض',
  );

  String get backUpYourData => _value(
    en: 'Back up your data',
    es: 'Haz copia de seguridad',
    fr: 'Sauvegarder vos données',
    ru: 'Создать резервную копию',
    uk: 'Створити резервну копію',
    fa: 'پشتیبان‌گیری از داده‌ها',
  );

  String get exportPdfCsv => _value(
    en: 'Export PDF/CSV',
    es: 'Exportar PDF/CSV',
    fr: 'Exporter PDF/CSV',
    ru: 'Экспорт PDF/CSV',
    uk: 'Експорт PDF/CSV',
    fa: 'صدور PDF/CSV',
  );

  String get lastBackup => _value(
    en: 'Last backup',
    es: 'Última copia',
    fr: 'Dernière sauvegarde',
    ru: 'Последняя копия',
    uk: 'Остання копія',
    fa: 'آخرین پشتیبان',
  );

  String get checklistGuidance => _value(
    en: 'Use this as a quick pre-export review. It does not block export.',
    es: 'Úsala como revisión rápida antes de exportar. No bloquea la exportación.',
    fr: 'Utilisez-la comme contrôle rapide avant export. Elle ne bloque pas l’export.',
    ru: 'Используйте как быструю проверку перед экспортом. Экспорт не блокируется.',
    uk: 'Використовуйте як швидку перевірку перед експортом. Експорт не блокується.',
    fa: 'از این برای بررسی سریع پیش از صدور استفاده کنید. صدور را مسدود نمی‌کند.',
  );

  String get reviewTrips => _value(
    en: 'Review trips',
    es: 'Revisar viajes',
    fr: 'Vérifier les trajets',
    ru: 'Проверить поездки',
    uk: 'Переглянути поїздки',
    fa: 'بررسی سفرها',
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
    en: 'Fuel',
    es: 'Combustible',
    fr: 'Carburant',
    ru: 'Топливо',
    uk: 'Пальне',
    fa: 'سوخت',
  );

  String get parking => _value(
    en: 'Parking',
    es: 'Estacionamiento',
    fr: 'Stationnement',
    ru: 'Парковка',
    uk: 'Паркування',
    fa: 'پارکینگ',
  );

  String get tolls => _value(
    en: 'Tolls',
    es: 'Peajes',
    fr: 'Péages',
    ru: 'Платные дороги',
    uk: 'Платні дороги',
    fa: 'عوارض',
  );

  String get totalExpenses => _value(
    en: 'Total expenses',
    es: 'Gastos totales',
    fr: 'Dépenses totales',
    ru: 'Итого расходов',
    uk: 'Загальні витрати',
    fa: 'مجموع هزینه‌ها',
  );

  String get optional => _value(
    en: 'optional',
    es: 'opcional',
    fr: 'facultatif',
    ru: 'необязательно',
    uk: "необов'язково",
    fa: 'اختیاری',
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
    en: 'Cancel',
    es: 'Cancelar',
    fr: 'Annuler',
    ru: 'Отмена',
    uk: 'Скасувати',
    fa: 'لغو',
  );

  String get delete => _value(
    en: 'Delete',
    es: 'Eliminar',
    fr: 'Supprimer',
    ru: 'Удалить',
    uk: 'Видалити',
    fa: 'حذف',
  );

  String get all => _value(
    en: 'All',
    es: 'Todos',
    fr: 'Tout',
    ru: 'Все',
    uk: 'Усі',
    fa: 'همه',
  );

  String get edit => _value(
    en: 'Edit',
    es: 'Editar',
    fr: 'Modifier',
    ru: 'Изменить',
    uk: 'Редагувати',
    fa: 'ویرایش',
  );

  String get noTripsFound => _value(
    en: 'No trips found',
    es: 'No se encontraron viajes',
    fr: 'Aucun trajet trouvé',
    ru: 'Поездок не найдено',
    uk: 'Поїздок не знайдено',
    fa: 'سفری یافت نشد',
  );

  String get tryChangingFilters => _value(
    en: 'Try changing the filters',
    es: 'Intenta cambiar los filtros',
    fr: 'Essayez de modifier les filtres',
    ru: 'Попробуйте изменить фильтры',
    uk: 'Спробуйте змінити фільтри',
    fa: 'فیلترها را تغییر دهید',
  );

  // ─── Onboarding ───────────────────────────────────────────────────────────

  String get welcomeToRouteMint => _value(
    en: 'Welcome to MarV Route',
    es: 'Bienvenido a MarV Route',
    fr: 'Bienvenue sur MarV Route',
    ru: 'Добро пожаловать в MarV Route',
    uk: 'Ласкаво просимо до MarV Route',
    fa: 'به MarV Route خوش آمدید',
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
    en: 'USA rate',
    es: 'Tasa EE.UU.',
    fr: 'Taux USA',
    ru: 'Ставка США',
    uk: 'Ставка США',
    fa: 'نرخ آمریکا',
  );

  String get canadaRate => _value(
    en: 'Canada rate',
    es: 'Tasa Canadá',
    fr: 'Taux Canada',
    ru: 'Ставка Канады',
    uk: 'Ставка Канади',
    fa: 'نرخ کانادا',
  );

  String get tripsLabel => _value(
    en: 'trips',
    es: 'viajes',
    fr: 'trajets',
    ru: 'поездок',
    uk: 'поїздок',
    fa: 'سفر',
  );

  String get taxSavingsToday => _value(
    en: 'Tax savings today',
    es: 'Ahorro fiscal hoy',
    fr: "Économies fiscales aujourd'hui",
    ru: 'Налоговая экономия сегодня',
    uk: 'Податкова економія сьогодні',
    fa: 'صرفه‌جویی مالیاتی امروز',
  );

  String get todayPeriod => _value(
    en: 'Today',
    es: 'Hoy',
    fr: "Aujourd'hui",
    ru: 'Сегодня',
    uk: 'Сьогодні',
    fa: 'امروز',
  );

  String get mileageToday => _value(
    en: 'Mileage today',
    es: 'Distancia hoy',
    fr: "Distance aujourd'hui",
    ru: 'Пробег сегодня',
    uk: 'Пробіг сьогодні',
    fa: 'مسافت امروز',
  );

  String get mileageThisWeek => _value(
    en: 'Mileage this week',
    es: 'Distancia esta semana',
    fr: 'Distance cette semaine',
    ru: 'Пробег за неделю',
    uk: 'Пробіг цього тижня',
    fa: 'مسافت این هفته',
  );

  String get mileageThisMonth => _value(
    en: 'Mileage this month',
    es: 'Distancia este mes',
    fr: 'Distance ce mois',
    ru: 'Пробег за месяц',
    uk: 'Пробіг цього місяця',
    fa: 'مسافت این ماه',
  );

  String get mileageThisYear => _value(
    en: 'Mileage this year',
    es: 'Distancia este año',
    fr: 'Distance cette année',
    ru: 'Пробег за год',
    uk: 'Пробіг цього року',
    fa: 'مسافت این سال',
  );

  String get taxSavingsThisWeek => _value(
    en: 'Tax savings this week',
    es: 'Ahorro fiscal esta semana',
    fr: 'Économies cette semaine',
    ru: 'Экономия за неделю',
    uk: 'Економія цього тижня',
    fa: 'صرفه‌جویی این هفته',
  );

  String get taxSavingsThisMonth => _value(
    en: 'Tax savings this month',
    es: 'Ahorro fiscal este mes',
    fr: 'Économies ce mois',
    ru: 'Экономия за месяц',
    uk: 'Економія цього місяця',
    fa: 'صرفه‌جویی این ماه',
  );

  String get taxSavingsThisYear => _value(
    en: 'Tax savings this year',
    es: 'Ahorro fiscal este año',
    fr: 'Économies cette année',
    ru: 'Экономия за год',
    uk: 'Економія цього року',
    fa: 'صرفه‌جویی این سال',
  );

  String get errorLoadingTrips => _value(
    en: 'Error loading trips',
    es: 'Error al cargar viajes',
    fr: 'Erreur de chargement',
    ru: 'Ошибка загрузки поездок',
    uk: 'Помилка завантаження поїздок',
    fa: 'خطا در بارگذاری سفرها',
  );

  String get noTripsYet => _value(
    en: 'No trips yet',
    es: 'Sin viajes aún',
    fr: "Aucun trajet pour l'instant",
    ru: 'Поездок пока нет',
    uk: 'Поїздок ще немає',
    fa: 'هنوز سفری وجود ندارد',
  );

  // ─── Address search ───────────────────────────────────────────────────────

  String get searchingAddress => _value(
    en: 'Searching…',
    es: 'Buscando…',
    fr: 'Recherche…',
    ru: 'Поиск…',
    uk: 'Пошук…',
    fa: 'در حال جستجو…',
  );

  String get noAddressSuggestions => _value(
    en: 'No suggestions found',
    es: 'No se encontraron sugerencias',
    fr: 'Aucune suggestion trouvée',
    ru: 'Нет подсказок',
    uk: 'Підказок не знайдено',
    fa: 'هیچ پیشنهادی یافت نشد',
  );

  String get addressSearchUnavailable => _value(
    en: 'Address search unavailable',
    es: 'Búsqueda de dirección no disponible',
    fr: 'Recherche d\'adresse indisponible',
    ru: 'Поиск адреса недоступен',
    uk: 'Пошук адреси недоступний',
    fa: 'جستجوی آدرس در دسترس نیست',
  );

  String get selectPlatform => _value(
    en: 'Select platform',
    es: 'Seleccionar plataforma',
    fr: 'Choisir une plateforme',
    ru: 'Выбрать платформу',
    uk: 'Обрати платформу',
    fa: 'انتخاب پلتفرم',
  );

  String get otherPlatform => _value(
    en: 'Other',
    es: 'Otro',
    fr: 'Autre',
    ru: 'Другое',
    uk: 'Інше',
    fa: 'سایر',
  );

  String get customPlatformName => _value(
    en: 'Platform name',
    es: 'Nombre de plataforma',
    fr: 'Nom de la plateforme',
    ru: 'Название платформы',
    uk: 'Назва платформи',
    fa: 'نام پلتفرم',
  );

  // ─── Auth ─────────────────────────────────────────────────────────────────

  String get account => _value(
    en: 'Account',
    es: 'Cuenta',
    fr: 'Compte',
    ru: 'Аккаунт',
    uk: 'Акаунт',
    fa: 'حساب',
  );

  String get signIn => _value(
    en: 'Sign In',
    es: 'Iniciar sesión',
    fr: 'Se connecter',
    ru: 'Войти',
    uk: 'Увійти',
    fa: 'ورود',
  );

  String get signUp => _value(
    en: 'Sign Up',
    es: 'Registrarse',
    fr: "S'inscrire",
    ru: 'Регистрация',
    uk: 'Реєстрація',
    fa: 'ثبت‌نام',
  );

  String get signOut => _value(
    en: 'Sign Out',
    es: 'Cerrar sesión',
    fr: 'Se déconnecter',
    ru: 'Выйти',
    uk: 'Вийти',
    fa: 'خروج',
  );

  String get email => _value(
    en: 'Email',
    es: 'Correo electrónico',
    fr: 'E-mail',
    ru: 'Эл. почта',
    uk: 'Ел. пошта',
    fa: 'ایمیل',
  );

  String get password => _value(
    en: 'Password',
    es: 'Contraseña',
    fr: 'Mot de passe',
    ru: 'Пароль',
    uk: 'Пароль',
    fa: 'رمز عبور',
  );

  String get confirmPassword => _value(
    en: 'Confirm password',
    es: 'Confirmar contraseña',
    fr: 'Confirmer le mot de passe',
    ru: 'Подтвердите пароль',
    uk: 'Підтвердьте пароль',
    fa: 'تأیید رمز عبور',
  );

  String get forgotPassword => _value(
    en: 'Forgot password?',
    es: '¿Olvidaste tu contraseña?',
    fr: 'Mot de passe oublié?',
    ru: 'Забыли пароль?',
    uk: 'Забули пароль?',
    fa: 'رمز عبور را فراموش کردید؟',
  );

  String get continueWithoutAccount => _value(
    en: 'Continue without account',
    es: 'Continuar sin cuenta',
    fr: 'Continuer sans compte',
    ru: 'Продолжить без аккаунта',
    uk: 'Продовжити без акаунту',
    fa: 'ادامه بدون حساب',
  );

  String get guestMode => _value(
    en: 'Guest mode',
    es: 'Modo invitado',
    fr: 'Mode invité',
    ru: 'Гостевой режим',
    uk: 'Гостьовий режим',
    fa: 'حالت مهمان',
  );

  String get createAccount => _value(
    en: 'Create account',
    es: 'Crear cuenta',
    fr: 'Créer un compte',
    ru: 'Создать аккаунт',
    uk: 'Створити акаунт',
    fa: 'ایجاد حساب',
  );

  String get alreadyHaveAccount => _value(
    en: 'Already have an account?',
    es: '¿Ya tienes una cuenta?',
    fr: 'Vous avez déjà un compte?',
    ru: 'Уже есть аккаунт?',
    uk: 'Вже маєте акаунт?',
    fa: 'قبلاً حساب دارید؟',
  );

  String get dontHaveAccount => _value(
    en: "Don't have an account?",
    es: '¿No tienes una cuenta?',
    fr: 'Pas encore de compte?',
    ru: 'Нет аккаунта?',
    uk: 'Немає акаунту?',
    fa: 'حساب ندارید؟',
  );

  String get passwordResetSent => _value(
    en: 'Password reset email sent',
    es: 'Correo de restablecimiento enviado',
    fr: 'E-mail de réinitialisation envoyé',
    ru: 'Письмо для сброса пароля отправлено',
    uk: 'Лист для скидання пароля надіслано',
    fa: 'ایمیل بازنشانی رمز ارسال شد',
  );

  String get passwordsDoNotMatch => _value(
    en: 'Passwords do not match',
    es: 'Las contraseñas no coinciden',
    fr: 'Les mots de passe ne correspondent pas',
    ru: 'Пароли не совпадают',
    uk: 'Паролі не збігаються',
    fa: 'رمزهای عبور مطابقت ندارند',
  );

  String get passwordTooShort => _value(
    en: 'Password must be at least 6 characters',
    es: 'La contraseña debe tener al menos 6 caracteres',
    fr: 'Le mot de passe doit contenir au moins 6 caractères',
    ru: 'Пароль должен содержать не менее 6 символов',
    uk: 'Пароль має містити щонайменше 6 символів',
    fa: 'رمز عبور باید حداقل ۶ کاراکتر باشد',
  );

  String get authFailed => _value(
    en: 'Sign in failed. Please try again.',
    es: 'Error al iniciar sesión. Inténtalo de nuevo.',
    fr: 'Échec de la connexion. Veuillez réessayer.',
    ru: 'Ошибка входа. Попробуйте снова.',
    uk: 'Помилка входу. Спробуйте ще раз.',
    fa: 'ورود ناموفق بود. دوباره تلاش کنید.',
  );

  String get signedOut => _value(
    en: 'Signed out',
    es: 'Sesión cerrada',
    fr: 'Déconnecté',
    ru: 'Выход выполнен',
    uk: 'Вийшли з системи',
    fa: 'از سیستم خارج شدید',
  );

  // ─── Cloud backup ─────────────────────────────────────────────────────────

  String get cloudBackup => _value(
    en: 'Cloud Backup',
    es: 'Copia en la nube',
    fr: 'Sauvegarde cloud',
    ru: 'Облачная копия',
    uk: 'Хмарна резервна копія',
    fa: 'پشتیبان ابری',
  );

  String get backupToCloud => _value(
    en: 'Back up to cloud',
    es: 'Hacer copia en la nube',
    fr: 'Sauvegarder dans le cloud',
    ru: 'Создать облачную копию',
    uk: 'Зберегти в хмарі',
    fa: 'پشتیبان‌گیری در ابر',
  );

  String get restoreFromCloud => _value(
    en: 'Restore from cloud',
    es: 'Restaurar desde la nube',
    fr: 'Restaurer depuis le cloud',
    ru: 'Восстановить из облака',
    uk: 'Відновити з хмари',
    fa: 'بازیابی از ابر',
  );

  String get lastCloudBackup => _value(
    en: 'Last cloud backup',
    es: 'Última copia en la nube',
    fr: 'Dernière sauvegarde cloud',
    ru: 'Последняя облачная копия',
    uk: 'Остання хмарна копія',
    fa: 'آخرین پشتیبان ابری',
  );

  String get signInToUseCloudBackup => _value(
    en: 'Sign in to use cloud backup',
    es: 'Inicia sesión para usar la copia en la nube',
    fr: 'Connectez-vous pour utiliser la sauvegarde cloud',
    ru: 'Войдите для использования облачного резервного копирования',
    uk: 'Увійдіть, щоб використовувати хмарну резервну копію',
    fa: 'برای استفاده از پشتیبان ابری وارد شوید',
  );

  String get cloudBackupUploaded => _value(
    en: 'Backed up to cloud',
    es: 'Copia guardada en la nube',
    fr: 'Sauvegardé dans le cloud',
    ru: 'Резервная копия сохранена в облаке',
    uk: 'Резервну копію збережено в хмарі',
    fa: 'پشتیبان در ابر ذخیره شد',
  );

  String get cloudBackupExplanation => _value(
    en: 'Cloud backup saves your trips and settings to your account.',
    es: 'La copia en la nube guarda tus viajes y ajustes en tu cuenta.',
    fr: 'La sauvegarde cloud enregistre vos trajets et réglages sur votre compte.',
    ru: 'Облачная копия сохраняет ваши поездки и настройки в аккаунте.',
    uk: 'Хмарна копія зберігає ваші поїздки та налаштування в акаунті.',
    fa: 'پشتیبان ابری سفرها و تنظیمات شما را در حساب‌تان ذخیره می‌کند.',
  );

  String get cloudRestoreExplanation => _value(
    en: 'Restore replaces local data on this device.',
    es: 'Restaurar reemplaza los datos locales en este dispositivo.',
    fr: 'La restauration remplace les données locales sur cet appareil.',
    ru: 'Восстановление заменяет локальные данные на этом устройстве.',
    uk: 'Відновлення замінює локальні дані на цьому пристрої.',
    fa: 'بازیابی داده‌های محلی این دستگاه را جایگزین می‌کند.',
  );

  String get cloudBackupRestored => _value(
    en: 'Cloud backup restored',
    es: 'Copia en la nube restaurada',
    fr: 'Sauvegarde cloud restaurée',
    ru: 'Облачная резервная копия восстановлена',
    uk: 'Хмарну резервну копію відновлено',
    fa: 'پشتیبان ابری بازیابی شد',
  );

  String get cloudBackupFailed => _value(
    en: 'Cloud backup failed',
    es: 'Error al hacer copia en la nube',
    fr: 'Échec de la sauvegarde cloud',
    ru: 'Ошибка облачного резервного копирования',
    uk: 'Помилка хмарного резервного копіювання',
    fa: 'پشتیبان‌گیری ابری ناموفق بود',
  );

  String get cloudRestoreFailed => _value(
    en: 'Cloud restore failed',
    es: 'Error al restaurar desde la nube',
    fr: 'Échec de la restauration cloud',
    ru: 'Ошибка восстановления из облака',
    uk: 'Помилка відновлення з хмари',
    fa: 'بازیابی از ابر ناموفق بود',
  );

  String get cloudRestoreConfirmTitle => _value(
    en: 'Restore from cloud?',
    es: '¿Restaurar desde la nube?',
    fr: 'Restaurer depuis le cloud?',
    ru: 'Восстановить из облака?',
    uk: 'Відновити з хмари?',
    fa: 'از ابر بازیابی شود؟',
  );

  String get cloudRestoreConfirmMessage => _value(
    en: 'Restoring from cloud will replace all your current trips, preferences, and work mode settings.',
    es: 'Restaurar desde la nube reemplazará todos tus viajes, preferencias y configuración de modo trabajo.',
    fr: 'La restauration depuis le cloud remplacera tous vos trajets, préférences et paramètres de travail.',
    ru: 'Восстановление из облака заменит все поездки, настройки и параметры рабочего режима.',
    uk: 'Відновлення з хмари замінить усі поїздки, налаштування та параметри робочого режиму.',
    fa: 'بازیابی از ابر، تمام سفرها، تنظیمات و حالت کاری فعلی شما را جایگزین می‌کند.',
  );

  String get noCloudBackupFound => _value(
    en: 'No cloud backup found',
    es: 'No se encontró copia en la nube',
    fr: 'Aucune sauvegarde cloud trouvée',
    ru: 'Облачная резервная копия не найдена',
    uk: 'Хмарна резервна копія не знайдена',
    fa: 'پشتیبان ابری یافت نشد',
  );

  // ─── Privacy & Data ───────────────────────────────────────────────────────

  String get privacyAndData => _value(
    en: 'Privacy & Data',
    es: 'Privacidad y datos',
    fr: 'Confidentialité et données',
    ru: 'Конфиденциальность и данные',
    uk: 'Конфіденційність і дані',
    fa: 'حریم خصوصی و داده‌ها',
  );

  String get tripsStoredLocally => _value(
    en: 'Trips are stored locally on this device.',
    es: 'Los viajes se almacenan localmente en este dispositivo.',
    fr: 'Les trajets sont stockés localement sur cet appareil.',
    ru: 'Поездки хранятся локально на этом устройстве.',
    uk: 'Поїздки зберігаються локально на цьому пристрої.',
    fa: 'سفرها به صورت محلی در این دستگاه ذخیره می‌شوند.',
  );

  String get cloudBackupOptional => _value(
    en: 'Cloud backup is optional and only available when signed in.',
    es: 'La copia en la nube es opcional y solo está disponible al iniciar sesión.',
    fr: 'La sauvegarde cloud est facultative et disponible uniquement une fois connecté.',
    ru: 'Облачное резервное копирование необязательно и доступно только при входе в аккаунт.',
    uk: 'Хмарне резервне копіювання необов\'язкове і доступне лише після входу в акаунт.',
    fa: 'پشتیبان ابری اختیاری است و فقط پس از ورود در دسترس است.',
  );

  String get locationUsageExplanation => _value(
    en: 'Location is used only for trip tracking and address suggestions.',
    es: 'La ubicación se usa solo para el seguimiento de viajes y sugerencias de dirección.',
    fr: "La localisation est utilisée uniquement pour le suivi des trajets et les suggestions d'adresse.",
    ru: 'Геолокация используется только для отслеживания поездок и подсказок адресов.',
    uk: 'Геолокація використовується лише для відстеження поїздок та підказок адрес.',
    fa: 'موقعیت مکانی فقط برای ردیابی سفر و پیشنهاد آدرس استفاده می‌شود.',
  );

  String get foregroundTrackingExplanation => _value(
    en: 'Tracking continues while the screen is off. A notification is shown during active tracking.',
    es: 'El rastreo continúa con la pantalla apagada. Se muestra una notificación durante el rastreo activo.',
    fr: "Le suivi continue écran éteint. Une notification est affichée pendant le suivi actif.",
    ru: 'Отслеживание продолжается при выключенном экране. Во время отслеживания отображается уведомление.',
    uk: 'Відстеження триває при вимкненому екрані. Під час активного відстеження відображається сповіщення.',
    fa: 'ردیابی با خاموشی صفحه ادامه می‌یابد. در طول ردیابی فعال یک اعلان نمایش داده می‌شود.',
  );

  // ─── Internal ─────────────────────────────────────────────────────────────

  // ─── Tracking Diagnostics ────────────────────────────────────────────────

  String get trackingDiagnostics => _value(
    en: 'Permission check',
    es: 'Revisión de permisos',
    fr: 'Vérification des autorisations',
    ru: 'Проверка разрешений',
    uk: 'Перевірка дозволів',
    fa: 'بررسی اجازه‌ها',
  );

  String get trackingDiagnosticsSubtitle => _value(
    en: 'GPS, notifications, and battery checks',
    es: 'GPS, notificaciones y batería',
    fr: 'GPS, notifications et batterie',
    ru: 'GPS, уведомления и батарея',
    uk: 'GPS, сповіщення та батарея',
    fa: 'GPS، اعلان‌ها و باتری',
  );

  String get phoneReadiness => _value(
    en: 'Phone readiness',
    es: 'Estado del teléfono',
    fr: 'État du téléphone',
    ru: 'Готовность телефона',
    uk: 'Готовність телефону',
    fa: 'آمادگی تلفن',
  );

  String get locationServices => _value(
    en: 'Location services',
    es: 'Servicios de ubicación',
    fr: 'Services de localisation',
    ru: 'Службы геолокации',
    uk: 'Служби геолокації',
    fa: 'خدمات مکان‌یابی',
  );

  String get locationPermission => _value(
    en: 'Location permission',
    es: 'Permiso de ubicación',
    fr: 'Autorisation de localisation',
    ru: 'Разрешение геолокации',
    uk: 'Дозвіл геолокації',
    fa: 'اجازه مکان‌یابی',
  );

  String get tripSavedNotifications => _value(
    en: 'Trip saved notifications',
    es: 'Notificaciones de viaje guardado',
    fr: 'Notifications de trajet enregistré',
    ru: 'Уведомления о сохранении поездки',
    uk: 'Сповіщення про збережену поїздку',
    fa: 'اعلان‌های ذخیره سفر',
  );

  String get batteryOptimization => _value(
    en: 'Battery optimization',
    es: 'Optimización de batería',
    fr: 'Optimisation de la batterie',
    ru: 'Оптимизация батареи',
    uk: 'Оптимізація батареї',
    fa: 'بهینه‌سازی باتری',
  );

  String get liveTrackingState => _value(
    en: 'Live tracking state',
    es: 'Estado de seguimiento',
    fr: 'État du suivi en direct',
    ru: 'Состояние отслеживания',
    uk: 'Стан відстеження',
    fa: 'وضعیت ردیابی زنده',
  );

  String get manualTracking => _value(
    en: 'Manual tracking',
    es: 'Seguimiento manual',
    fr: 'Suivi manuel',
    ru: 'Ручное отслеживание',
    uk: 'Ручне відстеження',
    fa: 'ردیابی دستی',
  );

  String get lastGpsFix => _value(
    en: 'Last GPS fix',
    es: 'Última señal GPS',
    fr: 'Dernier point GPS',
    ru: 'Последняя точка GPS',
    uk: 'Остання точка GPS',
    fa: 'آخرین موقعیت GPS',
  );

  String get refreshDiagnostics => _value(
    en: 'Refresh checks',
    es: 'Actualizar revisión',
    fr: 'Actualiser les vérifications',
    ru: 'Обновить проверку',
    uk: 'Оновити перевірку',
    fa: 'به‌روزرسانی بررسی‌ها',
  );

  String get allow => _value(
    en: 'Allow',
    es: 'Permitir',
    fr: 'Autoriser',
    ru: 'Разрешить',
    uk: 'Дозволити',
    fa: 'اجازه دادن',
  );

  String get sendTestNotification => _value(
    en: 'Send test notification',
    es: 'Enviar notificación de prueba',
    fr: 'Envoyer une notification test',
    ru: 'Отправить тестовое уведомление',
    uk: 'Надіслати тестове сповіщення',
    fa: 'ارسال اعلان آزمایشی',
  );

  String get testNotificationBody => _value(
    en: 'Notifications are working.',
    es: 'Las notificaciones funcionan.',
    fr: 'Les notifications fonctionnent.',
    ru: 'Уведомления работают.',
    uk: 'Сповіщення працюють.',
    fa: 'اعلان‌ها کار می‌کنند.',
  );

  String get testNotificationSent => _value(
    en: 'Test notification sent.',
    es: 'Notificación de prueba enviada.',
    fr: 'Notification test envoyée.',
    ru: 'Тестовое уведомление отправлено.',
    uk: 'Тестове сповіщення надіслано.',
    fa: 'اعلان آزمایشی ارسال شد.',
  );

  String get notificationTestHint => _value(
    en: 'If nothing appears, enable notifications for MarV Route in Android settings.',
    es: 'Si no aparece nada, activa las notificaciones de MarV Route en los ajustes de Android.',
    fr: "Si rien n'apparaît, activez les notifications de MarV Route dans les réglages Android.",
    ru: 'Если ничего не появилось, включите уведомления MarV Route в настройках Android.',
    uk: 'Якщо нічого не зʼявилося, увімкніть сповіщення MarV Route в налаштуваннях Android.',
    fa: 'اگر چیزی نمایش داده نشد، اعلان‌های MarV Route را در تنظیمات Android فعال کنید.',
  );

  String get trackingSetupWarningTitle => _value(
    en: 'Tracking setup needs attention',
    es: 'Revisa la configuración de seguimiento',
    fr: 'Le suivi demande une vérification',
    ru: 'Нужно проверить настройки отслеживания',
    uk: 'Потрібно перевірити налаштування відстеження',
    fa: 'تنظیمات ردیابی نیاز به توجه دارد',
  );

  String get trackingSetupWarningBody => _value(
    en: 'Notifications or battery settings may limit trip alerts and background tracking.',
    es: 'Las notificaciones o la batería pueden limitar las alertas y el seguimiento en segundo plano.',
    fr: 'Les notifications ou la batterie peuvent limiter les alertes et le suivi en arrière-plan.',
    ru: 'Уведомления или батарея могут ограничивать оповещения и фоновое отслеживание.',
    uk: 'Сповіщення або налаштування батареї можуть обмежувати попередження та фонове відстеження.',
    fa: 'اعلان‌ها یا تنظیمات باتری ممکن است هشدارهای سفر و ردیابی پس‌زمینه را محدود کند.',
  );

  String get checkPermissions => _value(
    en: 'Check permissions',
    es: 'Revisar permisos',
    fr: 'Vérifier les autorisations',
    ru: 'Проверить разрешения',
    uk: 'Перевірити дозволи',
    fa: 'بررسی اجازه‌ها',
  );

  String get open => _value(
    en: 'Open',
    es: 'Abrir',
    fr: 'Ouvrir',
    ru: 'Открыть',
    uk: 'Відкрити',
    fa: 'باز کردن',
  );

  String get ok =>
      _value(en: 'OK', es: 'OK', fr: 'OK', ru: 'OK', uk: 'OK', fa: 'تأیید');

  String get needsAttention => _value(
    en: 'Needs attention',
    es: 'Requiere atención',
    fr: 'À vérifier',
    ru: 'Требует внимания',
    uk: 'Потребує уваги',
    fa: 'نیاز به توجه دارد',
  );

  String get unknown => _value(
    en: 'Unknown',
    es: 'Desconocido',
    fr: 'Inconnu',
    ru: 'Неизвестно',
    uk: 'Невідомо',
    fa: 'نامشخص',
  );

  String get unrestricted => _value(
    en: 'Unrestricted',
    es: 'Sin restricciones',
    fr: 'Sans restriction',
    ru: 'Без ограничений',
    uk: 'Без обмежень',
    fa: 'بدون محدودیت',
  );

  String get noPointYet => _value(
    en: 'No point yet',
    es: 'Aún no hay punto',
    fr: 'Aucun point pour le moment',
    ru: 'Точки пока нет',
    uk: 'Точки ще немає',
    fa: 'هنوز نقطه‌ای نیست',
  );

  String get tracking => _value(
    en: 'tracking',
    es: 'rastreando',
    fr: 'suivi actif',
    ru: 'отслеживается',
    uk: 'відстежується',
    fa: 'در حال ردیابی',
  );

  String get notTrackingStatus => _value(
    en: 'not tracking',
    es: 'sin seguimiento',
    fr: 'pas de suivi',
    ru: 'не отслеживается',
    uk: 'не відстежується',
    fa: 'ردیابی نمی‌شود',
  );

  String get alwaysPermission => _value(
    en: 'Always',
    es: 'Siempre',
    fr: 'Toujours',
    ru: 'Всегда',
    uk: 'Завжди',
    fa: 'همیشه',
  );

  String get whileInUsePermission => _value(
    en: 'While in use',
    es: 'Mientras se usa',
    fr: 'Pendant l’utilisation',
    ru: 'При использовании',
    uk: 'Під час використання',
    fa: 'هنگام استفاده',
  );

  String get denied => _value(
    en: 'Denied',
    es: 'Denegado',
    fr: 'Refusé',
    ru: 'Запрещено',
    uk: 'Заборонено',
    fa: 'رد شده',
  );

  String get deniedForever => _value(
    en: 'Denied forever',
    es: 'Denegado permanentemente',
    fr: 'Refusé définitivement',
    ru: 'Запрещено навсегда',
    uk: 'Заборонено назавжди',
    fa: 'برای همیشه رد شده',
  );

  String gpsError(Object error) => _value(
    en: 'GPS error: $error',
    es: 'Error de GPS: $error',
    fr: 'Erreur GPS : $error',
    ru: 'Ошибка GPS: $error',
    uk: 'Помилка GPS: $error',
    fa: 'خطای GPS: $error',
  );

  // ─── Trip Purpose Templates ──────────────────────────────────────────────

  String get purposeDelivery => _value(
    en: 'Delivery',
    es: 'Entrega',
    fr: 'Livraison',
    ru: 'Доставка',
    uk: 'Доставка',
    fa: 'تحویل',
  );

  String get purposeClientVisit => _value(
    en: 'Client visit',
    es: 'Visita a cliente',
    fr: 'Visite client',
    ru: 'Визит к клиенту',
    uk: 'Візит до клієнта',
    fa: 'دیدار با مشتری',
  );

  String get purposeSupplies => _value(
    en: 'Supplies',
    es: 'Suministros',
    fr: 'Fournitures',
    ru: 'Закупки',
    uk: 'Закупівлі',
    fa: 'تدارکات',
  );

  String get purposeAirport => _value(
    en: 'Airport',
    es: 'Aeropuerto',
    fr: 'Aéroport',
    ru: 'Аэропорт',
    uk: 'Аеропорт',
    fa: 'فرودگاه',
  );

  String get purposeMaintenance => _value(
    en: 'Maintenance',
    es: 'Mantenimiento',
    fr: 'Entretien',
    ru: 'Обслуживание',
    uk: 'Обслуговування',
    fa: 'نگهداری',
  );

  String get purposeOther => _value(
    en: 'Other',
    es: 'Otro',
    fr: 'Autre',
    ru: 'Другое',
    uk: 'Інше',
    fa: 'سایر',
  );

  String get businessTrip => _value(
    en: 'Business trip',
    es: 'Viaje de trabajo',
    fr: 'Trajet professionnel',
    ru: 'Рабочая поездка',
    uk: 'Робоча поїздка',
    fa: 'سفر کاری',
  );

  String platformBusinessTrip(String platform) => _value(
    en: '$platform business trip',
    es: 'Viaje de trabajo de $platform',
    fr: 'Trajet professionnel $platform',
    ru: 'Рабочая поездка $platform',
    uk: 'Робоча поїздка $platform',
    fa: 'سفر کاری $platform',
  );

  // ─── Trip Tracking Quality ───────────────────────────────────────────────

  String get trackingQuality => _value(
    en: 'Tracking quality',
    es: 'Calidad del seguimiento',
    fr: 'Qualité du suivi',
    ru: 'Качество отслеживания',
    uk: 'Якість відстеження',
    fa: 'کیفیت ردیابی',
  );

  String get trackingQualityGood => _value(
    en: 'Good GPS quality',
    es: 'Buena calidad de GPS',
    fr: 'Bonne qualité GPS',
    ru: 'Хорошее качество GPS',
    uk: 'Хороша якість GPS',
    fa: 'کیفیت GPS خوب است',
  );

  String get trackingQualityFair => _value(
    en: 'Fair GPS quality',
    es: 'Calidad de GPS aceptable',
    fr: 'Qualité GPS moyenne',
    ru: 'Среднее качество GPS',
    uk: 'Середня якість GPS',
    fa: 'کیفیت GPS متوسط است',
  );

  String get trackingQualityPoor => _value(
    en: 'GPS needs attention',
    es: 'El GPS requiere atención',
    fr: 'Le GPS nécessite une vérification',
    ru: 'GPS требует внимания',
    uk: 'GPS потребує уваги',
    fa: 'GPS نیاز به توجه دارد',
  );

  String get trackingQualityGap => _value(
    en: 'GPS gaps detected',
    es: 'Se detectaron pausas de GPS',
    fr: 'Écarts GPS détectés',
    ru: 'Обнаружены разрывы GPS',
    uk: 'Виявлено розриви GPS',
    fa: 'فاصله‌های GPS شناسایی شد',
  );

  String get rawGpsPoints => _value(
    en: 'Raw GPS points',
    es: 'Puntos GPS sin procesar',
    fr: 'Points GPS bruts',
    ru: 'Сырые GPS-точки',
    uk: 'Сирі GPS-точки',
    fa: 'نقاط خام GPS',
  );

  String get acceptedGpsPoints => _value(
    en: 'Accepted points',
    es: 'Puntos aceptados',
    fr: 'Points acceptés',
    ru: 'Принятые точки',
    uk: 'Прийняті точки',
    fa: 'نقاط پذیرفته‌شده',
  );

  String get droppedGpsPoints => _value(
    en: 'Dropped points',
    es: 'Puntos descartados',
    fr: 'Points rejetés',
    ru: 'Отклонённые точки',
    uk: 'Відхилені точки',
    fa: 'نقاط حذف‌شده',
  );

  String get averageGpsAccuracy => _value(
    en: 'Average accuracy',
    es: 'Precisión promedio',
    fr: 'Précision moyenne',
    ru: 'Средняя точность',
    uk: 'Середня точність',
    fa: 'دقت میانگین',
  );

  String get maxGpsGap => _value(
    en: 'Largest GPS gap',
    es: 'Mayor pausa de GPS',
    fr: 'Plus grand écart GPS',
    ru: 'Самый большой разрыв GPS',
    uk: 'Найбільша пауза GPS',
    fa: 'بزرگ‌ترین فاصله GPS',
  );

  String get trackingDuration => _value(
    en: 'Tracking duration',
    es: 'Duración del seguimiento',
    fr: 'Durée du suivi',
    ru: 'Длительность отслеживания',
    uk: 'Тривалість відстеження',
    fa: 'مدت ردیابی',
  );

  String get tripSavedAutomatically => _value(
    en: 'Saved automatically from movement detection.',
    es: 'Guardado automáticamente por detección de movimiento.',
    fr: 'Enregistré automatiquement par détection de mouvement.',
    ru: 'Сохранено автоматически по движению.',
    uk: 'Збережено автоматично за рухом.',
    fa: 'با تشخیص حرکت به‌صورت خودکار ذخیره شد.',
  );

  String get stoppedAfterIdle => _value(
    en: 'Auto detection stops a trip after 3 minutes without movement.',
    es: 'La detección automática detiene el viaje tras 3 minutos sin movimiento.',
    fr: 'La détection automatique arrête le trajet après 3 minutes sans mouvement.',
    ru: 'Автообнаружение завершает поездку после 3 минут без движения.',
    uk: 'Автовиявлення завершує поїздку після 3 хвилин без руху.',
    fa: 'تشخیص خودکار پس از ۳ دقیقه بدون حرکت سفر را متوقف می‌کند.',
  );

  String get routeMayBeShortHint => _value(
    en: 'Large GPS gaps can make the map draw straight lines and undercount distance.',
    es: 'Las pausas grandes de GPS pueden dibujar líneas rectas y reducir la distancia.',
    fr: 'De grands écarts GPS peuvent tracer des lignes droites et sous-estimer la distance.',
    ru: 'Большие разрывы GPS могут рисовать прямые линии и занижать пробег.',
    uk: 'Великі паузи GPS можуть малювати прямі лінії та занижувати пробіг.',
    fa: 'فاصله‌های بزرگ GPS می‌تواند مسیر را خط مستقیم نشان دهد و مسافت را کمتر حساب کند.',
  );

  String get distanceCalculationHint => _value(
    en: 'Small parked drift is ignored when calculating distance.',
    es: 'El pequeño movimiento del GPS al estar estacionado no se cuenta.',
    fr: 'Les petites dérives GPS à l’arrêt ne sont pas comptées.',
    ru: 'Небольшой GPS-дрейф на стоянке не учитывается.',
    uk: 'Малий GPS-дрейф під час стоянки не рахується.',
    fa: 'لرزش کوچک GPS هنگام توقف در مسافت حساب نمی‌شود.',
  );

  String get backgroundTrackingChecklist => _value(
    en: 'For best background tracking, keep location allowed and battery unrestricted.',
    es: 'Para mejor seguimiento en segundo plano, permite ubicación y quita restricciones de batería.',
    fr: 'Pour un meilleur suivi en arrière-plan, autorisez la localisation et retirez les restrictions batterie.',
    ru: 'Для фонового отслеживания разрешите геолокацию и снимите ограничения батареи.',
    uk: 'Для кращого фонового відстеження дозвольте геолокацію та зніміть обмеження батареї.',
    fa: 'برای ردیابی بهتر در پس‌زمینه، مکان‌یابی را فعال و محدودیت باتری را بردارید.',
  );

  String get ready => _value(
    en: 'Ready',
    es: 'Listo',
    fr: 'Prêt',
    ru: 'Готово',
    uk: 'Готово',
    fa: 'آماده',
  );

  String get fixNow => _value(
    en: 'Fix now',
    es: 'Corregir ahora',
    fr: 'Corriger',
    ru: 'Исправить',
    uk: 'Виправити',
    fa: 'اکنون اصلاح کنید',
  );

  String get actionNeeded => _value(
    en: 'Action needed',
    es: 'Requiere acción',
    fr: 'Action requise',
    ru: 'Требуется действие',
    uk: 'Потрібна дія',
    fa: 'اقدام لازم است',
  );

  String get trackingReliabilityMode => _value(
    en: 'Tracking Reliability Mode',
    es: 'Modo de seguimiento fiable',
    fr: 'Mode de suivi fiable',
    ru: 'Режим надёжного отслеживания',
    uk: 'Режим надійного відстеження',
    fa: 'حالت ردیابی قابل اعتماد',
  );

  String get readyForScreenOffTracking => _value(
    en: 'Ready for screen-off tracking',
    es: 'Listo para rastrear con la pantalla apagada',
    fr: 'Prêt pour le suivi écran éteint',
    ru: 'Готово к отслеживанию с выключенным экраном',
    uk: 'Готово до відстеження з вимкненим екраном',
    fa: 'آماده برای ردیابی با صفحه خاموش',
  );

  String get screenOffTrackingRisk => _value(
    en: 'Screen-off tracking may have gaps',
    es: 'El seguimiento con pantalla apagada puede tener pausas',
    fr: 'Le suivi écran éteint peut avoir des écarts',
    ru: 'При выключенном экране возможны разрывы',
    uk: 'При вимкненому екрані можливі розриви',
    fa: 'ردیابی با صفحه خاموش ممکن است فاصله داشته باشد',
  );

  String get reliabilityModeExplanation => _value(
    en: 'This checks the settings that most often cause missing GPS points while the screen is off.',
    es: 'Esto revisa los ajustes que más suelen causar pérdida de puntos GPS con la pantalla apagada.',
    fr: 'Cela vérifie les réglages qui causent le plus souvent des points GPS manquants écran éteint.',
    ru: 'Здесь проверяются настройки, которые чаще всего вызывают пропуски GPS при выключенном экране.',
    uk: 'Тут перевіряються налаштування, які найчастіше спричиняють пропуски GPS при вимкненому екрані.',
    fa: 'این بخش تنظیماتی را بررسی می‌کند که بیشتر باعث حذف نقاط GPS هنگام خاموش بودن صفحه می‌شوند.',
  );

  String get reliabilityChecklist => _value(
    en: 'Reliability checklist',
    es: 'Lista de fiabilidad',
    fr: 'Liste de fiabilité',
    ru: 'Проверка надёжности',
    uk: 'Перевірка надійності',
    fa: 'فهرست اطمینان',
  );

  String get requiredForScreenOffTracking => _value(
    en: 'Required for screen-off tracking',
    es: 'Necesario para rastrear con pantalla apagada',
    fr: 'Nécessaire pour le suivi écran éteint',
    ru: 'Нужно для отслеживания с выключенным экраном',
    uk: 'Потрібно для відстеження з вимкненим екраном',
    fa: 'برای ردیابی با صفحه خاموش لازم است',
  );

  String get recommendedForTripAlerts => _value(
    en: 'Recommended for trip saved alerts',
    es: 'Recomendado para alertas de viaje guardado',
    fr: 'Recommandé pour les alertes de trajet enregistré',
    ru: 'Рекомендуется для уведомлений о поездках',
    uk: 'Рекомендовано для сповіщень про поїздки',
    fa: 'برای اعلان‌های ذخیره سفر توصیه می‌شود',
  );

  String get likelyCause => _value(
    en: 'Likely cause',
    es: 'Causa probable',
    fr: 'Cause probable',
    ru: 'Вероятная причина',
    uk: 'Ймовірна причина',
    fa: 'علت احتمالی',
  );

  String get likelyCauseGpsGap => _value(
    en: 'Android likely paused location updates while the screen was off or battery optimization limited the app.',
    es: 'Probablemente Android pausó la ubicación con la pantalla apagada o la batería limitó la app.',
    fr: 'Android a probablement mis la localisation en pause écran éteint ou la batterie a limité l’app.',
    ru: 'Android, вероятно, приостановил геолокацию при выключенном экране или батарея ограничила приложение.',
    uk: 'Android, ймовірно, призупинив геолокацію при вимкненому екрані або батарея обмежила додаток.',
    fa: 'احتمالاً Android هنگام خاموش بودن صفحه مکان‌یابی را متوقف کرده یا بهینه‌سازی باتری برنامه را محدود کرده است.',
  );

  String get likelyCausePoorAccuracy => _value(
    en: 'The GPS signal was weak. Open sky usually improves accuracy.',
    es: 'La señal GPS fue débil. Cielo abierto suele mejorar la precisión.',
    fr: 'Le signal GPS était faible. Le ciel dégagé améliore souvent la précision.',
    ru: 'Сигнал GPS был слабым. На открытом месте точность обычно лучше.',
    uk: 'Сигнал GPS був слабким. На відкритому місці точність зазвичай краща.',
    fa: 'سیگنال GPS ضعیف بود. فضای باز معمولاً دقت را بهتر می‌کند.',
  );

  String get setupChecklist => _value(
    en: 'Setup checklist',
    es: 'Lista de configuración',
    fr: 'Liste de configuration',
    ru: 'Список настройки',
    uk: 'Список налаштування',
    fa: 'فهرست راه‌اندازی',
  );

  String get checklistChooseCountry => _value(
    en: 'Choose country',
    es: 'Elegir país',
    fr: 'Choisir le pays',
    ru: 'Выбрать страну',
    uk: 'Обрати країну',
    fa: 'انتخاب کشور',
  );

  String get checklistAddVehicle => _value(
    en: 'Add vehicle',
    es: 'Agregar vehículo',
    fr: 'Ajouter un véhicule',
    ru: 'Добавить авто',
    uk: 'Додати авто',
    fa: 'افزودن خودرو',
  );

  String get checklistEnableAutoDetection => _value(
    en: 'Enable auto detection',
    es: 'Activar detección automática',
    fr: 'Activer la détection automatique',
    ru: 'Включить автообнаружение',
    uk: 'Увімкнути авто-виявлення',
    fa: 'فعال کردن تشخیص خودکار',
  );

  String get checklistAddWorkShift => _value(
    en: 'Add work shift',
    es: 'Agregar turno de trabajo',
    fr: 'Ajouter un créneau de travail',
    ru: 'Добавить рабочую смену',
    uk: 'Додати робочу зміну',
    fa: 'افزودن شیفت کاری',
  );

  String get checklistCloudBackup => _value(
    en: 'Make cloud backup',
    es: 'Crear copia en la nube',
    fr: 'Faire une sauvegarde cloud',
    ru: 'Сделать облачную копию',
    uk: 'Зробити cloud backup',
    fa: 'ایجاد پشتیبان ابری',
  );

  String get weeklyOdometerReminder => _value(
    en: 'Weekly odometer check',
    es: 'Revisión semanal del odómetro',
    fr: 'Vérification hebdomadaire du compteur',
    ru: 'Еженедельная проверка одометра',
    uk: 'Щотижнева перевірка одометра',
    fa: 'بررسی هفتگی کیلومترشمار',
  );

  String get weeklyOdometerReminderMessage => _value(
    en: 'Enter the current odometer reading so oil and brake pad reminders stay accurate.',
    es: 'Ingresa el odómetro actual para mantener precisos los recordatorios de aceite y frenos.',
    fr: 'Saisissez le kilométrage actuel pour garder les rappels huile et freins précis.',
    ru: 'Введите текущий одометр, чтобы напоминания о масле и колодках были точными.',
    uk: 'Введіть поточний показник одометра, щоб нагадування про масло та колодки були точними.',
    fa: 'عدد فعلی کیلومترشمار را وارد کنید تا یادآوری روغن و لنت ترمز دقیق بماند.',
  );

  String get updateOdometer => _value(
    en: 'Update odometer',
    es: 'Actualizar odómetro',
    fr: 'Mettre à jour le compteur',
    ru: 'Обновить одометр',
    uk: 'Оновити одометр',
    fa: 'به‌روزرسانی کیلومترشمار',
  );

  String get odometerUpdated => _value(
    en: 'Odometer updated',
    es: 'Odómetro actualizado',
    fr: 'Compteur mis à jour',
    ru: 'Одометр обновлён',
    uk: 'Одометр оновлено',
    fa: 'کیلومترشمار به‌روزرسانی شد',
  );

  String get quickReview => _value(
    en: 'Quick review',
    es: 'Revisión rápida',
    fr: 'Vérification rapide',
    ru: 'Быстрая проверка',
    uk: 'Швидка перевірка',
    fa: 'بررسی سریع',
  );

  String get allPendingTripsReviewed => _value(
    en: 'All pending trips reviewed',
    es: 'Todos los viajes pendientes fueron revisados',
    fr: 'Tous les trajets en attente ont été vérifiés',
    ru: 'Все поездки на проверку проверены',
    uk: 'Усі очікувані поїздки перевірено',
    fa: 'همه سفرهای منتظر بررسی شدند',
  );

  String suggestedPlatform(String platform) => _value(
    en: 'Suggested: $platform',
    es: 'Sugerido: $platform',
    fr: 'Suggéré : $platform',
    ru: 'Предложено: $platform',
    uk: 'Пропозиція: $platform',
    fa: 'پیشنهاد: $platform',
  );

  String usePlatform(String platform) => _value(
    en: 'Use $platform',
    es: 'Usar $platform',
    fr: 'Utiliser $platform',
    ru: 'Использовать $platform',
    uk: 'Використати $platform',
    fa: 'استفاده از $platform',
  );

  String get mergeNearbySegment => _value(
    en: 'Merge nearby segment',
    es: 'Unir segmento cercano',
    fr: 'Fusionner le segment proche',
    ru: 'Объединить близкий сегмент',
    uk: 'Об’єднати близький сегмент',
    fa: 'ادغام بخش نزدیک',
  );

  String get tripSegmentsMerged => _value(
    en: 'Trip segments merged',
    es: 'Segmentos del viaje unidos',
    fr: 'Segments du trajet fusionnés',
    ru: 'Сегменты поездки объединены',
    uk: 'Сегменти поїздки об’єднано',
    fa: 'بخش‌های سفر ادغام شدند',
  );

  String get whatNeedsAttention => _value(
    en: 'What needs attention',
    es: 'Qué requiere atención',
    fr: 'Éléments à vérifier',
    ru: 'Что требует внимания',
    uk: 'Що потребує уваги',
    fa: 'چه چیزی نیاز به توجه دارد',
  );

  String detectedTripsNeedReview(int count) => _value(
    en: '$count detected trips need review',
    es: '$count viajes detectados requieren revisión',
    fr: '$count trajets détectés sont à vérifier',
    ru: '$count обнаруженных поездок требуют проверки',
    uk: '$count авто-виявлених поїздок потребують перевірки',
    fa: '$count سفر شناسایی‌شده نیاز به بررسی دارد',
  );

  String tripsHaveGpsIssues(int count) => _value(
    en: '$count trips have GPS gaps or weak accuracy',
    es: '$count viajes tienen pausas de GPS o baja precisión',
    fr: '$count trajets ont des coupures GPS ou une faible précision',
    ru: '$count поездок имеют пробелы GPS или низкую точность',
    uk: '$count поїздок мають GPS-паузи або слабку точність',
    fa: '$count سفر دارای وقفه GPS یا دقت ضعیف است',
  );

  String get taxReportTemplates => _value(
    en: 'Tax report templates',
    es: 'Plantillas de informes fiscales',
    fr: 'Modèles de rapports fiscaux',
    ru: 'Шаблоны налоговых отчётов',
    uk: 'Шаблони податкових звітів',
    fa: 'قالب‌های گزارش مالیاتی',
  );

  String get mileageSummary => _value(
    en: 'Mileage summary',
    es: 'Resumen de millaje',
    fr: 'Résumé du kilométrage',
    ru: 'Сводка пробега',
    uk: 'Зведення пробігу',
    fa: 'خلاصه مسافت',
  );

  String businessMileage(String distance) => _value(
    en: '$distance business mileage',
    es: '$distance de millaje de trabajo',
    fr: '$distance de kilométrage professionnel',
    ru: '$distance рабочего пробега',
    uk: '$distance робочого пробігу',
    fa: '$distance مسافت کاری',
  );

  String get platformBreakdownReport => _value(
    en: 'Platform breakdown',
    es: 'Desglose por plataforma',
    fr: 'Répartition par plateforme',
    ru: 'Разбивка по платформам',
    uk: 'Розбивка за платформами',
    fa: 'تفکیک بر اساس پلتفرم',
  );

  String platformCount(int count) => _value(
    en: '$count platforms',
    es: '$count plataformas',
    fr: '$count plateformes',
    ru: '$count платформ',
    uk: '$count платформ',
    fa: '$count پلتفرم',
  );

  String get rawTripLog => _value(
    en: 'Raw trip log',
    es: 'Registro completo de viajes',
    fr: 'Journal brut des trajets',
    ru: 'Полный журнал поездок',
    uk: 'Повний журнал поїздок',
    fa: 'ثبت خام سفرها',
  );

  String tripsAsCsv(int count) => _value(
    en: '$count trips as CSV',
    es: '$count viajes como CSV',
    fr: '$count trajets en CSV',
    ru: '$count поездок в CSV',
    uk: '$count поїздок у CSV',
    fa: '$count سفر به صورت CSV',
  );

  String get tripQualityManual => _value(
    en: 'Manual',
    es: 'Manual',
    fr: 'Manuel',
    ru: 'Вручную',
    uk: 'Вручну',
    fa: 'دستی',
  );

  String get tripQualityManualDetail => _value(
    en: 'No GPS quality diagnostics.',
    es: 'Sin diagnóstico de calidad GPS.',
    fr: 'Aucun diagnostic de qualité GPS.',
    ru: 'Нет диагностики качества GPS.',
    uk: 'Немає діагностики якості GPS.',
    fa: 'عیب‌یابی کیفیت GPS وجود ندارد.',
  );

  String get tripQualityGpsGaps => _value(
    en: 'GPS gaps',
    es: 'Pausas GPS',
    fr: 'Coupures GPS',
    ru: 'Пробелы GPS',
    uk: 'GPS-паузи',
    fa: 'وقفه‌های GPS',
  );

  String get tripQualityGpsGapsDetail => _value(
    en: 'Large GPS pauses may undercount mileage.',
    es: 'Las pausas grandes de GPS pueden reducir el millaje calculado.',
    fr: 'De grandes coupures GPS peuvent sous-estimer la distance.',
    ru: 'Большие паузы GPS могут занижать пробег.',
    uk: 'Великі GPS-паузи можуть занижувати пробіг.',
    fa: 'وقفه‌های زیاد GPS ممکن است مسافت را کم حساب کند.',
  );

  String get tripQualityLowGps => _value(
    en: 'Low GPS',
    es: 'GPS bajo',
    fr: 'GPS faible',
    ru: 'Слабый GPS',
    uk: 'Слабкий GPS',
    fa: 'GPS ضعیف',
  );

  String get tripQualityLowGpsDetail => _value(
    en: 'Average GPS accuracy was weak.',
    es: 'La precisión media del GPS fue baja.',
    fr: 'La précision GPS moyenne était faible.',
    ru: 'Средняя точность GPS была низкой.',
    uk: 'Середня точність GPS була слабкою.',
    fa: 'دقت میانگین GPS ضعیف بود.',
  );

  String get tripQualityGpsGood => _value(
    en: 'GPS good',
    es: 'GPS bueno',
    fr: 'GPS bon',
    ru: 'GPS хороший',
    uk: 'GPS добрий',
    fa: 'GPS خوب',
  );

  String get tripQualityGpsGoodDetail => _value(
    en: 'Mileage quality looks healthy.',
    es: 'La calidad del millaje se ve bien.',
    fr: 'La qualité du kilométrage semble bonne.',
    ru: 'Качество пробега выглядит хорошим.',
    uk: 'Якість пробігу виглядає нормальною.',
    fa: 'کیفیت مسافت خوب به نظر می‌رسد.',
  );

  String get authEmailAlreadyInUse => _value(
    en: 'This email is already registered. Try signing in.',
    es: 'Este correo ya está registrado. Intenta iniciar sesión.',
    fr: 'Cet e-mail est déjà enregistré. Essayez de vous connecter.',
    ru: 'Этот адрес уже зарегистрирован. Попробуйте войти.',
    uk: 'Цю електронну адресу вже зареєстровано. Спробуйте увійти.',
    fa: 'این ایمیل قبلاً ثبت شده است. وارد شوید.',
  );

  String get authInvalidEmail => _value(
    en: 'Please enter a valid email address.',
    es: 'Ingresa una dirección de correo válida.',
    fr: 'Saisissez une adresse e-mail valide.',
    ru: 'Введите действительный адрес электронной почты.',
    uk: 'Введіть дійсну електронну адресу.',
    fa: 'لطفاً یک ایمیل معتبر وارد کنید.',
  );

  String get authWeakPassword => _value(
    en: 'Password is too weak. Use at least 6 characters.',
    es: 'La contraseña es demasiado débil. Usa al menos 6 caracteres.',
    fr: 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.',
    ru: 'Пароль слишком слабый. Используйте минимум 6 символов.',
    uk: 'Пароль занадто слабкий. Використайте щонайменше 6 символів.',
    fa: 'رمز عبور خیلی ضعیف است. حداقل از ۶ نویسه استفاده کنید.',
  );

  String get authWrongPassword => _value(
    en: 'Incorrect password.',
    es: 'Contraseña incorrecta.',
    fr: 'Mot de passe incorrect.',
    ru: 'Неверный пароль.',
    uk: 'Неправильний пароль.',
    fa: 'رمز عبور نادرست است.',
  );

  String get authUserNotFound => _value(
    en: 'No account found with this email.',
    es: 'No se encontró una cuenta con este correo.',
    fr: 'Aucun compte trouvé avec cet e-mail.',
    ru: 'Аккаунт с этим адресом не найден.',
    uk: 'Обліковий запис із цією адресою не знайдено.',
    fa: 'هیچ حسابی با این ایمیل پیدا نشد.',
  );

  String get networkErrorCheckConnection => _value(
    en: 'Network error. Check your internet connection.',
    es: 'Error de red. Revisa tu conexión a internet.',
    fr: 'Erreur réseau. Vérifiez votre connexion internet.',
    ru: 'Ошибка сети. Проверьте подключение к интернету.',
    uk: 'Помилка мережі. Перевірте підключення до інтернету.',
    fa: 'خطای شبکه. اتصال اینترنت خود را بررسی کنید.',
  );

  String get authTooManyRequests => _value(
    en: 'Too many attempts. Try again later.',
    es: 'Demasiados intentos. Inténtalo más tarde.',
    fr: 'Trop de tentatives. Réessayez plus tard.',
    ru: 'Слишком много попыток. Попробуйте позже.',
    uk: 'Забагато спроб. Спробуйте пізніше.',
    fa: 'تلاش‌های زیادی انجام شد. بعداً دوباره امتحان کنید.',
  );

  String get authOperationNotAllowed => _value(
    en: 'Email/password sign-in is not enabled.',
    es: 'El inicio con correo y contraseña no está habilitado.',
    fr: 'La connexion par e-mail/mot de passe n’est pas activée.',
    ru: 'Вход по email/паролю не включён.',
    uk: 'Вхід через email/пароль не ввімкнено.',
    fa: 'ورود با ایمیل/رمز عبور فعال نیست.',
  );

  String get authenticationFailedTryAgain => _value(
    en: 'Authentication failed. Please try again.',
    es: 'Autenticación fallida. Inténtalo de nuevo.',
    fr: 'Échec de l’authentification. Veuillez réessayer.',
    ru: 'Ошибка аутентификации. Попробуйте снова.',
    uk: 'Помилка автентифікації. Спробуйте ще раз.',
    fa: 'احراز هویت ناموفق بود. دوباره تلاش کنید.',
  );

  String get cloudBackupFailedTryAgain => _value(
    en: 'Cloud backup failed. Please try again.',
    es: 'La copia en la nube falló. Inténtalo de nuevo.',
    fr: 'La sauvegarde cloud a échoué. Veuillez réessayer.',
    ru: 'Не удалось создать облачную копию. Попробуйте снова.',
    uk: 'Не вдалося створити хмарну резервну копію. Спробуйте ще раз.',
    fa: 'پشتیبان‌گیری ابری ناموفق بود. دوباره تلاش کنید.',
  );

  String get cloudRestoreFailedTryAgain => _value(
    en: 'Cloud restore failed. Please try again.',
    es: 'La restauración desde la nube falló. Inténtalo de nuevo.',
    fr: 'La restauration cloud a échoué. Veuillez réessayer.',
    ru: 'Не удалось восстановить из облака. Попробуйте снова.',
    uk: 'Не вдалося відновити з хмари. Спробуйте ще раз.',
    fa: 'بازیابی ابری ناموفق بود. دوباره تلاش کنید.',
  );

  String get cloudBackupPermissionDenied => _value(
    en: 'Cloud backup permission denied. Please sign in again.',
    es: 'Permiso de copia en la nube denegado. Inicia sesión de nuevo.',
    fr: 'Autorisation de sauvegarde cloud refusée. Reconnectez-vous.',
    ru: 'Доступ к облачной копии запрещён. Войдите снова.',
    uk: 'Доступ до хмарної резервної копії заборонено. Увійдіть знову.',
    fa: 'مجوز پشتیبان‌گیری ابری رد شد. دوباره وارد شوید.',
  );

  String get fuelLog => _value(
    en: 'Fuel Log',
    es: 'Registro de combustible',
    fr: 'Journal carburant',
    ru: 'Журнал топлива',
    uk: 'Журнал пального',
    fa: 'ثبت سوخت',
  );

  String get fuelSummary => _value(
    en: 'Fuel summary',
    es: 'Resumen de combustible',
    fr: 'Résumé carburant',
    ru: 'Сводка топлива',
    uk: 'Підсумок пального',
    fa: 'خلاصه سوخت',
  );

  String get fuelCost => _value(
    en: 'Fuel cost',
    es: 'Costo de combustible',
    fr: 'Coût du carburant',
    ru: 'Стоимость топлива',
    uk: 'Вартість пального',
    fa: 'هزینه سوخت',
  );

  String get addFuel => _value(
    en: 'Add Fuel',
    es: 'Agregar combustible',
    fr: 'Ajouter du carburant',
    ru: 'Добавить топливо',
    uk: 'Додати пальне',
    fa: 'افزودن سوخت',
  );

  String get editFuel => _value(
    en: 'Edit Fuel',
    es: 'Editar combustible',
    fr: 'Modifier le carburant',
    ru: 'Редактировать топливо',
    uk: 'Редагувати пальне',
    fa: 'ویرایش سوخت',
  );

  String get fuelAmount => _value(
    en: 'Fuel amount',
    es: 'Cantidad de combustible',
    fr: 'Quantité de carburant',
    ru: 'Количество топлива',
    uk: 'Кількість пального',
    fa: 'مقدار سوخت',
  );

  String get averageFuelPrice => _value(
    en: 'Average fuel price',
    es: 'Precio promedio del combustible',
    fr: 'Prix moyen du carburant',
    ru: 'Средняя цена топлива',
    uk: 'Середня ціна пального',
    fa: 'میانگین قیمت سوخت',
  );

  String get costPerMile => _value(
    en: 'Cost per mile',
    es: 'Costo por milla',
    fr: 'Coût par mile',
    ru: 'Стоимость за милю',
    uk: 'Вартість за милю',
    fa: 'هزینه در هر مایل',
  );

  String get costPerKm => _value(
    en: 'Cost per km',
    es: 'Costo por km',
    fr: 'Coût par km',
    ru: 'Стоимость за км',
    uk: 'Вартість за км',
    fa: 'هزینه در هر کیلومتر',
  );

  String get perGallon => _value(
    en: 'per gallon',
    es: 'por galón',
    fr: 'par gallon',
    ru: 'за галлон',
    uk: 'за галон',
    fa: 'در هر گالن',
  );

  String get perLiter => _value(
    en: 'per liter',
    es: 'por litro',
    fr: 'par litre',
    ru: 'за литр',
    uk: 'за літр',
    fa: 'در هر لیتر',
  );

  String get notAvailable => _value(
    en: 'N/A',
    es: 'N/D',
    fr: 'N/D',
    ru: 'Н/Д',
    uk: 'Н/Д',
    fa: 'ناموجود',
  );

  String get gallons =>
      _value(en: 'gal', es: 'gal', fr: 'gal', ru: 'гал', uk: 'гал', fa: 'گالن');

  String get liters =>
      _value(en: 'L', es: 'L', fr: 'L', ru: 'л', uk: 'л', fa: 'لیتر');

  String get totalCost => _value(
    en: 'Total cost',
    es: 'Costo total',
    fr: 'Coût total',
    ru: 'Общая стоимость',
    uk: 'Загальна вартість',
    fa: 'هزینه کل',
  );

  String get stationName => _value(
    en: 'Station name',
    es: 'Nombre de la gasolinera',
    fr: 'Nom de la station',
    ru: 'Название заправки',
    uk: 'Назва заправки',
    fa: 'نام پمپ بنزین',
  );

  String get fuelEntrySaved => _value(
    en: 'Fuel entry saved',
    es: 'Registro de combustible guardado',
    fr: 'Entrée carburant enregistrée',
    ru: 'Запись о топливе сохранена',
    uk: 'Запис про пальне збережено',
    fa: 'ثبت سوخت ذخیره شد',
  );

  String get fuelEntryDeleted => _value(
    en: 'Fuel entry deleted',
    es: 'Registro de combustible eliminado',
    fr: 'Entrée carburant supprimée',
    ru: 'Запись о топливе удалена',
    uk: 'Запис про пальне видалено',
    fa: 'ثبت سوخت حذف شد',
  );

  String get fuelAmountMustBePositive => _value(
    en: 'Fuel amount must be greater than 0',
    es: 'La cantidad de combustible debe ser mayor que 0',
    fr: 'La quantité de carburant doit être supérieure à 0',
    ru: 'Количество топлива должно быть больше 0',
    uk: 'Кількість пального має бути більшою за 0',
    fa: 'مقدار سوخت باید بیشتر از ۰ باشد',
  );

  String get totalCostCannotBeNegative => _value(
    en: 'Total cost cannot be negative',
    es: 'El costo total no puede ser negativo',
    fr: 'Le coût total ne peut pas être négatif',
    ru: 'Общая стоимость не может быть отрицательной',
    uk: 'Загальна вартість не може бути від’ємною',
    fa: 'هزینه کل نمی‌تواند منفی باشد',
  );

  String get noFuelEntries => _value(
    en: 'No fuel entries yet',
    es: 'Aún no hay registros de combustible',
    fr: 'Aucune entrée carburant pour le moment',
    ru: 'Записей о топливе пока нет',
    uk: 'Записів про пальне ще немає',
    fa: 'هنوز ثبت سوختی وجود ندارد',
  );

  String get deleteFuelEntry => _value(
    en: 'Delete fuel entry',
    es: 'Eliminar registro de combustible',
    fr: 'Supprimer l’entrée carburant',
    ru: 'Удалить запись о топливе',
    uk: 'Видалити запис про пальне',
    fa: 'حذف ثبت سوخت',
  );

  String get deleteFuelEntryConfirm => _value(
    en: 'Delete this fuel purchase?',
    es: '¿Eliminar esta compra de combustible?',
    fr: 'Supprimer cet achat de carburant ?',
    ru: 'Удалить эту покупку топлива?',
    uk: 'Видалити цю покупку пального?',
    fa: 'این خرید سوخت حذف شود؟',
  );

  String get date => _value(
    en: 'Date',
    es: 'Fecha',
    fr: 'Date',
    ru: 'Дата',
    uk: 'Дата',
    fa: 'تاریخ',
  );

  String get odometer => _value(
    en: 'Odometer',
    es: 'Odómetro',
    fr: 'Compteur',
    ru: 'Одометр',
    uk: 'Одометр',
    fa: 'کیلومترشمار',
  );

  String get saving => _value(
    en: 'Saving...',
    es: 'Guardando...',
    fr: 'Enregistrement...',
    ru: 'Сохранение...',
    uk: 'Збереження...',
    fa: 'در حال ذخیره...',
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
}
