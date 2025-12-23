use('test1')
db.weather.aggregate([
    {
        $group: {
            _id: "$year",
            maxTemp: { $max: "$temperature" },
            minTemp: { $min: "$temperature" }
        }
    },
    {
        $project: {
            year: "$_id",
            tempDifference: { $subtract: ["$maxTemp", "$minTemp"] },
            _id: 0
        }
    }
])