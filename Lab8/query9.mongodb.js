db.restaurants.aggregate([
    { $match: { borough: "Bronx" } },
    { $unwind: "$grades" },
    {
        $group: {
            _id: "$_id",
            name: { $first: "$name" },
            totalScore: { $sum: "$grades.score" }
        }
    },
    { $sort: { totalScore: 1 } },
    { $limit: 1 },
    { $project: { _id: 0, name: 1, totalScore: 1 } }
]);