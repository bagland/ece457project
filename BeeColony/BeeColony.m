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
numEmployedBee = 10;
numOnlookerBee = 5;
beeArray = cell(numBees);

bestSolnCost = 99999999;
%bestCurrentPurchaseArray = currentPurchaseArray;
%bestStoreList = currentStoreList;

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
    midRoute = {};
    midRoute{1} = startLocation;
    currentStoreList = cell(size(itemPurchaseArray));
    count = 2;
    for loc = storeList
        midRoute{count} = loc{1};
        currentStoreList{count-1} = loc{1};
        count = count + 1;
    end
    midRoute{count} = startLocation;

    %get initial soln cost
    [distCost, priceCost] = evaluateSoln(midRoute,itemPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
    currentSolnCost = weightDist * distCost + weightPrice * priceCost;
    
    
    if (currentSolnCost < bestSolnCost)
       bestSolnCost = currentSolnCost;
       bestCurrentPurchaseArray = itemPurchaseArray;
       bestStoreRoute = midRoute;
    end
    
    dataMap('route') = midRoute;
    dataMap('currSolnCost') = currentSolnCost;
    dataMap('currPurchaseArray') = itemPurchaseArray;
    dataMap('age') = 0;
    
    beeArray{i} = dataMap;
end

runNum = 0;
totalLoopTimeTaken = 0;

while (runNum < maxNumRuns)
  
    %for employee?
    
    %Worker bees.
    solnCostArray = zeros(1,numBees);
    for beeNum =1:numEmployedBee
        dataMap = beeArray{beeNum};
        midRoute = dataMap('route');
        itemPurchaseArray = dataMap('currPurchaseArray');
        oldSolnCost = dataMap('currSolnCost');
        
		
		%NEIGHBOURHOOD OPERATOR TODO (only swap right now)
        newSolnRoute = midRoute;
        newSolnStoreList = currentStoreList;
        newItemPurchaseArray = itemPurchaseArray;
        
        firstSlot = randi(numItems);
        secondSlot = randi(numItems);

        % assume > 1 items. or else infinite loop
        while secondSlot == firstSlot
           secondSlot = randi(numItems);
        end

        %Swap the items in the grocery list
        temp = newItemPurchaseArray{firstSlot};
        newItemPurchaseArray{firstSlot} = newItemPurchaseArray{secondSlot};
        newItemPurchaseArray{secondSlot} = temp;

        %Swap in the route. note the +1, zzz.
        temp = newSolnRoute{firstSlot+1};
        newSolnRoute{firstSlot+1} = newSolnRoute{secondSlot+1};
        newSolnRoute{secondSlot+1} = temp;
        
        [distCost, priceCost] = evaluateSoln(newSolnRoute,newItemPurchaseArray,newSolnRoute(2:size(newSolnRoute,2)-1), purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        currentSolnCost = weightDist * distCost + weightPrice * priceCost;
        
        %we improved
        if (currentSolnCost < oldSolnCost)
            oldSolnCost = currentSolnCost;
            
            dataMap('route') = newSolnRoute;
            dataMap('currSolnCost') = currentSolnCost;
            dataMap('currPurchaseArray') = newItemPurchaseArray;
            
        end
        
        if (currentSolnCost < bestSolnCost)
           bestSolnCost = currentSolnCost;
           bestCurrentPurchaseArray = newItemPurchaseArray;
           bestStoreRoute = newSolnRoute;
        end
        dataMap('age') = dataMap('age') + 1;
        beeArray{beeNum} = dataMap;
        solnCostArray(beeNum) = currentSolnCost;
    end
    
    %Onlooker bees.
    for onlookerIndex =1:numOnlookerBee
        
        randomNumber = rand();
        index = rouletteWheel(solnCostArray);
        beeNum = index;
        dataMap = beeArray{beeNum};
        midRoute = dataMap('route');
        itemPurchaseArray = dataMap('currPurchaseArray');
        oldSolnCost = dataMap('currSolnCost');
        
        newSolnRoute = midRoute;
        newSolnStoreList = currentStoreList;
        newItemPurchaseArray = itemPurchaseArray;
        
		%NEIGHBOURHOOD OPERATOR TODO (only swap right now)
        firstSlot = randi(numItems);
        secondSlot = randi(numItems);

        % assume > 1 items. or else infinite loop
        while secondSlot == firstSlot
           secondSlot = randi(numItems);
        end

        %Swap the items in the grocery list
        temp = newItemPurchaseArray{firstSlot};
        newItemPurchaseArray{firstSlot} = newItemPurchaseArray{secondSlot};
        newItemPurchaseArray{secondSlot} = temp;

        %Swap in the route. note the +1, zzz.
        temp = newSolnRoute{firstSlot+1};
        newSolnRoute{firstSlot+1} = newSolnRoute{secondSlot+1};
        newSolnRoute{secondSlot+1} = temp;
        
        [distCost, priceCost] = evaluateSoln(newSolnRoute,newItemPurchaseArray,newSolnRoute(2:size(newSolnRoute,2)-1), purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        currentSolnCost = weightDist * distCost + weightPrice * priceCost;
        
        %we improved
        if (currentSolnCost < oldSolnCost)
            oldSolnCost = currentSolnCost;
            
            dataMap('route') = newSolnRoute;
            dataMap('currSolnCost') = currentSolnCost;
            dataMap('currPurchaseArray') = newItemPurchaseArray;
		    dataMap('age') = 0; %We were noticed & improved by onlooker, refresh age
            
        end
        
        if (currentSolnCost < bestSolnCost)
           bestSolnCost = currentSolnCost;
           bestCurrentPurchaseArray = newItemPurchaseArray;
           bestStoreRoute = newSolnRoute;
        end
        
        beeArray{beeNum} = dataMap;
    end
    
    %Weed out abandoned solns. & generate new to replace.
    for i =1:numEmployedBee
        dataMap = beeArray{beeNum};
        
        if (dataMap('age') >= ageThreshold)
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
            midRoute = {};
            midRoute{1} = startLocation;
            currentStoreList = cell(size(itemPurchaseArray));
            count = 2;
            for loc = storeList
                midRoute{count} = loc{1};
                currentStoreList{count-1} = loc{1};
                count = count + 1;
            end
            midRoute{count} = startLocation;

            %get initial soln cost
            [distCost, priceCost] = evaluateSoln(midRoute,itemPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
            currentSolnCost = weightDist * distCost + weightPrice * priceCost;


            if (currentSolnCost < bestSolnCost)
               bestSolnCost = currentSolnCost;
               bestCurrentPurchaseArray = itemPurchaseArray;
               bestStoreRoute = midRoute;
            end

            dataMap('route') = midRoute;
            dataMap('currSolnCost') = currentSolnCost;
            dataMap('currPurchaseArray') = itemPurchaseArray;
            dataMap('age') = 0;

            beeArray{i} = dataMap;
        end
    end
end
%... todo.
%http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5946125
%http://mf.erciyes.edu.tr/abc/pub/PsuedoCode.pdf
%https://en.wikipedia.org/wiki/Artificial_bee_colony_algorithm
%http://popot.googlecode.com/svn/trunk/Trash/Documents/ABC/Karaboga2012.pdf