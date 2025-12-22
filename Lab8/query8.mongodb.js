db.restaurants.aggregate([
    {
        $group: {
            _id: { borough: "$borough", cuisine: "$cuisine" },
            count: { $sum: 1 }
        }
    },
    {
        $project: {
            _id: 0,
            borough: "$_id.borough",
            cuisine: "$_id.cuisine",
            count: 1
        }
    },
    { $sort: { borough: 1, cuisine: 1 } }
]);