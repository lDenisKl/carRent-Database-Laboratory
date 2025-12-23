use('test1')
db.weather.aggregate([
    {
        $group: {
            _id: {
                year: "$year",
                month: "$month",
                day: "$day"
            },
            avgDailyTemp: { $avg: "$temperature" },
            year: { $first: "$year" }
        }
    },
    { $sort: { avgDailyTemp: 1 } },
    {
        $group: {
            _id: "$year",
            dailyTemps: { $push: "$avgDailyTemp" }
        }
    },
    {
        $project: {
            trimmedTemps: {
                $slice: [
                    "$dailyTemps",
                    10,
                    { $subtract: [{ $size: "$dailyTemps" }, 20] }
                ]
            }
        }
    },
    {
        $project: {
            year: "$_id",
            avgTemperature: { $avg: "$trimmedTemps" },
            _id: 0
        }
    }
])