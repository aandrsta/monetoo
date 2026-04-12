# 🔍 FINDING.md — Analisis Mendalam Monetoo Codebase

> Dokumen ini merupakan hasil deep-analysis independen terhadap keseluruhan codebase Monetoo.
> Berbeda dari ISSUE.md yang hanya fokus pada refactoring permukaan (duplikasi UI, file splitting),
> dokumen ini menggali **kelemahan arsitektur, bug tersembunyi, risiko data production,
> dan peluang upgrade** yang belum terdeteksi oleh analisis sebelumnya.

---

## 🚨 CRITICAL — Risiko Data Production

### 1. Orphaned Transactions saat Delete Account/Category

**File:** `database_helper.dart:149-152`, `database_helper.dart:271-274`

```dart
Future<int> deleteCategory(String id) async {
  final db = await database;
  return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
}

Future<int> deleteAccount(String id) async {
  final db = await database;
  return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
}
```

**Masalah:** Saat akun atau kategori dihapus, **transaksi yang mereferensikan akun/kategori tersebut TIDAK dihapus dan TIDAK di-update**. Ini menyebabkan:
- Transaksi menjadi *orphaned* — mereferensikan `accountId` atau `categoryId` yang sudah tidak ada.
- `AccountDetailScreen` tidak akan pernah menampilkan transaksi orphan ini.
- Di `TransactionTile`, lookup akun gagal diam-diam (`firstOrNull` returns null).
- Data keuangan (total balance, income/expense) tetap menghitung transaksi orphan, sehingga **saldo menjadi tidak akurat** setelah delete.

**Severity:** 🔴 CRITICAL — Berdampak langsung pada integritas data production.

**Rekomendasi:**
- Tambahkan cascade logic: saat delete account → update semua transaction yang mereferensikannya (set `accountId = null`).
- Saat delete category → pindahkan transaksi ke kategori "Lainnya" yang sesuai tipe, atau tampilkan warning jumlah transaksi terdampak sebelum konfirmasi delete.
- **JANGAN** hapus transaksi secara otomatis — ini uang orang.

---

### 2. Balance Calculation Race Condition

**File:** `finance_provider.dart:97-110`

```dart
Future<void> addTransaction(TransactionModel transaction) async {
  await _db.insertTransaction(transaction);
  await loadTransactions(); // ← full reload
}
```

**Masalah:** Setiap operasi CRUD pada transaksi memicu `loadTransactions()` yang melakukan **full SELECT \* FROM transactions**. Saat data besar (1000+ transaksi):
- UI freeze pada operasi insert/update/delete.
- Multiple rapid operations (misalnya delete via swipe) dapat menyebabkan race condition karena `notifyListeners()` dipanggil sebelum data konsisten.

**Severity:** 🟡 MEDIUM — Tidak merusak data, tapi degradasi UX signifikan seiring data bertambah.

**Rekomendasi:**
- Tambahkan operasi lokal optimistic: update `_transactions` list secara lokal dulu, lalu sync ke DB di background.
- Atau, setidaknya, gunakan `await Future.wait([...])` untuk batch operations.

---

### 3. Denormalized Category Data di Transactions

**File:** `transaction_model.dart:10-13`

```dart
final String categoryId;
final String categoryName;    // ← duplikat
final String categoryIcon;    // ← duplikat
final String categoryColor;   // ← duplikat
```

**Masalah:** Ini adalah desain denormalisasi yang *intentional* (untuk performa read), tapi `updateTransactionsByCategory()` hanya dipanggil saat edit category — **tidak** saat category icon/color berubah melalui flow lain. Sudah ada mekanisme sync di `updateCategory()`, tapi ini fragile.

**Severity:** 🟡 MEDIUM — Sudah di-handle tapi arsitektur ini rapuh.

**Rekomendasi:** Pastikan semua mutation path terhadap category selalu memanggil `updateTransactionsByCategory()`. Pertimbangkan menambahkan audit log sederhana untuk catch desync.

---

## 🟡 Kelemahan Arsitektur

### 4. `FinanceProvider` Memuat Semua Data ke Memory

**File:** `finance_provider.dart:47-61`

```dart
Future<void> initialize() async {
  _categories = await categoriesFuture;   // semua kategori
  _accounts = await accountsFuture;       // semua akun
  _transactions = await transactionsFuture; // SEMUA transaksi
}
```

**Masalah:** Semua transaksi dari awal waktu dimuat ke RAM. Untuk pengguna aktif 1+ tahun (misalnya 10 transaksi/hari × 365 hari = 3650 records), ini bisa menghabiskan memory signifikan di perangkat low-end.

**Rekomendasi:**
- Pertimbangkan lazy-loading transaksi per bulan.
- Gunakan `getTransactionsByMonth()` (sudah ada di DB!) untuk load hanya data yang dibutuhkan.
- Cache 3 bulan terakhir dan load on-demand untuk bulan lama.

---

### 5. Duplikasi Logika Balance Calculation

