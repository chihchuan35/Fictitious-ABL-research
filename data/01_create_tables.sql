/* =============================================================
   01_create_tables.sql
   ABL Club Operations  |  Azure SQL Database (OLTP source)
   Business keys used directly as PK/FK. Single season, no pitching.
   Note: Fabric Mirroring requires every table to have a PRIMARY KEY;
   all tables below have one.
   Run order: this file, then 02_seed_dimensions.sql, then the
   inserts produced by 03_generate_data.py.
   ============================================================= */

-- ---------- Dimensions (real ABL data) ----------

CREATE TABLE dim_venue (
    venue_id    INT           NOT NULL PRIMARY KEY,
    venue_name  NVARCHAR(100) NOT NULL,
    city        NVARCHAR(60)  NOT NULL,
    capacity    INT           NOT NULL
);

CREATE TABLE dim_team (
    team_id       INT          NOT NULL PRIMARY KEY,
    team_name     NVARCHAR(60) NOT NULL,
    city          NVARCHAR(60) NOT NULL,
    abbreviation  CHAR(3)      NOT NULL,
    home_venue_id INT          NOT NULL
        CONSTRAINT fk_team_venue REFERENCES dim_venue(venue_id)
);

CREATE TABLE dim_player (
    player_id     INT          NOT NULL PRIMARY KEY,
    full_name     NVARCHAR(80) NOT NULL,
    team_id       INT          NOT NULL
        CONSTRAINT fk_player_team REFERENCES dim_team(team_id),
    position      NVARCHAR(20) NOT NULL,
    bats          CHAR(1)      NULL,
    throws        CHAR(1)      NULL,
    jersey_number INT          NULL,
    nationality   NVARCHAR(40) NULL
);

CREATE TABLE dim_date (
    date_key     INT          NOT NULL PRIMARY KEY,  -- yyyymmdd
    full_date    DATE         NOT NULL,
    [year]       INT          NOT NULL,
    [month]      INT          NOT NULL,
    [day]        INT          NOT NULL,
    weekday      NVARCHAR(10) NOT NULL,
    is_weekend   BIT          NOT NULL,
    season_label NVARCHAR(10) NOT NULL
);

-- ---------- Synthetic PII dimension (for Purview sensitivity labels) ----------

CREATE TABLE dim_member (
    member_id       INT           NOT NULL PRIMARY KEY,
    full_name       NVARCHAR(80)  NOT NULL,
    email           NVARCHAR(120) NOT NULL,   -- PII
    join_date       DATE          NOT NULL,
    membership_tier NVARCHAR(20)  NULL
);

-- ---------- Facts (synthetic) ----------

CREATE TABLE fact_game (
    game_id      INT          NOT NULL PRIMARY KEY,
    game_date    DATE         NOT NULL,
    date_key     INT          NOT NULL
        CONSTRAINT fk_game_date REFERENCES dim_date(date_key),
    venue_id     INT          NOT NULL
        CONSTRAINT fk_game_venue REFERENCES dim_venue(venue_id),
    home_team_id INT          NOT NULL
        CONSTRAINT fk_game_home REFERENCES dim_team(team_id),
    away_team_id INT          NOT NULL
        CONSTRAINT fk_game_away REFERENCES dim_team(team_id),
    home_score   INT          NULL,
    away_score   INT          NULL,
    status       NVARCHAR(12) NOT NULL,   -- 'scheduled' | 'final'
    attendance   INT          NULL
);

-- Grain: one batting line per player per game. Stores additive raw
-- counts only; AVG/OBP/SLG/OPS are computed in Power BI with DAX.
CREATE TABLE fact_player_batting (
    game_id      INT NOT NULL
        CONSTRAINT fk_bat_game REFERENCES fact_game(game_id),
    player_id    INT NOT NULL
        CONSTRAINT fk_bat_player REFERENCES dim_player(player_id),
    team_id      INT NOT NULL
        CONSTRAINT fk_bat_team REFERENCES dim_team(team_id),
    at_bats      INT NOT NULL,
    hits         INT NOT NULL,
    doubles      INT NOT NULL,
    triples      INT NOT NULL,
    home_runs    INT NOT NULL,
    rbi          INT NOT NULL,
    runs         INT NOT NULL,
    walks        INT NOT NULL,
    strikeouts   INT NOT NULL,
    stolen_bases INT NOT NULL,
    hit_by_pitch INT NOT NULL,
    CONSTRAINT pk_fact_player_batting PRIMARY KEY (game_id, player_id)
);

-- Grain: one ticket sale transaction
CREATE TABLE fact_ticket_sales (
    sale_id    INT          NOT NULL PRIMARY KEY,
    game_id    INT          NOT NULL
        CONSTRAINT fk_sale_game REFERENCES fact_game(game_id),
    member_id  INT          NOT NULL
        CONSTRAINT fk_sale_member REFERENCES dim_member(member_id),
    sale_ts    DATETIME2    NOT NULL,
    quantity   INT          NOT NULL,
    unit_price DECIMAL(6,2) NOT NULL,
    amount     DECIMAL(8,2) NOT NULL
);
