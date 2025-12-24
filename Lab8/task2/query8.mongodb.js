//средняя за каждый сезон

use('test1')
db.weather.aggregate([
    {
        $addFields: {
            season: {
                $switch: {
                    branches: [
                        { case: { $in: ["$month", [12, 1, 2]] }, then: "Зима" },
                        { case: { $in: ["$month", [3, 4, 5]] }, then: "Весна" },
                        { case: { $in: ["$month", [6, 7, 8]] }, then: "Лето" },
                        { case: { $in: ["$month", [9, 10, 11]] }, then: "Осень" }
                    ],
                }
            }
        }
    },
    {
        $group: {
            _id: {
                year: "$year",
                season: "$season"
            },
            avgSeasonTemp: { $avg: "$temperature" }
        }
    },
    {
        $project: {
            _id: 0,
            year: "$_id.year",
            season: "$_id.season",
            avgSeasonTemp: 1
        }
    }
])