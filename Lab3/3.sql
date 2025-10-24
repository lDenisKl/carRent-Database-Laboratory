-- 1.1
-- Вывести список автомобилей, отсортировать по производителю по возрастанию и по цене по убыванию
use Cars1;
SELECT *
FROM Model
ORDER BY manufacturer ASC, dailyPrice DESC;

-- 1.2
-- Вывести все автомобили в идеальном состоянии
SELECT *
FROM Car
WHERE condition = 'Идеальное';

-- Вывести активные процентные скидки
SELECT *
FROM Discount
WHERE isActive = 1 AND type = 'Процент';

-- Вывести все завершённые аренды, стоимостью более 20000
SELECT *
FROM Rental
WHERE status = 'Завершена' AND rentalCost > 20000;

-- 1.3
-- Вывести общее количество автомобилей
SELECT COUNT(*) AS CarCount
FROM Car

-- Вывести среднюю стоимость аренды для каждого производителя
SELECT manufacturer, AVG(dailyPrice) AS AvgPrice
FROM Model
GROUP BY manufacturer;

-- Вывести суммы за аренду для каждого статуса заказа
SELECT status, SUM(rentalCost) AS TotalCost
FROM Rental
GROUP BY status;

-- 1.4
-- Проанализировать количество автомобилей по типам и состояниям с подведением итогов по типам и общему количеству.
SELECT 
    type, 
    condition,
    COUNT(*) as CarCount
FROM Car c
JOIN Model m ON c.modelId = m.id
GROUP BY ROLLUP (type, condition);

-- Получить все комбинации производителя и типа модели с количеством и средней ценой, включая итоги по каждому параметру отдельно.
SELECT 
    manufacturer,
    type,
    COUNT(*) as ModelCount,
    AVG(dailyPrice) as AvgPrice
FROM Model
GROUP BY CUBE (manufacturer, type);

-- Проанализировать выручку и количество заказов по статусам и клиентам с итогами по статусам и общими итогами.
SELECT 
    status,
    clientPassport,
    COUNT(*) as OrderCount,
    SUM(ISNULL(totalPrice, 0)) as TotalRevenue
FROM RentalOrder
GROUP BY ROLLUP (status, clientPassport);

--1.5
-- Найти всех клиентов, которые проживают не в Москве
SELECT *
FROM Client
WHERE address NOT LIKE '%Москва%';

-- 2.1
-- Вывести список всех аренд с названием модели автомобиля и ФИО
SELECT 
    r.id,
    c.licensePlate,
    m.name as ModelName,
    cl.fullName as ClientName
FROM Rental r, Car c, Model m, Client cl
WHERE r.carLicensePlate = c.licensePlate 
    AND c.modelId = m.id 
    AND r.rentalOrderId IN (SELECT id FROM RentalOrder WHERE clientPassport = cl.passport);

-- Показать все штрафы с указанием типа штрафа и госномера автомобиля.
SELECT 
    rf.rentalId,
    f.type as FineType,
    c.licensePlate
FROM RentalFine rf, Fine f, Rental r, Car c
WHERE rf.fineId = f.id 
    AND rf.rentalId = r.id 
    AND r.carLicensePlate = c.licensePlate;

-- 2.2
SELECT 
    r.id,
    c.licensePlate,
    m.name as ModelName,
    cl.fullName as ClientName
FROM Rental r
INNER JOIN Car c ON r.carLicensePlate = c.licensePlate
INNER JOIN Model m ON c.modelId = m.id
INNER JOIN RentalOrder ro ON r.rentalOrderId = ro.id
INNER JOIN Client cl ON ro.clientPassport = cl.passport;

SELECT 
    rf.rentalId,
    f.type as FineType,
    c.licensePlate
FROM RentalFine rf
INNER JOIN Fine f ON rf.fineId = f.id
INNER JOIN Rental r ON rf.rentalId = r.id
INNER JOIN Car c ON r.carLicensePlate = c.licensePlate;

-- 2.3
-- Найти всех клиентов и показать их скидки, включая тех, у кого скидок нет.
SELECT 
    cl.fullName,
    d.name as DiscountName
FROM Client cl
LEFT JOIN ClientDiscount cd ON cl.passport = cd.clientPassport
LEFT JOIN Discount d ON cd.discountId = d.id;

-- Вывести все автомобили и информацию об их активных арендах.
SELECT 
    c.licensePlate,
    r.status as RentalStatus
