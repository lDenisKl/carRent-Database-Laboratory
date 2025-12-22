USE [Cars1]
GO

SET NOCOUNT ON;

SELECT 'ДО ТРАНЗАКЦИИ' AS [Статус], * FROM RentalOrder 
WHERE clientPassport = '4510 111111';
GO

BEGIN TRANSACTION;

INSERT INTO RentalOrder (createDate, status, clientPassport)
VALUES (GETDATE(), 'Создан', '4510 111111');

DECLARE @NewOrderId INT = SCOPE_IDENTITY();

SAVE TRANSACTION Point1;

INSERT INTO Rental (startDate, plannedReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
VALUES (GETDATE(), DATEADD(DAY, 3, GETDATE()), 15000.00, 'Активна', 'А001АА777', @NewOrderId);

SELECT 'ПОСЛЕ ПЕРВОЙ АРЕНДЫ' AS [Статус], * FROM Rental WHERE rentalOrderId = @NewOrderId;

SAVE TRANSACTION Point2;

-- Пробуем добавить вторую аренду 
INSERT INTO Rental (startDate, plannedReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
VALUES (GETDATE(), GETDATE(), 10000.00, 'Активна', 'В101ВВ777', @NewOrderId);

IF @@ERROR <> 0
BEGIN
    PRINT 'Ошибка. Откат к Point2';
    ROLLBACK TRANSACTION Point2;
END

SELECT 'ПОСЛЕ ОТКАТА' AS [Статус], * FROM Rental WHERE rentalOrderId = @NewOrderId;

INSERT INTO Rental (startDate, plannedReturnDate, rentalCost, status, carLicensePlate, rentalOrderId)
VALUES (DATEADD(HOUR, 2, GETDATE()), DATEADD(DAY, 3, DATEADD(HOUR, 2, GETDATE())), 18000.00, 'Активна', 'В101ВВ777', @NewOrderId);

UPDATE RentalOrder 
SET status = 'Подтвержден', 
    totalPrice = (SELECT SUM(rentalCost) FROM Rental WHERE rentalOrderId = @NewOrderId)
WHERE id = @NewOrderId;

SELECT 'ПЕРЕД ФИКСАЦИЕЙ' AS [Статус], * FROM RentalOrder WHERE id = @NewOrderId;
SELECT * FROM Rental WHERE rentalOrderId = @NewOrderId;

COMMIT TRANSACTION;

SELECT 'ПОСЛЕ ФИКСАЦИИ' AS [Статус], * FROM RentalOrder WHERE id = @NewOrderId;
SELECT * FROM Rental WHERE rentalOrderId = @NewOrderId;