
DROP PROCEDURE GetAvailableSUVs;
CREATE PROCEDURE GetAvailableSUVs
AS
BEGIN    
    SELECT 
        *
    FROM Car c
    JOIN Model m ON c.modelId = m.id
    WHERE m.type = 'Внедорожник'
      AND c.year >= YEAR(GETDATE()) - 5
      AND c.licensePlate NOT IN (
          SELECT r.carLicensePlate 
          FROM Rental r 
          WHERE r.status = 'Активна'
      );
END;

EXEC GetAvailableSUVs;

---------

DROP PROCEDURE GetCarRentalClients;

CREATE PROCEDURE GetCarRentalClients
    @carLicensePlate NVARCHAR(15)
AS
BEGIN
    SELECT DISTINCT
        cl.passport
    FROM Rental r
    JOIN RentalOrder ro ON r.rentalOrderId = ro.id
    JOIN Client cl ON ro.clientPassport = cl.passport
    WHERE r.carLicensePlate = @carLicensePlate
      AND r.status IN ('Завершена', 'Активна');
END;

EXEC GetCarRentalClients @carLicensePlate = 'А001АИ777';

---------

DROP PROCEDURE IF EXISTS GetModelPopularityRating;

CREATE OR ALTER PROCEDURE GetModelPopularityRating
    @modelName NVARCHAR(50),
    @rankPosition INT OUTPUT
AS
BEGIN    
    WITH ModelRanks AS (
        SELECT 
            m.name,
            RANK() OVER (ORDER BY 
                COUNT(r.id) * ISNULL(SUM(DATEDIFF(DAY, r.startDate, 
                    ISNULL(r.actualReturnDate, r.plannedReturnDate))), 0) 
                DESC) as position
        FROM Model m
        LEFT JOIN Car c ON m.id = c.modelId
        LEFT JOIN Rental r ON c.licensePlate = r.carLicensePlate 
            AND r.status IN ('Завершена', 'Активна')
        GROUP BY m.name
    )
    
    SELECT @rankPosition = position
    FROM ModelRanks 
    WHERE name = @modelName;
    
    IF @rankPosition IS NULL
        SET @rankPosition = 0;
END;

DECLARE @position INT;
EXEC GetModelPopularityRating @modelName = 'RAV4', @rankPosition = @position OUTPUT;
SELECT @position AS 'Место в рейтинге';

--------

DROP PROCEDURE FindMostExpensiveRental;
DROP PROCEDURE GetMostExpensiveRentalDetails;


CREATE OR ALTER PROCEDURE FindMostExpensiveRental
    @rentalOrderId INT OUTPUT
AS
BEGIN
    SELECT TOP 1 
        @rentalOrderId = r.rentalOrderId
    FROM Rental r
    WHERE r.rentalCost IS NOT NULL
      AND r.status = 'Завершена'
    ORDER BY r.rentalCost DESC;
END;

CREATE Or ALTER PROCEDURE GetMostExpensiveRentalDetails
AS
BEGIN
    DECLARE @orderId INT;

    EXEC FindMostExpensiveRental @orderId OUTPUT;

    SELECT 
        cl.fullName,
        m.name,
        m.manufacturer,
        r.rentalCost,
        r.startDate,
        r.actualReturnDate
    FROM Rental r
    JOIN RentalOrder ro ON r.rentalOrderId = ro.id
    JOIN Client cl ON ro.clientPassport = cl.passport
    JOIN Car c ON r.carLicensePlate = c.licensePlate
    JOIN Model m ON c.modelId = m.id
    WHERE r.rentalOrderId = @orderId;
END;


EXEC GetMostExpensiveRentalDetails;