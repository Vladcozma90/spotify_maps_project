-- Schema
CREATE SCHEMA IF NOT EXISTS spotify_maps;

-- Countries (reference)
CREATE TABLE IF NOT EXISTS spotify_maps.countries (
  country_code VARCHAR(2) PRIMARY KEY,      -- ISO-3166-1 alpha-2
  country_name TEXT NOT NULL,
  market_code  VARCHAR(2) NOT NULL          -- Spotify market (usually same as ISO-2)
);

-- Playlists (editorial Top/Viral per country)
CREATE TABLE IF NOT EXISTS spotify_maps.playlists (
  playlist_id   TEXT PRIMARY KEY,            -- Spotify ID
  country_code  VARCHAR(2) NOT NULL REFERENCES spotify_maps.countries(country_code),
  name          TEXT NOT NULL,
  kind          TEXT NOT NULL CHECK (kind IN ('top','viral')),
  owner_name    TEXT,
  discovered_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Artists
CREATE TABLE IF NOT EXISTS spotify_maps.artists (
  artist_id TEXT PRIMARY KEY,                -- Spotify ID
  name      TEXT NOT NULL
);

-- Tracks (+ minimal album info)
CREATE TABLE IF NOT EXISTS spotify_maps.tracks (
  track_id           TEXT PRIMARY KEY,       -- Spotify ID
  name               TEXT NOT NULL,
  album_name         TEXT,
  album_release_date DATE
);

-- Many-to-many: track ↔ artist
CREATE TABLE IF NOT EXISTS spotify_maps.track_artists (
  track_id  TEXT NOT NULL REFERENCES spotify_maps.tracks(track_id)   ON DELETE CASCADE,
  artist_id TEXT NOT NULL REFERENCES spotify_maps.artists(artist_id) ON DELETE CASCADE,
  PRIMARY KEY (track_id, artist_id)
);

-- Audio features (one row per track)
CREATE TABLE IF NOT EXISTS spotify_maps.audio_features (
  track_id      TEXT PRIMARY KEY REFERENCES spotify_maps.tracks(track_id) ON DELETE CASCADE,
  tempo         REAL,
  energy        REAL,
  danceability  REAL,
  valence       REAL,
  loudness      REAL,
  acousticness  REAL,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Chart snapshots (append-only)
CREATE TABLE IF NOT EXISTS spotify_maps.chart_entries (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  snapshot_ts   TIMESTAMPTZ NOT NULL,   -- exact poll time (prefer UTC)
  snapshot_date DATE NOT NULL,          -- set from snapshot_ts in your INSERTs
  country_code  VARCHAR(2) NOT NULL REFERENCES spotify_maps.countries(country_code),
  playlist_id   TEXT NOT NULL REFERENCES spotify_maps.playlists(playlist_id),
  track_id      TEXT NOT NULL REFERENCES spotify_maps.tracks(track_id),
  rank          INT NOT NULL CHECK (rank BETWEEN 1 AND 50),
  CONSTRAINT chart_entries_unique_ts UNIQUE (snapshot_ts, playlist_id, rank)
);

-- Indexes (useful, minimal)
CREATE INDEX IF NOT EXISTS idx_playlists_country           ON spotify_maps.playlists (country_code);
CREATE INDEX IF NOT EXISTS idx_track_artists_artist        ON spotify_maps.track_artists (artist_id);
CREATE INDEX IF NOT EXISTS idx_audio_features_updated_at   ON spotify_maps.audio_features (updated_at);
CREATE INDEX IF NOT EXISTS idx_chart_date_country          ON spotify_maps.chart_entries (snapshot_date, country_code);
CREATE INDEX IF NOT EXISTS idx_chart_playlist_latest       ON spotify_maps.chart_entries (playlist_id, snapshot_ts);
CREATE INDEX IF NOT EXISTS idx_chart_playlist_rank_date    ON spotify_maps.chart_entries (playlist_id, rank, snapshot_date);
CREATE INDEX IF NOT EXISTS idx_chart_track_history         ON spotify_maps.chart_entries (track_id, snapshot_date);



-- If you often query only rank=1:
CREATE INDEX IF NOT EXISTS idx_chart_rank1_by_country_date
  ON spotify_maps.chart_entries (country_code, snapshot_ts)
  WHERE rank = 1;