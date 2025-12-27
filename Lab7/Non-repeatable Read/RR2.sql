-- REPEATABLE READ 2 сеанс
USE [Cars1]
GO


SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

UPDATE CarTest SET color = 'ДругойЦвет' WHERE licensePlate = 'А001АА777';
-- Будет ждать, пока сеанс 1 не завершит транзакцию
-- Возвращаемся в сеанс 1 и завершаем транзакцию

Commit;