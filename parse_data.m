fileId = fopen('outputDistance.txt', 'r');
rawText = textscan(fileId, '%s', 'delimiter', '\n');
numberOfLines = length(rawText{1});
distance_data = zeros(numberOfLines, numberOfLines);

iteration = 1;

fileId = fopen('outputDistance.txt', 'r');

while (~feof(fileId))
    input_data = textscan(fileId, '%s', , 'Delimiter', '\n');
    for i=2:10
        value = input_data{1}{i};
        distance_data(iteration, i - 1) = str2double(value);
    end
    iteration = iteration + 1;
end
disp(store_names('outputDistance.txt'));