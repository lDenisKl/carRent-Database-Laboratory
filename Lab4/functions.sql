CREATE OR ALTER FUNCTION dbo.GetAverageRentalsPerDay()
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @AvgRentals DECIMAL(10,2);
    
    SELECT @AvgRentals = CAST(COUNT(*) AS DECIMAL(10,2)) / 
                         NULLIF(COUNT(DISTINCT CAST(startDate AS DATE)), 0)
    FROM Rental
    WHERE status IN ('Завершена', 'Активна');
    
    RETURN ISNULL(@AvgRentals, 0);
END;

CREATE OR ALTER FUNCTION dbo.GetCurrentlyRentedCars()
RETURNS TABLE
AS
RETURN
    SELECT 
        c.licensePlate,
        m.name,
        m.type,
        cl.fullName,
        r.plannedReturnDate
    FROM Rental r
    JOIN Car c ON r.carLicensePlate = c.licensePlate
    JOIN Model m ON c.modelId = m.id
    JOIN RentalOrder ro ON r.rentalOrderId = ro.id
    JOIN Client cl ON ro.clientPassport = cl.passport
    WHERE r.status = 'Активна'
      AND r.actualReturnDate IS NULL;


CREATE OR ALTER FUNCTION dbo.GetRevenueByMonth(@Year INT)
RETURNS @RevenueTable TABLE
(
    MonthNumber INT,
    Revenue DECIMAL(15,2),
    RentalCount INT,
    AverageRentalPrice DECIMAL(10,2)
)
AS
BEGIN
    INSERT INTO @RevenueTable
    SELECT 
        MONTH(r.startDate) AS MonthNumber,
        SUM(ISNULL(r.rentalCost, 0)) AS Revenue,
        COUNT(*) AS RentalCount,
        AVG(ISNULL(r.rentalCost, 0)) AS AverageRentalPrice
    FROM Rental r
    WHERE YEAR(r.startDate) = @Year
      AND r.status IN ('Завершена', 'Активна')
    GROUP BY MONTH(r.startDate)
    ORDER BY MonthNumber;
    
    RETURN;
END;




SELECT dbo.GetAverageRentalsPerDay() AS 'Среднее количество сделок в день';

SELECT * FROM dbo.GetCurrentlyRentedCars();

SELECT * FROM dbo.GetRevenueByMonth(2025);