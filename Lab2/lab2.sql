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
    type NVARCHAR(20) NOT NULL CHECK (type IN ('�����', '�����������', '�������', '���������', '����', '�������')),
    manufacturer NVARCHAR(30) NOT NULL,
    dailyPrice DECIMAL(10, 2) NOT NULL CHECK (dailyPrice > 0)
);
GO

CREATE TABLE Car (
    licensePlate NVARCHAR(15) PRIMARY KEY,
    year INT NOT NULL CHECK (year BETWEEN 1990 AND YEAR(GETDATE())),
    color NVARCHAR(20),
    condition NVARCHAR(20) NOT NULL CHECK (condition IN ('���������', '�������', '������������������', '������')),
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
    type NVARCHAR(20) NOT NULL CHECK (type IN ('�������', '�������������')),
    isActive BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE RentalOrder (
    id INT IDENTITY(1,1) PRIMARY KEY,
    createDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    status NVARCHAR(20) NOT NULL CHECK (status IN ('������', '�����������', '�������', '��������', '�������')),
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
    status NVARCHAR(20) NOT NULL CHECK (status IN ('�������', '���������', '��������')),
    carLicensePlate NVARCHAR(15) NOT NULL FOREIGN KEY REFERENCES Car(licensePlate) ON DELETE CASCADE,
    rentalOrderId INT NOT NULL FOREIGN KEY REFERENCES RentalOrder(id) ON DELETE CASCADE,
    -- plannedReturnDate ������ ���� ����� startDate
    CONSTRAINT CHK_Rental_Dates CHECK (plannedReturnDate > startDate AND (actualReturnDate IS NULL OR actualReturnDate >= startDate))
);
GO


CREATE TABLE Fine (
    id INT IDENTITY(1,1) PRIMARY KEY,
    type NVARCHAR(50) NOT NULL CHECK (type IN ('���������', '�����������', '�����������')),
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

-- ������� �������� ������

INSERT INTO Model (name, type, manufacturer, dailyPrice) VALUES
('Camry', '�����', 'Toyota', 2500.00),
('RAV4', '�����������', 'Toyota', 3000.00),
('Solaris', '�����', 'Hyundai', 2000.00),
('Creta', '�����������', 'Hyundai', 2800.00),
('X5', '�����������', 'BMW', 6000.00),
('Logan', '�����', 'Renault', 1800.00);
GO

INSERT INTO Car (licensePlate, year, color, condition, modelId) VALUES
('�123��777', 2022, '�����', '���������', 1),
('�456��777', 2023, '������', '���������', 2),
('�789��777', 2021, '�����', '�������', 3),
('�000��777', 2020, '�������', '������������������', 4),
('�999��777', 2023, '�����', '���������', 5),
('�111��777', 2019, '�������', '������', 6);
GO

INSERT INTO Client (passport, fullName, address, phone) VALUES
('4510 123456', '������ ���� ��������', '�. ������, ��. ������, �. 1', '+7 (999) 123-45-67'),
('4510 654321', '������ ���� ��������', '�. �����-���������, ������� ��-�, �. 10', '+7 (999) 765-43-21'),
('4510 111111', '�������� ���� ���������', '�. ������, ��. �������, �. 5', '+7 (999) 111-11-11'),
('4510 222222', '�������� ������� ����������', '�. ������������, ��. ��������, �. 15', '+7 (999) 222-22-22');
GO

INSERT INTO Discount (name, description, rate, type, isActive) VALUES
('��������������', '������ ��� ����� ��������', 0.05, '�������', 1),
('���������� ������', '��� �������� � 3+ ��������', 0.10, '�������', 1),
('������ �����', '����������� ����������� �� ������ ������', 0.15, '�������', 0),
('���c ������', '������ �� ������� ������', 0.01, '�������������', 1);
GO

INSERT INTO RentalOrder (createDate, status, totalPrice, clientPassport) VALUES
('2024-01-15 10:00:00', '��������', 15000.00, '4510 123456'),
('2024-02-20 14:30:00', '��������', 24000.00, '4510 123456'),
('2024-03-10 09:15:00', '�������', NULL, '4510 654321'),
('2024-03-12 16:45:00', '�����������', NULL, '4510 111111');
GO

INSERT INTO Rental (startDate, plannedReturnDate, actualReturnDate, rentalCost, status, carLicensePlate, rentalOrderId) VALUES
('2024-01-15 10:00:00', '2024-01-20 10:00:00', '2024-01-20 09:30:00', 15000.00, '���������', '�123��777', 1),
('2024-02-20 14:30:00', '2024-02-28 14:30:00', '2024-02-28 15:15:00', 24000.00, '���������', '�456��777', 2),
('2024-03-10 09:15:00', '2024-03-15 09:15:00', NULL, 12000.00, '�������', '�789��777', 3)
GO

INSERT INTO Fine (type, description, amount) VALUES
('���������', '������� ���������� � ����������', 1000.00),
('�����������', '�������� �� �������', 5000.00),
('�����������', '������� ����������� ������', 2000.00);
GO

INSERT INTO RentalFine (rentalId, fineId) VALUES
(2, 1); -- ������ ������ ������ � ����������
GO

INSERT INTO ClientDiscount (clientPassport, discountId) VALUES
('4510 123456', 2); -- ������ ���� ���������� ��������
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