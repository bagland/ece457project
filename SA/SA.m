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
boltzman = 160;
initialTemp =1.0; 
maxNumRuns = 20000;
alpha=0.95; % Cooling factor used is geometric, T = T * alpha
temperature = initialTemp;

%Other params.
    %Stagnation/stuck in local minimum
noIterImprovement = 0;
numNoIterImprovementExit = 2000; %BREAK EARLY, WE ARE REALLY STUCK TRY AGAIN
noIterImprovementReheat = 500;
reheatValue = 1.05;
reheatRunThreshold = maxNumRuns/2; %STOP REHEATING IF PAST THIS POINT!

    %Few iterations on initial temp, more on lower and lower temps
currTempIter = 0;
numIterPerTempDecrease = 20;
numIterPertempDecreaseIncrement = 20;

    %Neighbourhood operator probabilities
swapProbability = 0.85;
randomStoreProbability = 0.85;

%Objective Fcn
weightDist = 0.5;
weightPrice = 1 - weightDist;

%Generating an initial soln------------
storeList = cell(numItems);
count = 0;
%Get Stores that sell the items we want.
for itemName = currentPurchaseArray
    itemCharName = itemName{1};
    storeItemMap = inventoryMap(itemCharName);
    storeKeys = keys(storeItemMap);
    count = count + 1;
    storeList{count} = storeKeys{1};
end

%Select 1st store that sells each item as initial soln and generate route
%Route is initialLoc, store1, store2...., storeN, initialLoc
midRoute{1} = startLocation;
currentStoreList = cell(size(currentPurchaseArray));
count = 2;
for loc = storeList
    midRoute{count} = loc{1};
    currentStoreList{count-1} = loc{1};
    count = count + 1;
end
midRoute{count} = startLocation;

%get initial soln cost
[distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
currentSolnCost = weightDist * distCost + weightPrice * priceCost;


%Stored best soln for output
bestSolnCost = currentSolnCost;
bestcurrentPurchaseArray = currentPurchaseArray;
bestStoreList = currentStoreList;

%Stored current soln to compare against (we may have accepted a worse soln
%than the best)
iterSolnCost = currentSolnCost;
itercurrentPurchaseArray = currentPurchaseArray;
iterStoreList = currentStoreList;

%Graphing
solnXAxis = [0];
solnYAxis = [iterSolnCost];
thePlot = plot(solnXAxis, solnYAxis)
set(thePlot,'XDataSource', 'solnXAxis')
set(thePlot,'YDataSource', 'solnYAxis')
%linkdata on

runNum = 0;
totalLoopTimeTaken = 0;
while (runNum < maxNumRuns || noIterImprovement >= numNoIterImprovementExit)
    
    loopStartTime = cputime;
    %swap
    if (rand() < swapProbability && numItems(2) > 1)
        %disp('swap');
        firstSlot = randi(numItems);
        secondSlot = randi(numItems);
        
        % assume > 1 items. or else infinite loop
        while secondSlot == firstSlot
           secondSlot = randi(numItems);
        end
        
        %Swap the items in the grocery list
        temp = currentPurchaseArray{firstSlot};
        currentPurchaseArray{firstSlot} = currentPurchaseArray{secondSlot};
        currentPurchaseArray{secondSlot} = temp;

        %Swap them in the reference store list. (need these keys in order)
        temp = storeList{firstSlot};
        storeList{firstSlot} = storeList{secondSlot};
        storeList{secondSlot} = temp;

        %Swap in the route. note the +1, zzz.
        temp = midRoute{firstSlot+1};
        midRoute{firstSlot+1} = midRoute{secondSlot+1};
        midRoute{secondSlot+1} = temp;

        %swap the current store order.
        temp = currentStoreList{firstSlot};
        currentStoreList{firstSlot} = currentStoreList{secondSlot};
        currentStoreList{secondSlot} = temp;
    end
    if (rand() < randomStoreProbability)
        %Random Store
        %disp('randomstore.');
        whatItem = randi(numItems); %Pick which item select a different store.
        itemCharName = currentPurchaseArray{whatItem};
        storeItemMap = inventoryMap(itemCharName); %Get what stores sell that item
        storeKeys = keys(storeItemMap);
        whatStore = randi(size(storeKeys)); % Pick a random store in that list
        currentStoreList{whatItem} = storeKeys{whatStore};
    end
   
    %Eval soln
    [distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
    currentSolnCost = weightDist * distCost + weightPrice * priceCost;

    deltaCost = currentSolnCost - iterSolnCost;
    
    %Best soln we've seen so far
    if (currentSolnCost < bestSolnCost)
        bestSolnCost = currentSolnCost;
        bestcurrentPurchaseArray = currentPurchaseArray;
        bestStoreList = currentStoreList;
        iterSolnCost = currentSolnCost;
        itercurrentPurchaseArray = currentPurchaseArray;
        iterStoreList = currentStoreList;
        noIterImprovement = 0;
    %Better than the current soln we have
    elseif (currentSolnCost < iterSolnCost)
        iterSolnCost = currentSolnCost;
        itercurrentPurchaseArray = currentPurchaseArray;
        iterStoreList = currentStoreList;
        noIterImprovement = 0;
    else
        %SA check probability of acceptance.
        chance = exp(-deltaCost/(boltzman*temperature));
        if chance>rand()
           %Accept when worse 
           iterSolnCost = currentSolnCost;
           itercurrentPurchaseArray = currentPurchaseArray;
           iterStoreList = currentStoreList;
        end
        
        noIterImprovement = noIterImprovement + 1;
        if (mod(noIterImprovement,noIterImprovementReheat) == 0 && runNum < reheatRunThreshold) 
            temperature = temperature * reheatValue;
            disp('reheat');
        end
    end
    %cooldown
    %Can change this too.
    currTempIter = currTempIter + 1;
    if (currTempIter >= numIterPerTempDecrease)
        numIterPerTempDecrease = numIterPerTempDecrease + numIterPertempDecreaseIncrement; 
        currTempIter = 0;
        temperature = temperature * alpha;
    end
        
    runNum = runNum + 1;
    
    solnXAxis = [solnXAxis runNum];
    solnYAxis = [solnYAxis iterSolnCost];
    
    loopEndTime = cputime;
    %DO NOT INCLUDE GRAPH DRAW TIME IN LOOP TIME, THAT IS POINTLESS
    loopTimeTaken = loopEndTime - loopStartTime;
    totalLoopTimeTaken = totalLoopTimeTaken + loopTimeTaken;
    
    %Graph update
    if (mod(runNum,200) == 0)
        refreshdata
        drawnow
    end
    
end

refreshdata
drawnow
%linkdata off;

avgLoopTimeTaken = totalLoopTimeTaken/runNum;
fprintf('Best soln in %d runs\n', runNum);
fprintf('Avg loop time %d seconds, full time taken %d\n', avgLoopTimeTaken, totalLoopTimeTaken);
disp(bestcurrentPurchaseArray);
disp (bestStoreList);
disp(bestSolnCost);