FROM Car c
LEFT JOIN Rental r ON c.licensePlate = r.carLicensePlate AND r.status = 'Активна';

-- 2.4 
-- Показать все возможные скидки и клиентов, которые ими владеют.
SELECT 
    d.name as DiscountName,
    cl.fullName
FROM ClientDiscount cd
RIGHT JOIN Discount d ON cd.discountId = d.id
LEFT JOIN Client cl ON cd.clientPassport = cl.passport;

-- Вывести все типы штрафов и аренды, к которым они применены.
SELECT 
    f.type as FineType,
    r.id as RentalId
FROM RentalFine rf
RIGHT JOIN Fine f ON rf.fineId = f.id
LEFT JOIN Rental r ON rf.rentalId = r.id;

-- 2.5
-- Посчитать общее количество автомобилей каждого производителя.
SELECT 
    manufacturer,
    COUNT(*) as CarCount
FROM Car c
JOIN Model m ON c.modelId = m.id
GROUP BY manufacturer;

-- Найти среднюю стоимость аренды для каждого типа кузова.
SELECT 
    m.type,
    AVG(r.rentalCost) as AvgRentalCost
FROM Rental r
JOIN Car c ON r.carLicensePlate = c.licensePlate
JOIN Model m ON c.modelId = m.id
WHERE r.rentalCost IS NOT NULL
GROUP BY m.type;

-- 2.6
-- Найти клиентов, у которых больше 2 завершенных заказов.
SELECT 
    clientPassport,
    COUNT(*) as CompletedOrders
FROM RentalOrder
WHERE status = 'Завершен'
GROUP BY clientPassport
HAVING COUNT(*) > 2;

-- Вывести производителей, у которых средняя цена модели превышает 3000 руб.
SELECT 
    manufacturer,
    AVG(dailyPrice) as AvgPrice
FROM Model
GROUP BY manufacturer
HAVING AVG(dailyPrice) > 3000;

-- 2.7
-- Найти клиентов, которые арендовали внедорожники.
SELECT *
FROM Client
WHERE passport IN (
    SELECT DISTINCT ro.clientPassport
    FROM RentalOrder ro
    JOIN Rental r ON ro.id = r.rentalOrderId
    JOIN Car c ON r.carLicensePlate = c.licensePlate
    JOIN Model m ON c.modelId = m.id
    WHERE m.type = 'Внедорожник'
);

-- Вывести автомобили, которые никогда не арендовались.
SELECT *
FROM Car
WHERE licensePlate NOT IN (
    SELECT DISTINCT carLicensePlate
    FROM Rental
);

-- Найти модели, цена которых выше средней.
SELECT *
FROM Model
WHERE dailyPrice > (
    SELECT AVG(dailyPrice)
    FROM Model
);

-- 3.1
-- Активные аренды с деталями
CREATE VIEW ActiveRentalsView AS
SELECT 
    r.id as RentalId,
    c.licensePlate,
    m.manufacturer,
    m.name as ModelName,
    cl.fullName as ClientName,
    r.startDate,
    r.plannedReturnDate
FROM Rental r
JOIN Car c ON r.carLicensePlate = c.licensePlate
JOIN Model m ON c.modelId = m.id
JOIN RentalOrder ro ON r.rentalOrderId = ro.id
JOIN Client cl ON ro.clientPassport = cl.passport
WHERE r.status = 'Активна';
SELECT * FROM ActiveRentalsView;

-- Клиенты со скидками
CREATE VIEW ClientsWithDiscountsView AS
SELECT 
    cl.passport,
    cl.fullName,
    d.name as DiscountName,
    d.rate as DiscountRate
FROM Client cl
JOIN ClientDiscount cd ON cl.passport = cd.clientPassport
JOIN Discount d ON cd.discountId = d.id
WHERE d.isActive = 1;
SELECT * FROM ClientsWithDiscountsView;

-- 3.2
-- Получить количество аренд каждого клиента
WITH ClientRentalCount AS (
    SELECT 
        clientPassport,
        COUNT(*) as RentalCount
    FROM RentalOrder
    GROUP BY clientPassport
)
SELECT 
    c.fullName,
    crc.RentalCount
FROM Client c
JOIN ClientRentalCount crc ON c.passport = crc.clientPassport;

-- Получить автомобили с их последней арендой
WITH LastRental AS (
    SELECT 
        carLicensePlate,
        MAX(startDate) as LastRentalDate
    FROM Rental
    GROUP BY carLicensePlate
)
SELECT 
    c.licensePlate,
    m.manufacturer,
    m.name as ModelName,
    lr.LastRentalDate
