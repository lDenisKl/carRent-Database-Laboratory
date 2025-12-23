db.restaurants.updateOne(
    { restaurant_id: "99999999" },
    {
        $set: {
            "operating_hours": {
                "monday": "10:00-22:00",
                "tuesday": "10:00-22:00",
                "wednesday": "10:00-22:00",
                "thursday": "10:00-23:00",
                "friday": "10:00-23:00",
                "saturday": "11:00-23:00",
                "sunday": "11:00-21:00"
            }
        }
    }
);