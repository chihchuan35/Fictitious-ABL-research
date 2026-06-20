/* =============================================================
   05_update_real_names.sql
   Fills real ABL data into the dimensions:
   - dim_venue: real 2025-26 stadium names (capacity left for you to fill)
   - dim_player: real names, mapped to the right team via player_id ranges
       Adelaide = player_id 1-15   (filled below)
       Brisbane = player_id 16-30  (template - paste from team /roster)
       Perth    = player_id 31-45  (template)
       Sydney   = player_id 46-60  (template)
   Run in SSMS against free-sql-db-6671901, after 01-03.
   Note: stats remain synthetic; attaching real names to a clearly
   labelled fictitious dataset is fine. Rosters change weekly, so treat
   these as a snapshot. Official source: add /roster to each club site.
   ============================================================= */

-- ---------- dim_venue: real stadium names (2025-26) ----------
UPDATE dim_venue SET venue_name = N'Dicolor Australia Stadium' WHERE venue_id = 1; -- Adelaide
UPDATE dim_venue SET venue_name = N'Viticon Stadium'          WHERE venue_id = 2; -- Brisbane
UPDATE dim_venue SET venue_name = N'Empire Ballpark'          WHERE venue_id = 3; -- Perth
UPDATE dim_venue SET venue_name = N'Blue Sox Stadium'         WHERE venue_id = 4; -- Sydney
-- TODO: fill real capacities, e.g.
-- UPDATE dim_venue SET capacity = 5000 WHERE venue_id = 1;

-- ---------- Adelaide Giants (player_id 1-15), real names ----------
UPDATE dim_player SET full_name = N'Jordan McArdle'      WHERE player_id = 1;   -- DH
UPDATE dim_player SET full_name = N'Josh Tols'           WHERE player_id = 2;   -- P
UPDATE dim_player SET full_name = N'Drew Davies'         WHERE player_id = 3;   -- OF
UPDATE dim_player SET full_name = N'Max Tracey'          WHERE player_id = 4;   -- OF
UPDATE dim_player SET full_name = N'Alexander Wells'     WHERE player_id = 5;   -- P
UPDATE dim_player SET full_name = N'Lachlan Wells'       WHERE player_id = 6;   -- P
UPDATE dim_player SET full_name = N'Devin Saltiban'      WHERE player_id = 7;   -- OF
UPDATE dim_player SET full_name = N'Nikau Pouaka-Grego'  WHERE player_id = 8;   -- 2B
UPDATE dim_player SET full_name = N'Todd Van Steensel'   WHERE player_id = 9;   -- P
UPDATE dim_player SET full_name = N'Liam Spence'         WHERE player_id = 10;  -- INF
UPDATE dim_player SET full_name = N'Nick Ward'           WHERE player_id = 11;  -- INF
UPDATE dim_player SET full_name = N'Mitch Edwards'       WHERE player_id = 12;  -- C
UPDATE dim_player SET full_name = N'Yu Aramaki'          WHERE player_id = 13;  -- 1B
UPDATE dim_player SET full_name = N'Mitch Neunborn'      WHERE player_id = 14;  -- P
UPDATE dim_player SET full_name = N'Jack Partington'     WHERE player_id = 15;  -- OF

-- ---------- Brisbane Bandits (player_id 16-30) ----------
-- Roster: https://brisbanebandits.com.au/roster
-- Known 2025-26 names you can use: Brennon McNair, Hyungchan Um,
--   Natanael Garabitos, Alessandro Ranieri, Tyler Jeans
UPDATE dim_player SET full_name = N'Dermot Fritsch' WHERE player_id = 16;
UPDATE dim_player SET full_name = N'Jeremy Atkinson' WHERE player_id = 17;
UPDATE dim_player SET full_name = N'Matt Beattie' WHERE player_id = 18;
UPDATE dim_player SET full_name = N'Jackson Grounds' WHERE player_id = 19;
UPDATE dim_player SET full_name = N'George Callil' WHERE player_id = 20;
UPDATE dim_player SET full_name = N'Sohoo Ham' WHERE player_id = 21;
UPDATE dim_player SET full_name = N'Noah Barber' WHERE player_id = 22;
UPDATE dim_player SET full_name = N'Kailen Hamson' WHERE player_id = 23;
UPDATE dim_player SET full_name = N'Rixon Wingrove' WHERE player_id = 24;
UPDATE dim_player SET full_name = N'Robbie Perkins' WHERE player_id = 25;
UPDATE dim_player SET full_name = N'Seung-Won Hong' WHERE player_id = 26;
UPDATE dim_player SET full_name = N'Will Riley' WHERE player_id = 27;
UPDATE dim_player SET full_name = N'Kyosuke Mashiko' WHERE player_id = 28;
UPDATE dim_player SET full_name = N'Seung-Min Ryu' WHERE player_id = 29;
UPDATE dim_player SET full_name = N'Liam MacDonald' WHERE player_id = 30;

