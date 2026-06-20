/* =============================================================
   02_seed_dimensions.sql
   Real ABL dimensions. Team names/cities are filled in; please
   confirm venue_name and capacity on each club's official site
   before populating (I won't insert "real" values I can't verify).
   The player roster (dim_player) is emitted as a skeleton by the
   03 generator; later overwrite full_name with real names from the
   ABL Weekly Rosters page (keep player_id unchanged).
   ============================================================= */

-- ---------- dim_venue (replace the <<...>> placeholders) ----------
INSERT INTO dim_venue (venue_id, venue_name, city, capacity) VALUES
(1, N'<<Adelaide home venue>>', N'Adelaide', 0),   -- adelaidegiants.com.au
(2, N'<<Brisbane home venue>>', N'Brisbane', 0),   -- brisbanebandits.com.au
(3, N'<<Perth home venue>>',    N'Perth',    0),   -- perthheat.com.au
(4, N'<<Sydney home venue>>',   N'Sydney',   0);   -- sydneybluesox.com.au

-- ---------- dim_team (real) ----------
INSERT INTO dim_team (team_id, team_name, city, abbreviation, home_venue_id) VALUES
(1, N'Adelaide Giants',  N'Adelaide', 'ADL', 1),
(2, N'Brisbane Bandits', N'Brisbane', 'BRI', 2),
(3, N'Perth Heat',       N'Perth',    'PER', 3),
(4, N'Sydney Blue Sox',  N'Sydney',   'SYD', 4);
-- If the season has more teams (check the Standings page), add them
-- in the same format and mirror the change in the 03 generator's TEAMS.

-- ---------- dim_date (auto-generated, 2025-11-01 .. 2026-02-28) ----------
;WITH d AS (
    SELECT CAST('2025-11-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt) FROM d WHERE dt < '2026-02-28'
)
INSERT INTO dim_date (date_key, full_date, [year], [month], [day],
                      weekday, is_weekend, season_label)
SELECT
    CONVERT(INT, FORMAT(dt, 'yyyyMMdd')),
    dt,
    YEAR(dt), MONTH(dt), DAY(dt),
    DATENAME(WEEKDAY, dt),
    CASE WHEN DATENAME(WEEKDAY, dt) IN ('Saturday','Sunday') THEN 1 ELSE 0 END,
    N'2025-26'
FROM d
OPTION (MAXRECURSION 0);
