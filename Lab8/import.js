use('test');
const fs = require('fs');
const path = 'C:/Users/l_DK_l/Documents/GitHub/carRent-Database-Laboratory/Lab8/restaurants.json';
const rawData = fs.readFileSync(path, 'utf8');
const data = JSON.parse(rawData);

const result = db.restaurants.insertMany(data);
console.log(result)