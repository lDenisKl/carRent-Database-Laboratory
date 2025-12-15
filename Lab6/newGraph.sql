
-- 1. УЗЛы
CREATE TABLE ClientNode (
    passport NVARCHAR(20) PRIMARY KEY,
    fullName NVARCHAR(100),
    address NVARCHAR(200),
    phone NVARCHAR(20)
) AS NODE;

CREATE TABLE CarNode (
    licensePlate NVARCHAR(15) PRIMARY KEY,
    year INT,
    color NVARCHAR(20),
    condition NVARCHAR(20)
) AS NODE;

CREATE TABLE ModelNode (
    id INT PRIMARY KEY,
    name NVARCHAR(50),
    type NVARCHAR(20),
    manufacturer NVARCHAR(30),
    dailyPrice DECIMAL(10,2)
) AS NODE;

CREATE TABLE OrderNode (
    id INT PRIMARY KEY,
    createDate DATETIME2,
    status NVARCHAR(20),
    totalPrice DECIMAL(10,2),
    discountApplied DECIMAL(10,2) NULL, 
    discountType NVARCHAR(20) NULL
) AS NODE;

-- 2. РЁБРа
-- Автомобиль принадлежит модели
CREATE TABLE OF_MODEL AS EDGE;
-- Клиент делает заказ
CREATE TABLE PLACES_ORDER AS EDGE;
-- Заказ содержит автомобиль (с деталями аренды)
CREATE TABLE HAS (
    rentalCost DECIMAL(10,2),
    startDate DATETIME2,
    plannedReturnDate DATETIME2,
    actualReturnDate DATETIME2,
    rentalStatus NVARCHAR(20),
    fineAmount DECIMAL(10,2) NULL,
    fineType NVARCHAR(50) NULL
) AS EDGE;

-- 3. ДАННЫе

INSERT INTO ClientNode (passport, fullName, address, phone)
SELECT passport, fullName, address, phone FROM Client;
PRINT 'Добавлено клиентов: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO CarNode (licensePlate, year, color, condition)
SELECT licensePlate, year, color, condition FROM Car;
PRINT 'Добавлено автомобилей: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO ModelNode (id, name, type, manufacturer, dailyPrice)
SELECT id, name, type, manufacturer, dailyPrice FROM Model;
PRINT 'Добавлено моделей: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO OrderNode (id, createDate, status, totalPrice, discountApplied, discountType)
SELECT 
    ro.id,
    ro.createDate,
    ro.status,
    ro.totalPrice,
    CASE 
        WHEN EXISTS (SELECT 1 FROM ClientDiscount cd 
                     JOIN Discount d ON cd.discountId = d.id 
                     WHERE cd.clientPassport = ro.clientPassport AND d.isActive = 1)
        THEN (SELECT TOP 1 d.rate 
              FROM ClientDiscount cd 
              JOIN Discount d ON cd.discountId = d.id 
              WHERE cd.clientPassport = ro.clientPassport AND d.isActive = 1)
        ELSE 0
    END as discountApplied,
    CASE 
        WHEN EXISTS (SELECT 1 FROM ClientDiscount cd 
                     JOIN Discount d ON cd.discountId = d.id 
                     WHERE cd.clientPassport = ro.clientPassport AND d.isActive = 1)
        THEN (SELECT TOP 1 d.type 
              FROM ClientDiscount cd 
              JOIN Discount d ON cd.discountId = d.id 
              WHERE cd.clientPassport = ro.clientPassport AND d.isActive = 1)
        ELSE NULL
    END as discountType
FROM RentalOrder ro;
PRINT 'Добавлено заказов: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 4. ДАННЫЕ рёбер

-- 4.1 Автомобиль → Модель
INSERT INTO OF_MODEL ($from_id, $to_id)
SELECT 
    cn.$node_id,
    mn.$node_id
FROM Car c
JOIN CarNode cn ON c.licensePlate = cn.licensePlate
JOIN Model m ON c.modelId = m.id
JOIN ModelNode mn ON m.id = mn.id;
PRINT 'Создано связей автомобиль-модель: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 4.2 Клиент → Заказ
INSERT INTO PLACES_ORDER ($from_id, $to_id)
SELECT 
    cln.$node_id,
    onode.$node_id
FROM RentalOrder ro
JOIN ClientNode cln ON ro.clientPassport = cln.passport
JOIN OrderNode onode ON ro.id = onode.id;
PRINT 'Создано связей клиент-заказ: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 4.3 Заказ → Автомобиль
INSERT INTO HAS ($from_id, $to_id, rentalCost, startDate, plannedReturnDate, 
                     actualReturnDate, rentalStatus, fineAmount, fineType)
SELECT 
    onode.$node_id,
    can.$node_id,
    r.rentalCost,
    r.startDate,
    r.plannedReturnDate,
    r.actualReturnDate,
    r.status,
    ISNULL((
        SELECT SUM(f.amount)
        FROM RentalFine rf
        JOIN Fine f ON rf.fineId = f.id
        WHERE rf.rentalId = r.id
    ), 0),
    ISNULL((
        SELECT STRING_AGG(f.type, ', ')
        FROM RentalFine rf
        JOIN Fine f ON rf.fineId = f.id
        WHERE rf.rentalId = r.id
    ), 'Нет штрафов')
FROM Rental r
JOIN RentalOrder ro ON r.rentalOrderId = ro.id
JOIN OrderNode onode ON ro.id = onode.id
JOIN CarNode can ON r.carLicensePlate = can.licensePlate;
PRINT 'Создано связей заказ-автомобиль: ' + CAST(@@ROWCOUNT AS NVARCHAR);
