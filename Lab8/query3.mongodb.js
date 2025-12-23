db.restaurants.find({
    "grades.score": { $gt: 80, $lt: 100 }
});