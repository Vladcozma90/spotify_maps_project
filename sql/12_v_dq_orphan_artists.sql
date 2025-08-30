CREATE OR REPLACE VIEW spotify_maps.v_dq_orphan_artists AS
SELECT
  t.track_id,
  t.name AS track_name
FROM spotify_maps.tracks t
LEFT JOIN spotify_maps.track_artists ta 
       ON t.track_id = ta.track_id
WHERE ta.artist_id IS NULL;
