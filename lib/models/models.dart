class Medicine {
  Medicine({
    required this.id,
    required this.name,
    this.genericName,
    this.company,
    this.unit = 'pcs',
    this.sellPrice = 0,
    this.barcode,
    this.reorderLevel = 0,
    this.stripSize = 0,
    this.boxSize = 0,
    this.stockQty = 0,
    this.nearestExpiry,
  });

  final String id;
  final String name;
  final String? genericName;
  final String? company;
  final String unit; // base unit; all quantities are counted in it
  final int sellPrice; // poisha per base unit, default price for new batches
  final String? barcode;
  final int reorderLevel; // alert when stock <= this (base units); 0 = off
  final int stripSize; // base units per strip; 0 = not sold by strip
  final int boxSize; // base units per box; 0 = not sold by box

  // Computed (not stored on medicines table)
  final int stockQty;
  final String? nearestExpiry;

  bool get isLowStock => reorderLevel > 0 && stockQty <= reorderLevel;

  /// Ways this medicine can be bought or sold: the base unit, then strip / box if set.
  List<PackUnit> get packUnits => [
        const PackUnit(null, 1),
        if (stripSize > 1) PackUnit('strip', stripSize),
        if (boxSize > 1) PackUnit('box', boxSize),
      ];

  factory Medicine.fromMap(Map<String, Object?> m) => Medicine(
        id: m['id'] as String,
        name: m['name'] as String,
        genericName: m['generic_name'] as String?,
        company: m['company'] as String?,
        unit: (m['unit'] as String?) ?? 'pcs',
        sellPrice: (m['sell_price'] as int?) ?? 0,
        barcode: m['barcode'] as String?,
        reorderLevel: (m['reorder_level'] as int?) ?? 0,
        stripSize: (m['strip_size'] as int?) ?? 0,
        boxSize: (m['box_size'] as int?) ?? 0,
        stockQty: (m['stock_qty'] as int?) ?? 0,
        nearestExpiry: m['nearest_expiry'] as String?,
      );
}

/// A unit a medicine is counted in. [name] null = the medicine's base unit.
class PackUnit {
  const PackUnit(this.name, this.factor);
  final String? name; // 'strip' | 'box' | null
  final int factor; // base units in one of these

  @override
  bool operator ==(Object other) => other is PackUnit && other.name == name && other.factor == factor;
  @override
  int get hashCode => Object.hash(name, factor);
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
  final String type; // 'due' | 'payment' | 'return'
  final int amount;
  final String? saleId;
  final String? note;
  final int entryAt;

  bool get isDue => type == 'due';
  bool get isReturn => type == 'return';

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
  CartLine({
    required this.medicine,
    required this.qty,
    required this.unitPrice,
    required this.available,
    this.pack = const PackUnit(null, 1),
  });

  final Medicine medicine;
  int qty; // in [pack] units
  int unitPrice; // poisha per [pack]
  final int available; // base units in stock
  PackUnit pack;

  int get baseQty => qty * pack.factor;
  int get maxQty => available ~/ pack.factor;
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
    this.returned = 0,
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
  final int returned; // value of goods returned so far (computed)

  bool get fullyReturned => returned > 0 && returned >= total;

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
        returned: (m['returned'] as int?) ?? 0,
      );
}

/// One line of an invoice: a medicine sold in one unit at one price
/// (the FEFO split across batches is merged back together).
class ReceiptLine {
  ReceiptLine({
    required this.medicineId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.soldUnit,
    this.unitFactor = 1,
    this.returnedQty = 0,
  });

  final String medicineId;
  final String name;
  final int qty; // in sold units
  final int unitPrice; // per sold unit
  final int lineTotal;
  final String? soldUnit; // 'strip' | 'box' | null = base unit
  final int unitFactor;
  final int returnedQty; // in sold units

  int get returnableQty => qty - returnedQty;

  /// Identifies this line when returning items.
  String get key => '$medicineId|${soldUnit ?? ''}|$unitFactor|$unitPrice';

  factory ReceiptLine.fromMap(Map<String, Object?> m) {
    final factor = (m['unit_factor'] as int?) ?? 1;
    return ReceiptLine(
      medicineId: m['medicine_id'] as String,
      name: m['medicine_name'] as String,
      qty: (m['qty'] as int) ~/ factor,
      unitPrice: m['unit_price'] as int,
      lineTotal: m['line_total'] as int,
      soldUnit: m['sold_unit'] as String?,
      unitFactor: factor,
      returnedQty: ((m['returned_qty'] as int?) ?? 0) ~/ factor,
    );
  }
}

/// Everything printed on a customer receipt for one saved sale.
class Receipt {
  Receipt({required this.sale, this.customerPhone, required this.items});

  final Sale sale;
  final String? customerPhone;
  final List<ReceiptLine> items;

  int get subtotal => sale.total + sale.discount;
  DateTime get soldAt => DateTime.fromMillisecondsSinceEpoch(sale.soldAt);
}

class SaleReturn {
  SaleReturn({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.cost,
    required this.refund,
    required this.bakiReduced,
    required this.returnedAt,
  });

  final String id;
  final String saleId;
  final int amount; // value of returned goods after the invoice discount share
  final int cost;
  final int refund; // cash given back
  final int bakiReduced; // taken off the customer's baki instead of cash
  final int returnedAt;
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
    this.returns = 0,
    this.refunds = 0,
  });

  final String date;
  final int saleCount;
  final int totalSales;
  final int totalDiscount;
  final int totalCost; // net of returned goods
  final int profit; // net of returns
  final int cashFromSales;
  final int dueGiven;
  final int duePaymentsReceived;
  final List<Sale> sales;
  final int returns; // value of goods returned on this day
  final int refunds; // cash given back for returns on this day

  int get netSales => totalSales - returns;
  int get cashInHand => cashFromSales + duePaymentsReceived - refunds;
}
