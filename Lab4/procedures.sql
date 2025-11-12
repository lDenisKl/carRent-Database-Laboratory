
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

EXEC GetCarRentalClients @carLicensePlate = 'А001АА777';

---------

DROP PROCEDURE GetModelPopularityRating;

CREATE PROCEDURE GetModelPopularityRating
    @modelName NVARCHAR(50),
    @popularityRating DECIMAL(10,2) OUTPUT
AS
BEGIN
    DECLARE @totalRentals INT;
    DECLARE @totalDays INT;
    DECLARE @modelId INT;

    SELECT @modelId = id FROM Model WHERE name = @modelName;

    IF @modelId IS NOT NULL
    BEGIN
        -- Считаем общее количество аренд и дней аренды для модели
        SELECT 
            @totalRentals = COUNT(r.id),
            @totalDays = SUM(DATEDIFF(DAY, r.startDate, 
                CASE WHEN r.actualReturnDate IS NOT NULL THEN r.actualReturnDate 
                     ELSE r.plannedReturnDate END))
        FROM Rental r
        JOIN Car c ON r.carLicensePlate = c.licensePlate
        WHERE c.modelId = @modelId
          AND r.status IN ('Завершена', 'Активна');

        --  рейтинг популярности (аренды * дни)
        SET @popularityRating = ISNULL(@totalRentals, 0) * ISNULL(@totalDays, 0);
    END
    ELSE
    BEGIN
        SET @popularityRating = 0;
    END
END;

DECLARE @rating DECIMAL(10,2);
EXEC GetModelPopularityRating @modelName = 'Corolla', @popularityRating = @rating OUTPUT;
SELECT @rating AS 'Рейтинг популярности';

--------

DROP PROCEDURE FindMostExpensiveRental;
DROP PROCEDURE GetMostExpensiveRentalDetails;


CREATE PROCEDURE FindMostExpensiveRental
    @maxRentalCost DECIMAL(10,2) OUTPUT,
    @rentalOrderId INT OUTPUT
AS
BEGIN
    SELECT TOP 1 
        @maxRentalCost = r.rentalCost,
        @rentalOrderId = r.rentalOrderId
    FROM Rental r
    WHERE r.rentalCost IS NOT NULL
      AND r.status = 'Завершена'
    ORDER BY r.rentalCost DESC;
END;

CREATE PROCEDURE GetMostExpensiveRentalDetails
AS
BEGIN
    DECLARE @maxCost DECIMAL(10,2);
    DECLARE @orderId INT;

    EXEC FindMostExpensiveRental @maxCost OUTPUT, @orderId OUTPUT;

    IF @orderId IS NOT NULL
    BEGIN
        SELECT 
            cl.fullName,
            m.name,
            m.manufacturer,
            r.rentalCost,
            r.startDate,
            r.plannedReturnDate
        FROM Rental r
        JOIN RentalOrder ro ON r.rentalOrderId = ro.id
        JOIN Client cl ON ro.clientPassport = cl.passport
        JOIN Car c ON r.carLicensePlate = c.licensePlate
        JOIN Model m ON c.modelId = m.id
        WHERE r.rentalOrderId = @orderId;
    END
    ELSE
    BEGIN
        PRINT 'Не найдено завершенных аренд с указанной стоимостью.';
    END
END;


EXEC GetMostExpensiveRentalDetails;