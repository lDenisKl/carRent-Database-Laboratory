use('test1');
db.weather.aggregate([
    {
        $group: {
            _id: null,
            delta: {
                $avg: {
                    $cond: [
                        {
                            $and: [
                                { $in: ["$month", [12, 1, 2]] },
                                { $eq: [{ $mod: ["$day", 2] }, 1] }
                            ]
                        },
                        1,
                        0
                    ]
                }
            }
        }
    }
])