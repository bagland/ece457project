

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

%Bee Colony parameters.
maxNumRuns = 1000;
ageThreshold = 5;
numEmployedBee = 10;
numOnlookerBee = 15;

%Adaptive params.
minNumOnlookerbee = 5;
minAgeThreshold = 3;
abandonRateThreshold = 0.70; %threshold for too many abandoned searches, increase # onlookers and age size
liveRateThreshold = 0.30; %threshold for too many explored sources, decrease # onlookers and age size.

%Objective Fcn
weightDist = 0.5;
weightPrice = 1 - weightDist;




%Get files
distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventory('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numItems = size(currentPurchaseArray);

%Setup stuff.
beeArray = cell(numEmployedBee);
runNum = 0;
totalLoopTimeTaken = 0;
bestSolnCost = 99999999;
numAbandoned = 0;

%Generate initial population.
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

solnXAxis = [0];
solnYAxis = [bestSolnCost];
thePlot = plot(solnXAxis, solnYAxis)
set(thePlot,'XDataSource', 'solnXAxis')
set(thePlot,'YDataSource', 'solnYAxis')



while (runNum < maxNumRuns)
  
    tic
    
    %Worker bees.
    solnCostArray = zeros(1,numEmployedBee);
    for beeNum =1:numEmployedBee
        dataMap = beeArray{beeNum};
        dataMap = deepCopy(dataMap);
        midRoute = dataMap('route');
        itemPurchaseArray = dataMap('currPurchaseArray');
        oldSolnCost = dataMap('currSolnCost');
        
        
        newSolnRoute = midRoute;
        newSolnStoreList = currentStoreList;
        newItemPurchaseArray = itemPurchaseArray;
		
        phi = (rand() - 0.5) * 2; %Uniform number between -1 and 1
        % If < 0 do swap buying order
        % >= 0 buy from different stores.
        
        %Explore one step around neighbourhood.
        if (phi < 0)
            numSwapToMake = 1;
            for numSwaps = 1: numSwapToMake
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
            end
        else
            numRandomStoreToMake = 1;
            for numRandomStores = 1 : numRandomStoreToMake
                whatItem = randi(numItems); %Pick which item select a different store.
                itemCharName = newItemPurchaseArray{whatItem};
                storeItemMap = inventoryMap(itemCharName); %Get what stores sell that item
                storeKeys = keys(storeItemMap);
                whatStore = randi(size(storeKeys)); % Pick a random store in that list
                newSolnStoreList{whatItem} = storeKeys{whatStore};
                newSolnRoute{whatItem+1} = storeKeys{whatStore};
            end
        end
        
        
        
        [distCost, priceCost] = evaluateSoln(newSolnRoute,newItemPurchaseArray,newSolnRoute(2:size(newSolnRoute,2)-1), purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        currentSolnCost = weightDist * distCost + weightPrice * priceCost;
        
        %we improved, greedy selection between old and new explored soln
        if (currentSolnCost < oldSolnCost)
            oldSolnCost = currentSolnCost;
            
            dataMap('route') = newSolnRoute;
            dataMap('currSolnCost') = currentSolnCost;
            dataMap('currPurchaseArray') = newItemPurchaseArray;
            
        end
        
        %Overwrite best
        if (currentSolnCost < bestSolnCost)
           bestMap = deepCopy(dataMap);
           bestSolnCost = bestMap('currSolnCost');
           bestCurrentPurchaseArray = bestMap('currPurchaseArray');
           bestStoreRoute = bestMap('route');
        end
        
        %Age solution
        dataMap('age') = dataMap('age') + 1;
        beeArray{beeNum} = dataMap;
        solnCostArray(beeNum) = currentSolnCost;
    end
    
    %Onlooker bees.
    for onlookerIndex =1:numOnlookerBee
        
        %roulette probability selection on the solution costs from the
        %employed bees.
        index = rouletteWheel(solnCostArray);
        beeNum = index;
        dataMap = beeArray{beeNum};
        
        
        dataMap = deepCopy(dataMap);
        midRoute = dataMap('route');
        itemPurchaseArray = dataMap('currPurchaseArray');
        oldSolnCost = dataMap('currSolnCost');
        
        newSolnRoute = midRoute;
        newSolnStoreList = currentStoreList;
        newItemPurchaseArray = itemPurchaseArray;
        
		phi = (rand() - 0.5) * 2; %Uniform number between -1 and 1
        % If < 0 do swap buying order
        % >= 0 buy from different stores.
        
        %explore solution just like employed bee.
        if (phi < 0)
            numSwapToMake = 1;
            for numSwaps = 1: numSwapToMake
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
            end
        else
            numRandomStoreToMake = 1;
            for numRandomStores = 1 : numRandomStoreToMake
                whatItem = randi(numItems); %Pick which item select a different store.
                itemCharName = newItemPurchaseArray{whatItem};
                storeItemMap = inventoryMap(itemCharName); %Get what stores sell that item
                storeKeys = keys(storeItemMap);
                whatStore = randi(size(storeKeys)); % Pick a random store in that list
                newSolnStoreList{whatItem} = storeKeys{whatStore};
                newSolnRoute{whatItem+1} = storeKeys{whatStore};
            end
        end
        
        [distCost, priceCost] = evaluateSoln(newSolnRoute,newItemPurchaseArray,newSolnRoute(2:size(newSolnRoute,2)-1), purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        currentSolnCost = weightDist * distCost + weightPrice * priceCost;
        
        %we improved, greedy selection between the two, and reset age
        if (currentSolnCost < oldSolnCost)
            oldSolnCost = currentSolnCost;
            dataMap('route') = newSolnRoute;
            dataMap('currSolnCost') = currentSolnCost;
            dataMap('currPurchaseArray') = newItemPurchaseArray;
		    dataMap('age') = 0; %We were noticed & improved by onlooker, refresh age
        end
        
        %Overwrite best
        if (currentSolnCost < bestSolnCost)
           bestMap = deepCopy(dataMap);
           bestSolnCost = bestMap('currSolnCost');
           bestCurrentPurchaseArray = bestMap('currPurchaseArray');
           bestStoreRoute = bestMap('route');
        end
        
        beeArray{beeNum} = dataMap;
    end
    
    %Weed out abandoned feed sources, sources that were not found to be possible to be improved by onlookers.  
    %employed bees become scouts & then return to being employed
    
    
    for i = 1:numEmployedBee
        dataMap = beeArray{beeNum};
        
        if (dataMap('age') >= ageThreshold)
            %fprintf('Source %d is abandoned run num :%d\n', i, runNum);
            numAbandoned = numAbandoned + 1;
            dataMap = deepCopy(dataMap);
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


            %Overwrite best
            if (currentSolnCost < bestSolnCost)
               bestMap = deepCopy(dataMap);
               bestSolnCost = bestMap('currSolnCost');
               bestCurrentPurchaseArray = bestMap('currPurchaseArray');
               bestStoreRoute = bestMap('route');
            end

            dataMap('route') = midRoute;
            dataMap('currSolnCost') = currentSolnCost;
            dataMap('currPurchaseArray') = itemPurchaseArray;
            dataMap('age') = 0;

            beeArray{i} = dataMap;
        end
    end
    
    %Adaptation, increase or decrease threshold and number of onlookers
    if (mod(runNum,ageThreshold) == 0)
        abandonRate = numAbandoned / (numEmployedBee * ageThreshold); %abandoned on avg per run of this age threshold
        if (abandonRate > abandonRateThreshold)
            numOnlookerBee = numOnlookerBee + 2;
            ageThreshold = ageThreshold + 1;
        end

        if (abandonRate < liveRateThreshold)
            numOnlookerBee = max(numOnlookerBee - 2, minNumOnlookerbee);
            ageThreshold = max(ageThreshold - 1, minAgeThreshold);
        end
        numAbandoned = 0;  
    end
    
    
    runNum = runNum + 1;
    
    solnXAxis = [solnXAxis runNum];
    solnYAxis = [solnYAxis bestSolnCost];
    
    %DO NOT INCLUDE GRAPH DRAW TIME IN LOOP TIME, THAT IS POINTLESS
    loopTimeTaken = toc;
    totalLoopTimeTaken = totalLoopTimeTaken + loopTimeTaken;
    
    %Graph update
    if (mod(runNum,5) == 0)
        refreshdata
        drawnow
    end
end

refreshdata
drawnow

avgLoopTimeTaken = totalLoopTimeTaken/runNum;
fprintf('Best soln in %d runs\n', runNum);
fprintf('Avg loop time %d seconds, full time taken %d\n', avgLoopTimeTaken, totalLoopTimeTaken);
disp(bestCurrentPurchaseArray);
disp(bestStoreRoute);
disp(bestSolnCost);



%... todo.
%http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=5946125
%http://mf.erciyes.edu.tr/abc/pub/PsuedoCode.pdf
%https://en.wikipedia.org/wiki/Artificial_bee_colony_algorithm
%http://popot.googlecode.com/svn/trunk/Trash/Documents/ABC/Karaboga2012.pdf
