
const date = new Date("2014-08-11T00:00:00Z").getTime();
const result = db.restaurants.find(
    {
        "grades": {
            $elemMatch: {
                "grade": "A",
                "score": 9,
                "date.$date": date
            }
        }
    },
    { _id: 0, restaurant_id: 1, name: 1, grades: 1 }
);

printjson(result.toArray());