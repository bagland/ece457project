%{
	User Input requirements, start location + what they want to purchase
	objective function: SolnCost = weightDist * distanceCost + weightPrice * priceCost
	Tabu memory: swapped stores, take MIN cost per iteration
	Aspiration: willing to accept tabu solution iff solution is better than best overall solution so far
	Tabu length- adaptive approach
%}
function [results, route, items] = TS(maxNumRuns, tabu_length)

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

%Get files
distanceMap = parse_distances('REAL_distances.txt');
inventoryMap = parse_inventories('REAL_inventory.txt');
storeNames = store_names('REAL_distances.txt');
numItems = size(currentPurchaseArray);

%Initialize required TS params
%tabu_length = 10;
dim_store = size(storeNames,2);
currentBestSol = inf;
currentSolnCost = 0;
tabu_mem = zeros(dim_store, dim_store);
prev_iter_sol= 0;


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

%maxNumRuns = 1000;
runNum = 0;
totalLoopTimeTaken = 0;

solnXAxis = runNum;
solnYAxis = currentSolnCost;
x = plot(solnXAxis, solnYAxis, 'YDataSource', 'solnYAxis', 'XDataSource', 'solnXAxis');

% main search loop
while (runNum < maxNumRuns)
    
    tic
    %TS swap
	tmpRoute = midRoute;
	tmpstoreList = storeList;
	tmpcurrentStoreList = currentStoreList;
	tmpcurrentPurchaseArray = currentPurchaseArray;
	swap_pair = {}; % each element has [row index, col index, cost value]
	numSwaps = 1;
	revoke_T = 0;
	
	% go thru all possible pairwise swaps
	for firstSlot =1: size(tmpcurrentStoreList, 2)
		for secondSlot = firstSlot+1 : size(tmpcurrentStoreList, 2)
				
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
			
			% considered both tabu memory and aspiration criteria
			if(tabu_mem(firstSlot, secondSlot) >1 && currentBestSol < currentSolnCost)
				%case tabu, append route cost to very large cost, so won't be eval as lowest obj function
				swap_pair{1, numSwaps} = [firstSlot,secondSlot, inf];
			elseif(tabu_mem(firstSlot, secondSlot) >1 && currentBestSol > currentSolnCost)
				% case aspiration
				revoke_T = 1;
				swap_pair{1, numSwaps} = [firstSlot,secondSlot, currentSolnCost];
			else
				% case no tabu, simply store currentsolution to temporary memory
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
	for k = 1:size(swap_pair, 2) 
		 if (swap_pair{1,k}(3) < tmpCost)
			tmpCost = swap_pair{1,k}(3);
			tmpi = swap_pair{1,k}(1);
			tmpj= swap_pair{1,k}(2);
		 end 
	end 
	
	%update current best solution for aspiration criteria
	if(currentBestSol > tmpCost)
		currentBestSol = tmpCost;
	end
	
	% apply adaptive operator
	if(prev_iter_sol > tmpCost)
		tabu_length = tabu_length + 1; %deteriorated
	elseif(prev_iter_sol < tmpCost)
		tabu_length = tabu_length - 1; % improved
	end
	
	% insert tabu_length into tabu matrix
	if(revoke_T > 0)
		tabu_mem(tmpi,tmpj) = 0;
	else
		tabu_mem(tmpi,tmpj) = tabu_length;
	end
		
	
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
	
	% decrement all tabu entry by 1 at end of iteration, for recency sake
	for row = 1:size(tabu_mem, 2)
	   for col = row+1:size(tabu_mem, 2) 
			if(row ~= tmpi && col ~= tmpj)
				 if (tabu_mem(row,col) > 0) 
					tabu_mem(row,col)= tabu_mem(row,col) - 1; 
					tabu_mem(col,row)= tabu_mem(row, col);
				 end 
			end
	   end 
	end 
	
	% adaptive, remember previous iteration
	prev_iter_sol = tmpCost;
	
	%update best soln for output
	bestSolnCost = currentBestSol;
	bestcurrentPurchaseArray = currentPurchaseArray;
	bestStoreList = currentStoreList;
    
    runNum = runNum + 1;
    
    %DO NOT INCLUDE GRAPH DRAW TIME IN LOOP TIME
    loopTimeTaken = toc;
    totalLoopTimeTaken = totalLoopTimeTaken + loopTimeTaken;
    solnXAxis = [solnXAxis runNum];
    solnYAxis = [solnYAxis currentBestSol ];
    if (mod(runNum, 5) == 0)
       set (x, 'XData',solnXAxis, 'YData',  solnYAxis)
       %refreshdata
       drawnow
    end    
end

%avgLoopTimeTaken = totalLoopTimeTaken/runNum;
%fprintf('Best soln in %d runs\n', runNum);
%fprintf('Avg loop time %d seconds, full time taken %d\n', avgLoopTimeTaken, totalLoopTimeTaken);
%disp(bestcurrentPurchaseArray);
%disp(bestStoreList);
%disp(bestSolnCost);
results = [bestSolnCost runNum];
route = bestStoreList;
items = bestcurrentPurchaseArray;