FROM Car c
JOIN Model m ON c.modelId = m.id
LEFT JOIN LastRental lr ON c.licensePlate = lr.carLicensePlate;

-- 4.1
-- Пронумеровать автомобили по цене
SELECT 
    licensePlate,
    manufacturer,
    name as ModelName,
    dailyPrice,
    ROW_NUMBER() OVER (ORDER BY dailyPrice DESC) as PriceRank
FROM Car c
JOIN Model m ON c.modelId = m.id;

-- Рейтинг клиентов по количеству заказов (с разделами)
SELECT 
    fullName,
    COUNT(ro.id) as OrderCount,
    RANK() OVER (PARTITION BY ro.status ORDER BY COUNT(ro.id) DESC) as RankByStatus
FROM Client c
JOIN RentalOrder ro ON c.passport = ro.clientPassport
GROUP BY c.fullName, ro.status;

-- Рейтинг моделей по цене в рамках производителя
SELECT 
    manufacturer,
    name as ModelName,
    dailyPrice,
    DENSE_RANK() OVER (PARTITION BY manufacturer ORDER BY dailyPrice DESC) as PriceRank
FROM Model;

-- 5.1
-- Вывести всех клиентов из Москвы и СПб
SELECT fullName, address 
FROM Client 
WHERE address LIKE '%Москва%'
UNION ALL
SELECT fullName, address 
FROM Client 
WHERE address LIKE '%Санкт-Петербург%';

-- Уникальные типы кузовов из автомобилей и моделей
SELECT type FROM Model
UNION
SELECT 'Седан'
ORDER BY type;

-- Вывести клиентов без скидок
SELECT passport FROM Client
EXCEPT
SELECT clientPassport FROM ClientDiscount;

-- 6.1
-- Проанализировать цены по категориям
SELECT 
    manufacturer,
    name as ModelName,
    dailyPrice,
    CASE 
        WHEN dailyPrice < 2000 THEN 'Бюджетный'
        WHEN dailyPrice BETWEEN 2000 AND 4000 THEN 'Средний'
        ELSE 'Премиум'
    END as PriceCategory,
    CASE 
        WHEN condition = 'Идеальное' THEN 'Высший'
        WHEN condition IN ('Хорошее', 'Удовлетворительное') THEN 'Стандартный'
        ELSE 'Низкий'
    END as ConditionLevel
FROM Car c
JOIN Model m ON c.modelId = m.id;

-- Статусы заказов с группировкой
SELECT 
    clientPassport,
    COUNT(*) as TotalOrders,
    SUM(CASE WHEN status = 'Завершен' THEN 1 ELSE 0 END) as Completed,
    SUM(CASE WHEN status = 'Активен' THEN 1 ELSE 0 END) as Active,
    SUM(CASE WHEN status = 'Отменен' THEN 1 ELSE 0 END) as Cancelled
FROM RentalOrder
GROUP BY clientPassport;

-- 6.2
-- Количество автомобилей по состоянию и типу
SELECT *
FROM (
    SELECT 
        m.type,
        c.condition
    FROM Car c
    JOIN Model m ON c.modelId = m.id
) as SourceTable
PIVOT (
    COUNT(condition)
    FOR condition IN ([Идеальное], [Хорошее], [Удовлетворительное], [Плохое])
) as PivotTable;

-- Преобразование сводной таблицы обратно
WITH PivotData AS (
    SELECT 
        type,
        [Идеальное] as Ideal,
        [Хорошее] as Good,
        [Удовлетворительное] as Satisfactory
    FROM (
        SELECT m.type, c.condition
        FROM Car c 
        JOIN Model m ON c.modelId = m.id
    ) as src
    PIVOT (
        COUNT(condition)
        FOR condition IN ([Идеальное], [Хорошее], [Удовлетворительное])
    ) as pvt
)
SELECT type, Condition, CarCount
FROM PivotData
UNPIVOT (
    CarCount FOR Condition IN (Ideal, Good, Satisfactory)
) as unpvt;





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
    --HAVING COUNT(r.id) > 3
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

Select Sign(-5), sign(0), sign(5);

-- Найти клиентов, наиболее часто пользующихся услугами проката, 
-- и выдать для них общую сумму заключеннных сделок

use [Cars1]
SELECT TOP 1 With ties
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