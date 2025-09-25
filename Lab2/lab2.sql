use [2025_PMI_33]
IF OBJECT_ID('RentalFine', 'U') IS NOT NULL DROP TABLE RentalFine;
IF OBJECT_ID('Fine', 'U') IS NOT NULL DROP TABLE Fine;
IF OBJECT_ID('Rental', 'U') IS NOT NULL DROP TABLE Rental;
IF OBJECT_ID('ClientDiscount', 'U') IS NOT NULL DROP TABLE ClientDiscount;
IF OBJECT_ID('Discount', 'U') IS NOT NULL DROP TABLE Discount;
IF OBJECT_ID('RentalOrder', 'U') IS NOT NULL DROP TABLE RentalOrder;
IF OBJECT_ID('Car', 'U') IS NOT NULL DROP TABLE Car;
IF OBJECT_ID('Model', 'U') IS NOT NULL DROP TABLE Model;
IF OBJECT_ID('Client', 'U') IS NOT NULL DROP TABLE Client;
GO

CREATE TABLE Model (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL,
    type NVARCHAR(20) NOT NULL CHECK (type IN ('Седан', 'Внедорожник', 'Хэтчбек', 'Универсал', 'Купе', 'Минивэн')),
    manufacturer NVARCHAR(30) NOT NULL,
    dailyPrice DECIMAL(10, 2) NOT NULL CHECK (dailyPrice > 0)
);
GO

CREATE TABLE Car (
    licensePlate NVARCHAR(15) PRIMARY KEY,
    year INT NOT NULL CHECK (year BETWEEN 1990 AND YEAR(GETDATE())),
    color NVARCHAR(20),
    condition NVARCHAR(20) NOT NULL CHECK (condition IN ('Идеальное', 'Хорошее', 'Удовлетворительное', 'Плохое')),
    modelId INT NOT NULL FOREIGN KEY REFERENCES Model(id) ON DELETE CASCADE
);
GO

CREATE TABLE Client (
    passport NVARCHAR(20) PRIMARY KEY,
    fullName NVARCHAR(100) NOT NULL,
    address NVARCHAR(200),
    phone NVARCHAR(20) NOT NULL 
);
GO

CREATE TABLE Discount (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL,
    description NVARCHAR(200),
    rate DECIMAL(5, 2) NOT NULL CHECK (rate > 0),
    type NVARCHAR(20) NOT NULL CHECK (type IN ('Процент', 'Фиксированная')),
    isActive BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE RentalOrder (
    id INT IDENTITY(1,1) PRIMARY KEY,
    createDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    status NVARCHAR(20) NOT NULL CHECK (status IN ('Создан', 'Подтвержден', 'Активен', 'Завершен', 'Отменен')),
    totalPrice DECIMAL(10, 2) CHECK (totalPrice >= 0),
    clientPassport NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES Client(passport) ON DELETE CASCADE
);
GO

CREATE TABLE Rental (
    id INT IDENTITY(1,1) PRIMARY KEY,
    startDate DATETIME2 NOT NULL,
    plannedReturnDate DATETIME2 NOT NULL,
    actualReturnDate DATETIME2 NULL,
    rentalCost DECIMAL(10, 2) CHECK (rentalCost >= 0),
    status NVARCHAR(20) NOT NULL CHECK (status IN ('Активна', 'Завершена', 'Отменена')),
    carLicensePlate NVARCHAR(15) NOT NULL FOREIGN KEY REFERENCES Car(licensePlate) ON DELETE CASCADE,
    rentalOrderId INT NOT NULL FOREIGN KEY REFERENCES RentalOrder(id) ON DELETE CASCADE,
    -- plannedReturnDate должен быть после startDate
    CONSTRAINT CHK_Rental_Dates CHECK (plannedReturnDate > startDate AND (actualReturnDate IS NULL OR actualReturnDate >= startDate))
);
GO


CREATE TABLE Fine (
    id INT IDENTITY(1,1) PRIMARY KEY,
    type NVARCHAR(50) NOT NULL CHECK (type IN ('Просрочка', 'Повреждение', 'Загрязнение')),
    description NVARCHAR(200),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0)
);
GO

CREATE TABLE RentalFine (
    rentalId INT NOT NULL FOREIGN KEY REFERENCES Rental(id) ON DELETE CASCADE,
    fineId INT NOT NULL FOREIGN KEY REFERENCES Fine(id) ON DELETE CASCADE,
    PRIMARY KEY (rentalId, fineId)
);
GO

