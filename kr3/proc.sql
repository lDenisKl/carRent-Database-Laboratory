CREATE OR ALTER PROCEDURE MeetingVar10
    @Subject NVARCHAR(20)
AS
BEGIN
    DECLARE @Teachers TABLE (Учитель NVARCHAR(20));
    INSERT INTO @Teachers
    SELECT DISTINCT R1.Учитель
    FROM R1
    WHERE R1.Предмет = @Subject;
    IF NOT EXISTS (SELECT 1 FROM @Teachers)
    BEGIN
        SELECT NULL AS [День недели],
		NULL AS [Номер урока];
        RETURN;
    END
    -- Учитель свободнен, если:
    -- нет урока в это время и это не его выходной
    SELECT TOP 1
        d.[День недели],
        l.[Номер урока]
    FROM 
    (VALUES (1),(2),(3),(4),(5),(6)) AS d([День недели])
    CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6)) AS l([Номер урока])
    WHERE NOT EXISTS (
            SELECT 1
            FROM @Teachers t
            WHERE EXISTS (
                SELECT 1
                FROM R1
                WHERE R1.Учитель = t.Учитель AND R1.[День недели] = d.[День недели] AND R1.[Номер урока] = l.[Номер урока]
            )
        ) AND NOT EXISTS (
            SELECT 1
            FROM @Teachers t
            JOIN R3 ON R3.Учитель = t.Учитель
            WHERE R3.выходной = d.[День недели]
        )
    ORDER BY l.[Номер урока], d.[День недели];
END


EXEC MeetingVar10 @Subject = N'физкультура';
EXEC MeetingVar10 @Subject = N'математика';
EXEC MeetingVar10 @Subject = N'русский';
EXEC MeetingVar10 @Subject = N'алгебра';
EXEC MeetingVar10 @Subject = N'история';
EXEC MeetingVar10 @Subject = N'химия';
EXEC MeetingVar10 @Subject = N'география';