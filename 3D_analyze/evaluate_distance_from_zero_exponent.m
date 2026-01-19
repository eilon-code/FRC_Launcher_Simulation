function quality = evaluate_distance_from_zero_exponent(val)
%EVALUATE_DISTANCE_FROM_ZERO_EXPONENT
% Returns a quality measure based on the distance of val from zero
% using an exponential decay.
%
% Properties:
%   - exp(-|x|) = 1 if and only if x = 0
%   - The function is monotonically decreasing with |x|
%   - The value approaches 0 as |x| → ∞

    quality = exp(-abs(val));
end