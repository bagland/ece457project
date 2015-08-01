%{
	User Input requirements, start location + what they want to purchase
	objective function: SolnCost = weightDist * distanceCost + weightPrice * priceCost
	Tabu memory: swap stores, take MIN cost per iteration
	Tabu length- adaptive approach
%}

%shopping list
currentPurchaseArray = {'Apples', 'Chicken', 'Oranges', 'Duck', 'VeryExpensiveItem', 'Stationery', 'MediumItem'};
purchaseAmountMap = containers.Map;
purchaseAmountMap('Apples') = 5;
purchaseAmountMap('Chicken') = 1;
purchaseAmountMap('Oranges') = 1;
purchaseAmountMap('Duck') = 1;
purchaseAmountMap('VeryExpensiveItem') = 5;
purchaseAmountMap('Stationery') = 1;
purchaseAmountMap('MediumItem') = 5;

%currentPurchaseArray = {'Chicken', 'Duck'};
%purchaseAmountMap = containers.Map;
%purchaseAmountMap('Duck') = 5;
%purchaseAmountMap('Chicken') = 2;

% pick the depot
startLocation = 'Location_1';

%Get files
distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventory('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numItems = size(currentPurchaseArray);

%Initialize TS params
tabu_length = 3;
dim_store = size(storeNames,1);
tabu_mem = zeros(dim_store, dim_store);


% distanceMap('Location_1');


%Neighbourhood operator probabilities
numSuccessiveImprovement = 0;
swapProbability = 0.85;
numSwapsToMake = 5;
randomStoreProbability = 0.85;
numRandomStoreToMake = 5;
reduceNeighbourhoodThreshold = 50; % If we have a big delta F from the best soln, we should decrease neighbourhood to intensify

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
    storeKeys = keys(storeItemMap);% contains list of stores that sells that itemName
    count = count + 1;

    slot = randi(size(storeKeys,2));
    storeList{count} = storeKeys{slot}; %Choose random store rather than first store.
    %storeList{count} = storeKeys{1};
end

%Select 1st store that sells each item as initial soln and generate route
%Route is initialLoc, store1, store2...., storeN, initialLoc
midRoute{1} = startLocation; %midroute contains start+end+middle stores
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

maxNumRuns = 5
runNum = 0;
totalLoopTimeTaken = 0;
% main search loop
while (runNum < maxNumRuns)
    
    tic
    %TS swap
	if (rand() < swapProbability && numItems(2) > 1)
		tmpRoute = midRoute;
        cost = zeros(dim_store);
		
        for numSwaps = 1 : size(midRoute)
            %disp('swap');
            firstSlot = randi(numItems);
            secondSlot = randi(numItems);

            % assume > 1 items. or else infinite loop
            while secondSlot == firstSlot
               secondSlot = randi(numItems);
            end

            %Swap the items in the grocery list, the currentPurchaseArray
            temp = currentPurchaseArray{firstSlot};
            currentPurchaseArray{firstSlot} = currentPurchaseArray{secondSlot};
            currentPurchaseArray{secondSlot} = temp;

            %Swap them in the reference store list. (need these keys in order)
            temp = storeList{firstSlot};
            storeList{firstSlot} = storeList{secondSlot};
            storeList{secondSlot} = temp;

            %Swap in the route
            temp = tmpRoute{firstSlot+1};
            tmpRoute{firstSlot+1} = tmpRoute{secondSlot+1};
            tmpRoute{secondSlot+1} = temp;

            %swap the current store order.
            temp = currentStoreList{firstSlot};
            currentStoreList{firstSlot} = currentStoreList{secondSlot};
            currentStoreList{secondSlot} = temp;
			
			% evaluate swapped cost
			[distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
			currentSolnCost = weightDist * distCost + weightPrice * priceCost;
			
			%append value to route cost to array
			cost(numSwaps)= currentSolnCost;
        end
		
		% select swap store pair with lowest cost from array, input tabu entry
		[val,I] = min(cost);
		
		% insert tabu_length into tabu_mem(I)
		
    end
	
	% decrement all tabu entry by 1
	for row = 1:dim_store-1 
	   for col = row+1:dim_store 

		 if tabu_mem(row,col)>0 
		 
			tabu_mem(row,col)= tabu_mem(row,col) - 1; 
			tabu_mem(col,row)= tabu_mem(row,col); 

		 end 
	   end 
	end 
    
    % new trip, 
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
        
    runNum = runNum + 1;
    
    %DO NOT INCLUDE GRAPH DRAW TIME IN LOOP TIME
    loopTimeTaken = toc;
    totalLoopTimeTaken = totalLoopTimeTaken + loopTimeTaken;
    
end

avgLoopTimeTaken = totalLoopTimeTaken/runNum;
fprintf('Best soln in %d runs\n', runNum);
fprintf('Avg loop time %d seconds, full time taken %d\n', avgLoopTimeTaken, totalLoopTimeTaken);
disp(bestcurrentPurchaseArray);
disp(bestStoreList);
disp(bestSolnCost);
