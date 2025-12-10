SELECT 
    c.fullName,
    COUNT(r.$edge_id) as RentalCount
FROM ClientNode c
LEFT JOIN RENTED r ON MATCH(c-(r)->CarNode)
GROUP BY c.fullName;



SELECT 
    car.licensePlate,
    model.manufacturer,
    model.name as ModelName,
    MAX(r.startDate) as LastRentalDate
FROM CarNode car
JOIN HAS_MODEL hm ON MATCH(car-(hm)->model)
LEFT JOIN RENTED r ON MATCH(ClientNode-(r)->car)
GROUP BY car.licensePlate, model.manufacturer, model.name;