-- 1.1
-- Сортировка моделей по производителю (по возрастанию) и цене (по убыванию)
SELECT *
FROM Model
ORDER BY manufacturer ASC, dailyPrice DESC;

-- 1.2
-- Выбор автомобилей в идеальном состоянии
SELECT *
FROM Car
WHERE condition = 'Идеальное';

-- Выбор активных скидок процентного типа
SELECT *
FROM Discount
WHERE isActive = 1 AND type = 'Процент';

-- Выбор завершенных аренд с стоимостью более 20000
SELECT *
FROM Rental
WHERE status = 'Завершена' AND rentalCost > 20000;

-- 1.3
-- Количество автомобилей по состоянию
SELECT COUNT(*) AS CarCount
FROM Car

-- Средняя цена по производителям
SELECT manufacturer, AVG(dailyPrice) AS AvgPrice
FROM Model
GROUP BY manufacturer;

-- Суммарная стоимость аренд по статусу
SELECT status, SUM(rentalCost) AS TotalCost
FROM Rental
GROUP BY status;

-- 1.4
-- ROLLUP: Итоги по типу и состоянию автомобилей
SELECT 
    type, 
    condition,
    COUNT(*) as CarCount
FROM Car c
JOIN Model m ON c.modelId = m.id
GROUP BY ROLLUP (type, condition);

-- CUBE: Все возможные комбинации производителя и типа модели
SELECT 
    manufacturer,
    type,
    COUNT(*) as ModelCount,
    AVG(dailyPrice) as AvgPrice
FROM Model
GROUP BY CUBE (manufacturer, type);

-- ROLLUP: Статистика по статусам заказов и клиентам
SELECT 
    status,
    clientPassport,
    COUNT(*) as OrderCount,
    SUM(ISNULL(totalPrice, 0)) as TotalRevenue
FROM RentalOrder
GROUP BY ROLLUP (status, clientPassport);

--1.5
-- Клиенты, у которых в адресе нет слова 'Москва'
SELECT *
FROM Client
WHERE address NOT LIKE '%Москва%';