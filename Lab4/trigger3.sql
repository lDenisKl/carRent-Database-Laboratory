IF OBJECT_ID('Car_Delete_Trigger', 'TR') IS NOT NULL 
    DROP TRIGGER Car_Delete_Trigger;
GO

CREATE OR ALTER TRIGGER Car_Delete_Trigger
ON Car
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @errorMessages NVARCHAR(MAX) = '';
    
    WITH ErrorMessages AS (
        SELECT 
            'Автомобиль ' + d.licensePlate + ' не может быть удален. ' +
            CASE WHEN (YEAR(GETDATE()) - d.year <= 15) THEN 'Возраст менее 15 лет. ' ELSE '' END +
            CASE WHEN EXISTS (SELECT 1 FROM Rental r WHERE r.carLicensePlate = d.licensePlate) THEN 'Находился в прокате. ' ELSE '' END +
            CASE WHEN d.condition != 'Плохое' THEN 'Состояние не "Плохое".' ELSE '' END AS ErrorMsg
        FROM deleted d
        WHERE NOT ((YEAR(GETDATE()) - d.year > 15)
               AND NOT EXISTS (SELECT 1 FROM Rental r WHERE r.carLicensePlate = d.licensePlate)
               AND d.condition = 'Плохое')
    )
    SELECT @errorMessages = COALESCE(@errorMessages + CHAR(13) + CHAR(10), '') + ErrorMsg
    FROM ErrorMessages;
    
    -- Удаляем автомобили, которые можно удалить
    DELETE FROM Car 
    WHERE licensePlate IN (
        SELECT d.licensePlate 
        FROM deleted d
        WHERE (YEAR(GETDATE()) - d.year > 15)
           AND NOT EXISTS (SELECT 1 FROM Rental r WHERE r.carLicensePlate = d.licensePlate)
           AND d.condition = 'Плохое'
    );
    
    -- Если есть ошибки, выдаем их ВСЕ
    IF @errorMessages != ''
    BEGIN
        DECLARE @msg NVARCHAR(MAX) = 'Обнаружены ошибки удаления:' + CHAR(13) + CHAR(10) + @errorMessages;
        --PRINT @msg
            RAISERROR('%s', 16, 1, @msg);
        --THROW 50000, @msg, 1;
    END
END;
GO

SELECT d.licensePlate 
        FROM Car d
        WHERE (YEAR(GETDATE()) - d.year > 15)
           AND NOT EXISTS (SELECT 1 FROM Rental r WHERE r.carLicensePlate = d.licensePlate)
           AND d.condition = 'Плохое'


SELECT * FROM Car WHERE licensePlate = 'Х410ХХ777';

PRINT 'Тест 3 Удаление автомобиля, не удовлетворяющего условиям';
BEGIN TRY
    DELETE FROM Car WHERE licensePlate = 'С204СС777' OR licensePlate = 'Х410ХХ777'; -- Молодой, был в прокате, плохое состояние
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
    DELETE FROM Car WHERE licensePlate = 'А001АА777' OR licensePlate = 'Е305ЕЕ777';
    --DELETE FROM Car WHERE licensePlate = 'Е305ЕЕ777';
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
