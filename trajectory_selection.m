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

% --- Configuration ---
shooter_height = 0.5;           % meters
targetZ = 1.8288;               % meters
tolX = 1.12;                    % meters
radiusX = 0.626;                % meters
BallRadius = 0.075;             % meters
targetZ_relative = targetZ - shooter_height;

% Running params:
unique_angles = unique(masterTable.Angle);
distanceToTarget = 0.8:0.1:6;   % horizontal distance to center target

% Extract Ratios for the whole table once to save time
all_omegas = cellfun(@(x) x(2), masterTable.Omega);
masterTable.Ratio = all_omegas ./ masterTable.Velocity;
unique_ratios = unique(masterTable.Ratio);

% --- Nested Loops ---
for ang = unique_angles'
    % 1. Filter data for this specific shooting angle
    angle_subset = masterTable(abs(masterTable.Angle - ang) < 0.01, :);
    
    % Initialize grid for this specific angle
    [D_grid, R_grid] = meshgrid(distanceToTarget, unique_ratios);
    Success_grid = zeros(size(D_grid));
    
    fprintf('Processing Angle: %.1f...\n', ang);

    for j = 1:length(distanceToTarget)
        curr_dist = distanceToTarget(j);
        
        for i = 1:length(unique_ratios)
            curr_ratio = unique_ratios(i);
            
            % 2. Get all velocities available for this specific Angle + Ratio
            % This is the "Velocity Search" step
            cand_rows = angle_subset(abs(angle_subset.Ratio - curr_ratio) < 1e-5, :);
            
            if isempty(cand_rows), continue; end
            
            % 3. Check if ANY of these velocities result in a goal
            match_found = false;
            for r = 1:height(cand_rows)
                % Passing data to your function
                if check_goal_projectile(cand_rows(r, :), curr_dist, targetZ_relative, tolX, radiusX, BallRadius)
                    match_found = true;
                    break; % Found a velocity that works!
                end
            end
            
            if match_found
                Success_grid(i,j) = 1;
            end
        end
    end
    
    % --- Visualization for this Angle ---
    plot_success_map(D_grid, R_grid, Success_grid, ang);
end

function plot_success_map(D, R, S, ang)
    figure('Color', 'w', 'Name', sprintf('Angle %.1f', ang));
    surf(D, R, S);
    view(0, 90); % Top-down view
    shading flat;
    colormap([1 0.4 0.4; 0.4 1 0.4]); % Red for Fail, Green for Success
    xlabel('Distance to Target (m)');
    ylabel('Spin-to-Velocity Ratio (rad/m)');
    title(['Success Map | Launch Angle: ', num2str(ang), '°']);
    grid on;
end