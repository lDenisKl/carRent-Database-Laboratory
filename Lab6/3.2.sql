-- Рассчитать выручку пункта проката по датам с начала текущего месяца
SELECT 
    CAST(r.actualReturnDate AS DATE) AS return_date,
    SUM(r.rentalCost) AS daily_revenue
FROM 
    ClientNode c,
    RENTED r,
    CarNode ca
WHERE MATCH(c-(r)->ca)
    AND r.status = 'Завершена'
    AND r.actualReturnDate IS NOT NULL
    AND r.actualReturnDate >= DATEFROMPARTS(YEAR(GETDATE()-100), MONTH(GETDATE()-100), 1)
    AND r.actualReturnDate < DATEADD(DAY, 1, CAST(GETDATE() AS DATE))
GROUP BY CAST(r.actualReturnDate AS DATE)
ORDER BY return_date DESC;

SELECT 
    CAST(r.actualReturnDate AS DATE) AS return_date,
    SUM(r.rentalCost) AS daily_revenue
FROM Rental r
WHERE 
    r.status = 'Завершена'
    AND r.actualReturnDate >= DATEFROMPARTS(YEAR(GETDATE()-100), MONTH(GETDATE()-100), 1)
    AND CAST(r.actualReturnDate AS DATE) < CAST(GETDATE() + 1 AS DATE)
GROUP BY CAST(r.actualReturnDate AS DATE)
ORDER BY return_date;

-- Для каждого типа и модели автомобиля вывести количество машин
SELECT 
    m.type AS car_type,
    m.name AS model_name,
    m.manufacturer,
    COUNT(ca.licensePlate) AS car_count
FROM 
    ModelNode m,
    HAS_MODEL hm,
    CarNode ca
WHERE MATCH(ca-(hm)->m)
GROUP BY m.type, m.name, m.manufacturer
ORDER BY m.type, car_count DESC;


SELECT 
    m.type AS car_type,
    m.name AS model_name,
    m.manufacturer,
    COUNT(c.licensePlate) AS car_count
FROM Model m
LEFT JOIN Car c ON m.id = c.modelId
GROUP BY m.type, m.name, m.manufacturer
ORDER BY m.type, car_count DESC;

-- Найти модели, не пользующиеся спросом (с начала текущего года)
SELECT 
    m.id,
    m.name,
    m.type,
    m.manufacturer
FROM ModelNode m
WHERE m.id NOT IN (
    SELECT DISTINCT m2.id
    FROM 
        ModelNode m2,
        HAS_MODEL hm,
        CarNode ca,
        RENTED r
    WHERE MATCH(ca-(hm)->m2) 
        AND EXISTS (
            SELECT 1 
            FROM RENTED r2 
            WHERE r2.$to_id = ca.$node_id
                AND r2.startDate >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
                AND r2.status IN ('Активна', 'Завершена')
        )
);

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

-- Найти постоянных клиентов (более 3-х раз) с расчётом скидки

WITH ClientRentals AS (
    SELECT 
        c.passport,
        c.fullName,
        COUNT(r.$edge_id) AS rental_count
    FROM 
        ClientNode c,
        RENTED r,
        CarNode ca
    WHERE MATCH(c-(r)->ca)
        AND r.status IN ('Завершена', 'Активна')
    GROUP BY c.passport, c.fullName
),
ClientFines AS (
    SELECT 
        c.passport,
        1 AS has_fines
    FROM 
        ClientNode c,
        RENTED r,
        CarNode ca,
        ORDER_CONTAINS_CAR occ,
        OrderNode o,
        ORDER_HAS_FINE ohf,
        FineNode f
    WHERE MATCH(c-(r)->ca AND o-(occ)->ca AND o-(ohf)->f)
        AND r.status IN ('Завершена', 'Активна')
    GROUP BY c.passport
)
SELECT 
    cr.passport,
    cr.fullName,
    cr.rental_count,
    CASE WHEN cf.passport IS NOT NULL THEN 1 ELSE 0 END AS has_fines,
    CASE
        WHEN cf.passport IS NOT NULL THEN 0
        WHEN cr.rental_count = 4 THEN 2
        WHEN cr.rental_count = 6 THEN 4
        WHEN cr.rental_count >= 8 THEN 6
        ELSE 0
    END AS discount_percent
FROM ClientRentals cr
LEFT JOIN ClientFines cf ON cr.passport = cf.passport
-- WHERE cr.rental_count > 3 
ORDER BY cr.rental_count DESC;


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

-- Найти клиентов, наиболее часто пользующихся услугами проката
SELECT TOP 10
    c.passport,
    c.fullName,
    c.phone,
    COUNT(DISTINCT r.startDate) AS rentals_count,
    SUM(r.rentalCost) AS total_spent
FROM 
    ClientNode c,
    RENTED r,
    CarNode ca
WHERE MATCH(c-(r)->ca)
    AND r.status IN ('Завершена', 'Активна')
    AND r.rentalCost > 0
GROUP BY c.passport, c.fullName, c.phone
ORDER BY total_spent DESC, rentals_count DESC;


SELECT TOP 10 With ties
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
ORDER BY total_spent DESC
