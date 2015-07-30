
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
inventoryMap = parse_inventories('outputInventory.txt');
storeNames = store_names('outputDistance.txt');
numStores = length(storeNames);
numItems = size(currentPurchaseArray);

%Initial paramters
numParticles = 10;  %size of the swarm
probDim = 2;    %dimension of the problem
maxIterations = 20000;   %maximum number of iterations
swarmSize = 10; %unused
neighbourhoodSize = 1;  %unused (whole swarm is a neighbourhood)
c1 = 1; %acceleration coefficient - cognitive parameter
c2 = 4-c1;  %acceleration coefficient - social parameter
w = 0.792;  %inertia weight

%Other parameters
noIterImprovement = 0;
noIterImprovementExit = 500;

%Objective function
weightDist = 0.5;
weightPrice = 1 - weightDist;

%Generate initial solution
pbest = zeros(numParticles);
storeList = cell(numItems);
count = 0;

%Get stores that sell the items we want
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
currentStoreList
midRoute{count} = startLocation;
%get initial soln cost
[distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
currentSolnCost = weightDist * distCost + weightPrice * priceCost;
midRoute

%Select 1st store that sells each item as initial soln and generate route
%Route is initialLoc, random permutation of store list, initialLoc
for i = 1:numParticles
    midRoute{1} = startLocation;
    currentStoreList = cell(size(currentPurchaseArray));
    count = 2;
    permutation = randperm(length(storeList));
    randStoreList=storeList(permutation);
    for loc = randStoreList
        midRoute{count} = loc{1};
        currentStoreList{count - 1} = loc{1};
        count = count + 1;
    end
    midRoute{count} = startLocation;
    midRoute
    currentStoreList
    randStoreList
    %Get initial solution cost
    for j = 1:numParticles
       [distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray, currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
       currentSolnCost = weightDist * distCost + weightPrice * priceCost;
       pbest(j) = currentSolnCost;
    end
end

%Stored best solution for output
gbest = min(pbest);
bestcurrentPurchaseArray = currentPurchaseArray;
bestStoreList = currentStoreList;

%Stored current solutionn to compare against (we may have accepted a worse soln
%than the best)
iterSolnCost = currentSolnCost;
itercurrentPurchaseArray = currentPurchaseArray;
iterStoreList = currentStoreList;

%Graphing
solnXAxis = 0;
solnYAxis = iterSolnCost;
thePlot = plot(solnXAxis, solnYAxis)
set(thePlot, 'XDataSource', 'solnXAxis')
set(thePlot, 'YDataSource','solnYAxis')

%Iteration loop
iter = 0;
totalLoopTimeTaken = 0;
while (iter < maxIterations || noIterImprovement >= noIterImprovementExit)
   for i = 1:numParticles
       %Calculate fitness value
       [distCost, priceCost] = evaluateSoln(midRoute,currentPurchaseArray,currentStoreList, purchaseAmountMap, distanceMap, inventoryMap, storeNames);
       currentSolnCost = weightDist * distCost + weightPrice * priceCost;
       
       if (currentSolnCost < pbest(i))
           pbest(i) = currentSolnCost;
       end
   end
   %Choose the particle with best fitness value of all the particles as the gbest
   
   for i = 1:numParticles
       %v[t+1] = w*v[t] + c1*rand()*(pbest[]-x[t]) + c2*rand()*(gbest[]-x[t])
       %x[t+1] = x[t] + v[t+1]
   end
   iter = iter + 1;
   
   %Graph update
   if (mod(iter, 200) == 0)
       refreshdata
       drawnow
   end
end


refreshdata
drawnow

avgLoopTimeTaken = totalLoopTimeTaken/iter;
fprintf('Best soln in %d runs\n', iter);
fprintf('Avg loop time %d seconds, full time taken %d\n', avgLoopTimeTaken, totalLoopTimeTaken);
disp(bestcurrentPurchaseArray);
disp(bestStoreList);
disp(gbest);

