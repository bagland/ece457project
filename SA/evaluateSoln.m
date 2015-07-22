function cost = evaluateSoln( route, items, stores )
    
    
    distanceMap = parse_distances('outputDistance.txt');
    inventoryMap = parse_inventory('outputInventory.txt');
    storesList64 = keys(distanceMap)
    cost = 0;
    distance = 0;
    disp(route);
    locationPrev = route{1};
    locationNext = route{1};
    [u i]=unique(route,'first');% ??? magic here. https://www.mathworks.com/matlabcentral/newsreader/view_thread/263654
    route(sort(i))
    %route = unique(route)
    %route = route + {'ZLocation_1'};
    for i = 2:size(route,2)
        locationPrev = locationNext;
        locationNext = route{i};
        vDistances = distanceMap(locationPrev);
        index = getnameidx(storesList64,locationNext);
        distanceCost = vDistances{index};
        distanceCost = str2double(distanceCost);
        distance = distance + distanceCost%distance + distanceMap(locationPrev)(locationNext);
    end
    
    price = 0;
    
    i = 1;
    for itemName = items
        itemCharName = itemName{1}
        storeItemMap = inventoryMap(itemCharName);
        storeKey = stores{i};
        
        itemPrice = str2double(storeItemMap(storeKey));
        price = price + itemPrice
        i = i + 1;
    end

    cost = 0.5*distance + 0.5*price;
end