function [ index ] = PickFromProbabilities( probabilities, random_number )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    sum = 0;
    for index = 1:length(probabilities)
        sum = sum + probabilities(index);
        if sum > random_number
            break;
        end
    end
end

