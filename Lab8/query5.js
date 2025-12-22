db.restaurants.find(
    { name: /^Wil/ },
    { _id: 0, restaurant_id: 1, name: 1, borough: 1, cuisine: 1 }
);