-- Key stats per player per season (a readable subset of player_season_stats).
DROP VIEW IF EXISTS player_key_stats;
CREATE VIEW player_key_stats AS
SELECT
  s.player_id, s.player_name, s.season_id, s.season_name, s.team_id, s.team_name, s.position,
  COALESCE(s.scoring_appearances, 0)            AS appearances,
  COALESCE(s.scoring_minutesPlayed, 0)          AS minutes_played,
  COALESCE(s.scoring_points, 0)                 AS points,
  COALESCE(s.scoring_tryScored, 0)              AS tries,
  COALESCE(s.attack_tryAssist, 0)               AS try_assists,
  COALESCE(s.attack_carries, 0)                 AS carries,
  COALESCE(s.attack_metresMade, 0)              AS metres_made,
  COALESCE(s.attack_cleanBreak, 0)              AS clean_breaks,
  COALESCE(s.attack_defenderBeaten, 0)          AS defenders_beaten,
  COALESCE(s.attack_offload, 0)                 AS offloads,
  COALESCE(s.defence_tackle, 0)                 AS tackles,
  COALESCE(s.defence_missedTackle, 0)           AS missed_tackles,
  COALESCE(s.defence_turnoverWon, 0)            AS turnovers_won,
  COALESCE(s.lineout_lineoutThrowsWon, 0)       AS lineouts_won,
  COALESCE(s.lineout_lineoutSteals, 0)          AS lineout_steals,
  COALESCE(s.scoring_conversion, 0)             AS conversions,
  COALESCE(s.scoring_penaltyGoal, 0)            AS penalty_goals,
  COALESCE(s.scoring_dropGoal, 0)               AS drop_goals,
  COALESCE(s.scoring_missedConversion, 0) + COALESCE(s.scoring_missedPenaltyGoal, 0)
    + COALESCE(s.scoring_missedDropGoal, 0)     AS missed_goals,
  COALESCE(s.kicking_kicksInPlay, 0)            AS kicks_from_hand,
  COALESCE(s.kicking_kickMetres, 0)             AS kick_metres,
  COALESCE(s.discipline_penaltyConceded, 0)     AS penalties_conceded,
  COALESCE(s.discipline_yellowCard, 0)          AS yellow_cards,
  COALESCE(s.discipline_redCard, 0)             AS red_cards
FROM player_season_stats s;

-- One row per player in a current URC squad: bio plus URC totals across every season held.
DROP VIEW IF EXISTS player_cards;
CREATE VIEW player_cards AS
WITH totals AS (
  SELECT player_id,
    COUNT(DISTINCT season_id) AS seasons, SUM(appearances) AS appearances, SUM(minutes_played) AS minutes_played,
    SUM(points) AS points, SUM(tries) AS tries, SUM(try_assists) AS try_assists,
    SUM(carries) AS carries, SUM(metres_made) AS metres_made, SUM(clean_breaks) AS clean_breaks,
    SUM(defenders_beaten) AS defenders_beaten, SUM(offloads) AS offloads,
    SUM(tackles) AS tackles, SUM(missed_tackles) AS missed_tackles, SUM(turnovers_won) AS turnovers_won,
    SUM(lineouts_won) AS lineouts_won, SUM(lineout_steals) AS lineout_steals,
    SUM(conversions) AS conversions, SUM(penalty_goals) AS penalty_goals, SUM(drop_goals) AS drop_goals,
    SUM(missed_goals) AS missed_goals, SUM(kick_metres) AS kick_metres,
    SUM(penalties_conceded) AS penalties_conceded, SUM(yellow_cards) AS yellow_cards, SUM(red_cards) AS red_cards
  FROM player_key_stats GROUP BY player_id
)
SELECT
  p.id AS player_id, p.first_name, p.last_name, c.full_name AS club, c.short_name AS club_short,
  p.position, p.position_group, p.age, p.date_of_birth, p.height_cm, p.weight_kg,
  p.birth_country, p.national_team, p.urc_debut, p.image_path,
  COALESCE(t.seasons, 0) AS urc_seasons,
  COALESCE(t.appearances, 0) AS appearances, COALESCE(t.minutes_played, 0) AS minutes_played,
  COALESCE(t.points, 0) AS points, COALESCE(t.tries, 0) AS tries, COALESCE(t.try_assists, 0) AS try_assists,
  COALESCE(t.carries, 0) AS carries, COALESCE(t.metres_made, 0) AS metres_made,
  COALESCE(t.clean_breaks, 0) AS clean_breaks, COALESCE(t.defenders_beaten, 0) AS defenders_beaten,
  COALESCE(t.offloads, 0) AS offloads, COALESCE(t.tackles, 0) AS tackles,
  ROUND(100.0 * t.tackles / NULLIF(t.tackles + t.missed_tackles, 0), 1) AS tackle_success_pct,
  COALESCE(t.turnovers_won, 0) AS turnovers_won, COALESCE(t.lineouts_won, 0) AS lineouts_won,
  COALESCE(t.lineout_steals, 0) AS lineout_steals,
  COALESCE(t.conversions, 0) AS conversions, COALESCE(t.penalty_goals, 0) AS penalty_goals,
  ROUND(100.0 * (t.conversions + t.penalty_goals + t.drop_goals)
    / NULLIF(t.conversions + t.penalty_goals + t.drop_goals + t.missed_goals, 0), 1) AS goal_kick_pct,
  COALESCE(t.kick_metres, 0) AS kick_metres,
  COALESCE(t.penalties_conceded, 0) AS penalties_conceded,
  COALESCE(t.yellow_cards, 0) AS yellow_cards, COALESCE(t.red_cards, 0) AS red_cards
FROM players p
JOIN clubs c ON c.id = p.club_id
LEFT JOIN totals t ON t.player_id = p.id;
