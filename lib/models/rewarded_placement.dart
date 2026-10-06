/// Strictly permitted Rewarded Ad placements (Clauses 426, 432).
/// Exactly 3 placements. No extra placements or ad formats allowed.
enum RewardedPlacement {
  /// Preparation phase coin aid when player cannot afford next unit
  supplyDrop,

  /// One-time 50% HP revive when base health reaches zero
  secondChance,

  /// Doubles the base scrap salvaged at the end of a completed run
  extraScrap,
}
