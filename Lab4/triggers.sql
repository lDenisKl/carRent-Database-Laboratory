IF OBJECT_ID('Rental_Insert_Trigger', 'TR') IS NOT NULL DROP TRIGGER Rental_Insert_Trigger;
IF OBJECT_ID('Model_Update_Trigger', 'TR') IS NOT NULL DROP TRIGGER Model_Update_Trigger;
IF OBJECT_ID('Car_Delete_Trigger', 'TR') IS NOT NULL DROP TRIGGER Car_Delete_Trigger;
GO

CREATE TRIGGER Rental_Insert_Trigger
ON Rental
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @clientPassport NVARCHAR(20);
    DECLARE @rentalCost DECIMAL(10, 2);
    DECLARE @rentalOrderId INT;
    DECLARE @carLicensePlate NVARCHAR(15);
    DECLARE @startDate DATETIME2;
    DECLARE @plannedReturnDate DATETIME2;
    DECLARE @rentalStatus NVARCHAR(20);
    
    DECLARE rental_cursor CURSOR FOR
    SELECT ro.clientPassport, i.rentalCost, i.rentalOrderId, i.carLicensePlate, 
           i.startDate, i.plannedReturnDate, i.status
    FROM inserted i
    JOIN RentalOrder ro ON i.rentalOrderId = ro.id;
    
    OPEN rental_cursor;
    FETCH NEXT FROM rental_cursor INTO @clientPassport, @rentalCost, @rentalOrderId, 
                                      @carLicensePlate, @startDate, @plannedReturnDate, @rentalStatus;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM Rental r
            JOIN RentalOrder ro ON r.rentalOrderId = ro.id
            JOIN RentalFine rf ON r.id = rf.rentalId
            WHERE ro.clientPassport = @clientPassport
        ) OR EXISTS (
            SELECT 1 
            FROM Rental r
            JOIN RentalOrder ro ON r.rentalOrderId = ro.id
            WHERE ro.clientPassport = @clientPassport
            AND r.actualReturnDate > r.plannedReturnDate
            AND r.actualReturnDate IS NOT NULL
        )
        BEGIN
            RAISERROR('Клиент %s имеет нарушения в истории аренд. Сделка невозможна.', 16, 1, @clientPassport);
        END
        ELSE
        BEGIN
            DECLARE @rentalCount INT;
            SELECT @rentalCount = COUNT(*)
            FROM Rental r
            JOIN RentalOrder ro ON r.rentalOrderId = ro.id
            WHERE ro.clientPassport = @clientPassport
            AND r.status = 'Завершена';
            
            DECLARE @discountRate DECIMAL(10, 2) = 0;
            
            IF @rentalCount >= 10
                SET @discountRate = 15.0;
            ELSE IF @rentalCount >= 5
                SET @discountRate = 10.0;
            ELSE IF @rentalCount >= 3
                SET @discountRate = 5.0;
                
            SET @rentalCost = @rentalCost * (1 - @discountRate / 100);
            
            INSERT INTO Rental (startDate, plannedReturnDate, actualReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
            VALUES (@startDate, @plannedReturnDate, NULL, @rentalCost, @rentalStatus, @carLicensePlate, @rentalOrderId);
            
            PRINT 'Сделка для клиента ' + @clientPassport + ' успешно создана. Применена скидка: ' + CAST(@discountRate AS NVARCHAR) + '%. Количество аренд: ' + CAST(@rentalCount AS NVARCHAR);
        END
        
        FETCH NEXT FROM rental_cursor INTO @clientPassport, @rentalCost, @rentalOrderId, 
                                          @carLicensePlate, @startDate, @plannedReturnDate, @rentalStatus;
    END
    
    CLOSE rental_cursor;
    DEALLOCATE rental_cursor;
END;
GO

-- b) Триггер на изменение стоимости
CREATE TRIGGER Model_Update_Trigger
ON Model
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Проверяем, обновляется ли цена
    IF UPDATE(dailyPrice)
    BEGIN
        DECLARE @modelId INT;
        DECLARE @modelName NVARCHAR(50);
        
        DECLARE model_cursor CURSOR FOR
        SELECT i.id, i.name
        FROM inserted i
        WHERE EXISTS (
            SELECT 1 
            FROM Car c
            JOIN Rental r ON c.licensePlate = r.carLicensePlate
            WHERE c.modelId = i.id
            AND r.status = 'Активна'
            AND r.actualReturnDate IS NULL
        );
        
        OPEN model_cursor;
        FETCH NEXT FROM model_cursor INTO @modelId, @modelName;
        
        -- Если найдены модели с авто в активном прокате - откатываем изменения
        IF @@FETCH_STATUS = 0
        BEGIN
            DECLARE @errorMsg NVARCHAR(500) = 'Нельзя изменить стоимость для моделей с автомобилями в активном прокате: ';
            DECLARE @modelsList NVARCHAR(500) = '';
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @modelsList = @modelsList + @modelName + ' (ID:' + CAST(@modelId AS NVARCHAR) + '), ';
                FETCH NEXT FROM model_cursor INTO @modelId, @modelName;
            END
            
            SET @modelsList = LEFT(@modelsList, LEN(@modelsList) - 1); -- Убираем последнюю запятую
            
            CLOSE model_cursor;
            DEALLOCATE model_cursor;
            
            -- Откатываем транзакцию
            ROLLBACK TRANSACTION;
            RAISERROR('%s%s', 16, 1, @errorMsg, @modelsList);
        END
        ELSE
        BEGIN
            CLOSE model_cursor;
            DEALLOCATE model_cursor;
            PRINT 'Стоимость проката успешно обновлена для выбранных моделей.';
        END
    END
