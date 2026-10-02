abstract class BlockedUsersRepository {
  Stream<Set<String>> watchBlocked();

  Future<void> block(String userId);

  Future<void> unblock(String userId);
}
