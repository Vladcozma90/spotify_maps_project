CREATE OR REPLACE VIEW spotify_maps.v_dq_missing_ranks AS
SELECT
  ce.snapshot_ts,
  ce.snapshot_date,
  p.country_code,
  p.kind,
  ce.playlist_id,
  COUNT(DISTINCT ce.rank) AS got_ranks,
  50 - COUNT(DISTINCT ce.rank) AS missing_count,
  ARRAY(
    SELECT rnk FROM generate_series(1,50) rnk
    EXCEPT
    SELECT DISTINCT ce2.rank
    FROM spotify_maps.chart_entries ce2
    WHERE ce2.playlist_id = ce.playlist_id
      AND ce2.snapshot_ts = ce.snapshot_ts
    ORDER BY 1
  ) AS missing_ranks
FROM spotify_maps.chart_entries ce
JOIN spotify_maps.playlists p ON p.playlist_id = ce.playlist_id
GROUP BY ce.snapshot_ts, ce.snapshot_date, p.country_code, p.kind, ce.playlist_id
HAVING COUNT(DISTINCT ce.rank) < 50;
