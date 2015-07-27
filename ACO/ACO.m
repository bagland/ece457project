distances = parse_distances('outputDistance.txt');

currentPurchaseArray = {'Apples', 'Chicken', 'Oranges', 'Duck', 'VeryExpensiveItem', 'Stationery', 'MediumItem'};
purchaseAmountMap = containers.Map;
purchaseAmountMap('Apples') = 5;
purchaseAmountMap('Chicken') = 1;
purchaseAmountMap('Oranges') = 1;
purchaseAmountMap('Duck') = 1;
purchaseAmountMap('VeryExpensiveItem') = 5;
purchaseAmountMap('Stationery') = 1;
purchaseAmountMap('MediumItem') = 5;
startLocation = 'Location_1';

%Get files
distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventories('outputInventory.txt');
storeNames = store_names('outputDistance.txt');

numStores = length(storeNames);
numProducts = length(currentPurchaseArray);
evaporation_rate = 0.7;

maxIters = 3000;
alpha = 1;
beta = 1;
currentIter = 0;
numAnts = 5;

weightDist = 0.5;
weightPrice = 1 - weightDist;

%Generating an initial soln------------
count = 0;

% need to generate two pheromone matrices
% one for distances, another for cost
pricePheromones = zeros(numProducts, numStores);
distancePheromones = ones(numStores);

productIndex = 1;
% Fill price pheromones
for product = currentPurchaseArray
    productName = product{1};
    storeMap = inventoryMap(productName);
    storeKeys = keys(storeMap);
%     fprintf('');
    for key = storeKeys
        [m, index] = ismember(key, storeNames);
%         fprintf('Index for a product %s is %f\n', productName, index);
        if index
            pricePheromones(productIndex, index) = 1;
        end
    end
    productIndex = productIndex + 1;
end
stores_visited = cell(1);
stores_visited{1} = startLocation;
store_iteration = 2;
% each ant's route is start location + # of products + start location
best_ant_index = 1;

% product and price picked 
while currentIter < maxIters
%     set initial cost to a big number
    cost = inf;
%     products_bought{1} = 'product';
    
    bestSolnCost = inf;
    for i = 1:numAnts
        antsRoute{i, 1} = startLocation;
        products_index = 1;
        fprintf('Ant # = %f\n', i);
        while products_index < numProducts + 1
            product = currentPurchaseArray(products_index);
            productName = product{1};
            storeMap = inventoryMap(productName);
            storeKeys = keys(storeMap);
%             disp(keys(storeMap));
%             disp(values(storeMap));
            sumPrices = 0;
            sumDistances = 0;
            for key = storeKeys
                [m, index] = ismember(key, storeNames);
                price = storeMap(key{1});
                pricePheromone = pricePheromones(products_index, index);
                sumPrices = sumPrices + pricePheromone/str2double(price);
                [m, prevCityIndex] = ismember(stores_visited{store_iteration-1}, storeNames);
                prev_store = stores_visited{store_iteration-1};
                distancesFromPrevStore = distanceMap(prev_store);
                distance = distancesFromPrevStore(index);
                sumDistances = sumDistances + distancePheromones(prevCityIndex, index)/str2double(distance);
            end
            probability_index = 1;
            for key = storeKeys
                [m, index] = ismember(key, storeNames);
                price = storeMap(key{1});
                pricePheromone = pricePheromones(products_index, index);
                [m, prevCityIndex] = ismember(stores_visited{store_iteration-1}, storeNames);
                prev_store = stores_visited{store_iteration-1};
                distancesFromPrevStore = distanceMap(prev_store);
                distance = distancesFromPrevStore(index);
                price_probabilities(probability_index) = (pricePheromone/str2double(price))/sumPrices;
                distance_probabilities(probability_index) = (distancePheromones(prevCityIndex, index)/str2double(distance))/sumDistances;
                probability_index = probability_index + 1;
            end
            random_number = rand();
%             price_probabilities
%             distance_probabilities
            price_index = PickFromProbabilities(price_probabilities, random_number);
            dist_index = PickFromProbabilities(distance_probabilities, random_number);
            index_to_pick = dist_index;
            if price_index ~= dist_index
                random_number = randi([1 2],1,1);
                if random_number == 1
                    index_to_pick = price_index;
                else
                    index_to_pick = dist_index;
                end
            end
            storeName = storeKeys(index_to_pick);
            store_chosen = storeName{1};
            antsRoute{i, products_index + 1} = store_chosen;
            distance_probabilities = [];
            price_probabilities = [];
            products_index = products_index + 1;
        end
        antsRoute{i, products_index + 1} = startLocation;
    end
%     antsRoute{1, 2:numProducts}
%     disp(antsRoute);
%     antsRoute
    for i = 1:numAnts
        route = getRouteForAnt( antsRoute, i, numProducts );
        
        [distCost, priceCost] = evaluateSoln(route, currentPurchaseArray, route(2:numProducts+1), purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        currentSolnCost = weightDist * distCost + weightPrice * priceCost;
        if currentSolnCost < bestSolnCost
            bestSolnCost = currentSolnCost;
            best_ant_index = i;
        end
    end
    bestRoute = getRouteForAnt( antsRoute, best_ant_index, numProducts);
    [pricePheromones, distancePheromones] = updatePheromones( route, pricePheromones, distancePheromones, storeNames, numProducts, evaporation_rate );
    currentIter = currentIter + 1;
end
disp(currentPurchaseArray);
disp(bestRoute);
disp(bestSolnCost);
% antsRoute
