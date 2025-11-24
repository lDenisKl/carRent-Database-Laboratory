IF OBJECT_ID('Rental_Insert_Trigger', 'TR') IS NOT NULL DROP TRIGGER Rental_Insert_Trigger;

IF OBJECT_ID('Rental_Insert_Trigger', 'TR') IS NOT NULL DROP TRIGGER Rental_Insert_Trigger;
GO

CREATE OR ALTER TRIGGER Rental_Insert_Trigger
ON Rental
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Создаем временную таблицу для хранения данных клиентов
    CREATE TABLE #ClientData (
        clientPassport NVARCHAR(20) COLLATE DATABASE_DEFAULT,
        rentalCount INT,
        isProblemClient BIT
    );

    -- Заполняем временную таблицу с явным указанием кодировки
    INSERT INTO #ClientData
    SELECT 
        ro.clientPassport,
        COUNT(CASE WHEN r.status = 'Завершена' THEN 1 END) as rentalCount,
        CASE WHEN EXISTS (
            SELECT 1 FROM Rental r2 
            JOIN RentalOrder ro2 ON r2.rentalOrderId = ro2.id 
            WHERE ro2.clientPassport = ro.clientPassport
            AND (EXISTS (SELECT 1 FROM RentalFine rf WHERE rf.rentalId = r2.id)
                 OR r2.actualReturnDate > r2.plannedReturnDate)
        ) THEN 1 ELSE 0 END as isProblemClient
    FROM inserted i
    JOIN RentalOrder ro ON i.rentalOrderId = ro.id
    LEFT JOIN Rental r ON r.rentalOrderId = ro.id
    GROUP BY ro.clientPassport;
    
    -- Вставляем хороших клиентов
    INSERT INTO Rental (startDate, plannedReturnDate, actualReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
    SELECT 
        i.startDate,
        i.plannedReturnDate,
        NULL,
        i.rentalCost * (1 - 
            CASE 
                WHEN cd.rentalCount >= 10 THEN 0.15
                WHEN cd.rentalCount >= 5 THEN 0.10
                WHEN cd.rentalCount >= 3 THEN 0.05
                ELSE 0
            END),
        i.status,
        i.carLicensePlate,
        i.rentalOrderId
    FROM inserted i
    JOIN RentalOrder ro ON i.rentalOrderId = ro.id
    JOIN #ClientData cd ON ro.clientPassport = cd.clientPassport COLLATE DATABASE_DEFAULT
    WHERE cd.isProblemClient = 0;

    -- Выводим сообщения
    DECLARE @problemMsg NVARCHAR(MAX) = (
        SELECT STRING_AGG(clientPassport, ', ') 
        FROM #ClientData 
        WHERE isProblemClient = 1
    );
    IF @problemMsg IS NOT NULL 
        PRINT 'Клиенты с нарушениями: ' + @problemMsg;
    PRINT 'Добавлено записей: ' + CAST(@@ROWCOUNT AS NVARCHAR);
    
    DROP TABLE #ClientData;
END;
GO


BEGIN TRY
    DECLARE @testOrderId1 INT, @testOrderId2 INT, @testOrderId3 INT;
    DECLARE @hasFines INT, @hasDelays INT;
    
    INSERT INTO RentalOrder (createDate, status, totalPrice, clientPassport)
    VALUES 
        (GETDATE(), 'Создан', NULL, '4510 123456'),  -- Клиент с нарушениями (штрафы и просрочки)
        (GETDATE(), 'Создан', NULL, '4520 222222'),  -- Клиент без нарушений (3+ аренд)
        (GETDATE(), 'Создан', NULL, '4510 999999');  -- Клиент без нарушений (мало аренд)
    
    SET @testOrderId1 = SCOPE_IDENTITY() - 2;
    SET @testOrderId2 = SCOPE_IDENTITY() - 1;
    SET @testOrderId3 = SCOPE_IDENTITY();
    
    INSERT INTO Rental (startDate, plannedReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
    VALUES 
        ('2025-07-20 10:00:00', '2025-07-25 10:00:00', 15000.00, 'Активна', 'А008АА777', @testOrderId1),  -- Клиент с нарушениями
        ('2025-07-21 11:00:00', '2025-07-26 11:00:00', 20000.00, 'Активна', 'Е308ЕЕ777', @testOrderId2),  -- Клиент со скидкой 5%
        ('2025-07-22 12:00:00', '2025-07-27 12:00:00', 18000.00, 'Активна', 'В107ВВ777', @testOrderId3);  -- Клиент без скидки
    
    -- результаты
    DECLARE @insertedCount INT;
    SELECT @insertedCount = COUNT(*) FROM Rental WHERE rentalOrderId IN (@testOrderId1, @testOrderId2, @testOrderId3);
    
    PRINT 'Результат: Вставлено ' + CAST(@insertedCount AS NVARCHAR) + ' из 3 записей';
    
    IF @insertedCount = 2
        PRINT 'УСПЕХ: Триггер корректно заблокировал клиента с нарушениями';
    ELSE
        PRINT 'ОШИБКА: Триггер работает некорректно';
    
    -- скидки
    DECLARE @cost2 DECIMAL(10,2), @cost3 DECIMAL(10,2);
    SELECT @cost2 = rentalCost FROM Rental WHERE rentalOrderId = @testOrderId2; -- Должна быть скидка 5%
    SELECT @cost3 = rentalCost FROM Rental WHERE rentalOrderId = @testOrderId3; -- Без скидки
    
    PRINT 'Клиент 2 (4520 222222 со скидкой 5%): исходная 20000, итоговая ' + CAST(@cost2 AS NVARCHAR);
    PRINT 'Клиент 3 (4510 999999 без скидки): исходная 18000, итоговая ' + CAST(@cost3 AS NVARCHAR);
    
    -- Проверяем, что клиент с нарушениями действительно не был вставлен
    IF NOT EXISTS (SELECT 1 FROM Rental WHERE rentalOrderId = @testOrderId1)
        PRINT 'УСПЕХ: Клиент с нарушениями (4510 123456) корректно заблокирован';
    ELSE
        PRINT 'ОШИБКА: Клиент с нарушениями был ошибочно вставлен';
    
    DELETE FROM Rental WHERE rentalOrderId IN (@testOrderId2, @testOrderId3);
    DELETE FROM RentalOrder WHERE id IN (@testOrderId1, @testOrderId2, @testOrderId3);
    
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА ВЫПОЛНЕНИЯ: ' + ERROR_MESSAGE();
    IF @testOrderId1 IS NOT NULL AND EXISTS (SELECT 1 FROM RentalOrder WHERE id = @testOrderId1) 
        DELETE FROM RentalOrder WHERE id = @testOrderId1;
    IF @testOrderId2 IS NOT NULL AND EXISTS (SELECT 1 FROM RentalOrder WHERE id = @testOrderId2) 
        DELETE FROM RentalOrder WHERE id = @testOrderId2;
    IF @testOrderId3 IS NOT NULL AND EXISTS (SELECT 1 FROM RentalOrder WHERE id = @testOrderId3) 
        DELETE FROM RentalOrder WHERE id = @testOrderId3;
END CATCH