**Lokasi:**
- `finance_provider.dart:149-171` → `getAccountBalance()`
- `account_screen.dart:96-100` → `_getAccountBalance()`
- `account_detail_screen.dart:50-51` → menggunakan `allTx.totalIncome` / `allTx.totalExpense`
- `transaction_model.dart:99-106` → `TransactionListX.balance`

**Masalah:** Ada **4 tempat berbeda** yang menghitung balance dengan cara yang sedikit berbeda:
- Provider: `openingBalance + income - expense` (manual loop)
- AccountScreen: `openingBalance + txs.balance` (via extension)
- AccountDetailScreen: menampilkan `allTx.balance` **tanpa** openingBalance (ini BUG — saldo yang ditampilkan salah!)
- Extension: `totalIncome - totalExpense` (tanpa openingBalance)

**Severity:** 🔴 HIGH — `AccountDetailScreen` menampilkan saldo **tanpa memperhitungkan opening balance**. Ini sudah tampil ke user.

**Rekomendasi:** Sentralisasi ke satu method di `FinanceProvider` dan gunakan di semua tempat.

---

### 6. `disableAnimations: true` di Production

**File:** `main.dart:78`

```dart
builder: (context, child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      boldText: false,
      disableAnimations: true, // ← ⚠️
    ),
    child: child!,
  );
},
```

**Masalah:** Flag ini **mematikan semua implicit animation** di seluruh aplikasi. Ini bertentangan langsung dengan banyak widget yang menggunakan `AnimatedContainer`. Efeknya: animasi yang seharusnya smooth jadi instant/tersentak.

**Severity:** 🟡 MEDIUM — UX impact. Semua `AnimatedContainer`, `AnimatedOpacity`, dll jadi tidak berfungsi.

**Rekomendasi:** Hapus `disableAnimations: true`. Jika ini ditambahkan untuk debugging, ini seharusnya tidak sampai production.

---

### 7. Duplicate Import di `account_detail_screen.dart`

**File:** `account_detail_screen.dart:6,16`

```dart
import '../models/transaction_model.dart';  // line 6
...
import '../models/transaction_model.dart';  // line 16 (duplikat!)
```

**Severity:** 🟢 LOW — Tidak merusak apapun, tapi menunjukkan code review yang kurang teliti dari refactor sebelumnya.

---

### 8. Unused Imports yang Masih Tersisa

**File:** `add_transaction_bottom_sheet.dart:12`

```dart
import '../utils/app_theme.dart'; // ← tidak digunakan di file ini
```

**Severity:** 🟢 LOW — Clean-up saja.

---

## 📦 Dependency yang Tidak Terpakai

**File:** `pubspec.yaml`

| Dependency | Status | Keterangan |
|---|---|---|
| `flutter_svg` | ❌ **Tidak diimport di file manapun** | 0 usage di seluruh `lib/`. Hapus untuk mengurangi ukuran APK. |
| `table_calendar` | ❌ **Tidak diimport di file manapun** | 0 usage. DatePicker sudah pakai `showDatePicker` bawaan Flutter. |
| `url_launcher` | ❌ **Tidak diimport di file manapun** | 0 usage. Auto-update pakai `open_file` dan `dio`, bukan url_launcher. |

**Impact:** 3 dependency ini menambah ~500KB+ pada ukuran APK tanpa memberikan value apapun.

---

## 🎨 Dark Mode & Theming Issues

### 9. Hardcoded `Colors.grey.shade200` — Tidak Responsif Dark Mode

**File:** `category_screen.dart:205, 255`

```dart
color: _selectedType == TransactionType.expense
    ? c.expense
    : Colors.grey.shade200, // ← hardcoded, tidak berubah di dark mode
```

**Masalah:** Pada dark mode, `grey.shade200` terlalu terang sebagai border, menghasilkan kontras visual yang buruk.

**Rekomendasi:** Ganti dengan `c.divider` yang sudah theme-aware.

---

### 10. `AppTheme.divider` Dipakai Langsung (Bypass Theme System)

**File:** `statistics_screen.dart:1022`

```dart
color: AppTheme.divider, // ← always uses LIGHT mode divider
```

**Masalah:** `AppTheme.divider` selalu mengembalikan warna light mode. Seharusnya menggunakan `c.divider` (via `context.colors`) agar responsif terhadap tema aktif.

---

### 11. Sistem Tema Berlapis Tiga (Over-Engineered)

**Files:** `app_theme.dart`, `app_colors.dart`

**Masalah:** Ada tiga layer warna yang redundant:
1. `AppTheme` — static constants untuk light/dark
2. `AppColors` — abstract class + 2 implementasi
3. `ThemeData` — Flutter's built-in system

`AppColors` pada dasarnya hanya proxy ke `AppTheme` static constants. Ini bisa disederhanakan.

