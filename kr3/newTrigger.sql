CREATE OR ALTER TRIGGER CheckOrderDateVar2
ON [Строки-заказа]
AFTER INSERT, UPDATE
AS
BEGIN
    WITH MaxBookDates AS (
        SELECT i.[№ заказа],
            MAX(DATEADD(DAY, 7, k.[Дата выхода])) as NewDate
        FROM inserted i
        JOIN [Книги] k ON i.[№ контракта] = k.[№ контракта]
        GROUP BY i.[№ заказа]
    )
    UPDATE z
    SET [Дата выполнения заказа] = CASE 
        WHEN z.[Дата выполнения заказа] IS NULL 
            OR z.[Дата выполнения заказа] < m.NewDate 
        THEN m.NewDate
        ELSE z.[Дата выполнения заказа]
    END
    FROM [Заказы] z
    JOIN MaxBookDates m ON z.[№ заказа] = m.[№ заказа]
END