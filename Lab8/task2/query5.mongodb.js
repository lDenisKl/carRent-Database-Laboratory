use('test1')
db.weather.aggregate([
    {
        $match: {
            month: { $in: [12, 1, 2] },
            code: { $ne: "CL", $ne: "DZ" }
        }
    },
    {
        $addFields: {
            precipitation_type: {
                $cond: [
                    { $lt: ["$temperature", 0] },
                    "snow",
                    "rain"
                ]
            }
        }
    },
    {
        $group: {
            _id: "$precipitation_type",
            count: { $sum: 1 }
        }
    },
    {
        $group: {
            _id: null,
            precipitation_counts: { $push: { k: "$_id", v: "$count" } }
        }
    },
    {
        $project: {
            snow_count: {
                $let: {
                    vars: {
                        snow_obj: {
                            $arrayElemAt: [
                                { $filter: { input: "$precipitation_counts", as: "p", cond: { $eq: ["$$p.k", "snow"] } } },
                                0
                            ]
                        }
                    },
                    in: { $ifNull: ["$$snow_obj.v", 0] }
                }
            },
            rain_count: {
                $let: {
                    vars: {
                        rain_obj: {
                            $arrayElemAt: [
                                { $filter: { input: "$precipitation_counts", as: "p", cond: { $eq: ["$$p.k", "rain"] } } },
                                0
                            ]
                        }
                    },
                    in: { $ifNull: ["$$rain_obj.v", 0] }
                }
            }
        }
    },
    {
        $project: {
            snow_count: 1,
            rain_count: 1,
            difference: { $subtract: ["$snow_count", "$rain_count"] },
            _id: 0
        }
    }
])