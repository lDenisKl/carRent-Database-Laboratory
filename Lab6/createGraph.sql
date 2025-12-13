
-- 1. СОЗДАНИЕ ГРАФОВЫХ ТАБЛИЦ

-- Узлы
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

CREATE TABLE DiscountNode (
    id INT PRIMARY KEY,
    name NVARCHAR(50),
    description NVARCHAR(200),
    rate DECIMAL(10,2),
    type NVARCHAR(20),
    isActive BIT
) AS NODE;

CREATE TABLE OrderNode (
    id INT PRIMARY KEY,
    createDate DATETIME2,
    status NVARCHAR(20),
    totalPrice DECIMAL(10,2)
) AS NODE;

CREATE TABLE FineNode (
    id INT PRIMARY KEY,
    type NVARCHAR(50),
    description NVARCHAR(200),
    amount DECIMAL(10,2)
) AS NODE;

-- Рёбра
CREATE TABLE RENTED (
    rentalCost DECIMAL(10,2),
    startDate DATETIME2,
    plannedReturnDate DATETIME2,
    actualReturnDate DATETIME2,
    status NVARCHAR(20)
) AS EDGE;

CREATE TABLE HAS_MODEL AS EDGE;
CREATE TABLE HAS_DISCOUNT AS EDGE;
CREATE TABLE ORDER_CONTAINS_CAR AS EDGE;
CREATE TABLE ORDER_HAS_FINE AS EDGE;
CREATE TABLE ORDER_USES_DISCOUNT AS EDGE;

-- 2. ЗАПОЛНЕНИЕ УЗЛОВ ДАННЫМИ

INSERT INTO ClientNode (passport, fullName, address, phone)
SELECT passport, fullName, address, phone FROM Client;

PRINT 'Заполнено клиентов: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO CarNode (licensePlate, year, color, condition)
SELECT licensePlate, year, color, condition FROM Car;

PRINT 'Заполнено автомобилей: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO ModelNode (id, name, type, manufacturer, dailyPrice)
SELECT id, name, type, manufacturer, dailyPrice FROM Model;

PRINT 'Заполнено моделей: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO DiscountNode (id, name, description, rate, type, isActive)
SELECT id, name, description, rate, type, isActive FROM Discount;

PRINT 'Заполнено скидок: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO OrderNode (id, createDate, status, totalPrice)
SELECT id, createDate, status, totalPrice FROM RentalOrder;

PRINT 'Заполнено заказов: ' + CAST(@@ROWCOUNT AS NVARCHAR);

INSERT INTO FineNode (id, type, description, amount)
SELECT id, type, description, amount FROM Fine;

PRINT 'Заполнено штрафов: ' + CAST(@@ROWCOUNT AS NVARCHAR);


-- 3. ЗАПОЛНЕНИЕ РЁБЕР ДАННЫМИ

-- 3.1 Рёбра HAS_MODEL: Автомобиль → Модель
INSERT INTO HAS_MODEL ($from_id, $to_id)
SELECT 
    cn.$node_id,  -- из узла автомобиля
    mn.$node_id   -- в узел модели
FROM Car c
JOIN CarNode cn ON c.licensePlate = cn.licensePlate
JOIN Model m ON c.modelId = m.id
JOIN ModelNode mn ON m.id = mn.id;

PRINT 'Создано связей автомобиль-модель: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 3.2 Рёбра RENTED: Клиент → Автомобиль (через Rental)
INSERT INTO RENTED ($from_id, $to_id, rentalCost, startDate, plannedReturnDate, actualReturnDate, status)
SELECT 
    cln.$node_id,  -- из узла клиента
    can.$node_id,  -- в узел автомобиля
    r.rentalCost,
    r.startDate,
    r.plannedReturnDate,
    r.actualReturnDate,
    r.status
FROM Rental r
JOIN RentalOrder ro ON r.rentalOrderId = ro.id
JOIN Client cl ON ro.clientPassport = cl.passport
JOIN ClientNode cln ON cl.passport = cln.passport
JOIN Car ca ON r.carLicensePlate = ca.licensePlate
JOIN CarNode can ON ca.licensePlate = can.licensePlate;

PRINT 'Создано связей аренд: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 3.3 Рёбра HAS_DISCOUNT: Клиент → Скидка
INSERT INTO HAS_DISCOUNT ($from_id, $to_id)
SELECT 
    cln.$node_id,  -- из узла клиента
    dn.$node_id    -- в узел скидки
FROM ClientDiscount cd
JOIN Client cl ON cd.clientPassport = cl.passport
JOIN ClientNode cln ON cl.passport = cln.passport
JOIN Discount d ON cd.discountId = d.id
JOIN DiscountNode dn ON d.id = dn.id;

PRINT 'Создано связей клиент-скидка: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 3.4 Рёбра ORDER_CONTAINS_CAR: Заказ → Автомобиль (через Rental)
INSERT INTO ORDER_CONTAINS_CAR ($from_id, $to_id)
SELECT DISTINCT
    onode.$node_id,  -- из узла заказа
    can.$node_id     -- в узел автомобиля
FROM RentalOrder ro
JOIN OrderNode onode ON ro.id = onode.id
JOIN Rental r ON ro.id = r.rentalOrderId
JOIN Car ca ON r.carLicensePlate = ca.licensePlate
JOIN CarNode can ON ca.licensePlate = can.licensePlate;

PRINT 'Создано связей заказ-автомобиль: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 3.5 Рёбра ORDER_HAS_FINE: Заказ → Штраф (через RentalFine)
INSERT INTO ORDER_HAS_FINE ($from_id, $to_id)
SELECT DISTINCT
    onode.$node_id, 
    fn.$node_id      
FROM RentalFine rf
JOIN Rental r ON rf.rentalId = r.id
JOIN RentalOrder ro ON r.rentalOrderId = ro.id
JOIN OrderNode onode ON ro.id = onode.id
JOIN Fine f ON rf.fineId = f.id
JOIN FineNode fn ON f.id = fn.id;

PRINT 'Создано связей заказ-штраф: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- 3.6 Рёбра ORDER_USES_DISCOUNT: Заказ → Скидкаы
INSERT INTO ORDER_USES_DISCOUNT ($from_id, $to_id)
SELECT 
    onode.$node_id,
    dn.$node_id
FROM RentalOrder ro
JOIN OrderNode onode ON ro.id = onode.id
JOIN ClientDiscount cd ON ro.clientPassport = cd.clientPassport
JOIN DiscountNode dn ON cd.discountId = dn.id;

