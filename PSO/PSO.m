
%User shopping list and location.
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
probDim = 2;    %unused, dimension of the problem
maxIterations = 1000;   %maximum number of iterations
swarmSize = 10; %unused
neighbourhoodSize = 1;  %unused (whole swarm is a neighbourhood)
c1 = 1.1; %acceleration coefficient - cognitive parameter
c2 = 4-c1;  %acceleration coefficient - social parameter
w = 0.792;  %inertia weight

%Other parameters
noIterImprovement = 0;
noIterImprovementExit = 500;

%Objective function
weightDist = 0.5;
weightPrice = 1 - weightDist;

%Generate initial solution
%Select a random store that sells each item as initial soln and generate route
%Route is initialLoc, random permutation of store list, initialLoc
pbest = zeros(numParticles, 1);
iterSol = zeros(numParticles, 1);
[m, n] = size(currentPurchaseArray);
pbestPurchaseArray = cell(numParticles, n);
pbestStoreList = cell(numParticles, n);
currStoreListt = cell(numParticles, n);
currPurchaseArray = cell(numParticles, n);
velocity = zeros(0,2,numParticles);
velStores = zeros(numParticles, n);
probabilityDistribution = [1/3 1/3 1/3];    %[inertia cognitive social]

possibleStores = cell(n, 1);
count = 1;
originalItemsList = currentPurchaseArray;

%Get stores that sell the items we want
for itemName = currentPurchaseArray
    itemCharName = itemName{1};
    storeItemMap = inventoryMap(itemCharName);
    storeKeys = keys(storeItemMap);
    [t1, t2] = size(storeKeys);
    for i = 1:t2
        possibleStores(count, i) = storeKeys(i);
    end
    count = count + 1;
end

for i = 1:numParticles
    storeList = cell(numItems);
    count = 0;
    %Get stores that sell the items we want
    for itemName = currentPurchaseArray
        itemCharName = itemName{1};
        storeItemMap = inventoryMap(itemCharName);
        storeKeys = keys(storeItemMap);
        count = count + 1;
        %Choose random store rather than the first store.
        slot = randi(size(storeKeys,2));
        storeList{count} = storeKeys{slot};
    end

    %Generate a random route.
    midRoute{1} = startLocation;
    currentStoreList = cell(m, n);
    count = 2;
    permutation = randperm(length(storeList));
    t1 = storeList(permutation);
    t2 = currentPurchaseArray(permutation);
    for j = 1:n
        currStoreList(i, j)= t1(j);
        currPurchaseArray(i, j) = t2(j);
    end
    
    for loc = currStoreList
        midRoute{count} = loc{1};
        count = count + 1;
    end
    midRoute{count} = startLocation;
    
    %Get initial solution cost
    [distCost, priceCost] = evaluateSoln(midRoute, currPurchaseArray(i,:), currStoreList(i,:), purchaseAmountMap, distanceMap, inventoryMap, storeNames);
    currentSolnCost = weightDist * distCost + weightPrice * priceCost;
    pbest(i) = currentSolnCost;
    pbestPurchaseArray(i, :) = currPurchaseArray(i, :);
    pbestStoreList(i, :) = currStoreList(i, :);
end

%Stored best solution for output
[gbest, index] = min(pbest);
bestcurrentPurchaseArray = pbestPurchaseArray(index,:);
bestStoreList = pbestStoreList(index,:);

%Graphing
solnXAxis = 0;
solnYAxis = gbest;
thePlot = plot(solnXAxis, solnYAxis, 'YDataSource', 'solnYAxis', 'XDataSource', 'solnXAxis')

