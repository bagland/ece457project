
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
maxIterations = 10000;   %maximum number of iterations
swarmSize = 10; %unused
neighbourhoodSize = 1;  %unused (whole swarm is a neighbourhood)
c1 = 1.1; %acceleration coefficient - cognitive parameter
c2 = 4-c1;  %acceleration coefficient - social parameter
w = 1; %0.792;  %inertia weight

%Other parameters
noIterImprovement = 0;
noIterImprovementExit = 5000;

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

possibleStores
% stores = [14 1 0 12 11 16 1];
% originalItemsList = [1 2 3 4 5 6 7];
% items = [2 3 5 7 6 1 4];
% getNew = [1 0 0 0 0 1 0];
% 
% possibleStores = cell(7, 6);
% possibleStores
% 
% possibleStores{1,1} = 11;
% possibleStores{1,2} = 16;
% possibleStores{1,3} = 19;
% possibleStores{1,4} = 27;
% possibleStores{1,5} = 3;
% possibleStores{1,6} = 4;
% 
% possibleStores{2,1} = 12;
% possibleStores{2,2} = 14;
% possibleStores{2,3} = 17;
% possibleStores{2,4} = 2;
% possibleStores{2,5} = 22;
% possibleStores{2,6} = 6;
% 
% possibleStores{3,1} = 1;
% possibleStores{3,2} = 13;
% possibleStores{3,3} = 22;
% possibleStores{3,4} = 23;
% possibleStores{3,5} = 3;
% possibleStores{3,6} = 5;
% 
% possibleStores{4,1} = 1;
% possibleStores{4,2} = 11;
% possibleStores{4,3} = 15;
% possibleStores{4,4} = 18;
% possibleStores{4,5} = 2;
% possibleStores{4,6} = 5;
% 
% possibleStores{5,1} = 0;
% possibleStores{5,2} = 29;
% possibleStores{5,3} = 4;
% possibleStores{5,4} = 8;
% possibleStores{5,5} = 9;
% possibleStores{5,6} = 7;
% 
% possibleStores{6,1} = 12;
% possibleStores{6,2} = 16;
% possibleStores{6,3} = 2;
% possibleStores{6,4} = 27;
% possibleStores{6,5} = 4;
% possibleStores{6,6} = 5;
% 
% possibleStores{7,1} = 18;
% possibleStores{7,2} = 2;
% possibleStores{7,3} = 24;
% possibleStores{7,4} = 26;
% possibleStores{7,5} = 27;
% possibleStores{7,6} = 9;
% possibleStores
% possibleStores = [11 16 19 27 3 4; 12 14 17 2 22 6; 1 13 22 23 3 5; 1 11 15 18 2 5; 0 29 4 8 9 7; 12 16 2 27 4 5; 18 2 24 26 27 9];
% newStores = GetDiffStore(stores, items, originalItemsList, getNew, possibleStores);

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
%        if (i==1)
%             inertia
%             cognitive
%             social
%             pbestSol = pbestStoreList(i, :)
%             pbestList = pbestPurchaseArray(i,:)
%             gbestSol = bestStoreList
%             gbestList = bestcurrentPurchaseArray
%        end       
       %v[t+1] = w*v[t] + c1*rand()*(pbest[]-x[t]) + c2*rand()*(gbest[]-x[t])
       temp = inertia*probabilityDistribution(1) + cognitive*probabilityDistribution(2) + social*probabilityDistribution(3);

       [a, b] = size(temp);
       for j = 1:b
           velStores(i,j) = temp(j);
       end
       %x[t+1] = x[t] + v[t+1]
       %currPurchaseArray(i,:) = GetDiffStore(currPurchaseArray(i,:),temp); % Doesn't change
       
%        if (i == 1)
%        before = currStoreList(i,:);
%        addingVal = temp;
%        end
       currStoreList(i,:) = GetDiffStore(currStoreList(i,:), currPurchaseArray(i,:), originalItemsList, temp, possibleStores);
        
%        if (i==1)
%            after = currStoreList(i,:);
%            itemsList = currPurchaseArray(i,:)
%            before
%             after
%             addingVal
%        end

       %Get random values between 0 and 2
       r1 = 2*rand;
       r2 = 2*rand;

       inertia = Multiply(velocity(:,:,i), w);
       cognitive = Multiply(Multiply(Subtracting(pbestPurchaseArray(i,:), currPurchaseArray(i,:)), r1), c1);
       social = Multiply(Multiply(Subtracting(bestcurrentPurchaseArray, currPurchaseArray(i,:)), r2), c2);
       %v[t+1] = w*v[t] + c1*rand()*(pbest[]-x[t]) + c2*rand()*(gbest[]-x[t])
       
%        if( i == 1)
%        inertia
%        cognitive
%        social
%        end
       
% TODO - fix the augmentation/truncation to use value correctly
% TODO - increase particle size/etc or tweak parameters to get convergence
% TODO - test if one or both are converging

       temp = [inertia;cognitive;social];
       [a, b] = size(temp);
       if (a ~= 0)
           for j = 1:a
               for k = 1:b
                   velocity(j,k,i) = temp(j,k);
               end
           end
       end
%        if (i==1)
%        velocity(:,:,i)
%        beforeList = currPurchaseArray(i,:)
%        beforeStore = currStoreList(i,:)
%        end
       %x[t+1] = x[t] + v[t+1]
       currPurchaseArray(i,:) = Adding(currPurchaseArray(i,:), temp);
       currStoreList(i,:) = Adding(currStoreList(i,:), temp);
       %if (i==1)
       %afterList = currPurchaseArray(i,:)
       %afterStore = currStoreList(i,:)
       %end
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
    solnYAxis = [solnYAxis min_iter];
    
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

% possibleStores = 
% 
%     'Store_11'    'Store_16'    'Store_19'    'Store_27'    'Store_3'     'Store_4'            []
%     'Store_12'    'Store_14'    'Store_17'    'Store_2'     'Store_22'    'Store_6'            []
%     'Store_1'     'Store_13'    'Store_22'    'Store_23'    'Store_3'     'Store_5'            []
%     'Store_0'     'Store_11'    'Store_15'    'Store_18'    'Store_2'     'Store_5'     'Store_7'
%     'Store_0'     'Store_29'    'Store_4'     'Store_8'     'Store_9'             []           []
%     'Store_11'    'Store_12'    'Store_16'    'Store_2'     'Store_27'    'Store_4'     'Store_5'
%     'Store_12'    'Store_18'    'Store_2'     'Store_24'    'Store_26'    'Store_27'    'Store_9'