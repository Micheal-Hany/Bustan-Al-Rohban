import 'package:bustan_al_rohban/features/ai_chat/domain/chat_store.dart';

import 'chat_store_contract.dart';

void main() {
  runChatStoreContract(
    'in-memory',
    (newId, clock) async => InMemoryChatStore(newId: newId, clock: clock),
  );
}
