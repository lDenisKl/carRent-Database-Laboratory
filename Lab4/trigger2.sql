IF OBJECT_ID('Rental_Insert_Trigger', 'TR') IS NOT NULL DROP TRIGGER Model_Update_Trigger;

CREATE OR ALTER TRIGGER Model_Update_Trigger
ON Model
AFTER UPDATE
AS
BEGIN
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
            
            SET @modelsList = LEFT(@modelsList, LEN(@modelsList) - 1); 
            
            CLOSE model_cursor;
            DEALLOCATE model_cursor;
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

PRINT 'Тест 2: Изменение стоимости для модели в активном прокате';
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