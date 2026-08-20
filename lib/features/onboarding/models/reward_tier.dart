class RewardTier {
  final int goal;
  final String rewardDescription;

  const RewardTier({
    required this.goal,
    required this.rewardDescription,
  });

  RewardTier copyWith({
    int? goal,
    String? rewardDescription,
  }) {
    return RewardTier(
      goal: goal ?? this.goal,
      rewardDescription: rewardDescription ?? this.rewardDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'reward_description': rewardDescription,
    };
  }

  factory RewardTier.fromJson(Map<String, dynamic> json) {
    return RewardTier(
      goal: (json['goal'] as num?)?.toInt() ?? 10,
      rewardDescription: (json['reward_description'] as String?) ?? '',
    );
  }
}
