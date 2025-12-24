use('test1')
db.weather.aggregate([
    {
        $match: {
            month: { $in: [12, 1, 2] },
            code: { $nin: ["CL", "BR", "FG", "FZ"] }
        }
    },

    {
        $group: {
            _id: null,
            snow: {
                $sum: { $cond: [{ $lt: ["$temperature", 0] }, 1, 0] }
            },
            rain: {
                $sum: { $cond: [{ $gte: ["$temperature", 0] }, 1, 0] }
            }
        }
    },

    {
        $project: {
            _id: 0,
            snow: 1,
            rain: 1,
            difference: { $subtract: ["$rain", "$snow"] }
        }
    }
])