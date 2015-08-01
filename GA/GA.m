function [result] = GA()
NumGen = 500;
%pop size
PopSize = 10;
%probability of crossover/mutation
pCross = 0.9;
pMut = 1-pCross;
%weight distribution of distance/price
weightDist = 0.5;
weightPrice = 1 - weightDist;

%make up input, should put in file later
numItems = 7;
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

distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventories('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numItems = size(currentPurchaseArray);

%generate initial population
%get list of all of the stores that contain the given required products
  
%percentage of population to get crossover
GAPop = cell(PopSize);
   
%GENERATE POPULATION
for i= 1:PopSize
    
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
        %disp(itemName);
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
    dataMap('bestSolnCost') = currentSolnCost;
    dataMap('bestPurchaseArray') = itemPurchaseArray;
    
    GAPop{i} = dataMap;
end

lastCost = 1000000000;
noChange = 0;
yesChange = 0;
threshold = 5;
quit = 0;
i = 1;
%EVOLVE POPULATION
while i < NumGen && quit == 0

    tic; 
    [GAPop, average, bestCost] = evolve(GAPop,PopSize,purchaseAmountMap,inventoryMap,currentPurchaseArray, distanceMap, storeNames, numItems, pCross, pMut, weightDist, weightPrice);
    stats(i,:) = [average, bestCost];
 
    %ADAPT------------------------ 
    if lastCost == bestCost
         noChange = noChange + 1;
        yesChange = 0;
    else 
        noChange = 0;
        yesChange = yesChange + 1;
    end
 
    if noChange > threshold 
        if pCross > 0.3
            pCross = pCross - 0.1;
            pMut = 1- pCross;
            noChange = 0;
            threshold = threshold + 5; 
        else
            quit = 1;
            disp(i);
        end 
    elseif yesChange > 3 && pCross < 0.8
        pCross = pCross + 0.1;
        pMut = 1- pCross;
        yesChange = 0;
    end
    lastCost = bestCost;
    i = i+1;
    time(i) = toc;
end 
numIt = i-1;
for j=1:PopSize
    bestCost = 100000;
    worstCost = 0;
    popFitness(j) = GAPop{j}('bestSolnCost');
    if popFitness(j)<bestCost
        bestCost = popFitness(j);
        bestSolution2 = GAPop{j};
    elseif popFitness(j)>worstCost(1)
        worstCost = [popFitness(j) j];
        worstSolution2 = GAPop{j};
    end
end
%disp(pCross);
%disp(time);
%BEST SOLUTION
plot(stats);
bestSolution = bestSolution2('bestSolnCost');
bestRoute = bestSolution2('route');
result = [bestSolution numIt];

function new = copy(this)
% Instantiate new object of the same class.
new = feval(class(this));
 
% Copy all non-hidden properties.
new('bestSolnCost') = this('bestSolnCost');
new('route') = this('route');
new('storeList') = this('storeList');
new('bestPurchaseArray') = this('bestPurchaseArray');

function [GAPop, average, bestCost] = evolve(GAPop,PopSize, purchaseAmountMap, inventoryMap, currentPurchaseArray, distanceMap, storeNames, numItems, pCross, pMut, weightDist, weightPrice)
bestCost = 100000000000;
worstCost = [0, 0]; %value, index
for j=1:PopSize
    popFitness(j) = GAPop{j}('bestSolnCost');
    if popFitness(j)<bestCost
        bestCost = popFitness(j);
        bestSolution = GAPop{j};
    elseif popFitness(j)>worstCost(1)
        worstCost = [popFitness(j) j];
        worstSolution = GAPop{j};
    end
end

average = median(popFitness);
bestFit = min(popFitness);

newSoln = copy(bestSolution);
if worstCost(2) ~= PopSize
    GAPop{worstCost(2)} = GAPop{PopSize};
end %ignore last element in mutation and crossover
GAPop{PopSize} = newSoln;
%-------------------------------------------
randomIndex = randperm(PopSize-1);
index = 1;
randomIndex2 = randi(numItems,1,PopSize);
%CROSSOVER
while index <= pCross*(PopSize-1)
    %get random part of the population
    First = GAPop{randomIndex(index)};
    Second = GAPop{randomIndex(index+1)};
    %randomly select an item to swap stores for
    swapID = randomIndex2(index);
    swapItem = currentPurchaseArray(swapID);
    firstindex = 1;
    secondindex = 1;
    FirstArray = First('bestPurchaseArray');
    SecondArray = Second('bestPurchaseArray');
    %get indices of items
    done = 0;
    l = 1;
    while l<=numItems(2) && done<2
        if 1 == cellfun(@strcmp, FirstArray(l), swapItem)
            firstindex = l;
            done = done +1;
        end
        if 1 == cellfun(@strcmp, SecondArray(l), swapItem)
            secondindex = l;
            done = done + 1;
        end
        l = l+1;
    end 
    %swap stores
    FirstStores = First('storeList');
    SecondStores = Second('storeList');

    FirstRoute = First('route');
    SecondRoute = Second('route');

    swappedItem = FirstStores(firstindex);
    FirstStores(firstindex) = SecondStores(secondindex);
    FirstRoute(firstindex+1) = SecondStores(secondindex);
    SecondStores(secondindex) = swappedItem;
    SecondRoute(secondindex+1) = swappedItem;

    First('storeList') = FirstStores;
    Second('storeList') = SecondStores;

    First('route') = FirstRoute;
    Second('route') = SecondRoute;
    [distCost, priceCost] = evaluateSoln(FirstRoute,FirstArray,FirstStores, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
    First('bestSolnCost') = weightDist * distCost + weightPrice * priceCost;
    [distCost, priceCost] = evaluateSoln(SecondRoute,SecondArray,SecondStores, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
    Second('bestSolnCost') = weightDist * distCost + weightPrice * priceCost;

    index = index + 2;
end
%--------------
%MUTATION
randItemPerm = randperm(numItems(2));
randItemPerm(numItems+1)=randItemPerm(1);

for k = index:PopSize-1
    First = GAPop{randomIndex(k)};
    swapID1 = randomIndex2(index);
    swapItem1 = currentPurchaseArray(swapID1);
    %can't have the same store swap, must have unique value
    if swapID1 == randItemPerm(swapID1)
        swapID2 = randItemPerm(swapID1+1);
    else 
        swapID2 =  randItemPerm(swapID1);
    end
    swapItem2 = currentPurchaseArray(swapID2);

    FirstArray = First('bestPurchaseArray');
    %get indices of items
    
    switchID = rem(randItemPerm(swapID1)+index, numItems(2)) + 1;
    switchItem = currentPurchaseArray(switchID);
    %disp(switchID);
    l = 1;
    done = 0;
    while l<=numItems(2) && done<3
        if 1 == cellfun(@strcmp, FirstArray(l), swapItem1)
            firstindex = l;
            done = done +1;
        end
        if 1 == cellfun(@strcmp, FirstArray(l), swapItem2)
            secondindex = l;
            done = done + 1;
        end
        if 1 == cellfun(@strcmp, FirstArray(l), switchItem)
            switchindex = l;
            done = done + 1;
        end
        l = l+1;
    end 
    
    FirstStores = First('storeList');
    FirstRoute = First('route');
    %switch bewteen store and other possible store
    %switch index is location of object in list
    storeItemMap = inventoryMap(switchItem{1});
    storeKeys = keys(storeItemMap);
    slot = randi(size(storeKeys,2));
    FirstStores{switchindex} = char(storeKeys{slot}); %Choose random store rather than first store.
       
    %swap stores


    FirstArray(secondindex) = swapItem1;
    FirstArray(firstindex) = swapItem2;

    swappedItem = FirstStores(firstindex);
    FirstStores(firstindex) = FirstStores(secondindex);
    FirstRoute(firstindex+1) = FirstStores(secondindex);
    FirstStores(secondindex) = swappedItem;
    FirstRoute(secondindex+1) = swappedItem;


    First('bestPurchaseArray') = FirstArray;
    First('storeList') = FirstStores;
    First('route') = FirstRoute;
    [distCost, priceCost] = evaluateSoln(FirstRoute,FirstArray,FirstStores, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
    First('bestSolnCost') = weightDist * distCost + weightPrice * priceCost;
end