-- ---------- Perth Heat (player_id 31-45) ----------
-- Roster: https://perthheat.com.au/roster
-- Known 2025-26 name: Gary Grosjean (P)
UPDATE dim_player SET full_name = N'Gary Grosjean' WHERE player_id = 31;
UPDATE dim_player SET full_name = N'Owen Cobb' WHERE player_id = 32;
UPDATE dim_player SET full_name = N'Byron Armstrong' WHERE player_id = 33;
UPDATE dim_player SET full_name = N'Nicandro Aybar' WHERE player_id = 34;
UPDATE dim_player SET full_name = N'Tim Kennelly' WHERE player_id = 35;
UPDATE dim_player SET full_name = N'Drake Logan' WHERE player_id = 36;
UPDATE dim_player SET full_name = N'Leonardo Pineda' WHERE player_id = 37;
UPDATE dim_player SET full_name = N'Kristian Haeusler' WHERE player_id = 38;
UPDATE dim_player SET full_name = N'Kieren Hall' WHERE player_id = 39;
UPDATE dim_player SET full_name = N'Todd Hatcher' WHERE player_id = 40;
UPDATE dim_player SET full_name = N'Yirer Garcia' WHERE player_id = 41;
UPDATE dim_player SET full_name = N'Jake Bowey' WHERE player_id = 42;
UPDATE dim_player SET full_name = N'Jess Williams' WHERE player_id = 43;
UPDATE dim_player SET full_name = N'Andrew Hurrelbrink' WHERE player_id = 44;
UPDATE dim_player SET full_name = N'Raleigh Pelkonen' WHERE player_id = 45;

-- ---------- Sydney Blue Sox (player_id 46-60) ----------
-- Roster: https://sydneybluesox.com.au/roster
-- Known 2025-26 names: Landen Bourassa (P), Jack O''Loughlin (P), Coen Wynne (P)
UPDATE dim_player SET full_name = N'Eric Rataczak' WHERE player_id = 46;
UPDATE dim_player SET full_name = N'Jirvin Morillo' WHERE player_id = 47;
UPDATE dim_player SET full_name = N'Pablo Nunez' WHERE player_id = 48;
UPDATE dim_player SET full_name = N'Jagger Beck' WHERE player_id = 49;
UPDATE dim_player SET full_name = N'Jo Stevens' WHERE player_id = 50;
UPDATE dim_player SET full_name = N'Josh Bishopp' WHERE player_id = 51;
UPDATE dim_player SET full_name = N'Landen Bourassa' WHERE player_id = 52;
UPDATE dim_player SET full_name = N'Anthony Huezo' WHERE player_id = 53;
UPDATE dim_player SET full_name = N'Lachlan Brook' WHERE player_id = 54;
UPDATE dim_player SET full_name = N'Hansel Jimenez' WHERE player_id = 55;
UPDATE dim_player SET full_name = N'Jaylin Rae' WHERE player_id = 56;
UPDATE dim_player SET full_name = N'Michael Campbell' WHERE player_id = 57;
UPDATE dim_player SET full_name = N'Brodie Cooper-Vassalakis' WHERE player_id = 58;
UPDATE dim_player SET full_name = N'Dylan Leach' WHERE player_id = 59;
UPDATE dim_player SET full_name = N'Jo Stevens' WHERE player_id = 60;

-- ---------- verify ----------
-- SELECT player_id, full_name, team_id, position FROM dim_player ORDER BY player_id;
