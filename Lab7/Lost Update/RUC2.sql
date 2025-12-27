-- READ UNCOMMITTED 2 сеанс

USE [Cars1]
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
SELECT condition FROM Car WHERE licensePlate = 'А001АА777';
-- Тоже прочитали 'Идеальное' и обновляем
UPDATE Car SET condition = 'Хорошее' WHERE licensePlate = 'А001АА777';
-- переходим обратно в 1 сеанс
COMMIT;