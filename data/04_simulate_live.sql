/* =============================================================
   04_simulate_live.sql
   Live transaction simulator. Run this in SSMS connected to Azure SQL
   while watching the mirrored tables in Fabric to see data replicate
   in near real time.
   Flow: drip ticket sales into one unplayed game, then flip it to final.
   ============================================================= */

SET NOCOUNT ON;

DECLARE @game_id INT = (SELECT MIN(game_id) FROM fact_game WHERE status = 'scheduled');
IF @game_id IS NULL
BEGIN
    PRINT N'No scheduled games left. Re-run the 03 generator to reset the unplayed tail.';
    RETURN;
END

DECLARE @sale_id INT = (SELECT ISNULL(MAX(sale_id), 0) FROM fact_ticket_sales);
DECLARE @members INT = (SELECT COUNT(*) FROM dim_member);
DECLARE @i INT = 0, @att INT = 0;
DECLARE @prices TABLE (p DECIMAL(6,2));
INSERT INTO @prices VALUES (18.00),(28.00),(40.00),(65.00);

PRINT CONCAT(N'Dripping ticket sales into game_id=', @game_id,
             N'; watch the replication in Fabric...');

WHILE @i < 25            -- 25 batches, 3s apart, ~75 seconds total
BEGIN
    DECLARE @qty INT  = ABS(CHECKSUM(NEWID())) % 6 + 1;
    DECLARE @mem INT  = ABS(CHECKSUM(NEWID())) % @members + 1;
    DECLARE @price DECIMAL(6,2) = (SELECT TOP 1 p FROM @prices ORDER BY NEWID());

    SET @sale_id += 1;
    INSERT INTO fact_ticket_sales (sale_id, game_id, member_id, sale_ts,
                                   quantity, unit_price, amount)
    VALUES (@sale_id, @game_id, @mem, SYSDATETIME(), @qty, @price,
            @qty * @price);

    SET @att += @qty;
    SET @i  += 1;
    WAITFOR DELAY '00:00:03';
END

-- Post-game: set the score and attendance
DECLARE @home INT = ABS(CHECKSUM(NEWID())) % 9 + 1;
DECLARE @away INT = ABS(CHECKSUM(NEWID())) % 9 + 1;

UPDATE fact_game
SET status     = 'final',
    home_score = @home,
    away_score = @away,
    attendance = @att * 40      -- scale up to a realistic gate count
WHERE game_id = @game_id;

PRINT CONCAT(N'game_id=', @game_id, N' flipped to final, score ',
             @home, N':', @away, N', 25 new ticket sales added.');
