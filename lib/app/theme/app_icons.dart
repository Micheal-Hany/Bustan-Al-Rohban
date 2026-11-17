import 'package:flutter/widgets.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Single place that maps app concepts to Iconsax icons, so any icon can be
/// swapped by editing one line.
class AppIcons {
  const AppIcons._();

  static const IconData library = Iconsax.book_1;
  static const IconData search = Iconsax.search_normal_1;
  static const IconData bookmarkOff = Iconsax.bookmark;
  static const IconData bookmarkOn = Iconsax.bookmark_2;
  static const IconData chat = Iconsax.message_text;
  static const IconData settings = Iconsax.setting_2;
  static const IconData clear = Iconsax.close_circle;
  static const IconData delete = Iconsax.trash;
  static const IconData editorial = Iconsax.note_text;
  static const IconData send = Iconsax.send_1;
  static const IconData add = Iconsax.add;
  static const IconData play = Iconsax.play;
  static const IconData pause = Iconsax.pause;
  static const IconData stop = Iconsax.stop;
  static const IconData insights = Iconsax.lamp_on;
  static const IconData textSmaller = Iconsax.minus;
  static const IconData textLarger = Iconsax.add;
  static const IconData resume = Iconsax.play_circle;
  static const IconData preview = Iconsax.document_text;
  static const IconData voice = Iconsax.volume_high;
  static const IconData forward = Iconsax.arrow_left_2; // RTL: "next" points left
}
