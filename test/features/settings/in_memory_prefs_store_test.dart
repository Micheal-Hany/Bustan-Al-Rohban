import 'package:bustan_al_rohban/features/settings/domain/reading_prefs.dart';

import 'prefs_store_contract.dart';

void main() {
  runPrefsStoreContract('in-memory', () async => InMemoryPrefsStore());
}
