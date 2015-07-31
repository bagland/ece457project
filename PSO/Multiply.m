function [ velocity_new ] = Multiply( velocity, c )
%Multiply - Changes the length of the velocity vector (number of swaps)
%   according to the constant c.
% If c = 0, the lenght is set to zero.
% If c < 1, the velocity is truncated.
% IF c > 1, the velocity is augmented.

% Test case:
%velocity = [1 5; 3 7];
%c = 0.5;
%velocity_new = Multiply(velocity, c);
% Confirm that velocity_new = [1 5]
%velocity = [1 5; 3 7];
%c = 1.5;
%velocity_new = Multiply(velocity, c);
% Confirm that velocity_new = [1 5; 3 7; 1 5]
%velocity = [1 5; 3 7];
%c = 0;
%velocity_new = Multiply(velocity, c);
% Confirm that velocity_new =  []

%Remove extra zeros
velocity(any(velocity==0,2),:) = [];

velocity_new = velocity;
[numVelocity, n] = size(velocity);
if (numVelocity == 0 || n == 0)
    return
end

if (c == 0)
    velocity_new = [];
elseif (c <= 1)
    velocity_new(numVelocity,:) = [];
elseif (c > 1)
    new_row = velocity(1,:);
    velocity_new = [velocity_new; new_row];
end

end

