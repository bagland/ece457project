function [ storenames ] = store_names( filename )
%STORE_NAMES Summary of this function goes here
%   Detailed explanation goes here
    storenames = cell(1);
    fileId = fopen(filename, 'r');
    iteration = 1;
    input_data = textscan(fileId, '%s', 'Delimiter', '\n');
    store_num = length(input_data{1});
    for i = 1:store_num
       line = strsplit(input_data{1}{iteration});
       disp(line);
       storenames{iteration} = line{1};
       iteration = iteration+1;
    end
end

