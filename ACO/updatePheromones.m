function [ updated_price_pheromones, updated_dist_pheromones ] = updatePheromones( route, pricePheromones, distancePheromones, storeNames, numProducts, evaporation_rate, Q_dist, Q_price, dist_cost, price_cost )
%UPDATEPHEROMONES Summary of this function goes here
%   Detailed explanation goes here
    updated_price_pheromones = pricePheromones * (1 - evaporation_rate);
    updated_dist_pheromones = distancePheromones * (1 - evaporation_rate);
    
    for i = 2:numProducts+1
        prevStoreName = route{i-1};
        storeName = route(i);
        [m, index] = ismember(storeName, storeNames);
        [m, prevIndex] = ismember(prevStoreName, storeNames);
        updated_dist_pheromones(prevIndex, index) = updated_dist_pheromones(prevIndex, index) + Q_dist/dist_cost;
        updated_price_pheromones(i-1, index) = updated_price_pheromones(i-1, index) + Q_price/price_cost;
    end
%     updated_price_pheromones
%     updated_dist_pheromones
%     for key = storeKeys
%         [m, index] = ismember(key, storeNames);
% %         fprintf('Index for a product %s is %f\n', productName, index);
%         if index
%             pricePheromones(productIndex, index) = 1;
%         end
%     end
end

