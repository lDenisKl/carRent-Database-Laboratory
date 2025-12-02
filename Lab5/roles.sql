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
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Model TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Car TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Client TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Discount TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.RentalOrder TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Rental TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Fine TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.RentalFine TO ManagerRole WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ClientDiscount TO ManagerRole WITH GRANT OPTION;

 GRANT EXECUTE ON dbo.GetAvailableSUVs TO ManagerRole WITH GRANT OPTION;
 GRANT EXECUTE ON dbo.GetCarRentalClients TO ManagerRole WITH GRANT OPTION;
 GRANT EXECUTE ON dbo.GetModelPopularityRating TO ManagerRole WITH GRANT OPTION;

GRANT CREATE TABLE, CREATE PROCEDURE, CREATE VIEW TO ManagerRole;

GRANT ALTER ON SCHEMA::dbo TO ManagerRole;

-- ПРАВА СОТРУДНИКА
GRANT SELECT ON dbo.Model TO EmployeeRole;
GRANT SELECT ON dbo.Car TO EmployeeRole;
GRANT SELECT ON dbo.Discount TO EmployeeRole;

-- Может работать с клиентами
GRANT SELECT, INSERT, UPDATE ON dbo.Client TO EmployeeRole;
DENY DELETE ON dbo.Client TO EmployeeRole;

-- Может работать с заказами
GRANT SELECT, INSERT, UPDATE ON dbo.RentalOrder TO EmployeeRole;
DENY DELETE ON dbo.RentalOrder TO EmployeeRole;

-- Может работать с арендами
GRANT SELECT, INSERT, UPDATE ON dbo.Rental TO EmployeeRole;
DENY DELETE ON dbo.Rental TO EmployeeRole;

-- нет доступа к финансам
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Fine TO EmployeeRole;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.RentalFine TO EmployeeRole;

-- Может только просматривать связи клиент-скидка
GRANT SELECT ON dbo.ClientDiscount TO EmployeeRole;
DENY INSERT, UPDATE, DELETE ON dbo.ClientDiscount TO EmployeeRole;

 GRANT EXECUTE ON dbo.GetAvailableSUVs TO EmployeeRole;
 GRANT EXECUTE ON dbo.GetModelPopularityRating TO EmployeeRole;

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
REVOKE DELETE ON dbo.Rental FROM EmployeeRole;
REVOKE EXECUTE ON dbo.sp_CreateNewRentalOrder FROM EmployeeRole;
DENY SELECT ON dbo.Fine TO EmployeeRole;
DENY SELECT ON dbo.RentalFine TO EmployeeRole;
---------