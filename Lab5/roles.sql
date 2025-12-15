USE [Cars1];
GO

-- СОЗДАНИЕ РОЛЕЙ
-- для руководителя
CREATE ROLE ManagerRole;
GO

-- для сотрудника
CREATE ROLE EmployeeRole;
GO

-----------------
-- ПРАВА РУКОВОДИТЕЛЯ 
GRANT SELECT ON dbo.Model TO ManagerRole WITH GRANT OPTION;
GRANT SELECT ON Car TO ManagerRole WITH GRANT OPTION;
GRANT SELECT ON Client TO ManagerRole WITH GRANT OPTION;
GRANT SELECT ON Discount TO ManagerRole WITH GRANT OPTION;
GRANT SELECT ON ClientDiscount TO ManagerRole WITH GRANT OPTION;

GRANT SELECT, INSERT, UPDATE ON RentalOrder TO ManagerRole WITH GRANT OPTION;
DENY DELETE ON RentalOrder TO ManagerRole;

GRANT SELECT, INSERT, UPDATE ON Rental TO ManagerRole  WITH GRANT OPTION;
DENY DELETE ON Rental TO ManagerRole;

GRANT SELECT ON Fine TO ManagerRole  WITH GRANT OPTION;
DENY INSERT, UPDATE, DELETE ON Fine TO ManagerRole;

GRANT SELECT ON RentalFine TO ManagerRole  WITH GRANT OPTION;
DENY INSERT, UPDATE, DELETE ON RentalFine TO ManagerRole;

GRANT EXECUTE ON GetAvailableSUVs TO ManagerRole  WITH GRANT OPTION;
GRANT EXECUTE ON GetCarRentalClients TO ManagerRole  WITH GRANT OPTION;
GRANT EXECUTE ON GetModelPopularityRating TO ManagerRole  WITH GRANT OPTION;

GRANT EXECUTE ON GetAverageRentalsPerDay TO ManagerRole;
GRANT SELECT ON GetCurrentlyRentedCars TO ManagerRole;
GRANT SELECT ON GetRevenueByMonth TO ManagerRole;

-----------------
-- ПРАВА СОТРУДНИКА
GRANT SELECT ON Model TO EmployeeRole;
GRANT SELECT ON Car TO EmployeeRole;
GRANT SELECT ON Discount TO EmployeeRole;

-- Может работать с клиентами
GRANT SELECT, INSERT, UPDATE ON Client TO EmployeeRole;
DENY DELETE ON Client TO EmployeeRole;

-- Может работать с заказами
GRANT SELECT, INSERT, UPDATE ON RentalOrder TO EmployeeRole;
DENY DELETE ON RentalOrder TO EmployeeRole;

-- Может работать с арендами
GRANT SELECT, INSERT, UPDATE ON Rental TO EmployeeRole;
DENY DELETE ON Rental TO EmployeeRole;

-- Нет доступа к финансам
DENY SELECT, INSERT, UPDATE, DELETE ON Fine TO EmployeeRole;
DENY SELECT, INSERT, UPDATE, DELETE ON RentalFine TO EmployeeRole;

-- Может только просматривать связи клиент-скидка
GRANT SELECT ON ClientDiscount TO EmployeeRole;
DENY INSERT, UPDATE, DELETE ON ClientDiscount TO EmployeeRole;

GRANT EXECUTE ON GetAvailableSUVs TO EmployeeRole;
GRANT EXECUTE ON GetModelPopularityRating TO EmployeeRole;

GRANT EXECUTE ON GetAverageRentalsPerDay TO EmployeeRole;
GRANT SELECT ON GetCurrentlyRentedCars TO EmployeeRole;
DENY SELECT ON GetRevenueByMonth TO EmployeeRole;



 -- СОЗДАНИЕ ПОЛЬЗОВАТЕЛЕЙ

USE [master];
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'User_d.kolodochka')
BEGIN
    CREATE LOGIN [User_d.kolodochka] WITH PASSWORD = '1234567',
    DEFAULT_DATABASE = [Cars1],
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = OFF;
END

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'User1_d.kolodochka')
BEGIN
    CREATE LOGIN [User1_d.kolodochka] WITH PASSWORD = '1234567',
    DEFAULT_DATABASE = [Cars1],
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = OFF;
END

USE [Cars1];
GO

-- пользователи в базе данных
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'User_d.kolodochka')
BEGIN
    CREATE USER [User_d.kolodochka] FOR LOGIN [User_d.kolodochka];
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'User1_d.kolodochka')
BEGIN
    CREATE USER [User1_d.kolodochka] FOR LOGIN [User1_d.kolodochka];
END

-- Добавляем пользователей в роли
ALTER ROLE ManagerRole ADD MEMBER [User_d.kolodochka];
ALTER ROLE EmployeeRole ADD MEMBER [User1_d.kolodochka];
GO



---------
REVOKE DELETE ON Rental FROM EmployeeRole;
REVOKE EXECUTE ON sp_CreateNewRentalOrder FROM EmployeeRole;
DENY SELECT ON Fine TO EmployeeRole;
DENY SELECT ON RentalFine TO EmployeeRole;
REVOKE SELECT ON dbo.Fine FROM EmployeeRole;
---------


USE [Cars1];
GO

-- Пытаемся выполнить от User1
REVOKE SELECT ON dbo.Fine FROM [User1_d.kolodochka];
SELECT * FROM Fine;
Revert;

REVOKE SELECT ON dbo.Fine To [User_d.kolodochka]


-- Передаём права и пробуем еще раз
GRANT SELECT ON dbo.Fine TO [User1_d.kolodochka] as ManagerRole;

REVOKE SELECT ON dbo.Fine FROM [User1_d.kolodochka] as ManagerRole;

REVOKE GRANT OPTION FOR SELECT ON dbo.Fine FROM ManagerRole CASCADE

-- УДАЛЕНИЕ РОЛЕЙ И ПОЛЬЗОВАТЕЛЕЙ
USE [Cars1];
GO
ALTER ROLE ManagerRole DROP MEMBER [User_d.kolodochka];
ALTER ROLE EmployeeRole DROP MEMBER [User1_d.kolodochka];
GO
DROP ROLE IF EXISTS ManagerRole;
DROP ROLE IF EXISTS EmployeeRole;
GO
DROP USER IF EXISTS [User_d.kolodochka];
DROP USER IF EXISTS [User1_d.kolodochka];
GO
USE [master];
GO
DROP LOGIN IF EXISTS [User_d.kolodochka];
DROP LOGIN IF EXISTS [User1_d.kolodochka];
GO
