import 'moment_model.dart';

abstract class MomentsRepository {
  Stream<List<MomentModel>> watchMoments();

  Stream<List<MomentComment>> watchComments(String momentId);

  Future<void> toggleLike(String momentId);

  Future<void> addComment(String momentId, String text);

  Future<String> createMoment(MomentModel moment);

  Future<void> deleteMoment(String momentId);
}
