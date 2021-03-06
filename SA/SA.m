function [results, route, items] = SA(initialTempFactor, maxNumRuns, alpha)

%Standard SA params.
boltzman = 1;
%initialTempFactor = 0.8; % is percentage goal look later based on problem data size.
%maxNumRuns = 25000;
%alpha=0.9; % Cooling factor used is geometric, T = T * alpha

%Other params.
    %Stagnation/stuck in local minimum
noIterImprovement = 0;
numNoIterImprovementExit = 10000; %BREAK EARLY, WE ARE REALLY STUCK TRY AGAIN
noIterImprovementReheat = 500;
numNoIterImprovementSwap = 800;
numNoIterImprovementRandomStore = 600;

reheatValue = 1.05;
reheatRunThreshold = maxNumRuns/2; %STOP REHEATING IF PAST THIS POINT!

    %Few iterations on initial temp, more on lower and lower temps
currTempIter = 0;
numIterPerTempDecrease = 20;
numIterPertempDecreaseIncrement = 20;

    %Neighbourhood operator probabilities
swapProbability = 0.85;
numSwapsToMake = 2;
randomStoreProbability = 0.5;
numRandomStoreToMake = 3;
maxRandomStore = 5;
maxSwaps = 5;

%Objective Fcn
weightDist = 0.5;
weightPrice = 1 - weightDist;

%User Input requirements, starting location + what they want to purchase
% You need more than 2 items to swap.
currentPurchaseArray = {'fish_fillet', 'astro_yogurt', 'boneless_pork_chop', 'shredded_cheese', 'juice', 'coffee', 'grape', 'post_cereal', 'pepsi', 'cheese_bar', 'pc_chicken_breast', 'entree', 'water', 'salsa', 'salad'};
purchaseAmountMap = containers.Map;
purchaseAmountMap('fish_fillet') = 5;
purchaseAmountMap('astro_yogurt') = 10;
purchaseAmountMap('boneless_pork_chop') = 1;
purchaseAmountMap('shredded_cheese') = 1;
purchaseAmountMap('juice') = 5;
purchaseAmountMap('coffee') = 1;
purchaseAmountMap('grape') = 1;
purchaseAmountMap('post_cereal') = 1;
purchaseAmountMap('pepsi') = 6;
purchaseAmountMap('cheese_bar') = 1;
purchaseAmountMap('pc_chicken_breast') = 1;
purchaseAmountMap('entree') = 1;
purchaseAmountMap('water') = 6;
purchaseAmountMap('salsa') = 1;
purchaseAmountMap('salad') = 2;
startLocation = 'location_university_of_waterloo_1';

%get values
distanceMap = parse_distances('REAL_distances.txt');
inventoryMap = parse_inventories('REAL_inventory.txt');
storeNames = store_names('REAL_distances.txt');
numItems = size(currentPurchaseArray);



%Generating an initial soln------------
storeList = cell(numItems);
count = 0;


Perm1 = randperm(length(currentPurchaseArray));
currentPurchaseArray = currentPurchaseArray(Perm1);

%Get Stores that sell the items we want.
for itemName = currentPurchaseArray
    itemCharName = itemName{1};
    storeItemMap = inventoryMap(itemCharName);
    storeKeys = keys(storeItemMap);
    count = count + 1;

    slot = randi(size(storeKeys,2));
    storeList{count} = storeKeys{slot}; %Choose random store rather than first store.
    %storeList{count} = storeKeys{1};
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
bestStoreRoute = midRoute;

%initial temp was percentage goal.
initialTemp =  -(bestSolnCost * 0.1) / log(initialTempFactor) ; 
temperature = initialTemp;
reduceNeighbourhoodThreshold = bestSolnCost * 0.1; % If we have a big delta F from the best soln, we should decrease neighbourhood to intensify


%Stored current soln to compare against (we may have accepted a worse soln
%than the best)
iterSolnCost = currentSolnCost;
itercurrentPurchaseArray = currentPurchaseArray;
iterStoreList = currentStoreList;

