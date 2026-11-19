/// Remembers that the user has seen the "what is sent" notice, which is shown
/// once, before the first question is sent.
abstract class ChatNoticeStore {
  Future<bool> accepted();
  Future<void> accept();
}

class InMemoryChatNoticeStore implements ChatNoticeStore {
  InMemoryChatNoticeStore({bool accepted = false}) : _accepted = accepted;

  bool _accepted;

  @override
  Future<bool> accepted() async => _accepted;

  @override
  Future<void> accept() async => _accepted = true;
}
