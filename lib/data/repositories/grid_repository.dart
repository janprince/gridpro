import 'package:grid_professionals/core/models/models.dart';
import 'package:grid_professionals/data/mock_data.dart';

abstract interface class GridRepository {
  Professional getProfessional();
  List<Job> getJobs();
  List<Earning> getEarnings();
  List<Payout> getPayouts();
  List<Review> getReviews();
  List<TrainingModule> getTrainingModules();
}

class MockGridRepository implements GridRepository {
  const MockGridRepository();

  @override
  Professional getProfessional() => MockData.professional;

  @override
  List<Job> getJobs() => List<Job>.from(MockData.jobs);

  @override
  List<Earning> getEarnings() => List<Earning>.from(MockData.earnings);

  @override
  List<Payout> getPayouts() => List<Payout>.from(MockData.payouts);

  @override
  List<Review> getReviews() => List<Review>.from(MockData.reviews);

  @override
  List<TrainingModule> getTrainingModules() =>
      List<TrainingModule>.from(MockData.training);
}
