// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pharmacy POS';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get newLabel => 'New';

  @override
  String get print => 'Print';

  @override
  String get share => 'Share';

  @override
  String get language => 'Language';

  @override
  String get unit_pcs => 'pcs';

  @override
  String get unit_tablet => 'tablet';

  @override
  String get unit_capsule => 'capsule';

  @override
  String get unit_strip => 'strip';

  @override
  String get unit_box => 'box';

  @override
  String get unit_bottle => 'bottle';

  @override
  String get unit_tube => 'tube';

  @override
  String get unit_vial => 'vial';

  @override
  String get unit_sachet => 'sachet';

  @override
  String get todaySales => 'Today\'s sales';

  @override
  String get todayProfit => 'Today\'s profit';

  @override
  String get todayDue => 'Today\'s due';

  @override
  String get totalDue => 'Total due';

  @override
  String get newSale => 'New Sale';

  @override
  String get stock => 'Stock';

  @override
  String get expiryAlert => 'Expiry alert';

  @override
  String batchesCount(String count) {
    return '$count batches';
  }

  @override
  String get allGood => 'All good';

  @override
  String get bakiKhata => 'Baki khata';

  @override
  String get dailyReport => 'Daily report';

  @override
  String get lowStock => 'Low stock';

  @override
  String medicinesCount(String count) {
    return '$count medicines';
  }

  @override
  String get backup => 'Backup';

  @override
  String get settings => 'Settings';

  @override
  String get addShopDetails => 'Add your shop details';

  @override
  String get addShopDetailsHint =>
      'Shop name, address and printer for customer receipts';

  @override
  String get searchMedicine => 'Search medicine';

  @override
  String get addMedicine => 'Add medicine';

  @override
  String get noMedicines => 'No medicines yet. Tap \"Add medicine\".';

  @override
  String expShort(String date) {
    return 'Exp $date';
  }

  @override
  String get lowTag => 'Low';

  @override
  String stockLabel(String qty) {
    return 'Stock: $qty';
  }

  @override
  String sellable(String qty) {
    return '$qty sellable';
  }

  @override
  String priceLabel(String price) {
    return 'Price $price';
  }

  @override
  String get batches => 'Batches';

  @override
  String get noBatches => 'No stock batches';

  @override
  String get addStock => 'Add stock';

  @override
  String batchTitle(String no) {
    return 'Batch $no';
  }

  @override
  String get batchNo => 'Batch no.';

  @override
  String qtyInHand(String unit) {
    return 'Quantity in hand ($unit)';
  }

  @override
  String get deleteBatch => 'Delete batch';

  @override
  String batchPrices(String buy, String sell, String unit) {
    return 'Buy $buy · Sell $sell per $unit';
  }

  @override
  String get newMedicine => 'New medicine';

  @override
  String get editMedicine => 'Edit medicine';

  @override
  String get brandName => 'Brand name *';

  @override
  String get genericName => 'Generic name';

  @override
  String get company => 'Company';

  @override
  String get baseUnit => 'Smallest unit (sold loose)';

  @override
  String sellPricePer(String unit) {
    return 'Selling price per $unit';
  }

  @override
  String get barcode => 'Barcode';

  @override
  String get packSizes => 'Strip / box (optional)';

  @override
  String perStrip(String unit) {
    return '$unit in 1 strip';
  }

  @override
  String perBox(String unit) {
    return '$unit in 1 box';
  }

  @override
  String get packHint => 'Leave empty if not sold this way';

  @override
  String lowStockAt(String unit) {
    return 'Low stock alert at ($unit)';
  }

  @override
  String get lowStockAtHint => 'Leave empty for no alert';

  @override
  String addStockTitle(String name) {
    return 'Add stock · $name';
  }

  @override
  String get expiryRequired => 'Expiry date *';

  @override
  String expiryOn(String date) {
    return 'Expiry $date';
  }

  @override
  String get buyingIn => 'Buying in';

  @override
  String quantityIn(String unit) {
    return 'Quantity ($unit) *';
  }

  @override
  String buyPricePer(String unit) {
    return 'Buying price per $unit *';
  }

  @override
  String sellPricePerReq(String unit) {
    return 'Selling price per $unit *';
  }

  @override
  String get batchRequired => 'Expiry, quantity and selling price are required';

  @override
  String days(String n) {
    return '$n days';
  }

  @override
  String get sixMonths => '6 months';

  @override
  String get atRiskValue => 'Stock value at risk (buy price)';

  @override
  String get nothingExpiring => 'Nothing expiring in this period';

  @override
  String expiredAgo(String days) {
    return 'EXPIRED ${days}d ago';
  }

  @override
  String get expiresToday => 'Expires today';

  @override
  String inDays(String days) {
    return 'in $days days';
  }

  @override
  String get lowStockEmpty =>
      'Nothing is running low. Set a low-stock alert when you add or edit a medicine.';

  @override
  String lowStockLine(String qty, String level) {
    return 'In stock: $qty · Alert at: $level';
  }

  @override
  String get shareOrderList => 'Share order list';

  @override
  String get orderListTitle => 'Order list';

  @override
  String get searchMedicineHint =>
      'Search medicine by name / generic / barcode';

  @override
  String outOfStock(String name) {
    return '$name is out of stock (or all batches expired)';
  }

  @override
  String get noMedicineFound => 'No medicine found';

  @override
  String get cartEmpty => 'Search a medicine above to add it to the cart';

  @override
  String itemsCount(String count) {
    return '$count items';
  }

  @override
  String get checkout => 'Checkout';

  @override
  String get sellAs => 'Sell as';

  @override
  String quantityMax(String max) {
    return 'Quantity (max $max)';
  }

  @override
  String pricePer(String unit) {
    return 'Price per $unit';
  }

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get cashReceived => 'Cash received';

  @override
  String get returnChange => 'Give back change';

  @override
  String get dueBaki => 'Due (baki)';

  @override
  String get selectCustomerRequired => 'Select customer (required for baki)';

  @override
  String get customerOptional => 'Customer (optional)';

  @override
  String get saving => 'Saving…';

  @override
  String get saveSale => 'Save sale';

  @override
  String get saleSaved => 'Sale saved';

  @override
  String invoiceNo(String no) {
    return 'Invoice $no';
  }

  @override
  String addedToBaki(String amount) {
    return '$amount added to baki';
  }

  @override
  String get totalBakiToCollect => 'Total baki to collect';

  @override
  String get searchNamePhone => 'Search name / phone';

  @override
  String get hasDue => 'Has due';

  @override
  String get noCustomers => 'No customers here';

  @override
  String get customer => 'Customer';

  @override
  String get paymentReceived => 'Payment received';

  @override
  String get addBaki => 'Add baki';

  @override
  String get amount => 'Amount';

  @override
  String get note => 'Note';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get currentBaki => 'Current baki';

  @override
  String get gotPayment => 'Got payment';

  @override
  String get noEntries => 'No entries yet';

  @override
  String get entryBaki => 'Baki';

  @override
  String get entryPayment => 'Payment';

  @override
  String get entryReturn => 'Return';

  @override
  String get deleteEntry => 'Delete this entry?';

  @override
  String get newCustomer => 'New customer';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get nameRequired => 'Name *';

  @override
  String get today => 'Today';

  @override
  String salesInvoices(String count) {
    return 'Sales ($count invoices)';
  }

  @override
  String get returns => 'Returns';

  @override
  String get netSales => 'Net sales';

  @override
  String get discountGiven => 'Discount given';

  @override
  String get costOfGoods => 'Cost of goods';

  @override
  String get profit => 'Profit';

  @override
  String get cashFromSales => 'Cash from sales';

  @override
  String get bakiCollected => 'Baki collected';

  @override
  String get cashRefunded => 'Cash given back (returns)';

  @override
  String get cashInHand => 'Cash in hand';

  @override
  String get newBakiGiven => 'New baki given';

  @override
  String get invoices => 'Invoices';

  @override
  String get noSalesDay => 'No sales on this day';

  @override
  String get paid => 'Paid';

  @override
  String get returned => 'Returned';

  @override
  String get partlyReturned => 'Part returned';

  @override
  String get returnItems => 'Return items';

  @override
  String get cancelInvoice => 'Cancel invoice';

  @override
  String returnTitle(String invoice) {
    return 'Return · $invoice';
  }

  @override
  String returnLine(String sold, String left) {
    return 'Sold $sold · can return $left';
  }

  @override
  String get returnValue => 'Return value';

  @override
  String get confirmReturn => 'Confirm return';

  @override
  String get cancelInvoiceConfirm =>
      'Cancel the whole invoice? All items go back to stock.';

  @override
  String get returnDone => 'Return saved';

  @override
  String giveBackCash(String amount) {
    return 'Give back $amount cash';
  }

  @override
  String bakiReduced(String amount) {
    return '$amount taken off baki';
  }

  @override
  String get returnDiscountNote => 'Value includes this invoice\'s discount';

  @override
  String get backupRestore => 'Backup & restore';

  @override
  String get backupInfo =>
      'All data is stored only on this phone. Back up regularly: tap \"Backup now\" and choose Google Drive (or WhatsApp / email) in the share menu.';

  @override
  String get neverBackedUp => 'Never backed up';

  @override
  String lastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String changedRecords(String count) {
    return '$count records changed since the last sync';
  }

  @override
  String get backupNow => 'Backup now';

  @override
  String get restoreFromFile => 'Restore from file';

  @override
  String get restoreTitle => 'Restore backup?';

  @override
  String get restoreWarning =>
      'All data on this phone will be REPLACED by the backup file. This cannot be undone.';

  @override
  String get chooseFile => 'Choose file';

  @override
  String restoredCount(String count) {
    return 'Restored $count records';
  }

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get shopAndReceipt => 'Shop & receipt';

  @override
  String get printedOnReceipt => 'Printed at the top of every receipt';

  @override
  String get shopName => 'Shop name';

  @override
  String get license => 'Drug license no.';

  @override
  String get receiptFooter => 'Receipt footer';

  @override
  String get englishOnlyNote =>
      'Use English letters here: receipt printers cannot print Bangla.';

  @override
  String get receiptPrinter => 'Receipt printer';

  @override
  String paperMm(String mm) {
    return '$mm mm paper';
  }

  @override
  String get noBtPrinter => 'No Bluetooth printer';

  @override
  String get usesAndroidPrint => 'Print uses Android\'s print screen';

  @override
  String get pairedDevices => 'Paired Bluetooth devices';

  @override
  String get noPairedDevices =>
      'No paired devices. Turn the printer on and pair it in Android Settings → Bluetooth first.';

  @override
  String get testPrint => 'Test print';

  @override
  String get testSent => 'Test page sent';

  @override
  String get security => 'Security';

  @override
  String get pinLock => 'PIN lock';

  @override
  String get pinOn => 'On: PIN needed to open the app';

  @override
  String get pinOff => 'Off';

  @override
  String get setPin => 'Set PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get receiptPrinted => 'Receipt printed';

  @override
  String get noPrinterSharing =>
      'No printer on this device. Sharing the receipt as PDF instead.';

  @override
  String couldNotPrint(String error) {
    return 'Could not print: $error';
  }

  @override
  String couldNotShare(String error) {
    return 'Could not share: $error';
  }

  @override
  String get errBtPermission => 'Allow Bluetooth permission to use the printer';

  @override
  String get errBtOff => 'Turn on Bluetooth';

  @override
  String get errPrinterConnect =>
      'Could not connect to the printer. Is it on and in range?';

  @override
  String get errPrintFailed =>
      'Printing failed. Check the printer and try again.';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get newPin => 'Enter a new 4-digit PIN';

  @override
  String get confirmPin => 'Enter the same PIN again';

  @override
  String get pinMismatch => 'PINs did not match. Try again.';

  @override
  String get pinSet => 'PIN set';

  @override
  String get pinRemoved => 'PIN removed';

  @override
  String get currentPin => 'Enter your current PIN';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPinHelp =>
      'A PIN cannot be recovered. To remove it, clear this app\'s data in Android Settings → Apps. That deletes all data, so restore your latest backup afterwards.';

  @override
  String get errEmptyCart => 'Cart is empty';

  @override
  String get errInvalidDiscount => 'Invalid discount';

  @override
  String get errInvalidPaid => 'Invalid paid amount';

  @override
  String get errDueNeedsCustomer =>
      'Select a customer to keep the due in baki khata';

  @override
  String errInvalidQty(String name) {
    return 'Invalid quantity for $name';
  }

  @override
  String errNotEnoughStock(String name) {
    return 'Not enough stock for $name';
  }

  @override
  String get errSaleNotFound => 'Sale not found';

  @override
  String get errReturnTooMuch => 'Cannot return more than was sold';

  @override
  String get errNothingToReturn => 'Choose what is being returned';
}
