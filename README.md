# ABL Club Operations — Azure SQL to Microsoft Fabric Pipeline

End-to-end analytics pipeline for a fictional Australian Baseball League
club operation. An OLTP source in Azure SQL Database is mirrored into
Microsoft Fabric, modelled with a medallion (Bronze/Silver/Gold) and star
schema, surfaced in Power BI, and governed with Microsoft Purview.

> Data note: dimension tables (teams, venues, players) are based on public
> ABL information; all fact data (games, batting lines, ticket sales) and
> member PII are synthetically generated to demonstrate the pipeline, not to
> report real results.

## Architecture

```
SSMS -> Azure SQL Database (OLTP source)
              | Fabric Mirroring (near real-time replication)
              v
        Fabric Lakehouse  ->  Bronze / Silver / Gold (medallion)
              | transforms: PySpark notebook + T-SQL (Warehouse)
              v
        Star schema  ->  Power BI (Direct Lake)  +  Purview governance
```

(Replace with a diagram in `doc/` once built.)

## Tech stack

- Azure SQL Database (cloud OLTP source)
- Microsoft Fabric: Mirroring, Lakehouse/Warehouse, Data Factory pipeline
- PySpark + T-SQL for the medallion transforms
- Power BI (Direct Lake, DAX measures)
- Microsoft Purview (sensitivity labels, lineage, glossary)

## Repository structure

- `data/` SQL scripts, the Python data generator, and generated inserts
- `doc/` architecture notes, data dictionary, governance write-up
- `report/` Power BI screenshots, DAX snippets, and findings

## How to run (source database)

Run in SSMS connected to the Azure SQL Database (not MySQL, not local):

1. `data/01_create_tables.sql` — create tables
2. `data/02_seed_dimensions.sql` — seed real dimensions, build dim_date
   (fill the venue placeholders first)
3. `data/03_data_inserts.sql` — load players, members, and the fact tables
   (regenerate with `python data/03_generate_data.py` to change scale)
4. Configure Fabric Mirroring against this database
5. `data/04_simulate_live.sql` — drip live transactions to watch replication

## Data model

Star schema: `fact_player_batting`, `fact_game`, `fact_ticket_sales` with
`dim_team`, `dim_player`, `dim_venue`, `dim_date`, `dim_member`. Rate stats
(AVG/OBP/SLG/OPS) are computed in Power BI with DAX, not stored.

## Governance

`dim_member.email` is treated as PII for a Purview sensitivity-label and
end-to-end lineage demonstration (Azure SQL -> OneLake -> semantic model ->
report).
