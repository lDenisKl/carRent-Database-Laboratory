-- READ UNCOMMITED 1 сеанс
USE [Cars1]
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;

UPDATE CarTest SET color = 'ГрязныйЦвет' WHERE licensePlate = 'А001АА777';
-- Не фиксируем, оставляем транзакцию открытой.
-- Идём во второй сеанс

ROLLBACK TRANSACTION;