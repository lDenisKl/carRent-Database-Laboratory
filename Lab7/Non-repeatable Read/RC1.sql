-- READ COMMITED 1 сеанс

USE [Cars1]
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

SELECT * FROM CarTest WHERE licensePlate = 'А001АА777';
-- Запоминаем цвет
-- Переход во 2 сеанс

SELECT * FROM CarTest WHERE licensePlate = 'А001АА777';
-- Цвет изменился → неповторяющееся чтение
COMMIT;