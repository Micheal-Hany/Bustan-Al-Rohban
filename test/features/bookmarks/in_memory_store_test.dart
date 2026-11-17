import 'package:bustan_al_rohban/features/bookmarks/domain/bookmark_store.dart';
import 'package:bustan_al_rohban/features/reader/progress/reading_progress.dart';

import '../reader/progress/progress_store_contract.dart';
import 'bookmark_store_contract.dart';

void main() {
  runBookmarkStoreContract(
    'in-memory',
    (newId, clock) async => InMemoryBookmarkStore(newId: newId, clock: clock),
  );
  runProgressStoreContract(
    'in-memory',
    () async => InMemoryProgressStore(),
  );
}
