// db.restaurants.find({
//     "grades.score": { $gt: 80, $lt: 100 }
// });

db.restaurants.aggregate([
    {
        $unwind: "$grades"
    },
    {
        $group: {
            _id: "$_id",
            name: { $first: "$name" },
            totalScore: { $sum: "$grades.score" }
        }
    },
    {
        $match: {
            totalScore: { $gt: 80, $lt: 100 }
        }
    },
    {
        $project: {
            name: 1,
            totalScore: 1
        }
    }
])


// db.restaurants.find({
//     "grades": {
//         $not: {
//             $elemMatch: {
//                 score: { $not: { $gt: 2, $lt: 100 } }
//             }
//         }
//     }
// })