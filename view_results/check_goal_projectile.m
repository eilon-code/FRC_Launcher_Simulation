function isGoal = check_goal_projectile(row, targetX, targetZ, tolX, radiusX, BallRadius)
    % row: A single row from your masterTable
    % targetX, targetZ: Goal center coordinates
    
    % REQUIREMENT 1: Peak must happen before the target
    % We use your saved 'DisAtMaxHeight' column
    if row.DisAtMaxHeight >= targetX - radiusX
        isGoal = false;
        return;
    end
    if row.Apogee <= targetZ + BallRadius
        isGoal = false;
        return;
    end
    
    % Extract the trajectory for the crossing check
    trajectory = row.Trajectory{1};
    
    % 2. Check for points in the X-window (the "scoring zone")
    x_in_zone_idx = find(abs(trajectory(:,1) - targetX) <= tolX);
    
    if isempty(x_in_zone_idx)
        isGoal = false;
        return;
    end
    
    % 3. Check for vertical crossing (Requirement 2)
    % We look at the trajectory points that pass through the goal distance
    z_at_target_zone = trajectory(x_in_zone_idx, 3);
    
    has_point_above = any(z_at_target_zone >= targetZ);
    has_point_below = any(z_at_target_zone <= targetZ);
    
    isGoal = has_point_above && has_point_below;
end