END;
GO

CREATE TRIGGER Car_Delete_Trigger
ON Car
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @licensePlate NVARCHAR(15);
    DECLARE @year INT;
    DECLARE @color NVARCHAR(20);
    DECLARE @condition NVARCHAR(20);
    DECLARE @modelId INT;
    
    DECLARE car_cursor CURSOR FOR
    SELECT licensePlate, year, color, condition, modelId
    FROM deleted;
    
    OPEN car_cursor;
    FETCH NEXT FROM car_cursor INTO @licensePlate, @year, @color, @condition, @modelId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Проверка условий для удаления
        IF (YEAR(GETDATE()) - @year > 15)
           AND NOT EXISTS (SELECT 1 FROM Rental WHERE carLicensePlate = @licensePlate)
           AND @condition = 'Плохое'
        BEGIN
            -- Удаление автомобиля
            DELETE FROM Car WHERE licensePlate = @licensePlate;
            PRINT 'Автомобиль ' + @licensePlate + ' успешно удален.';
        END
        ELSE
        BEGIN
            DECLARE @errorMsg NVARCHAR(200) = 'Автомобиль ' + @licensePlate + ' не может быть удален. ';
            
            IF (YEAR(GETDATE()) - @year <= 15)
                SET @errorMsg = @errorMsg + 'Возраст менее 15 лет. ';
            
            IF EXISTS (SELECT 1 FROM Rental WHERE carLicensePlate = @licensePlate)
                SET @errorMsg = @errorMsg + 'Находился в прокате. ';
            
            IF @condition != 'Плохое'
                SET @errorMsg = @errorMsg + 'Состояние не "Плохое".';
                
            RAISERROR(@errorMsg, 16, 1);
        END
        
        FETCH NEXT FROM car_cursor INTO @licensePlate, @year, @color, @condition, @modelId;
    END
    
    CLOSE car_cursor;
    DEALLOCATE car_cursor;
END;
GO

-- ИСПРАВЛЕННЫЙ ТЕСТОВЫЙ КОД

PRINT '=== ТЕСТ 1: Триггер на добавление сделки (ИСПРАВЛЕННЫЙ) ===';

