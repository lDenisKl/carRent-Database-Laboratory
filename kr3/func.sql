CREATE OR ALTER FUNCTION reportVar10
(
    @Class INT
)
RETURNS TABLE
AS
RETURN
(
    WITH FactLessons AS (
        SELECT R1.Предмет,
            COUNT(*) AS Факт
        FROM R1 
        WHERE R1.Класс = @Class
        GROUP BY R1.Предмет
    ),
    PlanLessons AS (
        SELECT R2.Предмет,
            R2.[Количество уроков в неделю] AS План
        FROM R2
        WHERE R2.Класс = @Class
    )

    SELECT 
        COALESCE(p.Предмет, a.Предмет) AS Предмет,
        COALESCE(p.План, 0) AS План,
        COALESCE(a.Факт, 0) AS Факт
    FROM PlanLessons p
    FULL OUTER JOIN FactLessons a ON p.Предмет = a.Предмет
);
SELECT * FROM reportVar10(5);

SELECT * FROM reportVar10(7);