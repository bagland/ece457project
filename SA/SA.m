
purchaseArray = {'Apples', 'Chicken'};
startLocation = 'ZLocation_1';


distanceMap = parse_distances('outputDistance.txt');
inventoryMap = parse_inventory('outputInventory.txt');

storeList = cell(size(purchaseArray));

count = 0;
for itemName = purchaseArray
    itemCharName = itemName{1};
    storeItemMap = inventoryMap(itemCharName);
    storeKeys = keys(storeItemMap);
    count = count + 1;
    storeList{count} = storeKeys{1};
end

midRoute{1} = startLocation;
currentStoreList = cell(size(purchaseArray));
count = 2;
for loc = storeList
    midRoute{count} = loc{1};
    currentStoreList{count-1} = loc{1};
    count = count + 1;
end
midRoute{count} = startLocation;

evalSolnCost = evaluateSoln(midRoute,purchaseArray,currentStoreList)

% Initializing parameters and settings
T_init =1.0; % Initial temperature
T_min = 1e-10; % Final stopping temperature
%F_min = -1e+100; % Min value of the function
%max_rej=2500; % Maximum number of rejections
max_run=500; % Maximum number of runs
%max_accept = 15; % Maximum number of accept
k = 1; % Boltzmann constant
alpha=0.95; % Cooling factor
%Enorm=1e-8; % Energy norm (eg, Enorm=le-8)
%guess=[2 2]; % Initial guess

% Initializing the counters i,j etc
%i= 0; j = 0; accept = 0; totaleval = 0;

% Initializing various values
temperature = T_init;
%E_init = f(guess(1),guess(2));
%E_old = E_init; E_new=E_old;
%best=guess; % initially guessed values
runNum = 0;

bestEval = evalSolnCost;


while (runNum < 1)
    
    %swap
    
    %Swap the items in the grocery list
    temp = purchaseArray{1};
    purchaseArray{1} = purchaseArray{2};
    purchaseArray{2} = temp;
    
    %Swap them in the reference store list. (need these keys in order)
    temp = storeList{1};
    storeList{1} = storeList{2};
    storeList{2} = temp;
    
    %Swap in the route. note the +1, zzz.
    temp = midRoute{2};
    midRoute{2} = midRoute{3};
    midRoute{3} = temp;
    
    %swap the current store order.
    temp = currentStoreList{1};
    currentStoreList{1} = currentStoreList{2};
    currentStoreList{2} = temp;
    
    evalSolnCost = evaluateSoln(midRoute,purchaseArray,currentStoreList)
    %random store.
    
    
    %cooldown
    temperature = temperature * alpha;
    runNum = runNum + 1;
end