 class MatchRating {
  final int id;
  final int matchId;
  final int ratedUserId;
  final int raterUserId;
  final int rating;
  final String? comment;
  final bool mvpVote;

  MatchRating({
    required this.id,
    required this.matchId,
    required this.ratedUserId,
    required this.raterUserId,
    required this.rating,
    this.comment,
    required this.mvpVote,
  });

  factory MatchRating.fromJson(Map<String, dynamic> json) {
    return MatchRating(
      id: json['id'],
      matchId: json['match_id'],
      ratedUserId: json['rated_user_id'],
      raterUserId: json['rater_user_id'],
      rating: json['rating'],
      comment: json['comment'],
      mvpVote: json['mvp_vote'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'match_id': matchId,
    'rated_user_id': ratedUserId,
    'rater_user_id': raterUserId,
    'rating': rating,
    'comment': comment,
    'mvp_vote': mvpVote,
  };
}