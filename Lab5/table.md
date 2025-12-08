# Таблица прав доступа для ролей

---

## Сводная таблица прав

| Объект базы данных | ManagerRole (Руководитель) | EmployeeRole (Сотрудник)
|-------------------|---------------------------|--------------------------
| **ТАБЛИЦЫ** | | | |
| `dbo.Model` | ✅ SELECT | ✅ SELECT
| `dbo.Car` | ✅ SELECT | ✅ SELECT 
| `dbo.Client` | ✅ SELECT | ✅SELECT/INSERT/UPDATE<br>❌ DELETE
| `dbo.Discount` | ✅ SELECT  | ✅ SELECT
| `dbo.RentalOrder` | ✅SELECT/INSERT/UPDATE ❌ DELETE | ✅SELECT/INSERT/UPDATE<br>❌ DELETE
| `dbo.Rental` | ✅SELECT/INSERT/UPDATE<br>❌ DELETE | ✅SELECT/INSERT/UPDATE<br>❌ DELETE
| `dbo.Fine` | ✅ SELECT<br>❌INSERT/UPDATE/DELETE | ❌ ВСЕ операции
| `dbo.RentalFine` | ✅ SELECT<br>❌INSERT/UPDATE/DELETE | ❌ ВСЕ операции
| `dbo.ClientDiscount` | ✅ SELECT | ✅ SELECT<br>❌INSERT/UPDATE/DELETE|
| **ХРАНИМЫЕ ПРОЦЕДУРЫ** | | |
| `dbo.GetAvailableSUVs` | ✅ EXECUTE | ✅ EXECUTE
| `dbo.GetCarRentalClients` | ✅ EXECUTE | ❌ EXECUTE
| `dbo.GetModelPopularityRating` | ✅ EXECUTE | ✅ EXECUTE
| **ФУНКЦИИ** | | | |
| `dbo.GetAverageRentalsPerDay()` | ✅ EXECUTE | ✅ EXECUTE
| `dbo.GetCurrentlyRentedCars()` | ✅ SELECT | ✅ SELECT
| `dbo.GetRevenueByMonth()` | ✅ EXECUTE | ❌ EXECUTE
| **СПЕЦИАЛЬНЫЕ ПРАВА** | | | |
| `GRANT OPTION` | ✅ Присутствует | ❌ Отсутствует
| `CREATE/ALTER` | ❌ Отсутствует | ❌ Отсутствует
---