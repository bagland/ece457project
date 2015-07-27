%User Input requirements, starting location + what they want to purchase
% You need more than 2 items to swap.

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
inventoryMap = parse_inventory('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numItems = size(currentPurchaseArray);

%Standard SA params.
maxNumRuns = 20000;

%Other params.
    %Stagnation/stuck in local minimum
noIterImprovement = 0;
numNoIterImprovementExit = 3000; %BREAK EARLY, WE ARE REALLY STUCK TRY AGAIN
noIterImprovementReheat = 500;

    %Neighbourhood operator probabilities
swapProbability = 0.85;
randomStoreProbability = 0.85;

%Objective Fcn
weightDist = 0.5;
weightPrice = 1 - weightDist;

numBees = 10;
beeArray = cell(numBees);

for i= 1:10
    
    dataMap = containers.Map;
    %Generating an initial soln------------
    storeList = cell(numItems);
    count = 0;
    %Get Stores that sell the items we want.
    
    %Randomize buying order.
    itemPurchaseArray = currentPurchaseArray;
    Perm1 = randperm(length(currentPurchaseArray));
	itemPurchaseArray = itemPurchaseArray(Perm1);
    
    
    for itemName = itemPurchaseArray
        itemCharName = itemName{1};
        storeItemMap = inventoryMap(itemCharName);
        storeKeys = keys(storeItemMap);
        count = count + 1;
        slot = randi(size(storeKeys,2));
        storeList{count} = storeKeys{slot}; %Choose random store rather than first store.
    end

    %Select 1st store that sells each item as initial soln and generate route
    %Route is initialLoc, store1, store2...., storeN, initialLoc
    midRoute{1} = startLocation;
    currentStoreList = cell(size(itemPurchaseArray));
    count = 2;
    for loc = storeList
        size(loc);
        midRoute{count} = loc{1};
        currentStoreList{count-1} = loc{1};
        count = count + 1;
    end
    midRoute{count} = startLocation;

    %get initial soln cost
    [distCost, priceCost] = evaluateSoln(midRoute,itemPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
    currentSolnCost = weightDist * distCost + weightPrice * priceCost;
    
    dataMap('route') = midRoute;
    dataMap('storeList') = currentStoreList;
    dataMap('amountMap') = purchaseAmountMap;
    dataMap('bestSolnCost') = currentSolnCost;
    dataMap('bestPurchaseArray') = itemPurchaseArray;
    dataMap('bestStoreList') = currentStoreList;
    dataMap('bestSolnCost') = currentSolnCost;
    dataMap('bestPurchaseArray') = itemPurchaseArray;
    dataMap('bestStoreList') = currentStoreList;
    
    beeArray{i} = dataMap;
end

runNum = 0;
totalLoopTimeTaken = 0;
%... todo.
%http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5946125
%http://mf.erciyes.edu.tr/abc/pub/PsuedoCode.pdf