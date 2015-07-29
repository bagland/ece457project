function output = inRoute( route, i, storeName, numProducts )
%INROUTE Summary of this function goes here
%   Detailed explanation goes here
    route = getRouteForAnt(route, i, numProducts);
%     C = ['xyz' 'xxy' 'zyx']
%     type = 'xyz';
    output = any(strfind(route,storeName))
end

