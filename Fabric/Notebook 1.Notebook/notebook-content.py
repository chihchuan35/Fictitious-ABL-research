# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "9dd9a720-785f-4a6b-a6d1-e48e1a320f6c",
# META       "default_lakehouse_name": "abl_lakehouse",
# META       "default_lakehouse_workspace_id": "8b740c90-ef3e-4b46-bf50-eb120c892149",
# META       "known_lakehouses": [
# META         {
# META           "id": "9dd9a720-785f-4a6b-a6d1-e48e1a320f6c"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

df = spark.read.format("delta").load("Tables/dim_team")
df.show()
print("rows:", df.count())

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.read.format("delta").load("Tables/fact_ticket_sales").count()   

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql import functions as F

# From Brozen
bronze_team = spark.read.format("delta").load("Tables/dim_team")

# 2. Clean and Standlisation
silver_team = (
    bronze_team
    .dropDuplicates(["team_id"])                      # deduplicate
    .withColumn("team_name", F.trim(F.col("team_name")))   # trim
    .withColumn("city",      F.trim(F.col("city")))
    .withColumn("abbreviation", F.upper(F.trim(F.col("abbreviation"))))  
    .withColumn("_loaded_at", F.current_timestamp())  
)

# 3. silver
(silver_team.write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", "true")
    .save("Tables/silver_dim_team"))

# 4. Validation
spark.read.format("delta").load("Tables/silver_dim_team").show()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql import functions as F

# 1. Bronze 
bronze_bat = spark.read.format("delta").load("Tables/fact_player_batting")

# 2. rule
valid = (
    (F.col("at_bats") >= 0) &
    (F.col("hits") >= 0) &
    (F.col("hits") <= F.col("at_bats")) &                          # hit<ab
    ((F.col("doubles") + F.col("triples") + F.col("home_runs")) <= F.col("hits"))  # xbh<h
)

# 3. 
silver_bat = (
    bronze_bat
    .dropDuplicates(["game_id", "player_id"])      # deduplicate
    .withColumn("is_valid", F.when(valid, True).otherwise(False))
    .withColumn("_loaded_at", F.current_timestamp())
)

# 4. validation
total = silver_bat.count()
bad   = silver_bat.filter(F.col("is_valid") == False).count()
print(f"total rows: {total}, failed quality check: {bad}")

# 5. access
(silver_bat.filter(F.col("is_valid") == True)
    .drop("is_valid")
    .write.format("delta").mode("overwrite").option("overwriteSchema", "true")
    .save("Tables/silver_fact_player_batting"))

spark.read.format("delta").load("Tables/silver_fact_player_batting").count()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql import functions as F


bronze_sales = spark.read.format("delta").load("Tables/fact_ticket_sales")


amount_ok = F.abs(F.col("amount") - F.col("quantity") * F.col("unit_price")) < 0.01
valid = (
    (F.col("quantity") > 0) &
    (F.col("unit_price") > 0) &
    amount_ok
)


silver_sales = (
    bronze_sales
    .dropDuplicates(["sale_id"])
    .withColumn("is_valid", F.when(valid, True).otherwise(False))
    .withColumn("_loaded_at", F.current_timestamp())
)


total = silver_sales.count()
bad   = silver_sales.filter(~F.col("is_valid")).count()
print(f"total rows: {total}, failed quality check: {bad}")


(silver_sales.filter(F.col("is_valid"))
    .drop("is_valid")
    .write.format("delta").mode("overwrite").option("overwriteSchema", "true")
    .save("Tables/silver_fact_ticket_sales"))

spark.read.format("delta").load("Tables/silver_fact_ticket_sales").count()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql import functions as F


simple_tables = [
    ("dim_player", "player_id"),
    ("dim_member", "member_id"),
    ("dim_venue",  "venue_id"),
    ("dim_date",   "date_key"),
    ("fact_game",  "game_id"),
]

for tbl, pk in simple_tables:
    df = (spark.read.format("delta").load(f"Tables/{tbl}")
          .dropDuplicates([pk])
          .withColumn("_loaded_at", F.current_timestamp()))
    (df.write.format("delta").mode("overwrite").option("overwriteSchema", "true")
       .save(f"Tables/silver_{tbl}"))
    print(f"silver_{tbl}: {df.count()} rows")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
