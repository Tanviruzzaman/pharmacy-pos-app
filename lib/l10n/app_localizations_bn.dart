// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'ফার্মেসি POS';

  @override
  String get cancel => 'বাতিল';

  @override
  String get save => 'সেভ করুন';

  @override
  String get saved => 'সেভ হয়েছে';

  @override
  String get delete => 'মুছে ফেলুন';

  @override
  String get no => 'না';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get done => 'শেষ';

  @override
  String get newLabel => 'নতুন';

  @override
  String get print => 'প্রিন্ট';

  @override
  String get share => 'শেয়ার';

  @override
  String get language => 'ভাষা';

  @override
  String get unit_pcs => 'পিস';

  @override
  String get unit_tablet => 'ট্যাবলেট';

  @override
  String get unit_capsule => 'ক্যাপসুল';

  @override
  String get unit_strip => 'পাতা';

  @override
  String get unit_box => 'বক্স';

  @override
  String get unit_bottle => 'বোতল';

  @override
  String get unit_tube => 'টিউব';

  @override
  String get unit_vial => 'ভায়াল';

  @override
  String get unit_sachet => 'স্যাশে';

  @override
  String get todaySales => 'আজকের বিক্রি';

  @override
  String get todayProfit => 'আজকের লাভ';

  @override
  String get todayDue => 'আজকের বাকি';

  @override
  String get totalDue => 'মোট বাকি';

  @override
  String get newSale => 'নতুন বিক্রি';

  @override
  String get stock => 'স্টক';

  @override
  String get expiryAlert => 'মেয়াদ শেষ';

  @override
  String batchesCount(String count) {
    return '$countটি ব্যাচ';
  }

  @override
  String get allGood => 'সব ঠিক আছে';

  @override
  String get bakiKhata => 'বাকি খাতা';

  @override
  String get dailyReport => 'দৈনিক হিসাব';

  @override
  String get lowStock => 'স্টক কম';

  @override
  String medicinesCount(String count) {
    return '$countটি ওষুধ';
  }

  @override
  String get backup => 'ব্যাকআপ';

  @override
  String get settings => 'সেটিংস';

  @override
  String get addShopDetails => 'দোকানের তথ্য দিন';

  @override
  String get addShopDetailsHint =>
      'রসিদের জন্য দোকানের নাম, ঠিকানা ও প্রিন্টার';

  @override
  String get searchMedicine => 'ওষুধ খুঁজুন';

  @override
  String get addMedicine => 'নতুন ওষুধ';

  @override
  String get noMedicines => 'এখনো কোনো ওষুধ নেই। \"নতুন ওষুধ\" চাপুন।';

  @override
  String expShort(String date) {
    return 'মেয়াদ $date';
  }

  @override
  String get lowTag => 'কম';

  @override
  String stockLabel(String qty) {
    return 'স্টক: $qty';
  }

  @override
  String sellable(String qty) {
    return 'বিক্রিযোগ্য $qty';
  }

  @override
  String priceLabel(String price) {
    return 'দাম $price';
  }

  @override
  String get batches => 'ব্যাচ';

  @override
  String get noBatches => 'কোনো স্টক ব্যাচ নেই';

  @override
  String get addStock => 'স্টক যোগ';

  @override
  String batchTitle(String no) {
    return 'ব্যাচ $no';
  }

  @override
  String get batchNo => 'ব্যাচ নং';

  @override
  String qtyInHand(String unit) {
    return 'হাতে আছে ($unit)';
  }

  @override
  String get deleteBatch => 'ব্যাচ মুছুন';

  @override
  String batchPrices(String buy, String sell, String unit) {
    return 'কেনা $buy · বিক্রি $sell প্রতি $unit';
  }

  @override
  String get newMedicine => 'নতুন ওষুধ';

  @override
  String get editMedicine => 'ওষুধ এডিট';

  @override
  String get brandName => 'ওষুধের নাম *';

  @override
  String get genericName => 'জেনেরিক নাম';

  @override
  String get company => 'কোম্পানি';

  @override
  String get baseUnit => 'সবচেয়ে ছোট একক (খুচরা বিক্রি)';

  @override
  String sellPricePer(String unit) {
    return 'প্রতি $unit বিক্রি দাম';
  }

  @override
  String get barcode => 'বারকোড';

  @override
  String get packSizes => 'পাতা / বক্স (দরকার হলে)';

  @override
  String perStrip(String unit) {
    return '1 পাতায় কয়টি $unit';
  }

  @override
  String perBox(String unit) {
    return '1 বক্সে কয়টি $unit';
  }

  @override
  String get packHint => 'এভাবে বিক্রি না করলে খালি রাখুন';

  @override
  String lowStockAt(String unit) {
    return 'স্টক কম সতর্কতা ($unit)';
  }

  @override
  String get lowStockAtHint => 'সতর্কতা না চাইলে খালি রাখুন';

  @override
  String addStockTitle(String name) {
    return 'স্টক যোগ · $name';
  }

  @override
  String get expiryRequired => 'মেয়াদ শেষের তারিখ *';

  @override
  String expiryOn(String date) {
    return 'মেয়াদ $date';
  }

  @override
  String get buyingIn => 'কিনছেন';

  @override
  String quantityIn(String unit) {
    return 'পরিমাণ ($unit) *';
  }

  @override
  String buyPricePer(String unit) {
    return 'প্রতি $unit কেনা দাম *';
  }

  @override
  String sellPricePerReq(String unit) {
    return 'প্রতি $unit বিক্রি দাম *';
  }

  @override
  String get batchRequired => 'মেয়াদ, পরিমাণ আর বিক্রি দাম দিতে হবে';

  @override
  String days(String n) {
    return '$n দিন';
  }

  @override
  String get sixMonths => '6 মাস';

  @override
  String get atRiskValue => 'ঝুঁকিতে থাকা স্টকের দাম (কেনা দামে)';

  @override
  String get nothingExpiring => 'এই সময়ে কোনো ওষুধের মেয়াদ শেষ হচ্ছে না';

  @override
  String expiredAgo(String days) {
    return 'মেয়াদ শেষ $days দিন আগে';
  }

  @override
  String get expiresToday => 'আজ মেয়াদ শেষ';

  @override
  String inDays(String days) {
    return '$days দিন বাকি';
  }

  @override
  String get lowStockEmpty =>
      'কোনো ওষুধের স্টক কম নেই। ওষুধ যোগ বা এডিট করার সময় স্টক কম সতর্কতা দিন।';

  @override
  String lowStockLine(String qty, String level) {
    return 'আছে: $qty · সতর্কতা: $level';
  }

  @override
  String get shareOrderList => 'অর্ডার লিস্ট শেয়ার';

  @override
  String get orderListTitle => 'অর্ডার লিস্ট';

  @override
  String get searchMedicineHint => 'নাম / জেনেরিক / বারকোড দিয়ে ওষুধ খুঁজুন';

  @override
  String outOfStock(String name) {
    return '$name স্টকে নেই (অথবা সব ব্যাচের মেয়াদ শেষ)';
  }

  @override
  String get noMedicineFound => 'কোনো ওষুধ পাওয়া যায়নি';

  @override
  String get cartEmpty => 'উপরে ওষুধ খুঁজে কার্টে যোগ করুন';

  @override
  String itemsCount(String count) {
    return '$countটি আইটেম';
  }

  @override
  String get checkout => 'বিল করুন';

  @override
  String get sellAs => 'বিক্রি করুন';

  @override
  String quantityMax(String max) {
    return 'পরিমাণ (সর্বোচ্চ $max)';
  }

  @override
  String pricePer(String unit) {
    return 'প্রতি $unit দাম';
  }

  @override
  String get subtotal => 'ছাড়ের আগে মোট';

  @override
  String get discount => 'ছাড়';

  @override
  String get total => 'মোট';

  @override
  String get cashReceived => 'টাকা পেলাম';

  @override
  String get returnChange => 'ফেরত দিন';

  @override
  String get dueBaki => 'বাকি';

  @override
  String get selectCustomerRequired => 'কাস্টমার বাছুন (বাকির জন্য দরকার)';

  @override
  String get customerOptional => 'কাস্টমার (না দিলেও চলবে)';

  @override
  String get saving => 'সেভ হচ্ছে…';

  @override
  String get saveSale => 'বিক্রি সেভ করুন';

  @override
  String get saleSaved => 'বিক্রি সেভ হয়েছে';

  @override
  String invoiceNo(String no) {
    return 'ইনভয়েস $no';
  }

  @override
  String addedToBaki(String amount) {
    return '$amount বাকিতে যোগ হয়েছে';
  }

  @override
  String get totalBakiToCollect => 'মোট পাওনা বাকি';

  @override
  String get searchNamePhone => 'নাম / ফোন দিয়ে খুঁজুন';

  @override
  String get hasDue => 'বাকি আছে';

  @override
  String get noCustomers => 'কোনো কাস্টমার নেই';

  @override
  String get customer => 'কাস্টমার';

  @override
  String get paymentReceived => 'টাকা জমা';

  @override
  String get addBaki => 'বাকি যোগ';

  @override
  String get amount => 'টাকা';

  @override
  String get note => 'নোট';

  @override
  String get phone => 'ফোন';

  @override
  String get address => 'ঠিকানা';

  @override
  String get currentBaki => 'বর্তমান বাকি';

  @override
  String get gotPayment => 'টাকা পেলাম';

  @override
  String get noEntries => 'এখনো কোনো হিসাব নেই';

  @override
  String get entryBaki => 'বাকি';

  @override
  String get entryPayment => 'জমা';

  @override
  String get entryReturn => 'ফেরত';

  @override
  String get deleteEntry => 'এই হিসাবটি মুছবেন?';

  @override
  String get newCustomer => 'নতুন কাস্টমার';

  @override
  String get editCustomer => 'কাস্টমার এডিট';

  @override
  String get nameRequired => 'নাম *';

  @override
  String get today => 'আজ';

  @override
  String salesInvoices(String count) {
    return 'বিক্রি ($countটি ইনভয়েস)';
  }

  @override
  String get returns => 'ফেরত';

  @override
  String get netSales => 'নিট বিক্রি';

  @override
  String get discountGiven => 'ছাড় দেওয়া হয়েছে';

  @override
  String get costOfGoods => 'কেনা খরচ';

  @override
  String get profit => 'লাভ';

  @override
  String get cashFromSales => 'বিক্রির নগদ টাকা';

  @override
  String get bakiCollected => 'বাকি আদায়';

  @override
  String get cashRefunded => 'ফেরতের জন্য টাকা দেওয়া';

  @override
  String get cashInHand => 'হাতে নগদ';

  @override
  String get newBakiGiven => 'নতুন বাকি দেওয়া';

  @override
  String get invoices => 'ইনভয়েস';

  @override
  String get noSalesDay => 'এই দিনে কোনো বিক্রি নেই';

  @override
  String get paid => 'পরিশোধ';

  @override
  String get returned => 'ফেরত হয়েছে';

  @override
  String get partlyReturned => 'আংশিক ফেরত';

  @override
  String get returnItems => 'ফেরত নিন';

  @override
  String get cancelInvoice => 'ইনভয়েস বাতিল';

  @override
  String returnTitle(String invoice) {
    return 'ফেরত · $invoice';
  }

  @override
  String returnLine(String sold, String left) {
    return 'বিক্রি $sold · ফেরত নেওয়া যাবে $left';
  }

  @override
  String get returnValue => 'ফেরতের দাম';

  @override
  String get confirmReturn => 'ফেরত নিশ্চিত করুন';

  @override
  String get cancelInvoiceConfirm =>
      'পুরো ইনভয়েস বাতিল করবেন? সব ওষুধ স্টকে ফেরত যাবে।';

  @override
  String get returnDone => 'ফেরত সেভ হয়েছে';

  @override
  String giveBackCash(String amount) {
    return 'কাস্টমারকে $amount টাকা ফেরত দিন';
  }

  @override
  String bakiReduced(String amount) {
    return 'বাকি থেকে $amount কমেছে';
  }

  @override
  String get returnDiscountNote =>
      'এই ইনভয়েসের ছাড় হিসাব করে দাম দেখানো হয়েছে';

  @override
  String get backupRestore => 'ব্যাকআপ ও রিস্টোর';

  @override
  String get backupInfo =>
      'সব তথ্য শুধু এই ফোনে থাকে। নিয়মিত ব্যাকআপ নিন: \"এখনই ব্যাকআপ\" চাপুন, তারপর শেয়ার মেনু থেকে Google Drive (বা WhatsApp / ইমেইল) বাছুন।';

  @override
  String get neverBackedUp => 'এখনো ব্যাকআপ নেওয়া হয়নি';

  @override
  String lastBackup(String date) {
    return 'শেষ ব্যাকআপ: $date';
  }

  @override
  String changedRecords(String count) {
    return 'শেষ সিঙ্কের পর $countটি হিসাব বদলেছে';
  }

  @override
  String get backupNow => 'এখনই ব্যাকআপ';

  @override
  String get restoreFromFile => 'ফাইল থেকে রিস্টোর';

  @override
  String get restoreTitle => 'ব্যাকআপ রিস্টোর করবেন?';

  @override
  String get restoreWarning =>
      'এই ফোনের সব তথ্য ব্যাকআপ ফাইল দিয়ে বদলে যাবে। এটা আর ফেরানো যাবে না।';

  @override
  String get chooseFile => 'ফাইল বাছুন';

  @override
  String restoredCount(String count) {
    return '$countটি হিসাব রিস্টোর হয়েছে';
  }

  @override
  String backupFailed(String error) {
    return 'ব্যাকআপ হয়নি: $error';
  }

  @override
  String restoreFailed(String error) {
    return 'রিস্টোর হয়নি: $error';
  }

  @override
  String get shopAndReceipt => 'দোকান ও রসিদ';

  @override
  String get printedOnReceipt => 'প্রতিটি রসিদের উপরে ছাপা হবে';

  @override
  String get shopName => 'দোকানের নাম';

  @override
  String get license => 'ড্রাগ লাইসেন্স নং';

  @override
  String get receiptFooter => 'রসিদের নিচের লেখা';

  @override
  String get englishOnlyNote =>
      'এখানে ইংরেজি অক্ষরে লিখুন: রসিদ প্রিন্টার বাংলা ছাপতে পারে না।';

  @override
  String get receiptPrinter => 'রসিদ প্রিন্টার';

  @override
  String paperMm(String mm) {
    return '$mm mm কাগজ';
  }

  @override
  String get noBtPrinter => 'ব্লুটুথ প্রিন্টার নেই';

  @override
  String get usesAndroidPrint =>
      'প্রিন্ট চাপলে Android-এর প্রিন্ট স্ক্রিন খুলবে';

  @override
  String get pairedDevices => 'পেয়ার করা ব্লুটুথ ডিভাইস';

  @override
  String get noPairedDevices =>
      'কোনো ডিভাইস পেয়ার করা নেই। প্রিন্টার চালু করে আগে Android সেটিংস → Bluetooth থেকে পেয়ার করুন।';

  @override
  String get testPrint => 'টেস্ট প্রিন্ট';

  @override
  String get testSent => 'টেস্ট পেজ পাঠানো হয়েছে';

  @override
  String get security => 'নিরাপত্তা';

  @override
  String get pinLock => 'PIN লক';

  @override
  String get pinOn => 'চালু: অ্যাপ খুলতে PIN লাগবে';

  @override
  String get pinOff => 'বন্ধ';

  @override
  String get setPin => 'PIN সেট করুন';

  @override
  String get changePin => 'PIN বদলান';

  @override
  String get removePin => 'PIN তুলে দিন';

  @override
  String get receiptPrinted => 'রসিদ প্রিন্ট হয়েছে';

  @override
  String get noPrinterSharing =>
      'এই ফোনে প্রিন্টার নেই। রসিদ PDF হিসেবে শেয়ার করা হচ্ছে।';

  @override
  String couldNotPrint(String error) {
    return 'প্রিন্ট হয়নি: $error';
  }

  @override
  String couldNotShare(String error) {
    return 'শেয়ার হয়নি: $error';
  }

  @override
  String get errBtPermission => 'প্রিন্টারের জন্য ব্লুটুথ অনুমতি দিন';

  @override
  String get errBtOff => 'ব্লুটুথ চালু করুন';

  @override
  String get errPrinterConnect =>
      'প্রিন্টারে কানেক্ট হয়নি। প্রিন্টার চালু আর কাছে আছে তো?';

  @override
  String get errPrintFailed =>
      'প্রিন্ট হয়নি। প্রিন্টার দেখে আবার চেষ্টা করুন।';

  @override
  String get enterPin => 'PIN দিন';

  @override
  String get wrongPin => 'ভুল PIN';

  @override
  String get newPin => 'নতুন 4 সংখ্যার PIN দিন';

  @override
  String get confirmPin => 'একই PIN আবার দিন';

  @override
  String get pinMismatch => 'PIN মেলেনি। আবার চেষ্টা করুন।';

  @override
  String get pinSet => 'PIN সেট হয়েছে';

  @override
  String get pinRemoved => 'PIN তুলে দেওয়া হয়েছে';

  @override
  String get currentPin => 'বর্তমান PIN দিন';

  @override
  String get forgotPin => 'PIN ভুলে গেছেন?';

  @override
  String get forgotPinHelp =>
      'PIN ফেরত পাওয়ার কোনো উপায় নেই। PIN তুলতে Android সেটিংস → Apps থেকে এই অ্যাপের ডেটা মুছুন। এতে সব তথ্য মুছে যাবে, তাই পরে শেষ ব্যাকআপ রিস্টোর করুন।';

  @override
  String get errEmptyCart => 'কার্ট খালি';

  @override
  String get errInvalidDiscount => 'ছাড়ের টাকা ঠিক নেই';

  @override
  String get errInvalidPaid => 'পরিশোধের টাকা ঠিক নেই';

  @override
  String get errDueNeedsCustomer => 'বাকি রাখতে কাস্টমার বাছুন';

  @override
  String errInvalidQty(String name) {
    return '$name-এর পরিমাণ ঠিক নেই';
  }

  @override
  String errNotEnoughStock(String name) {
    return '$name যথেষ্ট স্টকে নেই';
  }

  @override
  String get errSaleNotFound => 'বিক্রি পাওয়া যায়নি';

  @override
  String get errReturnTooMuch =>
      'যত বিক্রি হয়েছে তার বেশি ফেরত নেওয়া যাবে না';

  @override
  String get errNothingToReturn => 'কী ফেরত নিচ্ছেন বাছুন';
}
