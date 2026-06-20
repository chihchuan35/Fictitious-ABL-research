#!/usr/bin/env python3
"""
03_generate_data.py
Generates a dim_player skeleton + dim_member (synthetic PII) + the three
fact tables, writing them to 03_data_inserts.sql (paste into SSMS, or load
with sqlcmd).

Design notes
- The player_id -> team mapping is decided here; later just overwrite
  full_name with real names from the ABL Weekly Rosters. Do NOT change
  player_id, or the fact tables won't line up.
- Rate stats (AVG/OBP/SLG/OPS) are neither generated nor stored; they are
  left to DAX in Power BI.
- A few end-of-season games are left as status='scheduled' with no score,
  so 04_simulate_live.sql can flip them later.

Usage:  python 03_generate_data.py        # writes 03_data_inserts.sql
"""

import random
from datetime import date, datetime, timedelta
from faker import Faker

fake = Faker('en_AU')
random.seed(42)
Faker.seed(42)

# ---------------- Tunable parameters ----------------
TEAMS = {1: 'ADL', 2: 'BRI', 3: 'PER', 4: 'SYD'}   # keep in sync with dim_team
ROSTER_SIZE       = 15        # players per team
GAMES_PER_MATCHUP = 3         # games per ordered (home, away) pair
NUM_MEMBERS       = 400       # number of members (synthetic PII)
SEASON_START      = date(2025, 11, 1)
SEASON_END        = date(2026, 2, 28)
SCHEDULED_TAIL    = 4         # games left unplayed (for the live sim)
OUT_PATH          = '03_data_inserts.sql'

POSITIONS = ['C','1B','2B','3B','SS','LF','CF','RF','DH'] + ['P']*5  # 10 hitters + 5 pitchers
HANDS = ['L','R']
TIERS = ['Bronze','Silver','Gold','Platinum']
TICKET_PRICES = [18.00, 28.00, 40.00, 65.00]

def sql_str(s):
    return "N'" + str(s).replace("'", "''") + "'"

# ---------------- dim_player skeleton ----------------
players = []          # (player_id, team_id, position, is_pitcher, skill_avg, power)
pid = 1
for team_id in TEAMS:
    pos_pool = POSITIONS.copy()
    random.shuffle(pos_pool)
    for i in range(ROSTER_SIZE):
        position = pos_pool[i % len(pos_pool)]
        is_pitcher = (position == 'P')
        skill_avg = max(0.180, min(0.360, random.gauss(0.270, 0.035)))
        power = random.random()  # 0..1, drives extra-base hits
        players.append({
            'player_id': pid, 'team_id': team_id, 'position': position,
            'bats': random.choice(HANDS), 'throws': random.choice(HANDS),
            'jersey': random.randint(1, 75),
            'nationality': random.choices(
                ['Australia','USA','Japan','Korea','Dominican Republic'],
                weights=[60,20,8,7,5])[0],
            'is_pitcher': is_pitcher, 'skill_avg': skill_avg, 'power': power,
        })
        pid += 1

batters_by_team = {t: [p for p in players if p['team_id'] == t and not p['is_pitcher']]
                   for t in TEAMS}

# ---------------- Schedule fact_game ----------------
season_days = [(SEASON_START + timedelta(days=i))
               for i in range((SEASON_END - SEASON_START).days + 1)]
matchups = [(h, a) for h in TEAMS for a in TEAMS if h != a] * GAMES_PER_MATCHUP
random.shuffle(matchups)

games = []
gid = 1
for idx, (home, away) in enumerate(matchups):
    gday = season_days[(idx * 3) % len(season_days)]
    games.append({
        'game_id': gid, 'date': gday, 'venue_id': home,  # home team's park = venue_id == team_id
        'home': home, 'away': away,
    })
    gid += 1
games.sort(key=lambda g: g['date'])
for n, g in enumerate(games):  # renumber game_id by date
    g['game_id'] = n + 1

scheduled_ids = {g['game_id'] for g in games[-SCHEDULED_TAIL:]}

# ---------------- Generate fact rows ----------------
bat_rows, game_rows, sale_rows = [], [], []
sale_id = 1

