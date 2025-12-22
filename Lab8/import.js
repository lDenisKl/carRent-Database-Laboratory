// 1. Проверим, что данные загрузились в переменную
use('test');
const fs = require('fs');
const path = 'C:/Users/l_DK_l/Documents/GitHub/carRent-Database-Laboratory/Lab8/restaurants.json';
const rawData = fs.readFileSync(path, 'utf8');
const data = JSON.parse(rawData);

// 2. Посмотрим, что в данных
console.log("Тип данных:", typeof data);
console.log("Это массив?", Array.isArray(data));
console.log("Количество элементов:", data?.length);

// 3. Посмотрим первую запись
console.log("Первая запись:", JSON.stringify(data?.[0], null, 2));
