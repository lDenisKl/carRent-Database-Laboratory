-- READ COMMITTED 1 сеанс

USE [Cars1]
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
UPDATE Car SET color = 'ГрязныйЦвет2' WHERE licensePlate = 'А002АА777';
-- Не коммитим и переходим в сеанс 2

COMMIT; -- Вернемся в сеанс 2 и сможем увидеть изменения