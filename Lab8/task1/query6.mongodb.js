db.restaurants.find({
    borough: "Bronx",
    cuisine: { $in: ["American ", "Chinese"] }
}).sort({ cuisine: 1 });