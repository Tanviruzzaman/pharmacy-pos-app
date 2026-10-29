import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy POS'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @unit_pcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get unit_pcs;

  /// No description provided for @unit_tablet.
  ///
  /// In en, this message translates to:
  /// **'tablet'**
  String get unit_tablet;

  /// No description provided for @unit_capsule.
  ///
  /// In en, this message translates to:
  /// **'capsule'**
  String get unit_capsule;

  /// No description provided for @unit_strip.
  ///
  /// In en, this message translates to:
  /// **'strip'**
  String get unit_strip;

  /// No description provided for @unit_box.
  ///
  /// In en, this message translates to:
  /// **'box'**
  String get unit_box;

  /// No description provided for @unit_bottle.
  ///
  /// In en, this message translates to:
  /// **'bottle'**
  String get unit_bottle;

  /// No description provided for @unit_tube.
  ///
  /// In en, this message translates to:
  /// **'tube'**
  String get unit_tube;

  /// No description provided for @unit_vial.
  ///
  /// In en, this message translates to:
  /// **'vial'**
  String get unit_vial;

  /// No description provided for @unit_sachet.
  ///
  /// In en, this message translates to:
  /// **'sachet'**
  String get unit_sachet;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get todaySales;

  /// No description provided for @todayProfit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s profit'**
  String get todayProfit;

  /// No description provided for @todayDue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s due'**
  String get todayDue;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get totalDue;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @expiryAlert.
  ///
  /// In en, this message translates to:
  /// **'Expiry alert'**
  String get expiryAlert;

  /// No description provided for @batchesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} batches'**
  String batchesCount(String count);

  /// No description provided for @allGood.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get allGood;

  /// No description provided for @bakiKhata.
  ///
  /// In en, this message translates to:
  /// **'Baki khata'**
  String get bakiKhata;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily report'**
  String get dailyReport;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @medicinesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} medicines'**
  String medicinesCount(String count);

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @addShopDetails.
  ///
  /// In en, this message translates to:
  /// **'Add your shop details'**
  String get addShopDetails;

  /// No description provided for @addShopDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Shop name, address and printer for customer receipts'**
  String get addShopDetailsHint;

  /// No description provided for @searchMedicine.
  ///
  /// In en, this message translates to:
  /// **'Search medicine'**
  String get searchMedicine;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get addMedicine;

  /// No description provided for @noMedicines.
  ///
  /// In en, this message translates to:
  /// **'No medicines yet. Tap \"Add medicine\".'**
  String get noMedicines;

  /// No description provided for @expShort.
  ///
  /// In en, this message translates to:
  /// **'Exp {date}'**
  String expShort(String date);

  /// No description provided for @lowTag.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowTag;

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: {qty}'**
  String stockLabel(String qty);

  /// No description provided for @sellable.
  ///
  /// In en, this message translates to:
  /// **'{qty} sellable'**
  String sellable(String qty);

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price {price}'**
  String priceLabel(String price);

  /// No description provided for @batches.
  ///
  /// In en, this message translates to:
  /// **'Batches'**
  String get batches;

  /// No description provided for @noBatches.
  ///
  /// In en, this message translates to:
  /// **'No stock batches'**
  String get noBatches;

  /// No description provided for @addStock.
  ///
  /// In en, this message translates to:
  /// **'Add stock'**
  String get addStock;

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch {no}'**
  String batchTitle(String no);

  /// No description provided for @batchNo.
  ///
  /// In en, this message translates to:
  /// **'Batch no.'**
  String get batchNo;

  /// No description provided for @qtyInHand.
  ///
  /// In en, this message translates to:
  /// **'Quantity in hand ({unit})'**
  String qtyInHand(String unit);

  /// No description provided for @deleteBatch.
  ///
  /// In en, this message translates to:
  /// **'Delete batch'**
  String get deleteBatch;

  /// No description provided for @batchPrices.
  ///
  /// In en, this message translates to:
  /// **'Buy {buy} · Sell {sell} per {unit}'**
  String batchPrices(String buy, String sell, String unit);

  /// No description provided for @newMedicine.
  ///
  /// In en, this message translates to:
  /// **'New medicine'**
  String get newMedicine;

  /// No description provided for @editMedicine.
  ///
  /// In en, this message translates to:
  /// **'Edit medicine'**
  String get editMedicine;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Brand name *'**
  String get brandName;

  /// No description provided for @genericName.
  ///
  /// In en, this message translates to:
  /// **'Generic name'**
  String get genericName;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @baseUnit.
  ///
  /// In en, this message translates to:
  /// **'Smallest unit (sold loose)'**
  String get baseUnit;

  /// No description provided for @sellPricePer.
  ///
  /// In en, this message translates to:
  /// **'Selling price per {unit}'**
  String sellPricePer(String unit);

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @packSizes.
  ///
  /// In en, this message translates to:
  /// **'Strip / box (optional)'**
  String get packSizes;

  /// No description provided for @perStrip.
  ///
  /// In en, this message translates to:
  /// **'{unit} in 1 strip'**
  String perStrip(String unit);

  /// No description provided for @perBox.
  ///
  /// In en, this message translates to:
  /// **'{unit} in 1 box'**
  String perBox(String unit);

  /// No description provided for @packHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if not sold this way'**
  String get packHint;

  /// No description provided for @lowStockAt.
  ///
  /// In en, this message translates to:
  /// **'Low stock alert at ({unit})'**
  String lowStockAt(String unit);

  /// No description provided for @lowStockAtHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no alert'**
  String get lowStockAtHint;

  /// No description provided for @addStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Add stock · {name}'**
  String addStockTitle(String name);

  /// No description provided for @expiryRequired.
  ///
  /// In en, this message translates to:
  /// **'Expiry date *'**
  String get expiryRequired;

  /// No description provided for @expiryOn.
  ///
  /// In en, this message translates to:
  /// **'Expiry {date}'**
  String expiryOn(String date);

  /// No description provided for @buyingIn.
  ///
  /// In en, this message translates to:
  /// **'Buying in'**
  String get buyingIn;

  /// No description provided for @quantityIn.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit}) *'**
  String quantityIn(String unit);

  /// No description provided for @buyPricePer.
  ///
  /// In en, this message translates to:
  /// **'Buying price per {unit} *'**
  String buyPricePer(String unit);

  /// No description provided for @sellPricePerReq.
  ///
  /// In en, this message translates to:
  /// **'Selling price per {unit} *'**
  String sellPricePerReq(String unit);

  /// No description provided for @batchRequired.
  ///
  /// In en, this message translates to:
  /// **'Expiry, quantity and selling price are required'**
  String get batchRequired;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String days(String n);

  /// No description provided for @sixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get sixMonths;

  /// No description provided for @atRiskValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value at risk (buy price)'**
  String get atRiskValue;

  /// No description provided for @nothingExpiring.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring in this period'**
  String get nothingExpiring;

  /// No description provided for @expiredAgo.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED {days}d ago'**
  String expiredAgo(String days);

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String inDays(String days);

  /// No description provided for @lowStockEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is running low. Set a low-stock alert when you add or edit a medicine.'**
  String get lowStockEmpty;

  /// No description provided for @lowStockLine.
  ///
  /// In en, this message translates to:
  /// **'In stock: {qty} · Alert at: {level}'**
  String lowStockLine(String qty, String level);

  /// No description provided for @shareOrderList.
  ///
  /// In en, this message translates to:
  /// **'Share order list'**
  String get shareOrderList;

  /// No description provided for @orderListTitle.
  ///
  /// In en, this message translates to:
  /// **'Order list'**
  String get orderListTitle;

  /// No description provided for @searchMedicineHint.
  ///
  /// In en, this message translates to:
  /// **'Search medicine by name / generic / barcode'**
  String get searchMedicineHint;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'{name} is out of stock (or all batches expired)'**
  String outOfStock(String name);

  /// No description provided for @noMedicineFound.
  ///
  /// In en, this message translates to:
  /// **'No medicine found'**
  String get noMedicineFound;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Search a medicine above to add it to the cart'**
  String get cartEmpty;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(String count);

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @sellAs.
  ///
  /// In en, this message translates to:
  /// **'Sell as'**
  String get sellAs;

  /// No description provided for @quantityMax.
  ///
  /// In en, this message translates to:
  /// **'Quantity (max {max})'**
  String quantityMax(String max);

  /// No description provided for @pricePer.
  ///
  /// In en, this message translates to:
  /// **'Price per {unit}'**
  String pricePer(String unit);

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get cashReceived;

  /// No description provided for @returnChange.
  ///
  /// In en, this message translates to:
  /// **'Give back change'**
  String get returnChange;

  /// No description provided for @dueBaki.
  ///
  /// In en, this message translates to:
  /// **'Due (baki)'**
  String get dueBaki;

  /// No description provided for @selectCustomerRequired.
  ///
  /// In en, this message translates to:
  /// **'Select customer (required for baki)'**
  String get selectCustomerRequired;

  /// No description provided for @customerOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer (optional)'**
  String get customerOptional;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveSale.
  ///
  /// In en, this message translates to:
  /// **'Save sale'**
  String get saveSale;

  /// No description provided for @saleSaved.
  ///
  /// In en, this message translates to:
  /// **'Sale saved'**
  String get saleSaved;

  /// No description provided for @invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice {no}'**
  String invoiceNo(String no);

  /// No description provided for @addedToBaki.
  ///
  /// In en, this message translates to:
  /// **'{amount} added to baki'**
  String addedToBaki(String amount);

  /// No description provided for @totalBakiToCollect.
  ///
  /// In en, this message translates to:
  /// **'Total baki to collect'**
  String get totalBakiToCollect;

  /// No description provided for @searchNamePhone.
  ///
  /// In en, this message translates to:
  /// **'Search name / phone'**
  String get searchNamePhone;

  /// No description provided for @hasDue.
  ///
  /// In en, this message translates to:
  /// **'Has due'**
  String get hasDue;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers here'**
  String get noCustomers;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @addBaki.
  ///
  /// In en, this message translates to:
  /// **'Add baki'**
  String get addBaki;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @currentBaki.
  ///
  /// In en, this message translates to:
  /// **'Current baki'**
  String get currentBaki;

  /// No description provided for @gotPayment.
  ///
  /// In en, this message translates to:
  /// **'Got payment'**
  String get gotPayment;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntries;

  /// No description provided for @entryBaki.
  ///
  /// In en, this message translates to:
  /// **'Baki'**
  String get entryBaki;

  /// No description provided for @entryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get entryPayment;

  /// No description provided for @entryReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get entryReturn;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntry;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameRequired;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @salesInvoices.
  ///
  /// In en, this message translates to:
  /// **'Sales ({count} invoices)'**
  String salesInvoices(String count);

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @netSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get netSales;

  /// No description provided for @discountGiven.
  ///
  /// In en, this message translates to:
  /// **'Discount given'**
  String get discountGiven;

  /// No description provided for @costOfGoods.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods'**
  String get costOfGoods;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @cashFromSales.
  ///
  /// In en, this message translates to:
  /// **'Cash from sales'**
  String get cashFromSales;

  /// No description provided for @bakiCollected.
  ///
  /// In en, this message translates to:
  /// **'Baki collected'**
  String get bakiCollected;

  /// No description provided for @cashRefunded.
  ///
  /// In en, this message translates to:
  /// **'Cash given back (returns)'**
  String get cashRefunded;

  /// No description provided for @cashInHand.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get cashInHand;

  /// No description provided for @newBakiGiven.
  ///
  /// In en, this message translates to:
  /// **'New baki given'**
  String get newBakiGiven;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @noSalesDay.
  ///
  /// In en, this message translates to:
  /// **'No sales on this day'**
  String get noSalesDay;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @partlyReturned.
  ///
  /// In en, this message translates to:
  /// **'Part returned'**
  String get partlyReturned;

  /// No description provided for @returnItems.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get returnItems;

  /// No description provided for @cancelInvoice.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice'**
  String get cancelInvoice;

  /// No description provided for @returnTitle.
  ///
  /// In en, this message translates to:
  /// **'Return · {invoice}'**
  String returnTitle(String invoice);

  /// No description provided for @returnLine.
  ///
  /// In en, this message translates to:
  /// **'Sold {sold} · can return {left}'**
  String returnLine(String sold, String left);

  /// No description provided for @returnValue.
  ///
  /// In en, this message translates to:
  /// **'Return value'**
  String get returnValue;

  /// No description provided for @confirmReturn.
  ///
  /// In en, this message translates to:
  /// **'Confirm return'**
  String get confirmReturn;

  /// No description provided for @cancelInvoiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel the whole invoice? All items go back to stock.'**
  String get cancelInvoiceConfirm;

  /// No description provided for @returnDone.
  ///
  /// In en, this message translates to:
  /// **'Return saved'**
  String get returnDone;

  /// No description provided for @giveBackCash.
  ///
  /// In en, this message translates to:
  /// **'Give back {amount} cash'**
  String giveBackCash(String amount);

  /// No description provided for @bakiReduced.
  ///
  /// In en, this message translates to:
  /// **'{amount} taken off baki'**
  String bakiReduced(String amount);

  /// No description provided for @returnDiscountNote.
  ///
  /// In en, this message translates to:
  /// **'Value includes this invoice\'s discount'**
  String get returnDiscountNote;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupRestore;

  /// No description provided for @backupInfo.
  ///
  /// In en, this message translates to:
  /// **'All data is stored only on this phone. Back up regularly: tap \"Backup now\" and choose Google Drive (or WhatsApp / email) in the share menu.'**
  String get backupInfo;

  /// No description provided for @neverBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Never backed up'**
  String get neverBackedUp;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String lastBackup(String date);

  /// No description provided for @changedRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} records changed since the last sync'**
  String changedRecords(String count);

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get backupNow;

  /// No description provided for @restoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get restoreFromFile;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get restoreTitle;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'All data on this phone will be REPLACED by the backup file. This cannot be undone.'**
  String get restoreWarning;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @restoredCount.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} records'**
  String restoredCount(String count);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @shopAndReceipt.
  ///
  /// In en, this message translates to:
  /// **'Shop & receipt'**
  String get shopAndReceipt;

  /// No description provided for @printedOnReceipt.
  ///
  /// In en, this message translates to:
  /// **'Printed at the top of every receipt'**
  String get printedOnReceipt;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get shopName;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'Drug license no.'**
  String get license;

  /// No description provided for @receiptFooter.
  ///
  /// In en, this message translates to:
  /// **'Receipt footer'**
  String get receiptFooter;

  /// No description provided for @englishOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Use English letters here: receipt printers cannot print Bangla.'**
  String get englishOnlyNote;

  /// No description provided for @receiptPrinter.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get receiptPrinter;

  /// No description provided for @paperMm.
  ///
  /// In en, this message translates to:
  /// **'{mm} mm paper'**
  String paperMm(String mm);

  /// No description provided for @noBtPrinter.
  ///
  /// In en, this message translates to:
  /// **'No Bluetooth printer'**
  String get noBtPrinter;

  /// No description provided for @usesAndroidPrint.
  ///
  /// In en, this message translates to:
  /// **'Print uses Android\'s print screen'**
  String get usesAndroidPrint;

  /// No description provided for @pairedDevices.
  ///
  /// In en, this message translates to:
  /// **'Paired Bluetooth devices'**
  String get pairedDevices;

  /// No description provided for @noPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'No paired devices. Turn the printer on and pair it in Android Settings → Bluetooth first.'**
  String get noPairedDevices;

  /// No description provided for @testPrint.
  ///
  /// In en, this message translates to:
  /// **'Test print'**
  String get testPrint;

  /// No description provided for @testSent.
  ///
  /// In en, this message translates to:
  /// **'Test page sent'**
  String get testSent;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @pinLock.
  ///
  /// In en, this message translates to:
  /// **'PIN lock'**
  String get pinLock;

  /// No description provided for @pinOn.
  ///
  /// In en, this message translates to:
  /// **'On: PIN needed to open the app'**
  String get pinOn;

  /// No description provided for @pinOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get pinOff;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get removePin;

  /// No description provided for @receiptPrinted.
  ///
  /// In en, this message translates to:
  /// **'Receipt printed'**
  String get receiptPrinted;

  /// No description provided for @noPrinterSharing.
  ///
  /// In en, this message translates to:
  /// **'No printer on this device. Sharing the receipt as PDF instead.'**
  String get noPrinterSharing;

  /// No description provided for @couldNotPrint.
  ///
  /// In en, this message translates to:
  /// **'Could not print: {error}'**
  String couldNotPrint(String error);

  /// No description provided for @couldNotShare.
  ///
  /// In en, this message translates to:
  /// **'Could not share: {error}'**
  String couldNotShare(String error);

  /// No description provided for @errBtPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth permission to use the printer'**
  String get errBtPermission;

  /// No description provided for @errBtOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth'**
  String get errBtOff;

  /// No description provided for @errPrinterConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the printer. Is it on and in range?'**
  String get errPrinterConnect;

  /// No description provided for @errPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Printing failed. Check the printer and try again.'**
  String get errPrintFailed;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'Enter a new 4-digit PIN'**
  String get newPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs did not match. Try again.'**
  String get pinMismatch;

  /// No description provided for @pinSet.
  ///
  /// In en, this message translates to:
  /// **'PIN set'**
  String get pinSet;

  /// No description provided for @pinRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN removed'**
  String get pinRemoved;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get currentPin;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPinHelp.
  ///
  /// In en, this message translates to:
  /// **'A PIN cannot be recovered. To remove it, clear this app\'s data in Android Settings → Apps. That deletes all data, so restore your latest backup afterwards.'**
  String get forgotPinHelp;

  /// No description provided for @errEmptyCart.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get errEmptyCart;

  /// No description provided for @errInvalidDiscount.
  ///
  /// In en, this message translates to:
  /// **'Invalid discount'**
  String get errInvalidDiscount;

  /// No description provided for @errInvalidPaid.
  ///
  /// In en, this message translates to:
  /// **'Invalid paid amount'**
  String get errInvalidPaid;

  /// No description provided for @errDueNeedsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select a customer to keep the due in baki khata'**
  String get errDueNeedsCustomer;

  /// No description provided for @errInvalidQty.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity for {name}'**
  String errInvalidQty(String name);

  /// No description provided for @errNotEnoughStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock for {name}'**
  String errNotEnoughStock(String name);

  /// No description provided for @errSaleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Sale not found'**
  String get errSaleNotFound;

  /// No description provided for @errReturnTooMuch.
  ///
  /// In en, this message translates to:
  /// **'Cannot return more than was sold'**
  String get errReturnTooMuch;

  /// No description provided for @errNothingToReturn.
  ///
  /// In en, this message translates to:
  /// **'Choose what is being returned'**
  String get errNothingToReturn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
