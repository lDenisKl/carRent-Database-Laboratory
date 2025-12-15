USE [Cars1];
GO

-- Добавляем маскирование для номера телефона
ALTER TABLE Client
ALTER COLUMN phone ADD MASKED WITH (FUNCTION = 'partial(3,"XXX-XXX-",5)');

-- Добавляем маскирование для паспорта
ALTER TABLE Client
ALTER COLUMN passport ADD MASKED WITH (FUNCTION = 'default()');

--сбросить
--ALTER TABLE Client
--ALTER COLUMN address DROP MASKED;

REVOKE UNMASK TO ManagerRole;
GRANT UNMASK ON OBJECT::dbo.Client([phone]) TO ManagerRole;
GO

EXECUTE AS USER = 'User1_d.kolodochka';
SELECT * FROM Client
--REVERT

REVOKE SELECT ON Client FROM EmployeeRole;

CREATE OR ALTER PROCEDURE ShowClients
AS
BEGIN
    IF IS_ROLEMEMBER('ManagerRole') = 1
    BEGIN
        SELECT 
            passport,
            fullName,
            address,
            phone
        FROM Client;
    END
    ELSE
    BEGIN
        SELECT 
            passport,
            fullName,
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                address,
            '0', '*'), '1', '*'), '2', '*'), '3', '*'), '4', '*'),
            '5', '*'), '6', '*'), '7', '*'), '8', '*'), '9', '*') 
            AS masked_address,
            phone
        FROM Client;
    END
END;
GO

-- Даем доступ всем ролям к процедуре
GRANT EXECUTE ON ShowClients TO ManagerRole, EmployeeRole;


EXECUTE AS USER = 'User_d.kolodochka';
EXEC ShowClients;
REVERT;
GO

EXECUTE AS USER = 'User1_d.kolodochka';
EXEC ShowClients;
REVERT;