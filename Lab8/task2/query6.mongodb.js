use('test1')
db.weather.aggregate([
    {
        $group: {
            _id: {
                year: "$year",
                month: "$month",
                day: "$day"
            },
            total: { $sum: 1 },
            clear: {
                $sum: { $cond: [{ $eq: ["$code", "CL"] }, 1, 0] }
            },
            has_os: {
                $max: { $cond: [{ $ne: ["$code", "CL"] }, 1, 0] }
            }
        }
    },
    {
        $addFields: {
            is_clear_day: {
                $gt: [
                    { $divide: ["$clear", "$total"] },
                    0.75
                ]
            }
        }
    },
    {
        $match: {
            is_clear_day: true
        }
    },
    {
        $group: {
            _id: null,
            total_clear_days: { $sum: 1 },
            clear_with_os: {
                $sum: "$has_os"
            }
        }
    },
    {
        $project: {
            probability: {
                $cond: [
                    { $eq: ["$total_clear_days", 0] },
                    0,
                    {
                        $multiply: [
                            { $divide: ["$clear_with_os", "$total_clear_days"] },
                            100
                        ]
                    }
                ]
            },
            total_clear_days: 1,
            clear_with_os: 1,
            _id: 0
        }
    }
])
