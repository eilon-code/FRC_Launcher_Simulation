function score = evaluate_goal_projectile(row, targetX, targetZ, tolX, radiusX, BallRadius, dt, ...
        slope_penalty, vel_penalty, distance_from_center_penalty)
    % 1. Binary check first (Pre-filtering)
    if ~check_goal_projectile(row, targetX, targetZ, tolX, radiusX, BallRadius)
        score = 0;
        return;
    end
    
    trajectory = row.Trajectory{1}; 
    X_coords = trajectory(:,1);
    Z_coords = trajectory(:,3);

    % 2. Find the exact transition where it drops below targetZ
    % Requirement: Must be after the peak (descending)
    idx = find(Z_coords <= targetZ & X_coords >= (targetX - radiusX), 1, 'first');
    
    if isempty(idx) || idx < 2
        score = 0; return;
    end

    % 3. Discrete Derivation of Velocity at targetZ
    dx = X_coords(idx) - X_coords(idx-1);
    dz = Z_coords(idx) - Z_coords(idx-1);
    
    vx = dx / dt;
    vz = dz / dt;
    v_mag = sqrt(vx^2 + vz^2); % Absolute velocity at targetZ

    % 4. Quality of Slope (Inverse Slope)
    % Score is 1 if dx=0 (vertical), decreases as horizontal velocity increases
    inverse_slope = dx / dz;
    quality_of_slope = evaluate_distance_from_zero(inverse_slope * slope_penalty);
    
    % 5. Velocity Penalty (New Requirement)
    % Higher absolute velocity = lower score. 
    quality_of_vel = evaluate_distance_from_zero(v_mag * vel_penalty);

    % 6. Distance From Center Penalty
    x = (X_coords(idx) + X_coords(idx-1))/2;
    distance_from_center = abs(x - targetX);
    quality_of_distance = evaluate_distance_from_zero( ...
        distance_from_center / tolX * distance_from_center_penalty);

    % Combined Score: High verticality AND low impact speed AND small
    % distance form center target
    score = quality_of_slope * quality_of_vel * quality_of_distance;
end