-- REPEATABLE READ 1 сеанс

USE [Cars1]
GO

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

SELECT * FROM CarTest WHERE year > 2022;
-- Переходим во второй сеанс

SELECT * FROM CarTest WHERE year > 2022;
-- Новая строка появится → фантомное чтение
COMMIT;