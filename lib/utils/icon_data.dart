// lib/utils/icon_data.dart

// ── DATA IKON PER GRUP ──
const List<Map<String, dynamic>> kIconGroups = [
  {
    'label': 'Makanan & Minuman',
    'icons': [
      '🍜',
      '🍚',
      '🍱',
      '🥗',
      '🍔',
      '🍕',
      '🍣',
      '🌮',
      '🍰',
      '☕',
      '🧋',
      '🥤',
      '🍺',
      '🍷'
    ],
  },
  {
    'label': 'Transportasi',
    'icons': ['🚗', '🛵', '🚕', '✈️', '🚌', '🚂', '🚢', '🛺', '⛽', '🅿️'],
  },
  {
    'label': 'Belanja',
    'icons': ['🛒', '👟', '👜', '👗', '💄', '🧴', '🕶️', '⌚', '💍', '🛍️'],
  },
  {
    'label': 'Rumah & Utilitas',
    'icons': ['🏠', '💡', '🔧', '🔌', '🚿', '🧹', '🪴', '🛋️', '🧺', '🏗️'],
  },
  {
    'label': 'Kesehatan',
    'icons': ['🏥', '💊', '🩺', '🧴', '🏋️', '🧘', '🦷', '👓', '🩹', '🧬'],
  },
  {
    'label': 'Hiburan',
    'icons': ['🎮', '🎬', '🎵', '🎧', '📺', '🎭', '🎪', '🎠', '🎯', '🎲'],
  },
  {
    'label': 'Pendidikan',
    'icons': ['🎓', '📚', '📝', '🖥️', '📖', '🔬', '✏️', '🏫', '📐', '🧑‍💻'],
  },
  {
    'label': 'Anak & Hewan',
    'icons': ['🍼', '🧸', '🎀', '🧒', '🐾', '🐶', '🐈', '🐠', '🐇', '🦜'],
  },
  {
    'label': 'Keuangan & Investasi',
    'icons': ['💰', '💳', '📈', '🏦', '💵', '🏧', '📉', '💹', '🪙', '🤑'],
  },
  {
    'label': 'Bisnis & Kerja',
    'icons': ['💼', '💻', '🤝', '🏪', '📊', '📋', '🖨️', '📞', '🏢', '📬'],
  },
  {
    'label': 'Perjalanan & Liburan',
    'icons': ['🏖️', '🏔️', '🗺️', '🧳', '🏨', '📸', '🎡', '⛺', '🌴', '🗼'],
  },
  {
    'label': 'Hadiah & Sosial',
    'icons': ['🎁', '🎉', '❤️', '🥳', '🎂', '💐', '🤲', '🙏', '💌', '🫂'],
  },
  {
    'label': 'Lainnya',
    'icons': ['📦', '✨', '⭐', '🎯', '🔥', '💫', '🌈', '🔮', '♻️', '🗑️'],
  },
];

final List<String> kAllIcons =
    kIconGroups.expand((g) => (g['icons'] as List).cast<String>()).toList();
