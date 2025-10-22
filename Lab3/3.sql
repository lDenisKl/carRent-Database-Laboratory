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



-- 2 часть

-- Рассчитать выручку пункта проката по датам с начала текущего месяца
use [Cars1]
SELECT 
    CAST(r.actualReturnDate AS DATE) AS return_date,
    SUM(r.rentalCost) AS daily_revenue
FROM Rental r
WHERE 
    r.status = 'Завершена'
    AND r.actualReturnDate >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
    AND CAST(r.actualReturnDate AS DATE) < CAST(GETDATE() + 1 AS DATE)
GROUP BY CAST(r.actualReturnDate AS DATE)
ORDER BY return_date;

--Для каждого типа и модели автомобиля вывести количество машин, имеющихся в фирме

use [Cars1]
SELECT 
    m.type AS car_type,
    m.name AS model_name,
    m.manufacturer,
    COUNT(c.licensePlate) AS car_count
FROM Model m
LEFT JOIN Car c ON m.id = c.modelId
GROUP BY m.type, m.name, m.manufacturer
ORDER BY m.type, car_count DESC;

-- Найти модели, не пользующиеся спросом (с начала текущего года на автомобили этих моделей не было заключено ни одной сделки)

use [Cars1]
SELECT 
    m.id,
    m.name,
    m.type,
    m.manufacturer
FROM Model m
WHERE m.id NOT IN (
    SELECT DISTINCT c.modelId
    FROM Car c
    JOIN Rental r ON c.licensePlate = r.carLicensePlate
    WHERE 
        r.startDate >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
        AND r.status IN ('Активна', 'Завершена')
)
ORDER BY m.manufacturer, m.name;

-- Найти постоянных клиентов (пользовавшихся услугами фирмы более 3-х раз) 
--и рассчитать для них размер скидки 
--(напр., если клиент берет машину в 4-й раз – скидка 2%, в 6-й – 4%, в 8-й – 6%,
-- но если клиент был когда-либо оштрафован, то скидка не предоставляется)

use [Cars1]
WITH ClientStats AS (
    SELECT 
        c.passport,
        c.fullName,
        COUNT(r.id) AS rental_count,
        SIGN(COUNT(rf.rentalId)) AS has_fines
    FROM Client c
    JOIN RentalOrder ro ON c.passport = ro.clientPassport
    JOIN Rental r ON ro.id = r.rentalOrderId
    LEFT JOIN RentalFine rf ON r.id = rf.rentalId
    WHERE r.status IN ('Завершена', 'Активна')
    GROUP BY c.passport, c.fullName
    HAVING COUNT(r.id) > 3
)
SELECT 
    passport,
    fullName,
    rental_count,
    has_fines,
    CASE
	    WHEN has_fines = 1 Then 0
	    WHEN rental_count = 4 Then 2
	    WHEN rental_count = 6 Then 4
	    WHEN rental_count >= 8 Then 6
	Else 0
	END AS discount_percent
FROM ClientStats
ORDER BY rental_count DESC;

-- Найти клиентов, наиболее часто пользующихся услугами проката, 
-- и выдать для них общую сумму заключеннных сделок

use [Cars1]
SELECT 
    c.passport,
    c.fullName,
    c.phone,
    COUNT(DISTINCT ro.id) AS orders_count,
    COUNT(r.id) AS rentals_count,
    SUM(COALESCE(r.rentalCost, 0)) AS total_spent
FROM Client c
JOIN RentalOrder ro ON c.passport = ro.clientPassport
JOIN Rental r ON ro.id = r.rentalOrderId
WHERE r.status IN ('Завершена', 'Активна')
GROUP BY c.passport, c.fullName, c.phone
HAVING COUNT(r.id) > 0
ORDER BY total_spent DESC, rentals_count DESC;