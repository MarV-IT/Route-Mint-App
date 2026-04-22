import 'package:flutter/material.dart';

void main() {
  runApp(const RouteMintApp());
}

enum AppUnit { kilometers, miles }

enum AppLanguage {
  english,
  spanish,
  french,
  russian,
  ukrainian,
  dari,
}

class RouteMintApp extends StatefulWidget {
  const RouteMintApp({super.key});

  @override
  State<RouteMintApp> createState() => _RouteMintAppState();
}

class _RouteMintAppState extends State<RouteMintApp> {
  AppUnit _unit = AppUnit.kilometers;
  AppLanguage _selectedLanguage = AppLanguage.english;

  void _changeUnit(AppUnit? newUnit) {
    if (newUnit == null) return;
    setState(() {
      _unit = newUnit;
    });
  }

  void _changeLanguage(AppLanguage? newLanguage) {
    if (newLanguage == null) return;
    setState(() {
      _selectedLanguage = newLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_selectedLanguage);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Route Mint',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        useMaterial3: true,
      ),
      home: MainNavigationScreen(
        unit: _unit,
        selectedLanguage: _selectedLanguage,
        onUnitChanged: _changeUnit,
        onLanguageChanged: _changeLanguage,
        strings: strings,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final AppUnit unit;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppUnit?> onUnitChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;
  final AppStrings strings;

  const MainNavigationScreen({
    super.key,
    required this.unit,
    required this.selectedLanguage,
    required this.onUnitChanged,
    required this.onLanguageChanged,
    required this.strings,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    final pages = [
      TodayScreen(strings: strings, unit: widget.unit),
      TripsScreen(strings: strings, unit: widget.unit),
      AddTripScreen(strings: strings, unit: widget.unit),
      ReportsScreen(strings: strings, unit: widget.unit),
      ProfileScreen(
        strings: strings,
        selectedUnit: widget.unit,
        selectedLanguage: widget.selectedLanguage,
        onUnitChanged: widget.onUnitChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: strings.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: strings.trips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: strings.add,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: strings.reports,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.profile,
          ),
        ],
      ),
    );
  }
}

class TodayScreen extends StatelessWidget {
  final AppStrings strings;
  final AppUnit unit;

  const TodayScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.today),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: strings.todayDistance,
            value: formatDistance(42.8, unit),
            subtitle: strings.tripsRecorded,
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: strings.businessTrips,
            value: formatDistance(28.4, unit),
            subtitle: strings.tripsNeedReview,
          ),
          const SizedBox(height: 12),
          QuickActionsCard(strings: strings),
        ],
      ),
    );
  }
}

class TripsScreen extends StatelessWidget {
  final AppStrings strings;
  final AppUnit unit;

  const TripsScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.trips),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TripTile(
            title: 'Home → Client Office',
            subtitle:
                '${formatDistance(12.4, unit)} • ${strings.business} • 08:30 AM',
          ),
          const SizedBox(height: 10),
          TripTile(
            title: 'Client Office → Cafe',
            subtitle:
                '${formatDistance(4.2, unit)} • ${strings.personal} • 12:10 PM',
          ),
          const SizedBox(height: 10),
          TripTile(
            title: 'Cafe → Home',
            subtitle:
                '${formatDistance(10.8, unit)} • ${strings.business} • 06:45 PM',
          ),
        ],
      ),
    );
  }
}

class AddTripScreen extends StatelessWidget {
  final AppStrings strings;
  final AppUnit unit;

  const AddTripScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    String? selectedCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.addTrip),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: strings.from,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: strings.to,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: strings.distance,
              border: const OutlineInputBorder(),
              suffixText: unitLabel(unit),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            items: [
              DropdownMenuItem(
                value: 'business',
                child: Text(strings.business),
              ),
              DropdownMenuItem(
                value: 'personal',
                child: Text(strings.personal),
              ),
            ],
            onChanged: (_) {},
            decoration: InputDecoration(
              labelText: strings.category,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              child: Text(strings.saveTrip),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final AppStrings strings;
  final AppUnit unit;

  const ReportsScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.reports),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: strings.thisMonth,
            value: formatDistance(684, unit),
            subtitle: '${strings.business}: ${formatDistance(420, unit)}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: strings.expenses,
            value: '\$186.00',
            subtitle: strings.fuelParkingTolls,
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final AppStrings strings;
  final AppUnit selectedUnit;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppUnit?> onUnitChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.strings,
    required this.selectedUnit,
    required this.selectedLanguage,
    required this.onUnitChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profile),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('March User'),
            subtitle: Text('march@example.com'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text(strings.vehicle),
            subtitle: const Text('Toyota Prius'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppUnit>(
            value: selectedUnit,
            decoration: InputDecoration(
              labelText: strings.units,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: AppUnit.kilometers,
                child: Text(strings.kilometers),
              ),
              DropdownMenuItem(
                value: AppUnit.miles,
                child: Text(strings.miles),
              ),
            ],
            onChanged: onUnitChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppLanguage>(
            value: selectedLanguage,
            decoration: InputDecoration(
              labelText: strings.languageLabel,
              border: const OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: AppLanguage.english,
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: AppLanguage.spanish,
                child: Text('Español'),
              ),
              DropdownMenuItem(
                value: AppLanguage.french,
                child: Text('Français'),
              ),
              DropdownMenuItem(
                value: AppLanguage.russian,
                child: Text('Русский'),
              ),
              DropdownMenuItem(
                value: AppLanguage.ukrainian,
                child: Text('Українська'),
              ),
              DropdownMenuItem(
                value: AppLanguage.dari,
                child: Text('Dari'),
              ),
            ],
            onChanged: onLanguageChanged,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(strings.reimbursementRate),
            subtitle: Text('\$0.45 / ${unitLabel(selectedUnit)}'),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class QuickActionsCard extends StatelessWidget {
  final AppStrings strings;

  const QuickActionsCard({
    super.key,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.quickActions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: Text(strings.startTrip),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: Text(strings.addManually),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long),
                  label: Text(strings.addExpense),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TripTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const TripTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.map),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

String unitLabel(AppUnit unit) {
  return unit == AppUnit.kilometers ? 'km' : 'mi';
}

String formatDistance(double kmValue, AppUnit unit) {
  if (unit == AppUnit.kilometers) {
    return '${kmValue.toStringAsFixed(1)} km';
  }

  final milesValue = kmValue * 0.621371;
  return '${milesValue.toStringAsFixed(1)} mi';
}

class AppStrings {
  final AppLanguage currentLanguage;

  const AppStrings(this.currentLanguage);

  String get today => _value(
        en: 'Today',
        es: 'Hoy',
        fr: 'Aujourd’hui',
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