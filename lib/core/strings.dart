class AppStrings {
  final bool isArabic;
  AppStrings(this.isArabic);

  String _t(String ar, String en) => isArabic ? ar : en;

  String get appName => _t('موقف ذكي', 'Smart Park');
  String get findYourSpot => _t('اعثر على موقفك بسهولة', 'Find your spot with ease');
  String get searchHint => _t('ابحث عن موقف سيارات...', 'Search for parking...');
  String get availableSpots => _t('الأماكن المتاحة', 'Available Spots');
  String get nearbyParking => _t('مواقف قريبة منك', 'Nearby Parking');
  String get offers => _t('عروض اليوم', 'Today\'s Offers');
  String get findParking => _t('ابحث عن موقف', 'Find Parking');
  String get seeAll => _t('عرض الكل', 'See all');
  String get km => _t('كم', 'km');
  String get perHour => _t('/ساعة', '/hr');

  String get home => _t('الرئيسية', 'Home');
  String get myParking => _t('موقفي', 'My Parking');
  String get profile => _t('حسابي', 'Profile');
  String get details => _t('تفاصيل', 'Details');

  String get parkingInfo => _t('معلومات الموقف', 'Parking Info');
  String get rating => _t('التقييم', 'Rating');
  String get price => _t('السعر', 'Price');
  String get workingHours => _t('ساعات العمل', 'Working Hours');
  String get amenities => _t('المرافق', 'Amenities');
  String get chooseSpot => _t('اختر مكانك', 'Choose your spot');
  String get available => _t('متاح', 'Available');
  String get occupied => _t('مشغول', 'Occupied');
  String get reserveNow => _t('احجز الآن', 'Reserve Now');
  String get selectSlotFirst => _t('اختر مكانًا فارغًا أولًا', 'Select an empty spot first');
  String get reviews => _t('تقييم', 'reviews');

  String get currentParking => _t('موقفك الحالي', 'Current Parking');
  String get noActiveParking => _t('لا يوجد موقف نشط حاليًا', 'No active parking session');
  String get goFindParking => _t('اذهب وابحث عن موقف', 'Go find a parking spot');
  String get startTime => _t('وقت البدء', 'Start Time');
  String get duration => _t('المدة', 'Duration');
  String get cost => _t('التكلفة', 'Cost');
  String get status => _t('الحالة', 'Status');
  String get active => _t('نشط', 'Active');
  String get endParking => _t('إنهاء الموقف', 'End Parking');
  String get parkingEnded => _t('تم إنهاء الموقف بنجاح', 'Parking ended successfully');
  String get spot => _t('مكان', 'Spot');

  String get statistics => _t('الإحصائيات', 'Statistics');
  String get totalTrips => _t('عدد المواقف', 'Parking Sessions');
  String get totalSpent => _t('إجمالي المصروف', 'Total Spent');
  String get totalHours => _t('إجمالي الساعات', 'Total Hours');
  String get parkingHistory => _t('سجل المواقف', 'Parking History');
  String get notifications => _t('الإشعارات', 'Notifications');
  String get darkMode => _t('الوضع الليلي', 'Dark Mode');
  String get language => _t('اللغة', 'Language');
  String get about => _t('عن التطبيق', 'About');
  String get logout => _t('تسجيل الخروج', 'Logout');
  String get arabic => _t('العربية', 'Arabic');
  String get english => _t('الإنجليزية', 'English');
  String get editProfile => _t('تعديل الملف الشخصي', 'Edit Profile');
  String get logoutConfirm => _t('هل تريد تسجيل الخروج؟', 'Do you want to logout?');
  String get cancel => _t('إلغاء', 'Cancel');
  String get aboutText => _t(
      'تطبيق موقف ذكي يساعدك في إيجاد وحجز أماكن انتظار السيارات بسهولة وسرعة، مع متابعة مباشرة لوقت وتكلفة موقفك.\n\nالإصدار 1.0.0',
      'Smart Park helps you find and reserve parking spots quickly and easily, with live tracking of your parking time and cost.\n\nVersion 1.0.0');
}
