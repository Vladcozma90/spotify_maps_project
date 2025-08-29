SELECT
  ce.snapshot_ts,
  ce.snapshot_date,
  p.country_code,
  p.kind,
  ce.playlist_id,
  ce.track_id,
  COUNT(*) AS dup_count
FROM spotify_maps.chart_entries ce
JOIN spotify_maps.playlists p ON p.playlist_id = ce.playlist_id
GROUP BY ce.snapshot_ts, ce.snapshot_date, p.country_code, p.kind, ce.playlist_id, ce.track_id
HAVING COUNT(*) > 1;