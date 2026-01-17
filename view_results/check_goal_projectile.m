function isGoal = check_goal_projectile(row, targetX, targetZ, tolX, radiusX, BallRadius)
    % row: A single row from your masterTable
    % targetX, targetZ: Goal center coordinates
    
    % --- OPTIMIZATION: Early Exit (Requirement 1) ---
    % Always check the cheapest conditions first.
    if row.DisAtMaxHeight >= (targetX - radiusX) || row.Apogee < (targetZ + BallRadius)
        isGoal = false;
        return;
    end

    trajectory = row.Trajectory{1}; % [X, Y, Z]
    X_coords = trajectory(:,1);
    
    % --- OPTIMIZATION: Use logical indexing once ---
    % Requirement 2: Check height at the FRONT EDGE of the goal
    % Instead of find(), just check the first point that crosses targetX - radiusX
    entry_idx = find(X_coords >= (targetX - radiusX), 1, 'first');
    
    if isempty(entry_idx)
        isGoal = false;
        return;
    end
    z_before_entry = trajectory(entry_idx-1, 3);
    z_after_entry = trajectory(entry_idx, 3);
    if z_before_entry < (targetZ + BallRadius) || z_after_entry < (targetZ + BallRadius)
        isGoal = false;
        return;
    end
    
    % --- OPTIMIZATION: Requirement 3 (The "Scoring Zone") ---
    % Find indices where X is within targetX +/- tolX
    in_zone = (X_coords >= (targetX - tolX)) & (X_coords <= (targetX + tolX));
    
    if ~any(in_zone)
        isGoal = false;
        return;
    end
    
    % Extract Z values only for the zone (efficient slicing)
    z_values = trajectory(in_zone, 3);
    
    % Check if the ball crossed the target height (one point above, one below)
    isGoal = any(z_values >= targetZ) && any(z_values <= targetZ);
end