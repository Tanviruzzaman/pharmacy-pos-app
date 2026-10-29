class Medicine {
  Medicine({
    required this.id,
    required this.name,
    this.genericName,
    this.company,
    this.unit = 'pcs',
    this.sellPrice = 0,
    this.barcode,
    this.stockQty = 0,
    this.nearestExpiry,
  });

  final String id;
  final String name;
  final String? genericName;
  final String? company;
  final String unit;
  final int sellPrice; // poisha, default price for new batches
  final String? barcode;

  // Computed (not stored on medicines table)
  final int stockQty;
  final String? nearestExpiry;

  factory Medicine.fromMap(Map<String, Object?> m) => Medicine(
        id: m['id'] as String,
        name: m['name'] as String,
        genericName: m['generic_name'] as String?,
        company: m['company'] as String?,
        unit: (m['unit'] as String?) ?? 'pcs',
        sellPrice: (m['sell_price'] as int?) ?? 0,
        barcode: m['barcode'] as String?,
        stockQty: (m['stock_qty'] as int?) ?? 0,
        nearestExpiry: m['nearest_expiry'] as String?,
      );
}

class StockBatch {
  StockBatch({
    required this.id,
    required this.medicineId,
    this.batchNo,
    required this.expiryDate,
    required this.qty,
    required this.buyPrice,
    required this.sellPrice,
    this.medicineName,
  });

  final String id;
  final String medicineId;
  final String? batchNo;
  final String expiryDate; // yyyy-MM-dd
  final int qty;
  final int buyPrice; // poisha per unit
  final int sellPrice; // poisha per unit
  final String? medicineName;

  DateTime get expiry => DateTime.parse(expiryDate);
  int daysToExpiry(DateTime today) =>
      expiry.difference(DateTime(today.year, today.month, today.day)).inDays;

  factory StockBatch.fromMap(Map<String, Object?> m) => StockBatch(
        id: m['id'] as String,
        medicineId: m['medicine_id'] as String,
        batchNo: m['batch_no'] as String?,
        expiryDate: m['expiry_date'] as String,
        qty: m['qty'] as int,
        buyPrice: m['buy_price'] as int,
        sellPrice: m['sell_price'] as int,
        medicineName: m['medicine_name'] as String?,
      );
}

class Customer {
  Customer({required this.id, required this.name, this.phone, this.address, this.balance = 0});

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final int balance; // poisha the customer owes (computed)

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        balance: (m['balance'] as int?) ?? 0,
      );
}

class CreditEntry {
  CreditEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.saleId,
    this.note,
    required this.entryAt,
  });

  final String id;
  final String customerId;
  final String type; // 'due' | 'payment'
  final int amount;
  final String? saleId;
  final String? note;
  final int entryAt;

  bool get isDue => type == 'due';

  factory CreditEntry.fromMap(Map<String, Object?> m) => CreditEntry(
        id: m['id'] as String,
        customerId: m['customer_id'] as String,
        type: m['type'] as String,
        amount: m['amount'] as int,
        saleId: m['sale_id'] as String?,
        note: m['note'] as String?,
        entryAt: m['entry_at'] as int,
      );
}

/// An item in the in-memory cart before the sale is saved.
class CartLine {
  CartLine({required this.medicine, required this.qty, required this.unitPrice, required this.available});

  final Medicine medicine;
  int qty;
  int unitPrice; // poisha
  final int available;

  int get lineTotal => qty * unitPrice;
}

class Sale {
  Sale({
    required this.id,
    required this.invoiceNo,
    this.customerId,
    this.customerName,
    required this.soldAt,
    required this.total,
    required this.paid,
    required this.due,
    required this.profit,
    required this.discount,
  });

  final String id;
  final String invoiceNo;
  final String? customerId;
  final String? customerName;
  final int soldAt;
  final int total;
  final int paid;
  final int due;
  final int profit;
  final int discount;

  factory Sale.fromMap(Map<String, Object?> m) => Sale(
        id: m['id'] as String,
        invoiceNo: m['invoice_no'] as String,
        customerId: m['customer_id'] as String?,
        customerName: m['customer_name'] as String?,
        soldAt: m['sold_at'] as int,
        total: m['total'] as int,
        paid: m['paid'] as int,
        due: m['due'] as int,
        profit: m['profit'] as int,
        discount: m['discount'] as int,
      );
}

class DailyReport {
  DailyReport({
    required this.date,
    required this.saleCount,
    required this.totalSales,
    required this.totalDiscount,
    required this.totalCost,
    required this.profit,
    required this.cashFromSales,
    required this.dueGiven,
    required this.duePaymentsReceived,
    required this.sales,
  });

  final String date;
  final int saleCount;
  final int totalSales;
  final int totalDiscount;
  final int totalCost;
  final int profit;
  final int cashFromSales;
  final int dueGiven;
  final int duePaymentsReceived;
  final List<Sale> sales;

  int get cashInHand => cashFromSales + duePaymentsReceived;
}
