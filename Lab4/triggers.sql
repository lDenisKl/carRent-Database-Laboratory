IF OBJECT_ID('Rental_Insert_Trigger', 'TR') IS NOT NULL DROP TRIGGER Rental_Insert_Trigger;


CREATE OR ALTER TRIGGER Rental_Insert_Trigger
ON Rental
INSTEAD OF INSERT
AS
BEGIN
    -- Клиенты с нарушениями
    DECLARE @ProblemClients TABLE (clientPassport NVARCHAR(20), reason NVARCHAR(100));
    
    INSERT INTO @ProblemClients
    SELECT DISTINCT ro.clientPassport, 'Имеет штрафы'
    FROM inserted i
    JOIN RentalOrder ro ON i.rentalOrderId = ro.id
    WHERE EXISTS (
        SELECT 1 
        FROM Rental r
        JOIN RentalOrder ro2 ON r.rentalOrderId = ro2.id
        JOIN RentalFine rf ON r.id = rf.rentalId
        WHERE ro2.clientPassport = ro.clientPassport
    )
    UNION
    SELECT DISTINCT ro.clientPassport, 'Имеет просрочки возврата'
    FROM inserted i
    JOIN RentalOrder ro ON i.rentalOrderId = ro.id
    WHERE EXISTS (
        SELECT 1 
        FROM Rental r
        JOIN RentalOrder ro2 ON r.rentalOrderId = ro2.id
        WHERE ro2.clientPassport = ro.clientPassport
        AND r.actualReturnDate > r.plannedReturnDate
        AND r.actualReturnDate IS NOT NULL
    );
    
    -- Вставка с учетом скидок
    INSERT INTO Rental (startDate, plannedReturnDate, actualReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
    SELECT 
        i.startDate,
        i.plannedReturnDate,
        NULL,
        i.rentalCost * (1 - 
            CASE 
                WHEN rentalCount >= 10 THEN 15.0
                WHEN rentalCount >= 5 THEN 10.0
                WHEN rentalCount >= 3 THEN 5.0
                ELSE 0
            END / 100),
        i.status,
        i.carLicensePlate,
        i.rentalOrderId
    FROM inserted i
    JOIN RentalOrder ro ON i.rentalOrderId = ro.id
    LEFT JOIN @ProblemClients pc ON ro.clientPassport = pc.clientPassport
    LEFT JOIN (
        SELECT ro3.clientPassport, COUNT(*) as rentalCount
        FROM Rental r
        JOIN RentalOrder ro3 ON r.rentalOrderId = ro3.id
        WHERE r.status = 'Завершена'
        GROUP BY ro3.clientPassport
    ) rc ON ro.clientPassport = rc.clientPassport
    WHERE pc.clientPassport IS NULL;
    
    DECLARE @insertedRows INT = @@ROWCOUNT;
    
    -- результат
    IF EXISTS(SELECT 1 FROM @ProblemClients)
    BEGIN
        DECLARE @errorMsg NVARCHAR(MAX) = 'Следующие клиенты имеют нарушения и не были добавлены: ';
        
        DECLARE @reasons TABLE (clientPassport NVARCHAR(20), reason NVARCHAR(100));
        INSERT INTO @reasons SELECT DISTINCT clientPassport, reason FROM @ProblemClients;
        
        SELECT @errorMsg = @errorMsg + clientPassport + ' (' + reason + '), '
        FROM @reasons;
        
        SET @errorMsg = LEFT(@errorMsg, LEN(@errorMsg) - 1);
        PRINT @errorMsg;
    END
    
    PRINT 'Успешно вставлено ' + CAST(@insertedRows AS NVARCHAR) + ' записей';
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
