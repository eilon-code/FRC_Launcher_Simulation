function quality = evaluate_distance_from_zero(val)
    % e^-|x| is 1 iff x=0.
    % also, e^-x is decreasing so as |x| grows, the value e^-|x| is lower
    % and tends to 0 at infinity.
    quality = exp(-abs(val));
end