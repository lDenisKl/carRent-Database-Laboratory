IF OBJECT_ID('Model_Update_Trigger', 'TR') IS NOT NULL DROP TRIGGER Model_Update_Trigger;

CREATE OR ALTER TRIGGER Model_Update_Trigger
ON Model
AFTER UPDATE
AS
BEGIN
    IF UPDATE(dailyPrice)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN Car c ON c.modelId = i.id
            JOIN Rental r ON r.carLicensePlate = c.licensePlate
            WHERE r.status = 'Активна' AND r.actualReturnDate IS NULL
        )
        BEGIN
            DECLARE @modelsList NVARCHAR(500);
            SELECT @modelsList = STRING_AGG(CONCAT(i.name, ' (ID:', i.id, ')'), ', ')
            FROM inserted i
            JOIN Car c ON c.modelId = i.id
            JOIN Rental r ON r.carLicensePlate = c.licensePlate
            WHERE r.status = 'Активна' AND r.actualReturnDate IS NULL;

            ROLLBACK TRANSACTION;
            RAISERROR('Нельзя изменить стоимость для моделей с автомобилями в активном прокате: %s', 16, 1, @modelsList);
        END
        ELSE
            PRINT 'Стоимость проката успешно обновлена.';
    END
END;

PRINT 'Тест 2: Изменение стоимости для модели в активном прокате';
BEGIN TRY
    DECLARE @activeModelId INT = 1;
    DECLARE @activeModelId2 INT = 2;
    --SELECT TOP 1 @activeModelId = m.id
    --FROM Model m
    --JOIN Car c ON m.id = c.modelId
    --JOIN Rental r ON c.licensePlate = r.carLicensePlate
    --WHERE r.status = 'Активна' AND r.actualReturnDate IS NULL;
    
    UPDATE Model SET dailyPrice = dailyPrice * 1.1 WHERE id = @activeModelId OR id = @activeModelId2;
    UPDATE Model SET dailyPrice = dailyPrice * 1.1 WHERE id = @activeModelId2;
    PRINT 'ОШИБКА: Триггер не сработал!';
END TRY
BEGIN CATCH
    PRINT 'УСПЕХ: ' + ERROR_MESSAGE();
END CATCH