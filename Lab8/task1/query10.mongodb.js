db.restaurants.insertOne({
    "restaurant_id": "99999999",
    "name": "Dodo Pizza",
    "borough": "Ukhta",
    "cuisine": "Russian",
    "address": {
        "building": "1",
        "coord": [-73.96, 40.75],
        "street": "Lenina",
        "zipcode": "11377"
    },
    "grades": [
        { "date": { "$date": 1672531200000 }, "grade": "A", "score": 100 }
    ]
});

