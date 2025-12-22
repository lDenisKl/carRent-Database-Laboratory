db.restaurants.find({
    borough: "Bronx",
    cuisine: { $in: ["American", "Chinese"] }
});