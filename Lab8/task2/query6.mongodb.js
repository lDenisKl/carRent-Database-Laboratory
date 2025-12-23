use('test1')
db.weather.aggregate([
    {
        $group: {
            _id: {
                year: "$year",
                month: "$month",
                day: "$day"
            },
            total_measurements: { $sum: 1 },
            clear_measurements: {
                $sum: { $cond: [{ $eq: ["$code", "CL"] }, 1, 0] }
            },
            has_precipitation: {
                $max: { $cond: [{ $ne: ["$code", "CL"] }, 1, 0] }
            }
        }
    },
    {
        $addFields: {
            clear_day_ratio: {
                $divide: ["$clear_measurements", "$total_measurements"]
            },
            is_clear_day: {
                $gt: [
                    { $divide: ["$clear_measurements", "$total_measurements"] },
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
            clear_days_with_precipitation: {
                $sum: "$has_precipitation"
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
                            { $divide: ["$clear_days_with_precipitation", "$total_clear_days"] },
                            100
                        ]
                    }
                ]
            },
            total_clear_days: 1,
            clear_days_with_precipitation: 1,
            _id: 0
        }
    }
])