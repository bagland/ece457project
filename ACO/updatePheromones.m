function [ updated_price_pheromones, updated_dist_pheromones ] = updatePheromones( route, pricePheromones, distancePheromones, storeNames, numProducts, evaporation_rate )
%UPDATEPHEROMONES Summary of this function goes here
%   Detailed explanation goes here
    updated_price_pheromones = pricePheromones * (1 - evaporation_rate);
    updated_dist_pheromones = distancePheromones * (1 - evaporation_rate);
    
    for i = 2:numProducts+1
        prevStoreName = route{i-1};
        storeName = route(i);
        [m, index] = ismember(storeName, storeNames);
        [m, prevIndex] = ismember(prevStoreName, storeNames);
        updated_dist_pheromones(prevIndex, index) = updated_dist_pheromones(prevIndex, index) + 0.15;
        updated_price_pheromones(i-1, index) = updated_price_pheromones(i-1, index) + 0.1;
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

