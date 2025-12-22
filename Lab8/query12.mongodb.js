db.restaurants.updateOne(
    { restaurant_id: "99999999" },
    {
        $set: {
            "operating_hours.friday": "10:00-00:00",
            "operating_hours.saturday": "11:00-00:00"
        }
    }
);