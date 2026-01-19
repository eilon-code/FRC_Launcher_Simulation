function quality = evaluate_distance_from_zero_divider(val)
%EVALUATE_DISTANCE_FROM_ZERO_DIVIDER
% Returns a quality measure based on the distance of val from zero
% using a rational decay.
%
% Properties:
%   - 1 / (1 + |x|) = 1 if and only if x = 0
%   - The function is monotonically decreasing with |x|
%   - The value approaches 0 as |x| → ∞

    quality = 1 / (1 + abs(val));
end