%Graphing
solnXAxis = 0;
solnYAxis = iterSolnCost;
thePlot = plot(solnXAxis, solnYAxis, 'YDataSource', 'solnYAxis', 'XDataSource', 'solnXAxis');
%set(thePlot,'XDataSource', 'solnXAxis');
%set(thePlot,'YDataSource', 'solnYAxis');
%linkdata on


runNum = 0;
totalLoopTimeTaken = 0;
while (runNum < maxNumRuns && noIterImprovement < numNoIterImprovementExit)
    
    tic
    %swap
    if (rand() < swapProbability && numItems(2) > 1)
        for numSwaps = 1 : numSwapsToMake
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
    end
    if (rand() < randomStoreProbability)
        %Random Store
        %disp('randomstore.');
        for numRandomStores = 1 : numRandomStoreToMake
            whatItem = randi(numItems); %Pick which item select a different store.
            itemCharName = currentPurchaseArray{whatItem};
            storeItemMap = inventoryMap(itemCharName); %Get what stores sell that item
            storeKeys = keys(storeItemMap);
            whatStore = randi(size(storeKeys)); % Pick a random store in that list
            currentStoreList{whatItem} = storeKeys{whatStore};
            midRoute{whatItem+1} = storeKeys{whatStore};
        end
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
        bestStoreRoute = midRoute;
        
        iterSolnCost = currentSolnCost;
        itercurrentPurchaseArray = currentPurchaseArray;
        iterStoreList = currentStoreList;
        noIterImprovement = 0;
        
        if deltaCost > reduceNeighbourhoodThreshold
            numSwapsToMake = max(1,numSwapsToMake - 1);
            numRandomStoreToMake = max(1,numRandomStoreToMake - 1);
            %disp('less swaps');
        end
        
    %Better than the current soln we have
    elseif (currentSolnCost < iterSolnCost)
        iterSolnCost = currentSolnCost;
        itercurrentPurchaseArray = currentPurchaseArray;
        iterStoreList = currentStoreList;
        noIterImprovement = 0;
        if deltaCost > reduceNeighbourhoodThreshold
            numSwapsToMake = max(1,numSwapsToMake - 1);
            numRandomStoreToMake = max(1,numRandomStoreToMake - 1);
            %disp('less swaps');
        end
        
    else
        %SA check probability of acceptance.
        chance = exp(-deltaCost/(boltzman*temperature));
        %disp (runNum);
        %disp(chance);
        %disp(deltaCost);
        %disp('\n');
        if chance>rand()
           %Accept when worse 
           iterSolnCost = currentSolnCost;
           itercurrentPurchaseArray = currentPurchaseArray;
           iterStoreList = currentStoreList;
        end
        
        noIterImprovement = noIterImprovement + 1;
        if (mod(noIterImprovement,noIterImprovementReheat) == 0 && runNum < reheatRunThreshold) 
            temperature = temperature * reheatValue;
            
            %disp('reheat');
        end
        
        if (mod(noIterImprovement,numNoIterImprovementSwap) == 0) 
            %disp('more swap');
            numSwapsToMake = min(numSwapsToMake + 1, maxSwaps);
        end
        
        if (mod(noIterImprovement,numNoIterImprovementRandomStore) == 0) 
            %disp('more random store');
            numRandomStoreToMake = min(numRandomStoreToMake + 1, maxRandomStore);
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
    
    %DO NOT INCLUDE GRAPH DRAW TIME IN LOOP TIME, THAT IS POINTLESS
    loopTimeTaken = toc;
    totalLoopTimeTaken = totalLoopTimeTaken + loopTimeTaken;
    
    %Graph update
    if (mod(runNum,200) == 0)
        set(thePlot, 'XData', solnXAxis, 'YData', solnYAxis);
        %refreshdata
        drawnow;
    end
    
end

%avgLoopTimeTaken = totalLoopTimeTaken/runNum;
%fprintf('Best soln in %d runs\n', runNum);
%fprintf('Avg loop time %d seconds, full time taken %d\n', avgLoopTimeTaken, totalLoopTimeTaken);
%disp(bestcurrentPurchaseArray);
%disp(bestStoreRoute);
%disp(bestSolnCost);
results(1) = bestSolnCost;
results(2) = runNum;
route = bestStoreRoute;
items = bestcurrentPurchaseArray;
