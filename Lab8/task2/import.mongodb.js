use('test1');
const fs = require('fs');
const path = 'C:/Users/l_DK_l/Documents/GitHub/carRent-Database-Laboratory/Lab8/weather.json';
const rawData = fs.readFileSync(path, 'utf8');
const data = JSON.parse(rawData);

const result = db.weather.insertMany(data);
console.log(result)