**Rekomendasi:** Pertimbangkan memindahkan semua color ke Flutter `ThemeExtension<AppColors>`, menghilangkan kebutuhan akan `AppTheme` static constants dan membuat warna langsung tersedia via `Theme.of(context).extension<AppColors>()`.

---

## ⚡ Peluang Upgrade & Optimisasi

### 12. `kIconGroups` dan `kAllIcons` — Lokasi Salah

**File:** `category_screen.dart:20-92`

**Masalah:** Data ikon global (`kIconGroups`, `kAllIcons`) dideklarasikan di `category_screen.dart`, padahal digunakan juga oleh `icon_picker_dialog.dart`. Ini menciptakan **circular dependency concern** (widget depend on screen).

**Rekomendasi:** Pindahkan ke file terpisah: `lib/utils/icon_data.dart` atau `lib/constants/icons.dart`.

---

### 13. `add_transaction_bottom_sheet.dart` Masih 1025 Baris

**File:** `add_transaction_bottom_sheet.dart` — 1025 lines, 37KB

**Masalah:** Meskipun numpad sudah diekstrak, file ini masih sangat besar. Masih berisi:
- Account picker bottom sheet (~100 baris)
- Category picker bottom sheet (~150 baris)
- Note dialog (~50 baris)
- Date picker logic (~30 baris)
- Calculator state management (~80 baris)
- Main build method (~300 baris)

**Rekomendasi:** Ekstrak account picker dan category picker sebagai widget terpisah.

---

### 14. Font Fallback yang Tidak Optimal

**File:** `app_theme.dart:41-44, 49, 129`

```dart
static String get _systemFontFamily {
  if (Platform.isIOS || Platform.isMacOS) return '.SF UI Text';
  return 'sans-serif';
}
// ...
fontFamily: 'SFProText', // ← hanya load 1 weight (500/Medium)
```

**Masalah:**
- `SFProText` font hanya memuat **1 weight** (Medium/500), tapi kode menggunakan `FontWeight.w400`, `w600`, `w700` secara ekstensif — semua ini akan fallback ke weight 500.
- `_systemFontFamily` dibuat tapi **tidak pernah digunakan sebagai primary font** (hanya di hint/label style).

**Rekomendasi:** Tambahkan font weights yang dibutuhkan (`Regular`, `SemiBold`, `Bold`) di `pubspec.yaml`, atau gunakan system font secara konsisten.

---

### 15. Tidak Ada Error Boundary / Global Error Handler

**Masalah:** Tidak ada `FlutterError.onError` atau `runZonedGuarded` di `main.dart`. Jika terjadi unhandled exception, aplikasi crash tanpa logging.

**Rekomendasi:** Tambahkan minimal:
```dart
FlutterError.onError = (details) {
  FlutterError.presentError(details);
  // Optional: kirim ke crash reporting
};
```

---

### 16. Tidak Ada Database Index

**File:** `database_helper.dart:33-84`

**Masalah:** Tabel `transactions` melakukan query berdasarkan:
- `date` (di `getTransactionsByDateRange`)
- `categoryId` (di `updateTransactionsByCategory`)
- `accountId` (filter di memory, tapi bisa optimized)

Tidak ada index pada kolom-kolom ini. Saat data ribuan row, query akan melambat.

**Rekomendasi:** Tambahkan index di migration berikutnya:
```sql
CREATE INDEX idx_tx_date ON transactions(date);
CREATE INDEX idx_tx_category ON transactions(categoryId);
CREATE INDEX idx_tx_account ON transactions(accountId);
```

---

## 📊 Ringkasan Prioritas

| # | Temuan | Severity | Effort | Prioritas |
|---|--------|----------|--------|-----------|
| 1 | Orphaned transactions saat delete | 🔴 CRITICAL | Medium | **P0** |
| 5 | AccountDetailScreen saldo tanpa openingBalance | 🔴 HIGH | Low | **P0** |
| 6 | `disableAnimations: true` di production | 🟡 MEDIUM | Trivial | **P1** |
| — | 3 unused dependencies (flutter_svg, table_calendar, url_launcher) | 🟡 MEDIUM | Trivial | **P1** |
| 9,10 | Hardcoded colors bypass dark mode | 🟡 MEDIUM | Low | **P1** |
| 2 | Full reload setiap CRUD | 🟡 MEDIUM | High | **P2** |
| 4 | Semua data di memory | 🟡 MEDIUM | High | **P2** |
| 12 | kIconGroups di lokasi salah | 🟢 LOW | Low | **P2** |
| 13 | add_transaction masih 1025 baris | 🟢 LOW | Medium | **P3** |
| 14 | Font hanya 1 weight | 🟢 LOW | Low | **P3** |
| 16 | Tidak ada database index | 🟢 LOW | Low | **P3** |

---

> **Catatan:** Semua rekomendasi di atas dirancang untuk bisa diimplementasi secara inkremental
> tanpa mengubah schema database yang ada (zero-migration untuk fix kritis),
> kecuali penambahan index yang memerlukan increment versi DB.
