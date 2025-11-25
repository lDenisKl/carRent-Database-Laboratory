IF OBJECT_ID('Rental_Insert_Trigger', 'TR') IS NOT NULL DROP TRIGGER Car_Delete_Trigger;


CREATE OR ALTER TRIGGER Car_Delete_Trigger
ON Car
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @licensePlate NVARCHAR(15);
    DECLARE @year INT;
    DECLARE @color NVARCHAR(20);
    DECLARE @condition NVARCHAR(20);
    DECLARE @modelId INT;
    DECLARE @errorCount INT = 0;
    DECLARE @errorMessages NVARCHAR(MAX) = '';
    
    DECLARE car_cursor CURSOR FOR
    SELECT licensePlate, year, color, condition, modelId
    FROM deleted;
    
    OPEN car_cursor;
    FETCH NEXT FROM car_cursor INTO @licensePlate, @year, @color, @condition, @modelId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (YEAR(GETDATE()) - @year > 15)
           AND NOT EXISTS (SELECT 1 FROM Rental WHERE carLicensePlate = @licensePlate)
           AND @condition = 'Плохое'
        BEGIN
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
            
            SET @errorMessages = @errorMessages + @errorMsg + CHAR(13) + CHAR(10);
            SET @errorCount = @errorCount + 1;
        END
        
        FETCH NEXT FROM car_cursor INTO @licensePlate, @year, @color, @condition, @modelId;
    END
    
    CLOSE car_cursor;
    DEALLOCATE car_cursor;
    
    IF @errorCount > 0
    BEGIN
        RAISERROR(@errorMessages, 17, 1);
        RETURN;
    END
END;
GO

PRINT 'Тест 3 Удаление автомобиля, не удовлетворяющего условиям';
BEGIN TRY
    DELETE FROM Car WHERE licensePlate = 'С204СС777'; -- Молодой, был в прокате, хорошее состояние
    PRINT 'ОШИБКА: Триггер не сработал!';
END TRY
BEGIN CATCH
    PRINT 'УСПЕХ: ' + ERROR_MESSAGE();
END CATCH

    DELETE FROM Rental WHERE carLicensePlate = 'С204СС777';
    DELETE FROM Rental WHERE carLicensePlate = 'Е305ЕЕ777';
    DELETE FROM Rental WHERE carLicensePlate = 'А001АА777';
PRINT 'Тест 3.2: Удаление автомобиля, удовлетворяющего условиям';
BEGIN TRY
    DELETE FROM Car WHERE licensePlate = 'Е305ЕЕ777';
    DELETE FROM Car WHERE licensePlate = 'А001АА777';
    PRINT 'УСПЕХ: Автомобили успешно удален';

    IF NOT EXISTS (SELECT 1 FROM Car WHERE licensePlate = 'Е305ЕЕ777') AND NOT EXISTS (SELECT 1 FROM Car WHERE licensePlate = 'А001АА777')
        PRINT 'ПРОВЕРКА: Автомобили удалены из базы';
    ELSE
        PRINT 'ОШИБКА: Автомобили не был удален';
END TRY
BEGIN CATCH
    PRINT 'ОШИБКА: ' + ERROR_MESSAGE();
END CATCH
SELECT * FROM Car
