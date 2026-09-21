abstract final class AppStrings {
  static const appName = 'Senter';

  static const tapToTurnOn = 'Ketuk untuk menyalakan';
  static const tapToTurnOff = 'Ketuk untuk mematikan';
  static const checkingTorch = 'Memeriksa senter…';
  static const torchUnavailable = 'Perangkat ini tidak memiliki senter.';
  static const torchError = 'Gagal mengakses senter. Coba lagi.';

  static const deniedLines = [
    'Mematikan senter adalah fitur Premium 👑',
    'Eits. Mau matikan? Langganan dulu, Kak.',
    'Senter ini sudah terlanjur nyaman menyala.',
    'Kegelapan itu mahal.',
    'Tutup pakai tangan? Kami tidak bisa melarang itu.',
    'Anda sudah mencoba berkali-kali.\nSenter mulai merasa dicintai. 🥹',
    'Menyerah saja. Cahaya ini abadi.',
  ];

  static String deniedLine(int attempts) =>
      deniedLines[(attempts).clamp(0, deniedLines.length - 1)];

  static const premium = 'Premium';
  static const paywallTitle = 'Senter Premium';
  static const paywallSubtitle =
      'Menyalakan senter selalu gratis.\nMematikannya? Itu kemewahan.';
  static const paywallBenefits = [
    'Matikan senter kapan saja',
    'Hemat baterai (akhirnya)',
    'Status sosial sebagai pemilik senter premium',
  ];
  static const socialProof = '12.483 orang sudah berhasil mematikan senter';
  static const promoEndsIn = 'Promo kegelapan berakhir dalam';
  static const restore = 'Pulihkan pembelian';
  static const restoreDone = 'Pemulihan selesai.';
  static const purchasePending = 'Pembayaran sedang diproses…';
  static const purchaseCancelled = 'Pembelian dibatalkan.';
  static const purchaseFailed = 'Pembelian gagal.';
  static const storeUnavailable = 'Toko tidak tersedia saat ini.';
  static const noPlans = 'Paket langganan belum tersedia.';
  static const demoReset = 'Mode demo: kembali ke akun Gratis.';

  static const celebrationTitle = 'Selamat! 🎉';
  static const celebrationBody =
      'Anda kini resmi termasuk 0,01% manusia\nyang mampu mematikan senter.';
  static const celebrationAction = 'Matikan senter sekarang';
}