-- Тест 1.1: Попытка добавить аренду для клиента с нарушениями (должен быть отказ)
PRINT 'Тест 1.1: Клиент с нарушениями в истории';
BEGIN TRY
    DECLARE @testOrderId1 INT;
    
    -- Создаем заказ для клиента с нарушениями
    INSERT INTO RentalOrder (createDate, status, totalPrice, clientPassport)
    VALUES (GETDATE(), 'Создан', NULL, '4510 123456'); -- Иванов имеет нарушения
    
    SET @testOrderId1 = SCOPE_IDENTITY();
    
    INSERT INTO Rental (startDate, plannedReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
    VALUES ('2025-07-20 10:00:00', '2025-07-25 10:00:00', 15000.00, 'Активна', 'А008АА777', @testOrderId1);
    
    PRINT 'ОШИБКА: Триггер не сработал для клиента с нарушениями!';
END TRY
BEGIN CATCH
    PRINT 'УСПЕХ: ' + ERROR_MESSAGE();
    
    -- Очистка тестового заказа
    DELETE FROM RentalOrder WHERE id = @testOrderId1;
END CATCH

-- Тест 1.2: Добавление аренды для клиента без нарушений (должна примениться скидка)
PRINT 'Тест 1.2: Клиент без нарушений со скидкой';
BEGIN TRY
    DECLARE @newOrderId INT;
    
    -- Создаем новый заказ для клиента без нарушений
    INSERT INTO RentalOrder (createDate, status, totalPrice, clientPassport)
    VALUES (GETDATE(), 'Создан', NULL, '4510 222222'); -- Кузнецов без нарушений
    
    SET @newOrderId = SCOPE_IDENTITY();
    
    DECLARE @originalCost DECIMAL(10,2) = 20000.00;
    
    INSERT INTO Rental (startDate, plannedReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
    VALUES ('2025-07-20 10:00:00', '2025-07-25 10:00:00', @originalCost, 'Активна', 'Е308ЕЕ777', @newOrderId);
    
    -- Проверяем примененную скидку
    DECLARE @finalCost DECIMAL(10,2);
    SELECT @finalCost = rentalCost FROM Rental WHERE rentalOrderId = @newOrderId;
    
    PRINT 'УСПЕХ: Сделка создана. Исходная стоимость: ' + CAST(@originalCost AS NVARCHAR) + 
          ', стоимость после скидки: ' + CAST(@finalCost AS NVARCHAR);
    
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА: ' + ERROR_MESSAGE();
    
    -- Очистка в случае ошибки
    IF @newOrderId IS NOT NULL
        DELETE FROM RentalOrder WHERE id = @newOrderId;
END CATCH

PRINT '';

PRINT '=== ТЕСТ 2: ПОСЛЕДУЮЩИЙ триггер на изменение стоимости ===';

-- Тест 2.1: Попытка изменить стоимость модели с автомобилями в активном прокате
PRINT 'Тест 2.1: Изменение стоимости для модели в активном прокате (последующий триггер)';
BEGIN TRY
    -- Находим модель, у которой есть автомобили в активном прокате
    DECLARE @activeModelId INT;
    SELECT TOP 1 @activeModelId = m.id
    FROM Model m
    JOIN Car c ON m.id = c.modelId
    JOIN Rental r ON c.licensePlate = r.carLicensePlate
    WHERE r.status = 'Активна' AND r.actualReturnDate IS NULL;
    
    IF @activeModelId IS NOT NULL
    BEGIN
        UPDATE Model SET dailyPrice = dailyPrice * 1.1 WHERE id = @activeModelId;
        PRINT 'ОШИБКА: Триггер не сработал!';
    END
    ELSE
    BEGIN
        PRINT 'ПРОПУЩЕНО: Нет моделей с активными прокатами для теста';
    END
END TRY
BEGIN CATCH
    PRINT 'УСПЕХ: ' + ERROR_MESSAGE();
END CATCH

-- Тест 2.2: Изменение стоимости модели без активных прокатов (должно работать)
PRINT 'Тест 2.2: Изменение стоимости для модели без активных прокатов';
BEGIN TRY
    -- Находим модель без активных прокатов
    DECLARE @inactiveModelId INT;
    SELECT TOP 1 @inactiveModelId = m.id
    FROM Model m
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Car c 
        JOIN Rental r ON c.licensePlate = r.carLicensePlate
        WHERE c.modelId = m.id 
        AND r.status = 'Активна' 
        AND r.actualReturnDate IS NULL
    );
    
    DECLARE @oldPrice DECIMAL(10,2), @newPrice DECIMAL(10,2);
    SELECT @oldPrice = dailyPrice FROM Model WHERE id = @inactiveModelId;
    SET @newPrice = @oldPrice * 1.15;
    
    UPDATE Model SET dailyPrice = @newPrice WHERE id = @inactiveModelId;
    
    -- Проверяем, что цена действительно изменилась
    DECLARE @updatedPrice DECIMAL(10,2);
    SELECT @updatedPrice = dailyPrice FROM Model WHERE id = @inactiveModelId;
    
    IF @updatedPrice = @newPrice
        PRINT 'УСПЕХ: Стоимость успешно изменена с ' + CAST(@oldPrice AS NVARCHAR) + ' на ' + CAST(@newPrice AS NVARCHAR);
    ELSE
        PRINT 'ОШИБКА: Цена не изменилась';
        
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА: ' + ERROR_MESSAGE();
END CATCH

-- 3. ТЕСТИРОВАНИЕ ТРИГГЕРА НА УДАЛЕНИЕ АВТОМОБИЛЯ (ИСПРАВЛЕННЫЙ)
PRINT '=== ТЕСТ 3: Триггер на удаление автомобиля (ИСПРАВЛЕННЫЙ) ===';

-- Сначала создадим тестовые автомобили для проверки удаления
PRINT 'Создание тестовых автомобилей...';

-- Автомобиль, который можно удалить (удовлетворяет всем условиям)
IF NOT EXISTS (SELECT 1 FROM Car WHERE licensePlate = 'TEST001')
BEGIN
    INSERT INTO Car (licensePlate, year, color, condition, modelId)
    VALUES ('TEST001', 2005, 'Ржавый', 'Плохое', 1);
END

-- Автомобиль, который нельзя удалить (хорошее состояние)
IF NOT EXISTS (SELECT 1 FROM Car WHERE licensePlate = 'TEST002')
BEGIN
    INSERT INTO Car (licensePlate, year, color, condition, modelId)
    VALUES ('TEST002', 2005, 'Синий', 'Хорошее', 1);
END

-- Автомобиль, который нельзя удалить (молодой)
IF NOT EXISTS (SELECT 1 FROM Car WHERE licensePlate = 'TEST003')
BEGIN
    INSERT INTO Car (licensePlate, year, color, condition, modelId)
    VALUES ('TEST003', 2020, 'Красный', 'Плохое', 1);
END

-- Тест 3.1: Попытка удалить автомобиль, который НЕЛЬЗЯ удалить
PRINT 'Тест 3.1: Удаление автомобиля, не удовлетворяющего условиям';
BEGIN TRY
    DELETE FROM Car WHERE licensePlate = 'А001АА777'; -- Молодой, был в прокате, хорошее состояние
    PRINT 'ОШИБКА: Триггер не сработал!';
END TRY
BEGIN CATCH
    PRINT 'УСПЕХ: ' + ERROR_MESSAGE();
END CATCH

-- Тест 3.2: Удаление автомобиля, который МОЖНО удалить
PRINT 'Тест 3.2: Удаление автомобиля, удовлетворяющего условиям';
BEGIN TRY
    DELETE FROM Car WHERE licensePlate = 'TEST001';
    PRINT 'УСПЕХ: Автомобиль успешно удален';
    
    -- Проверяем, что автомобиль удален
    IF NOT EXISTS (SELECT 1 FROM Car WHERE licensePlate = 'TEST001')
        PRINT 'ПРОВЕРКА: Автомобиль TEST001 удален из базы';
    ELSE
        PRINT 'ОШИБКА: Автомобиль не был удален';
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА: ' + ERROR_MESSAGE();
END CATCH

-- Тест 3.3: Попытка удалить автомобиль с хорошим состоянием
PRINT 'Тест 3.3: Удаление автомобиля с хорошим состоянием';
BEGIN TRY
    DELETE FROM Car WHERE licensePlate = 'TEST002';
    PRINT 'ОШИБКА: Удален автомобиль с хорошим состоянием!';
END TRY
BEGIN CATCH
    PRINT 'УСПЕХ: ' + ERROR_MESSAGE();
END CATCH

-- Тест 3.4: Попытка удалить молодой автомобиль
PRINT 'Тест 3.4: Удаление молодого автомобиля';
BEGIN TRY
    DELETE FROM Car WHERE licensePlate = 'TEST003';
    PRINT 'ОШИБКА: Удален молодой автомобиль!';
END TRY
BEGIN CATCH
    PRINT 'УСПЕХ: ' + ERROR_MESSAGE();
END CATCH
-- Очистка тестовых данных БЕЗ вызова триггера
PRINT 'Очистка тестовых данных...';

-- Удаляем без проверки условий (для тестовых данных)
DELETE FROM Car WHERE licensePlate = 'TEST002';
DELETE FROM Car WHERE licensePlate = 'TEST003';

PRINT 'Очистка завершена';
PRINT '';
PRINT '=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===';

-- ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Просмотр текущих данных
PRINT '';
PRINT '=== ПРОВЕРКА ДАННЫХ ПОСЛЕ ТЕСТИРОВАНИЯ ===';

PRINT '=== ПРОВЕРКА КЛИЕНТОВ С НАРУШЕНИЯМИ ===';

SELECT 
    c.passport,
    c.fullName,
    COUNT(r.id) as TotalRentals,
    COUNT(rf.rentalId) as RentalsWithFines,
    COUNT(CASE WHEN r.actualReturnDate > r.plannedReturnDate THEN 1 END) as LateReturns
FROM Client c
LEFT JOIN RentalOrder ro ON c.passport = ro.clientPassport
LEFT JOIN Rental r ON ro.id = r.rentalOrderId
LEFT JOIN RentalFine rf ON r.id = rf.rentalId
GROUP BY c.passport, c.fullName
HAVING COUNT(rf.rentalId) > 0 OR COUNT(CASE WHEN r.actualReturnDate > r.plannedReturnDate THEN 1 END) > 0;