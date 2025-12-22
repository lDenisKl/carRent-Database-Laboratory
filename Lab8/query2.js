db.restaurants.find(
    { borough: "Bronx" },
    { _id: 0, name: 1 }
).sort({ name: 1 }).limit(5);