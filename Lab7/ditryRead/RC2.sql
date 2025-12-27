-- READ COMMITTED 2 сеанс

USE [Cars1]
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT color FROM Car WHERE licensePlate = 'А002АА777';
-- Ждёт, пока Сеанс 1 не завершит транзакцию (грязного чтения нет)
