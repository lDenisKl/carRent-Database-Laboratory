-- READ UNCOMMITTED 1 сеанс

USE [Cars1]
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
SELECT condition FROM Car WHERE licensePlate = 'А001АА777';
-- прочитали 'Идеальное'
-- переходим в сеанс 2


-- Теперь на основе старого значения ('Идеальное') обновляем
UPDATE Car SET condition = 'Удовлетворительное' WHERE licensePlate = 'А001АА777';
COMMIT;
-- Потеряно изменение от Сеанса 2 (было 'Хорошее')