%User Input requirements, starting location + what they want to purchase
currentPurchaseArray = {'Apples', 'Chicken', 'Oranges', 'Duck', 'VeryExpensiveItem'};
startLocation = 'Location_1';

%Standard SA params.
boltzman = 1;
initialTemp =1.0; 
maxNumRuns = 1000;
alpha=0.95; % Cooling factor
temperature = initialTemp;
runNum = 0;

swapProbability = 0.5;
randomStoreProbability = 1 - swapProbability;

%Objective Fcn
weightDist = 0.5;
weightPrice = 1 - weightDist;

distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventory('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numItems = size(currentPurchaseArray);

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
[distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray,currentStoreList, distanceMap, inventoryMap, storeNames);
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

while (runNum < maxNumRuns)
    
    %swap
    if (rand() < swapProbability)
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
    else
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
    [distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray,currentStoreList, distanceMap, inventoryMap, storeNames);
    currentSolnCost = weightDist * distCost + weightPrice * priceCost;

    %Best soln we've seen so far
    if (currentSolnCost < bestSolnCost)
        bestSolnCost = currentSolnCost;
        bestcurrentPurchaseArray = currentPurchaseArray;
        bestStoreList = currentStoreList;
        iterSolnCost = currentSolnCost;
        itercurrentPurchaseArray = currentPurchaseArray;
        iterStoreList = currentStoreList;
    %Better than the current soln we have
    elseif (currentSolnCost < iterSolnCost)
        iterSolnCost = currentSolnCost;
        itercurrentPurchaseArray = currentPurchaseArray;
        iterStoreList = currentStoreList;
    else
        %SA check probability of acceptance.
        difference = currentSolnCost - iterSolnCost;
        if exp(-difference/(boltzman*temperature))>rand()
           %Accept when worse 
           iterSolnCost = currentSolnCost;
           itercurrentPurchaseArray = currentPurchaseArray;
           iterStoreList = currentStoreList;
        end
            
    end
    %cooldown
    %Can change this too.
    temperature = temperature * alpha;
    runNum = runNum + 1;
end
disp('Best soln');
disp(bestcurrentPurchaseArray);
disp (bestStoreList);
disp(bestSolnCost);
