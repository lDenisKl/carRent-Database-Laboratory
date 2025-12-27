-- READ UNCOMMITED 2 сеанс
USE [Cars1]
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM CarTest WHERE licensePlate = 'А001АА777';
-- Увидим "ГрязныйЦвет", хотя транзакция в сеансе 1 не завершена
-- Возвращаемся в сеанс 1

SELECT * FROM CarTest WHERE licensePlate = 'А001АА777';
-- Теперь цвет вернулся к исходному