use('test1');
//db.weather.find({ code: { $ne: 'CL' } })
db.weather.aggregate([
    {
        $match: {
            temperature: { $lt: 0 },
            code: { $ne: "CL", $ne: "BR", $ne: "FG", $ne: "FZ" }
        }
    },
    {
        $group: {
            _id: {
                year: "$year",
                month: "$month",
                day: "$day"
            }
        }
    },
    {
        $count: "snowDays"
    }
])