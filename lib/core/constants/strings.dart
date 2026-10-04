class AppStrings {
  // App Info
  static const appName = 'Patungin';
  static const appTagline = 'Bagi Tagihan & Scan Struk Tanpa Ribet';

  // Navigation & Tabs
  static const historyTitle = 'Riwayat Bill';
  static const newBillTitle = 'Buat Bill Baru';
  static const reviewOcrTitle = 'Review Hasil Scan';
  static const billResultTitle = 'Rincian Pembagian';

  // Stepper Steps
  static const stepItems = 'Daftar Item';
  static const stepParticipants = 'Peserta';
  static const stepAssign = 'Bagi Item';
  static const stepExtraCosts = 'Pajak & Biaya';
  static const stepResult = 'Hasil';

  // Item Step
  static const scanReceipt = 'Scan Struk';
  static const manualInput = 'Input Manual';
  static const addItem = 'Tambah Item';
  static const editItem = 'Edit Item';
  static const itemName = 'Nama Item';
  static const unitPrice = 'Harga Satuan';
  static const quantity = 'Jumlah (Qty)';
  static const totalPrice = 'Total Harga';
  static const emptyItemsMessage = 'Belum ada item. Scan struk atau tambah item secara manual.';

  // Participant Step
  static const addParticipant = 'Tambah Peserta';
  static const participantName = 'Nama Peserta';
  static const paidBy = 'Siapa yang bayar duluan?';
  static const noOnePaidYet = 'Belum dipilih (hanya hitung per orang)';
  static const minParticipantsWarning = 'Tambahkan minimal 2 peserta untuk melanjutkan.';
  static const duplicateNameWarning = 'Nama peserta sudah ada, tambahkan penanda unik.';

  // Assign Step
  static const assignTitle = 'Siapa makan apa?';
  static const assignAll = 'Semua Orang';
  static const portionWeight = 'Porsi';
  static const unassignedWarning = 'Ada item yang belum dibagikan ke siapa pun!';
  static const tempTotalLive = 'Perkiraan Sementara:';

  // Extra Costs Step
  static const subtotalLabel = 'Subtotal';
  static const taxLabel = 'Pajak (PPN/PB1)';
  static const serviceLabel = 'Biaya Layanan (Service)';
  static const discountLabel = 'Diskon / Voucher';
  static const receiptTotalLabel = 'Total di Struk';
  static const calculatedTotalLabel = 'Total Terhitung';
  static const nominalOption = 'Nominal (Rp)';
  static const percentOption = 'Persen (%)';
  static const mismatchWarning = 'Total terhitung berbeda dengan total di struk!';
  static const discountExceedsSubtotal = 'Diskon tidak boleh melebihi subtotal!';

  // Result Step
  static const whoPaysWhom = 'Siapa Bayar ke Siapa';
  static const personBreakdown = 'Rincian Peserta';
  static const shareToWhatsApp = 'Bagikan ke WhatsApp';
  static const shareAsImage = 'Bagikan Gambar Ringkasan';
  static const saveBill = 'Simpan Tagihan';
  static const editBill = 'Edit Tagihan';
  static const billSavedSuccess = 'Tagihan berhasil disimpan!';
  static const copyText = 'Salin Teks';
  static const textCopied = 'Teks rincian berhasil disalin!';

  // OCR Review
  static const ocrReviewNotice = 'Periksa kembali item hasil scan struk. Tandai item yang diragukan.';
  static const lowConfidenceBadge = 'Perlu Dicek';
  static const useThisResult = 'Gunakan Hasil Ini';
  static const takePhoto = 'Ambil Foto';
  static const pickFromGallery = 'Pilih dari Galeri';
  static const ocrFailed = 'Tidak berhasil membaca teks dari struk. Silakan coba foto yang lebih jelas atau input manual.';
  static const permissionDenied = 'Izin kamera dibutuhkan untuk memotret struk.';

  // Dialogs & Actions
  static const deleteConfirmTitle = 'Hapus Tagihan?';
  static const deleteConfirmMessage = 'Tagihan ini akan dihapus permanen dari riwayat.';
  static const cancel = 'Batal';
  static const delete = 'Hapus';
  static const save = 'Simpan';
  static const next = 'Lanjut';
  static const back = 'Kembali';
  static const close = 'Tutup';
  static const ok = 'OK';
}
