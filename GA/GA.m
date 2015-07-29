function [solution] = GA()

%large value to ensure nonnegative fitness
V = 1000; %todo: find actual value
%pop size
PopSize = 10;
%number of generations
NumGen = 50;

%make up input, should put in file later
numItems = 7;
currentPurchaseArray = {'Apples', 'Chicken', 'Oranges', 'Duck', 'VeryExpensiveItem', 'Stationery', 'MediumItem'};
%currentPurchaseArray = { 'Chicken', 'Oranges', 'Stationery', 'MediumItem'};
purchaseAmountMap = containers.Map;
purchaseAmountMap('Apples') = 5;
purchaseAmountMap('Chicken') = 1;
purchaseAmountMap('Oranges') = 1;
purchaseAmountMap('Duck') = 1;
purchaseAmountMap('VeryExpensiveItem') = 5;
purchaseAmountMap('Stationery') = 1;
purchaseAmountMap('MediumItem') = 5;
startLocation = 'Location_1';
disp(purchaseAmountMap);

distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventories('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numItems = size(currentPurchaseArray);

%generate initial population
%get list of all of the stores that contain the given required products
  
%percentage of population to get crossover
pCross = 0.5;
pMut = 1-pCross;


%Objective Fcn
weightDist = 0.5;
weightPrice = 1 - weightDist;

GAPop = cell(PopSize);
    
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
    %disp(midRoute);
    dataMap('storeList') = currentStoreList;
    %disp(currentStoreList);
    dataMap('amountMap') = purchaseAmountMap;
    dataMap('bestSolnCost') = currentSolnCost;
    %disp(currentSolnCost);
    dataMap('bestPurchaseArray') = itemPurchaseArray;
    %disp(itemPurchaseArray);
    dataMap('bestStoreList') = currentStoreList;
    dataMap('bestSolnCost') = currentSolnCost;
    %dataMap('bestPurchaseArray') = itemPurchaseArray;
    %dataMap('bestStoreList') = currentStoreList;
    
    GAPop{i} = dataMap;
    %disp(dataMap);
end
  %manipulate population???
for i = 1:NumGen
  %select parents - find best fitness parents
  %choosing pop that has better fitness than mean
 %-----------------------------------
 %remove worst, keep best doubled
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
    %disp(popFitness);
    average = median(popFitness);
    bestFit = min(popFitness);
    %disp(average);
    stats(i,:) = [average, bestCost];
    %add best solution to next generation
    
    nextGen{PopSize} = bestSolution;
    %disp(nextGen);
    disp(i);
    disp(bestCost);
    %remove worst solution from pool
    if worstCost(2) ~= PopSize
        GAPop{worstCost(2)} = GAPop{PopSize};
    end %ignore last element in mutation and crossover
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
        
        %disp(swappedItem)
        %can we change GA to only need the storelist and the start location
        %disp(FirstStores);
        %disp(FirstArray);
        [distCost, priceCost] = evaluateSoln(FirstRoute,FirstArray,FirstStores, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        First('bestSolnCost') = weightDist * distCost + weightPrice * priceCost;
        %disp(First('bestSolnCost'));
        %disp(SecondStores);
        %disp(SecondArray);
        [distCost, priceCost] = evaluateSoln(SecondRoute,SecondArray,SecondStores, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        Second('bestSolnCost') = weightDist * distCost + weightPrice * priceCost;
        %disp(Second('bestSolnCost'));
        if (index+1<PopSize)
        nextGen{index} = First;
        nextGen{index+1} = Second;
  %disp(nextGen{PopSize}('bestSolnCost'));
        end
        index = index + 2;
    end
    %--------------
%MUTATION
    randItemPerm = randperm(numItems(2));
    randItemPerm(numItems+1)=randItemPerm(1);
    
    for k = index:PopSize-1
        First = GAPop{randomIndex(k)};
        %swap order of things, need two stores to swap
        %buy 2 things in different order, evaluate solution will collapse
        %the items
        swapID1 = randomIndex2(index);
        swapItem1 = currentPurchaseArray(swapID1);
        if swapID1 == randItemPerm(swapID1)
            swapID2 = randItemPerm(swapID1+1);
        else 
            swapID2 =  randItemPerm(swapID1);
        end
        swapItem2 = currentPurchaseArray(swapID2);
        
        FirstArray = First('bestPurchaseArray');
        %get indices of items
        l = 1;
        done = 0;
        while l<=numItems(2) && done<2
            if 1 == cellfun(@strcmp, FirstArray(l), swapItem1)
                firstindex = l;
                done = done +1;
            end
            if 1 == cellfun(@strcmp, FirstArray(l), swapItem2)
                secondindex = l;
                done = done + 1;
            end
            l = l+1;
        end 
        %swap stores
        FirstStores = First('storeList');
        FirstRoute = First('route');

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
        

        %can we change GA to only need the storelist and the start location
        [distCost, priceCost] = evaluateSoln(FirstRoute,FirstArray,FirstStores, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        %disp(nextGen{PopSize}('bestSolnCost'));
        First('bestSolnCost') = weightDist * distCost + weightPrice * priceCost;
        
        %disp('2');
        %disp(nextGen{PopSize}('bestSolnCost'));
        %disp(First('bestSolnCost'));
        %disp('first time in mutation');
        %disp(index);
        %disp(PopSize);
        nextGen{index} = First;
        %disp(nextGen{PopSize}('bestSolnCost'));
        %disp(nextGen{PopSize}('route'));
        index = index + 1;
    end
    %-----------------------------
        %mutate half of the population
  %how do i represent binary - right now it is a list of stores
  %swapping stores? 
  %should I have 2 lists, one with the order of the stores and one with the
  %stores where it shows where each item is bought
  %then I can swap around the second one
  %and mutate the first one??? - I would need to remove 
  %apply crossover
  %mutate offspring
  %get next gen
  disp(nextGen{PopSize}('bestSolnCost'));
  GAPop = nextGen;
end
    %can swap out stores to get lower cost or 
    %swap out store orders to get lower distance
    
  
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

plot(stats);
  %return best solution
solution = [bestSolution('route'), bestSolution('bestSolnCost')];