for g in games:
    is_final = g['game_id'] not in scheduled_ids
    runs = {g['home']: 0, g['away']: 0}

    if is_final:
        for team in (g['home'], g['away']):
            lineup = random.sample(batters_by_team[team], 9)
            for p in lineup:
                ab = random.randint(3, 5)
                hits = sum(1 for _ in range(ab) if random.random() < p['skill_avg'])
                hr = sum(1 for _ in range(hits) if random.random() < 0.12 * p['power'])
                tr = sum(1 for _ in range(hits - hr) if random.random() < 0.04)
                db = sum(1 for _ in range(hits - hr - tr) if random.random() < 0.22)
                walks = 1 if random.random() < 0.10 else 0
                so = sum(1 for _ in range(ab - hits) if random.random() < 0.30)
                rbi = hr + random.randint(0, max(0, hits - hr))
                r = min(hits, random.randint(0, 2))
                sb = 1 if (hits and random.random() < 0.08) else 0
                hbp = 1 if random.random() < 0.03 else 0
                runs[team] += r
                bat_rows.append((g['game_id'], p['player_id'], team, ab, hits,
                                 db, tr, hr, rbi, r, walks, so, sb, hbp))

    home_score = runs[g['home']] if is_final else 'NULL'
    away_score = runs[g['away']] if is_final else 'NULL'

    # Ticket sales: aim for a target attendance, split into many transactions
    if is_final:
        target_att = random.randint(1500, 4200)
        att = 0
        while att < target_att:
            qty = random.choices([1,2,3,4,5,6], weights=[15,35,20,15,10,5])[0]
            m = random.randint(1, NUM_MEMBERS)
            price = random.choice(TICKET_PRICES)
            lead = random.randint(0, 14)
            sale_ts = datetime.combine(g['date'] - timedelta(days=lead),
                                       datetime.min.time()) + timedelta(
                                       seconds=random.randint(0, 86399))
            sale_rows.append((sale_id, g['game_id'], m, sale_ts, qty,
                              price, round(qty * price, 2)))
            sale_id += 1
            att += qty
        attendance = att
    else:
        attendance = 'NULL'

    date_key = int(g['date'].strftime('%Y%m%d'))
    game_rows.append((g['game_id'], g['date'], date_key, g['venue_id'],
                      g['home'], g['away'], home_score, away_score,
                      'final' if is_final else 'scheduled', attendance))

# ---------------- dim_member (synthetic PII) ----------------
member_rows = []
for mid in range(1, NUM_MEMBERS + 1):
    name = fake.name()
    email = fake.unique.email()
    join = fake.date_between(start_date=date(2019, 1, 1), end_date=date(2025, 10, 1))
    tier = random.choices(TIERS, weights=[40, 30, 20, 10])[0]
    member_rows.append((mid, name, email, join, tier))

# ---------------- Write SQL ----------------
def vals(rows, fmt):
    return ',\n'.join(fmt(r) for r in rows)

with open(OUT_PATH, 'w', encoding='utf-8') as f:
    f.write("/* 03_data_inserts.sql  auto-generated; run after 01/02 */\n\n")

    f.write("-- dim_player (overwrite full_name with real ABL names later; "
            "keep player_id)\n")
    f.write("INSERT INTO dim_player (player_id, full_name, team_id, position, "
            "bats, throws, jersey_number, nationality) VALUES\n")
    f.write(vals(players, lambda p: f"({p['player_id']}, "
            f"{sql_str('Player ' + str(p['player_id']))}, {p['team_id']}, "
            f"{sql_str(p['position'])}, '{p['bats']}', '{p['throws']}', "
            f"{p['jersey']}, {sql_str(p['nationality'])})") + ";\n\n")

    f.write("-- dim_member (synthetic PII)\n")
    f.write("INSERT INTO dim_member (member_id, full_name, email, join_date, "
            "membership_tier) VALUES\n")
    f.write(vals(member_rows, lambda m: f"({m[0]}, {sql_str(m[1])}, "
            f"{sql_str(m[2])}, '{m[3]}', {sql_str(m[4])})") + ";\n\n")

    f.write("-- fact_game\n")
    f.write("INSERT INTO fact_game (game_id, game_date, date_key, venue_id, "
            "home_team_id, away_team_id, home_score, away_score, status, "
            "attendance) VALUES\n")
    f.write(vals(game_rows, lambda g: f"({g[0]}, '{g[1]}', {g[2]}, {g[3]}, "
            f"{g[4]}, {g[5]}, {g[6]}, {g[7]}, {sql_str(g[8])}, {g[9]})") + ";\n\n")

    f.write("-- fact_player_batting\n")
    f.write("INSERT INTO fact_player_batting (game_id, player_id, team_id, "
            "at_bats, hits, doubles, triples, home_runs, rbi, runs, walks, "
            "strikeouts, stolen_bases, hit_by_pitch) VALUES\n")
    f.write(vals(bat_rows, lambda b: "(" + ", ".join(str(x) for x in b) + ")") + ";\n\n")

    f.write("-- fact_ticket_sales\n")
    f.write("INSERT INTO fact_ticket_sales (sale_id, game_id, member_id, "
            "sale_ts, quantity, unit_price, amount) VALUES\n")
    f.write(vals(sale_rows, lambda s: f"({s[0]}, {s[1]}, {s[2]}, "
            f"'{s[3].strftime('%Y-%m-%d %H:%M:%S')}', {s[4]}, {s[5]}, {s[6]})") + ";\n")

print(f"players={len(players)}  games={len(game_rows)}  "
      f"batting_rows={len(bat_rows)}  sales={len(sale_rows)}  "
      f"members={len(member_rows)}")
print(f"scheduled (unplayed) = {sorted(scheduled_ids)}")
print(f"output -> {OUT_PATH}")
