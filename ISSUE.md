# 🔧 Refactoring Plan — Monetoo

> **ATURAN UTAMA**: Tidak ada fitur yang diubah. Tidak ada perubahan pada skema database, query, atau perilaku yang sudah berjalan di production. Semua refactor ini murni **internal code quality** — hasilnya harus identik secara fungsional.

---

## Daftar Isi

1. [Kode Tidak Digunakan (Dead Code)](#1-kode-tidak-digunakan-dead-code)
2. [Kode Berulang (Duplicated Code)](#2-kode-berulang-duplicated-code)
3. [Kode Kurang Efisien / Perlu Modularisasi](#3-kode-kurang-efisien--perlu-modularisasi)
4. [File Terlalu Besar — Perlu Dipecah](#4-file-terlalu-besar--perlu-dipecah)
5. [Ringkasan Prioritas](#5-ringkasan-prioritas)

---

## 1. Kode Tidak Digunakan (Dead Code)

### 1.1 `report_screen.dart` — File Tidak Digunakan Sama Sekali

| Item | Detail |
|------|--------|
| **File** | `lib/screens/report_screen.dart` (671 baris) |
| **Masalah** | File ini **tidak di-import di manapun** dalam project. Tidak ada referensi dari `main_navigation.dart` atau file lain. Kemungkinan ini adalah versi lama dari `statistics_screen.dart`. |
| **Aksi** | Hapus file, atau pindahkan ke folder `_deprecated/` jika ingin disimpan sebagai referensi. |
| **Dampak** | Mengurangi ~671 baris dead code. Tidak ada efek ke fitur. |

### 1.2 Method-method Tidak Dipanggil di `FinanceProvider`

| Method | File | Baris | Keterangan |
|--------|------|-------|------------|
| `getRecentTransactions()` | `finance_provider.dart` | 161-165 | Tidak dipanggil di manapun |
| `getExpensesByCategory()` | `finance_provider.dart` | 167-175 | Tidak dipanggil di manapun |
| `getIncomesByCategory()` | `finance_provider.dart` | 177-185 | Tidak dipanggil di manapun |
| `getTransactionCountByCategory()` | `finance_provider.dart` | 187-195 | Tidak dipanggil di manapun |
| `getDailySummary()` | `finance_provider.dart` | 143-145 | Hanya dipanggil dari `report_screen.dart` (yang juga dead code) |
| `getMonthlySummary()` | `finance_provider.dart` | 147-149 | Hanya dipanggil dari `report_screen.dart` |
| `getCategoryExpenseByMonth()` | `finance_provider.dart` | 151-154 | Hanya dipanggil dari `report_screen.dart` |
| `getDailyTotalsForMonth()` | `finance_provider.dart` | 156-159 | Hanya dipanggil dari `report_screen.dart` |
| `getTransactionsByDate()` | `finance_provider.dart` | 91-93 | Tidak dipanggil di manapun (screen pakai `getTransactionsByMonth` langsung) |

**Aksi**: Hapus method-method ini. Jika `report_screen.dart` nanti dikembalikan, method-method ini bisa ditambahkan kembali.

### 1.3 Method-method Tidak Dipanggil di `DatabaseHelper`

| Method | File | Baris | Keterangan |
|--------|------|-------|------------|
| `getCategoriesByType()` | `database_helper.dart` | 132-141 | Tidak dipanggil di manapun (provider langsung filter dari list) |
| `getAccountsByType()` | `database_helper.dart` | 332-341 | Tidak dipanggil di manapun |
| `getPrimaryAccount()` | `database_helper.dart` | 343-353 | Tidak dipanggil di manapun |
| `getDailySummary()` | `database_helper.dart` | 249-263 | Hanya dipanggil dari provider dead code |
| `getMonthlySummary()` | `database_helper.dart` | 265-279 | Hanya dipanggil dari provider dead code |
| `getCategoryExpenseByMonth()` | `database_helper.dart` | 281-293 | Hanya dipanggil dari provider dead code |
| `getDailyTotalsForMonth()` | `database_helper.dart` | 295-321 | Hanya dipanggil dari provider dead code |

**Aksi**: Hapus method-method ini. **CATATAN**: Jangan hapus tabel atau ubah skema, hanya hapus method Dart yang tidak terpakai.

### 1.4 Getter Tidak Dipanggil di `FinanceProvider`

| Getter | Baris | Keterangan |
|--------|-------|------------|
| `savingsAccounts` | 33-34 | Tidak dipanggil di manapun |
| `primaryAccount` | 36-39 | Tidak dipanggil di manapun |

**Aksi**: Hapus getter-getter ini.

### 1.5 Property & Constant Tidak Digunakan di `AppTheme`

| Item | Baris | Keterangan |
|------|-------|------------|
| `accentGlow` | 13 | Tidak direferensikan |
| `darkAccentGlow` | 31 | Tidak direferensikan |
| `accentShadow` | 217-223 | Tidak direferensikan |
| `accentGradient` | 232-236 | Tidak direferensikan |
| `incomeGradient` | 238-242 | Tidak direferensikan |
| `expenseGradient` | 244-248 | Tidak direferensikan |

**Aksi**: Hapus constant/getter yang tidak digunakan.

### 1.6 Property Tidak Digunakan di `AppColors`

| Item | Baris | Keterangan |
|------|-------|------------|
| `AppColors.instance` | 40 | Static getter yang selalu return `null`, tidak digunakan |

**Aksi**: Hapus.

### 1.7 Utility Tidak Digunakan di `CurrencyFormatter`

| Method | Baris | Keterangan |
|--------|-------|------------|
| `formatWithSign()` | 31-34 | Tidak dipanggil di manapun |

**Aksi**: Hapus method ini.

---

## 2. Kode Berulang (Duplicated Code)

### 2.1 🔴 Month Picker Dialog — Duplikasi 3x (PRIORITAS TINGGI)

**Lokasi duplikasi**:
1. `transaction_screen.dart` → `_pickMonth()` (baris 23-133)
2. `category_screen.dart` → `_pickMonth()` (baris 126-228)
3. `statistics_screen.dart` → `_pickMonth()` (baris 55-157)

Ketiga implementasi **hampir identik**: dialog dengan year selector + grid 12 bulan. Perbedaan hanya styling minor.

**Aksi**: Buat **reusable widget** `MonthPickerDialog` di `lib/widgets/month_picker_dialog.dart`.

```dart
// Contoh API:
Future<DateTime?> showMonthPicker(BuildContext context, DateTime initial);
```

### 2.2 🔴 Month Selector Row — Duplikasi 3x (PRIORITAS TINGGI)

**Lokasi duplikasi**:
1. `transaction_screen.dart` → `_buildMonthSelector()` (baris 226-268)
2. `category_screen.dart` → dalam `build()` (baris 313-345)
3. `statistics_screen.dart` → `_buildMonthSelector()` (baris 226-261)
4. `report_screen.dart` → `_buildMonthSelector()` (baris 87-128) — dead code

Semua menampilkan `← [Bulan Tahun ▼] →` dengan logika identik.

**Aksi**: Buat widget `MonthSelectorBar` di `lib/widgets/month_selector_bar.dart`.

```dart
MonthSelectorBar(
  selectedMonth: _selectedMonth,
  onChanged: (date) => setState(() => _selectedMonth = date),
  onPickMonth: () => showMonthPicker(context, _selectedMonth),
)
```

### 2.3 🔴 Filter Chips (Semua/Pemasukan/Pengeluaran) — Duplikasi 3x (PRIORITAS TINGGI)

**Lokasi duplikasi**:
1. `transaction_screen.dart` → `_filterChip()` + `_buildFilterChips()` (baris 270-317)
2. `account_screen.dart` → `_AccountDetailScreenState._filterChip()` (baris 996-1029)
3. Logika filter `_applyFilter()` juga duplikat di `transaction_screen.dart` (216-224) dan `_AccountDetailScreenState` (780-786)

**Aksi**: Buat widget `TransactionFilterChips` di `lib/widgets/transaction_filter_chips.dart`.

### 2.4 🔴 Confirm Delete Bottom Sheet — Duplikasi 3x (PRIORITAS TINGGI)

**Lokasi duplikasi**:
1. `transaction_tile.dart` → `_showDeleteConfirm()` (baris 169-256)
2. `account_screen.dart` → `_confirmDeleteAccount()` (baris 629-726)
3. `category_screen.dart` → `_confirmDeleteCategory()` (baris 1057-1162)

Semua menggunakan pola identik:
- Handle bar
- Ikon hapus dalam circle
- Judul "Hapus X?"
- Deskripsi
- Tombol Batal + Hapus

**Aksi**: Buat widget `ConfirmDeleteSheet` di `lib/widgets/confirm_delete_sheet.dart`.

```dart
Future<bool?> showConfirmDeleteSheet(
  BuildContext context, {
  required String title,
  required String description,
  VoidCallback? onConfirm,
});
```

### 2.5 🟡 Bottom Sheet Handle Bar — Duplikasi 6x+ (PRIORITAS SEDANG)

Kode berikut muncul berulang di hampir semua bottom sheet:

```dart
Container(
  width: 40, height: 4,
  margin: const EdgeInsets.only(bottom: 20),
  decoration: BoxDecoration(
    color: c.divider, borderRadius: BorderRadius.circular(2)),
),
```

**Lokasi**: `transaction_tile.dart`, `account_screen.dart`, `category_screen.dart`, `update_checker.dart`, `add_transaction_bottom_sheet.dart`

**Aksi**: Buat widget kecil `BottomSheetHandle` di `lib/widgets/common/bottom_sheet_handle.dart`.

### 2.6 🟡 Edit Mode Toggle Button — Duplikasi 2x (PRIORITAS SEDANG)

**Lokasi duplikasi**:
1. `account_screen.dart` → Edit button + info banner (baris 61-116)
2. `category_screen.dart` → Edit button + info banner (baris 281-480)

Keduanya menampilkan:
- Tombol edit (AnimatedContainer dengan ikon)
- Info banner "Mode edit aktif — ketuk X untuk ubah atau hapus"

**Aksi**: Buat widget `EditModeButton` dan `EditModeBanner`.

### 2.7 🟡 Income/Expense Summary Row — Duplikasi 2x (PRIORITAS SEDANG)

**Lokasi duplikasi**:
1. `transaction_screen.dart` → `_buildMonthlySummary()` (baris 319-388)
2. `account_screen.dart` → `_AccountDetailScreen` summary (baris 866-918)

Keduanya menampilkan box Masuk + Keluar dengan styling identik.

**Aksi**: Buat widget `IncomeExpenseSummary`.

### 2.8 🟡 Pola Penghitungan Income/Expense dari List Transaksi — Duplikasi 8x+

Pola berikut muncul berulang di banyak file:

```dart
final income = txs
    .where((t) => t.type == TransactionType.income)
    .fold(0.0, (s, t) => s + t.amount);
final expense = txs
    .where((t) => t.type == TransactionType.expense)
    .fold(0.0, (s, t) => s + t.amount);
```

**Lokasi**: `transaction_screen.dart` (2x), `account_screen.dart` (2x), `category_screen.dart` (2x), `statistics_screen.dart` (2x), `report_screen.dart` (2x), `finance_provider.dart`

**Aksi**: Buat extension method pada `List<TransactionModel>`:

```dart
extension TransactionListX on List<TransactionModel> {
  double get totalIncome => where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);
  double get totalExpense => where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);
  double get balance => totalIncome - totalExpense;
}
```

### 2.9 🟡 Pola Group By Date — Duplikasi 3x (PRIORITAS SEDANG)

Pola grouping transaksi per tanggal muncul di:
1. `transaction_screen.dart` → `_buildGroupedList()` (baris 394-400)
2. `report_screen.dart` → `_buildDailyReport()` (baris 544-551) — dead code
3. `database_helper.dart` → `getDailyTotalsForMonth()` (baris 300-302) — dead code

Format key selalu: `'${t.date.year}-${...padLeft(2, '0')}-${...padLeft(2, '0')}'`

**Aksi**: Buat helper method `groupTransactionsByDate()` atau tambahkan sebagai extension, contoh:

```dart
extension TransactionListX on List<TransactionModel> {
  Map<String, List<TransactionModel>> groupByDate() { ... }
}
```

### 2.10 🟢 Duplikasi `_getAccountBalance()` (PRIORITAS RENDAH)

**Lokasi duplikasi**:
1. `account_screen.dart` → `_getAccountBalance()` (baris 129-139)
2. `finance_provider.dart` → `getAccountBalance()` (baris 214-236)

Logika **identik** tapi `account_screen.dart` membuat versi sendiri.

**Aksi**: Hapus `_getAccountBalance()` dari `account_screen.dart`, gunakan `provider.getAccountBalance()`.

### 2.11 🟢 showModalBottomSheet untuk AddTransaction — Duplikasi 4x (PRIORITAS RENDAH)

Kode berikut copy-paste di 4 tempat:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => AddTransactionBottomSheet(transaction: tx),
);
```

**Lokasi**: `transaction_screen.dart`, `account_screen.dart`, `category_screen.dart`, `statistics_screen.dart`

**Aksi**: Buat static helper di `AddTransactionBottomSheet`:

```dart
static void show(BuildContext context, {TransactionModel? transaction, CategoryModel? category}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddTransactionBottomSheet(transaction: transaction, initialCategory: category),
  );
}
```

---

## 3. Kode Kurang Efisien / Perlu Modularisasi

### 3.1 🔴 `UpdateChecker.check()` dan `checkManual()` — Duplikasi Logik API Call

**File**: `lib/utils/update_checker.dart`
**Masalah**: Method `check()` (baris 21-49) dan `checkManual()` (baris 53-94) mengandung logika API call yang **hampir identik**:
- Sama-sama `Dio().get(_apiUrl, ...)`
- Sama-sama parse `tag_name`, cari asset APK
- Sama-sama `PackageInfo.fromPlatform()`
- Sama-sama panggil `_isNewer()` dan `_showUpdateDialog()`

Bedanya hanya: `check()` silent, `checkManual()` kasih feedback.

**Aksi**: Ekstrak common logic ke private method:

```dart
static Future<_UpdateInfo?> _fetchLatestRelease() async { ... }

// Kemudian:
static Future<void> check(BuildContext context) async {
  final info = await _fetchLatestRelease();
  if (info != null && context.mounted) _showUpdateDialog(context, info);
}

static Future<void> checkManual(BuildContext context) async {
  final info = await _fetchLatestRelease();
  if (info != null) _showUpdateDialog(context, info);
  else AppToast.success(context, 'Sudah versi terbaru');
}
```

### 3.2 🟡 `_AccountDetailScreen` embedded dalam `account_screen.dart`

**File**: `lib/screens/account_screen.dart` (1031 baris)
**Masalah**: File ini mengandung 2 widget besar + dialogs, semuanya dalam 1 file:
- `AccountScreen` (baris 15-750)
- `_AccountDetailScreen` (baris 756-1031)

**Aksi**: Pisahkan `_AccountDetailScreen` ke file sendiri `lib/screens/account_detail_screen.dart`.

### 3.3 🟡 `_CategoryDetailScreen` embedded dalam `statistics_screen.dart`

**File**: `lib/screens/statistics_screen.dart` (1210 baris)
**Masalah**: Mengandung 3 class dalam 1 file:
- `StatisticsScreen` (baris 15-959)
- `_CategoryDetailScreen` (baris 965-1184)
- `_CatData` (baris 1190-1209)

**Aksi**: Pisahkan `_CategoryDetailScreen` ke `lib/screens/category_detail_screen.dart` dan `_CatData` ke `lib/models/category_data.dart`.

### 3.4 🟡 `_IconPickerDialog` embedded dalam `category_screen.dart`

**File**: `lib/screens/category_screen.dart` (1354 baris)
**Masalah**: Mengandung 3 class + global data:
- `kIconGroups` data (baris 16-84)
- `CategoryScreen` (baris 89-1191)
- `_IconPickerDialog` (baris 1195-1353)

**Aksi**:
- Pindahkan `kIconGroups` dan `kAllIcons` ke `lib/utils/icon_data.dart`
- Pisahkan `_IconPickerDialog` ke `lib/widgets/icon_picker_dialog.dart`

### 3.5 🟡 `add_transaction_bottom_sheet.dart` terlalu besar (1219 baris)

**File**: `lib/widgets/add_transaction_bottom_sheet.dart`
**Masalah**: Satu file berisi semua logika calculator, UI numpad, picker, dan form.

**Aksi**: Pisahkan menjadi:
- `lib/widgets/calculator_numpad.dart` — widget numpad + logika kalkulator
- `lib/widgets/add_transaction_bottom_sheet.dart` — tetap sebagai orchestrator

### 3.6 🟢 `_statDivider()` gunakan hardcoded `AppTheme.divider`

**File**: `lib/screens/statistics_screen.dart` (baris 1156-1160)
**Masalah**: Menggunakan `AppTheme.divider` (light mode color) secara langsung, bukan `context.colors.divider`. Ini membuat dark mode tidak render warna yang benar pada divider ini.

**Aksi**: Ganti `AppTheme.divider` → `context.colors.divider`.

### 3.7 🟢 `_isToday()` duplikasi fungsi `DateFormatter.isSameDay()`

**File**: `lib/widgets/add_transaction_bottom_sheet.dart` (baris 527-530)
**Masalah**: Method `_isToday()` mengimplementasikan logika yang sudah ada di `DateFormatter.isSameDay()`.

**Aksi**: Ganti `_isToday(d)` → `DateFormatter.isSameDay(d, DateTime.now())`.

---

## 4. File Terlalu Besar — Perlu Dipecah

| File | Baris | Rekomendasi |
|------|-------|-------------|
| `category_screen.dart` | 1354 | Pisahkan `_IconPickerDialog`, pindahkan `kIconGroups` |
| `add_transaction_bottom_sheet.dart` | 1219 | Pisahkan widget numpad/kalkulator |
| `statistics_screen.dart` | 1210 | Pisahkan `_CategoryDetailScreen` dan `_CatData` |
| `account_screen.dart` | 1031 | Pisahkan `_AccountDetailScreen` |
| `report_screen.dart` | 671 | **Hapus** (dead code) |

---

## 5. Ringkasan Prioritas

### 🔴 Prioritas Tinggi (Dampak Besar, Risiko Rendah)

| # | Aksi | Estimasi Baris Dihapus / Direfaktor |
|---|------|-------------------------------------|
| 1 | Hapus `report_screen.dart` (dead code) | -671 baris |
| 2 | Hapus dead method di `FinanceProvider` & `DatabaseHelper` | ~120 baris |
| 3 | Ekstrak `MonthPickerDialog` (deduplikasi 3x) | ~-200 baris duplikat |
| 4 | Ekstrak `MonthSelectorBar` (deduplikasi 3x) | ~-80 baris duplikat |
| 5 | Ekstrak `ConfirmDeleteSheet` (deduplikasi 3x) | ~-180 baris duplikat |
| 6 | Ekstrak `TransactionFilterChips` (deduplikasi 3x) | ~-80 baris duplikat |
| 7 | Buat extension `TransactionListX` (deduplikasi 8x+) | ~-50 baris duplikat |

### 🟡 Prioritas Sedang (Maintainability)

| # | Aksi |
|---|------|
| 8 | Refactor `UpdateChecker` — deduplikasi API call |
| 9 | Pisahkan `_AccountDetailScreen` ke file sendiri |
| 10 | Pisahkan `_CategoryDetailScreen` ke file sendiri |
| 11 | Pisahkan `_IconPickerDialog` + `kIconGroups` |
| 12 | Ekstrak `BottomSheetHandle` widget |
| 13 | Ekstrak `EditModeButton` + `EditModeBanner` |
| 14 | Ekstrak `IncomeExpenseSummary` widget |
| 15 | Pisahkan numpad dari `add_transaction_bottom_sheet.dart` |

### 🟢 Prioritas Rendah (Nice to Have)

| # | Aksi |
|---|------|
| 16 | Hapus unused constants di `AppTheme` |
| 17 | Hapus unused getter `AppColors.instance` |
| 18 | Hapus `CurrencyFormatter.formatWithSign()` |
| 19 | Gunakan `provider.getAccountBalance()` instead of duplicate di `account_screen` |
| 20 | Fix `_statDivider` yang hardcode `AppTheme.divider` |
| 21 | Ganti `_isToday()` → `DateFormatter.isSameDay()` |
| 22 | Buat static helper `AddTransactionBottomSheet.show()` |

---

## ⚠️ Catatan Penting

1. **JANGAN** mengubah skema database, nama tabel, atau nama kolom
2. **JANGAN** mengubah perilaku CRUD (create/read/update/delete) yang sudah ada
3. **JANGAN** mengubah UI/UX yang terlihat oleh user — refactor hanya di level kode
4. **JANGAN** mengubah `_upgradeDB()` migration — data user production bergantung pada ini
5. Setiap perubahan harus bisa di-build dan **identical secara fungsional** dengan versi sebelumnya
6. Lakukan refactor secara **incremental** — satu issue per PR agar mudah di-review

---

## 📊 Estimasi Dampak

| Metrik | Sebelum | Sesudah (Estimasi) |
|--------|---------|---------------------|
| Total baris kode | ~7500 | ~5800 (-23%) |
| File terbesar | 1354 baris | ~700 baris |
| Duplikasi kode | 8+ pattern | 0 |
| Dead code | ~900 baris | 0 |
| Reusable widgets | 2 | 9+ |
