use('test1')
db.weather.aggregate([
    {
        $match: {
            wind_direction: "Южный"
        }
    },
    { $sort: { temperature: 1 } },
    { $limit: 10 },
    {
        $group: {
            _id: null,
            avgTemperature: { $avg: "$temperature" }
        }
    },
    {
        $project: {
            avgTemperature: 1,
            _id: 0
        }
    }
])