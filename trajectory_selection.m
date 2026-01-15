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
angle_vals = 55:1:70;           % angle range
distanceToTarget = 0.8:0.1:6;   % horizontal distance to center target

for fixed_angle = angle_vals
    % --- Data Preparation ---
    % 1. Filter database for the fixed angle
    angle_tol = 0.1;
    angle_subset = masterTable(abs(masterTable.Angle - fixed_angle) < angle_tol, :);
    
    % 2. Extract unique omegas from this subset
    all_omegas = cellfun(@(x) x(2), angle_subset.Omega);
    unique_omegas = unique(all_omegas);
    
    % 3. Initialize the Success Grid
    [Dist_grid, W_grid] = meshgrid(distanceToTarget, unique_omegas);
    Success_grid = zeros(size(Dist_grid));
    
    % --- Processing ---
    for i = 1:length(unique_omegas)
        curr_w = unique_omegas(i);
        
        % Filter subset for this specific omega
        omega_rows = angle_subset(all_omegas == curr_w, :);
        
        for j = 1:length(distanceToTarget)
            curr_dist = distanceToTarget(j);
            
            % Check if any velocity in this (Angle, Omega) group hits the target
            match_found = false;
            for r = 1:height(omega_rows)
                if check_goal_projectile(omega_rows(r, :), curr_dist, targetZ_relative, tolX, radiusX, BallRadius)
                    match_found = true;
                    break; 
                end
            end
            
            if match_found
                Success_grid(i,j) = 1;
            end
        end
    end
    
    % --- Visualization ---
    figure('Color', 'w', 'Name', ['Success Map at Angle ', num2str(fixed_angle)]);
    surf(Dist_grid, W_grid, Success_grid);
    
    % Aesthetics
    shading interp; % Smooths out the color transitions
    view(0, 90);    % Top-down view (Heatmap style)
    colormap([0.9 0.3 0.3; 0.3 0.9 0.3]); % Red (Fail) to Green (Success)
    
    xlabel('Distance to Target (X) [m]');
    ylabel('Backspin (\omega_y) [rad/s]');
    title(['Feasibility Map: Fixed Angle = ', num2str(fixed_angle), '°']);
    subtitle('Green = Goal is possible at some velocity | Red = Impossible');
    grid on;
end