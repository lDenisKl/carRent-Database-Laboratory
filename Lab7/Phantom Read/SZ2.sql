-- SERIALIZABLE 2 сеанс

USE [Cars1]
GO

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

INSERT INTO CarTest VALUES ('НОВЫЙ456', 2024, 'Синий', 'Хорошее', 2);
-- Будет ждать, пока сеанс 1 не завершит транзакцию.
-- Возвращаеся и завершаем

Commit;