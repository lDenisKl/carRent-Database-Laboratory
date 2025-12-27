-- REPEATABLE READ 1 сеанс

USE [Cars1]
GO

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

SELECT * FROM CarTest WHERE licensePlate = 'А001АА777';
-- Переходим во 2 сеанс

SELECT * FROM CarTest WHERE licensePlate = 'А001АА777';
COMMIT;
-- После этого переходим во 2 сеанс и обновление в сеансе 2
-- сможет выполнится успешно