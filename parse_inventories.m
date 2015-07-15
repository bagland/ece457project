function [ store_inventories ] = parse_inventories( filename )
%INVENTORY_DATA Summary of this function goes here
%   Detailed explanation goes here
    fileId = fopen(filename, 'r');
    input_data = textscan(fileId, '%s', 'Delimiter', '\n');
    store_num = length(input_data{1});
    iteration = 1;
    store_inventories = cell(1);
    for i = 1:store_num
        line = strsplit(input_data{1}{iteration});
        store_inventories{iteration} = line;
        iteration = iteration + 1;
%         disp(line);
    end
%     containers.Map(keySet,valueSet)
    storePrice = containers.Map;
    for i = 1:length(store_inventories)
       line = store_inventories{i};
       product_name = 'product';
       for j = 2:length(line)
           if (mod(j,2) == 1)
               if isKey(storePrice, product_name)
                   product_map = storePrice(product_name);
                   product_map(line{1}) = line{j};
                   storePrice(product_name) = product_map;
               else
                   storePrice(product_name) = containers.Map(line{1}, line{j});
               end
           else
               product_name = line{j};
           end
       end
    end
    map_keys = values(storePrice);
    apple_dict = map_keys(1);
    apple_dict{1}('Drugs')
end

