%{
	User Input requirements, start location + what they want to purchase
	objective function: SolnCost = weightDist * distanceCost + weightPrice * priceCost
	Tabu memory: swapped stores, take MIN cost per iteration
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


% pick the starting location
startLocation = 'Location_1';

%Get files
distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventory('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numItems = size(currentPurchaseArray);

%Initialize required TS params
tabu_length = 4;
dim_store = size(storeNames,2);
currentBestSol = inf;
currentSolnCost = 0;
tabu_mem = zeros(dim_store, dim_store);


%adaptive Neighbourhood operator


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

maxNumRuns = 10;
runNum = 0;
totalLoopTimeTaken = 0;
% main search loop
while (runNum < maxNumRuns)
    
    tic
    %TS swap
	%if ( numItems(2) > 1) % does numItems ever gets decrement below 1?
		tmpRoute = midRoute;
        tmpStoreList = storeList;
		tmpCurrentStoreList = currentStoreList;
		tmpCurrentPurchase = currentPurchaseArray;
		swap_pair = {}; % each element has [row index, col index, cost value]
		numSwaps = 1;
		
		% go thru all possible pairwise swaps
		for firstSlot =1: size(midRoute)
			for secondSlot = firstSlot+1 : size(midRoute)
				
				% considered both tabu memory and aspiration criteria
				if(tabu_mem(firstSlot, secondSlot) >1 && currentBestSol < currentSolnCost)
					%tabu append route cost to very large cost, so won't be eval as lowest obj function
					swap_pair{1, numSwaps} = [firstSlot,secondSlot, inf];
					
				else
					%Swap the items in the grocery list, the currentPurchaseArray
					temp = tmpcurrentPurchaseArray{firstSlot};
					tmpcurrentPurchaseArray{firstSlot} = tmpcurrentPurchaseArray{secondSlot};
					tmpcurrentPurchaseArray{secondSlot} = temp;

					%Swap them in the reference store list. (need these keys in order)
					temp = tmpstoreList{firstSlot};
					tmpstoreList{firstSlot} = tmpstoreList{secondSlot};
					tmpstoreList{secondSlot} = temp;

					%Swap in the route, frist node in midroute isn't a store
					temp = tmpRoute{firstSlot+1};
					tmpRoute{firstSlot+1} = tmpRoute{secondSlot+1};
					tmpRoute{secondSlot+1} = temp;

					%swap the current store order.
					temp = tmpcurrentStoreList{firstSlot};
					tmpcurrentStoreList{firstSlot} = tmpcurrentStoreList{secondSlot};
					tmpcurrentStoreList{secondSlot} = temp;
					
					% evaluate swapped obj func solution
					[distCost, priceCost] = evaluateSoln(midRoute,tmpcurrentPurchaseArray,tmpcurrentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
					currentSolnCost = weightDist * distCost + weightPrice * priceCost;
					
					%append currentsolution to temporary memory
					swap_pair{1, numSwaps} = [firstSlot,secondSlot, currentSolnCost];
					
				end
				numSwaps = numSwaps +1;
			end
			
        end
		
		% find min cost from all swap pair solutions
		% matlab list counts from index 1 instead of 0
		tmpCost = inf;
		tmpi =1;
		tmpj=1;
		for k = 1:size(swap_pair) 
			 if (swap_pair{1,k}(3) < tmpCost)
				tmpCost = swap_pair{i,k}(3);
				tmpi = swap_pair{1,k}(1);
				tmpj= swap_pair{1,k}(2);
			 end 
		end 
		
		%update current best solution for aspiration criteria
		if(currentBestSol > tmpCost)
			currentBestSol = tmpCost;
		end
		
		% insert tabu_length into tabu matrix
		tabu_mem(tmpi,tmpj) = tabu_length;
		
		%finally, execute actual current best swap for next iteration
		%Swap the items in the grocery list, the currentPurchaseArray
		temp = currentPurchaseArray{tmpi};
		currentPurchaseArray{tmpi} = currentPurchaseArray{tmpj};
		currentPurchaseArray{tmpj} = temp;

		%Swap them in the reference store list. (need these keys in order)
		temp = storeList{tmpi};
		storeList{tmpi} = storeList{tmpj};
		storeList{tmpj} = temp;

		%Swap in the route, frist node in midroute isn't a store
		temp = midRoute{tmpi+1};
		midRoute{tmpi+1} = midRoute{tmpj+1};
		midRoute{tmpj+1} = temp;

		%swap the current store order.
		temp = currentStoreList{tmpi};
		currentStoreList{tmpi} = currentStoreList{tmpj};
		currentStoreList{tmpj} = temp;
		
		
    %end
	
	% decrement all tabu entry by 1 at end of iteration, for recency sake
	for row = 1:size(tabu_mem)
	   for col = row+1:size(tabu_mem) 

		 if tabu_mem(row,col) > 0 
			tabu_mem(row,col)= tabu_mem(row,col) - 1; 
			tabu_mem(col,row)= tabu_mem(col,row) - 1;
		 end 
	   end 
	end 
    
    % new trip, how to generate new swapped route, not random trip
    % if (rand() < randomStoreProbability)
        %Random Store
        %disp('randomstore.');
        % for numRandomStores = 1 : numRandomStoreToMake
            % whatItem = randi(numItems); %Pick which item select a different store.
            % itemCharName = currentPurchaseArray{whatItem};
            % storeItemMap = inventoryMap(itemCharName); %Get what stores sell that item
            % storeKeys = keys(storeItemMap);
            % whatStore = randi(size(storeKeys)); % Pick a random store in that list
            % currentStoreList{whatItem} = storeKeys{whatStore};
            % midRoute{whatItem+1} = storeKeys{whatStore};
        % end
		
    % end
        
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