%Iteration loop
iter = 0;
totalLoopTimeTaken = 0;
while (iter < maxIterations && noIterImprovement < noIterImprovementExit)
    
    tic
    
    for i = 1:numParticles
       %Get random values between 0 and 1
       r1 = rand;
       r2 = rand;
       inertia = velStores(i,:)*w;
       cognitive = FindDiff(pbestPurchaseArray(i,:), currPurchaseArray(i,:),  pbestStoreList(i, :), currStoreList(i,:))*r1*c1;
       social = FindDiff(bestcurrentPurchaseArray, currPurchaseArray(i,:), bestStoreList, currStoreList(i,:))*r1*c1;
       %v[t+1] = w*v[t] + c1*rand()*(pbest[]-x[t]) + c2*rand()*(gbest[]-x[t])
       temp = inertia*probabilityDistribution(1) + cognitive*probabilityDistribution(2) + social*probabilityDistribution(3);
       a = size(temp);
       for j = 1:a
           velStores(i,j) = temp(j);
       end
       %x[t+1] = x[t] + v[t+1]
       %currPurchaseArray(i,:) = GetDiffStore(currPurchaseArray(i,:),
       %temp); % Doesn't change
       currStoreList(i,:) = GetDiffStore(currStoreList(i,:), currPurchaseArray(i,:), originalItemsList, temp, possibleStores);
       
       %Get random values between 0 and 2
       r1 = 2*rand;
       r2 = 2*rand;

       inertia = Multiply(velocity(:,:,i), w);
       cognitive = Multiply(Multiply(Subtracting(pbestPurchaseArray(i,:), currPurchaseArray(i,:)), r1), c1);
       social = Multiply(Multiply(Subtracting(bestcurrentPurchaseArray, currPurchaseArray(i,:)), r2), c2);
       %v[t+1] = w*v[t] + c1*rand()*(pbest[]-x[t]) + c2*rand()*(gbest[]-x[t])
       temp = [inertia;cognitive;social];
       [a, b] = size(temp);
       if (a ~= 0)
           for j = 1:a
               for k = 1:b
                   velocity(j,k,i) = temp(j,k);
               end
           end
       end
       %x[t+1] = x[t] + v[t+1]
       currPurchaseArray(i,:) = Adding(currPurchaseArray(i,:), temp);
       currStoreList(i,:) = Adding(currStoreList(i,:), temp);
    end

    for i = 1:numParticles
        %Generate a random route.
        midRoute{1} = startLocation;
        count = 2;
        for loc = currStoreList
            midRoute{count} = loc{1};
            count = count + 1;
        end
        midRoute{count} = startLocation;
        
        %Calculate fitness value
        [distCost, priceCost] = evaluateSoln(midRoute,currPurchaseArray(i,:),currStoreList(i,:), purchaseAmountMap, distanceMap, inventoryMap, storeNames);
        currentSolnCost = weightDist * distCost + weightPrice * priceCost;
        iterSol(i) = currentSolnCost;
        if (currentSolnCost < pbest(i))
           pbest(i) = currentSolnCost;
           pbestPurchaseArray(i, :) = currPurchaseArray(i, :);
           pbestStoreList(i, :) = currStoreList(i, :);
        end
    end
    
    %Choose the particle with best fitness value of all the particles as the gbest
    [min_pbest, index] = min(pbest);
    [min_iter, ~] = min(iterSol);
    if (min_pbest < gbest)
       gbest = min_pbest;
       bestcurrentPurchaseArray = pbestPurchaseArray(index,:);
       bestStoreList = pbestStoreList(index,:);
       noIterImprovement = 0;
    else
       noIterImprovement = noIterImprovement + 1;
    end
   
    iter = iter + 1;
    
    solnXAxis = [solnXAxis iter];
    solnYAxis = [solnYAxis min_pbest];
    
    %Do not include graph draw time in the loop time
    loopTimeTaken = toc;
    totalLoopTimeTaken = totalLoopTimeTaken + loopTimeTaken;
    
    %Graph update
    if (mod(iter, 10) == 0)
       set (thePlot, 'Xdata',solnXAxis, 'YData',  solnYAxis)
       %refreshdata
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

%Best soln in 1123 runs
%Avg loop time 3.439914e-01 seconds, full time taken 3.863023e+02
%    'VeryExpensiveItem'    'Chicken'    'Apples'    'Duck'    'Stationery'    'MediumItem'    'Oranges'
%
%    'Store_4'    'Store_6'    'Store_19'    'Store_18'    'Store_27'    'Store_27'    'Store_23'
%
%  4.1525e+03


%Best soln in 512 runs
%Avg loop time 1.282486e-01 seconds, full time taken 6.566331e+01
%    'Stationery'    'Oranges'    'Duck'    'VeryExpensiveItem'    'Chicken'    'MediumItem'    'Apples'
%
%    'Store_5'    'Store_1'    'Store_5'    'Store_4'    'Store_2'    'Store_27'    'Store_11'
%
%       4240

%Best soln in 1000 runs
%Avg loop time 2.353916e-01 seconds, full time taken 2.353916e+02
%    'MediumItem'    'Oranges'    'Duck'    'Chicken'    'Apples'    'Stationery'    'VeryExpensiveItem'
%
%    'Store_27'    'Store_13'    'Store_5'    'Store_6'    'Store_16'    'Store_16'    'Store_4'

%   4.0375e+03