CREATE TABLE ClientDiscount (
    clientPassport NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES Client(passport) ON DELETE CASCADE,
    discountId INT NOT NULL FOREIGN KEY REFERENCES Discount(id) ON DELETE CASCADE,
    PRIMARY KEY (clientPassport, discountId)
);
GO

-- ВСТАВКА ТЕСТОВЫХ ДАННЫХ

INSERT INTO Model (name, type, manufacturer, dailyPrice) VALUES
('Camry', 'Седан', 'Toyota', 2500.00),
('RAV4', 'Внедорожник', 'Toyota', 3000.00),
('Solaris', 'Седан', 'Hyundai', 2000.00),
('Creta', 'Внедорожник', 'Hyundai', 2800.00),
('X5', 'Внедорожник', 'BMW', 6000.00),
('Logan', 'Седан', 'Renault', 1800.00);
GO

INSERT INTO Car (licensePlate, year, color, condition, modelId) VALUES
('А123АА777', 2022, 'Белый', 'Идеальное', 1),
('В456ВВ777', 2023, 'Черный', 'Идеальное', 2),
('С789СС777', 2021, 'Серый', 'Хорошее', 3),
('Е000ЕЕ777', 2020, 'Красный', 'Удовлетворительное', 4),
('Х999ХХ777', 2023, 'Синий', 'Идеальное', 5),
('М111ММ777', 2019, 'Зеленый', 'Плохое', 6);
GO

INSERT INTO Client (passport, fullName, address, phone) VALUES
('4510 123456', 'Иванов Иван Иванович', 'г. Москва, ул. Ленина, д. 1', '+7 (999) 123-45-67'),
('4510 654321', 'Петров Петр Петрович', 'г. Санкт-Петербург, Невский пр-т, д. 10', '+7 (999) 765-43-21'),
('4510 111111', 'Сидорова Анна Сергеевна', 'г. Казань, ул. Баумана, д. 5', '+7 (999) 111-11-11'),
('4510 222222', 'Кузнецов Дмитрий Алексеевич', 'г. Екатеринбург, ул. Малышева, д. 15', '+7 (999) 222-22-22');
GO

INSERT INTO Discount (name, description, rate, type, isActive) VALUES
('Приветственная', 'Скидка для новых клиентов', 0.05, 'Процент', 1),
('Постоянный клиент', 'Для клиентов с 3+ арендами', 0.10, 'Процент', 1),
('Зимняя акция', 'Специальное предложение на зимние месяцы', 0.15, 'Процент', 0),
('Фикc скидка', 'Скидка на дорогие модели', 0.01, 'Фиксированная', 1);
GO

INSERT INTO RentalOrder (createDate, status, totalPrice, clientPassport) VALUES
('2024-01-15 10:00:00', 'Завершен', 15000.00, '4510 123456'),
('2024-02-20 14:30:00', 'Завершен', 24000.00, '4510 123456'),
('2024-03-10 09:15:00', 'Активен', NULL, '4510 654321'),
('2024-03-12 16:45:00', 'Подтвержден', NULL, '4510 111111');
GO

INSERT INTO Rental (startDate, plannedReturnDate, actualReturnDate, rentalCost, status, carLicensePlate, rentalOrderId) VALUES
('2024-01-15 10:00:00', '2024-01-20 10:00:00', '2024-01-20 09:30:00', 15000.00, 'Завершена', 'А123АА777', 1),
('2024-02-20 14:30:00', '2024-02-28 14:30:00', '2024-02-28 15:15:00', 24000.00, 'Завершена', 'В456ВВ777', 2),
('2024-03-10 09:15:00', '2024-03-15 09:15:00', NULL, 12000.00, 'Активна', 'С789СС777', 3)
GO

INSERT INTO Fine (type, description, amount) VALUES
('Просрочка', 'Возврат автомобиля с опозданием', 1000.00),
('Повреждение', 'Царапина на бампере', 5000.00),
('Загрязнение', 'Сильное загрязнение салона', 2000.00);
GO

INSERT INTO RentalFine (rentalId, fineId) VALUES
(2, 1); -- Петров вернул машину с опозданием
GO

INSERT INTO ClientDiscount (clientPassport, discountId) VALUES
('4510 123456', 2); -- Иванов стал постоянным клиентом
GO

SELECT * FROM Model;
SELECT * FROM Car;
SELECT * FROM Client;
SELECT * FROM Discount;
SELECT * FROM RentalOrder;
SELECT * FROM Rental;
SELECT * FROM Fine;
SELECT * FROM RentalFine;
SELECT * FROM ClientDiscount;