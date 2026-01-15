%% Visualize Trajectories by Velocity for a Shared Angle
load('ShootingDatabase.mat'); % Load your generated data

% 1. Settings
for target_angle = 55:1:70   % The "shared angle" you want to inspect
    tol = 0.1;              % Tolerance (in case of floating point precision)
    
    % 2. Filter the table
    % We find all rows where the Angle is approximately our target
    subset = masterTable(abs(masterTable.Angle - target_angle) < tol, :);
    
    % 3. Sort by Velocity (important for the legend and color gradient)
    subset = sortrows(subset, 'Velocity');
    
    if isempty(subset)
        fprintf('No data found for Angle = %.1f. Check your database ranges.', target_angle);
    else
        % 4. Visualization
        figure('Color', 'w', 'Name', sprintf('Trajectories at Angle = %.1f', target_angle));
        hold on; grid on;
        
        % Create a color map (e.g., from blue for slow to red for fast)
        colors = jet(height(subset));
        
        for i = 1:height(subset)
            traj = subset.Trajectory{i}; % Extract the resampled trajectory
            v_val = subset.Velocity(i);
            
            % Clip at ground (z < 0)
            ground_idx = find(traj(:,3) < 0, 1);
            if ~isempty(ground_idx), traj = traj(1:ground_idx, :); end
        
            % Plot the line
            plot3(traj(:,1), traj(:,2), traj(:,3), ...
                'Color', colors(i,:), ...
                'LineWidth', 2, ...
                'DisplayName', sprintf('V = %.1f m/s', v_val));
        end
        
        % --- Add field context ---
        xlabel('Distance (X) [m]'); ylabel('Lateral (Y) [m]'); zlabel('Height (Z) [m]');
        title(['Velocity Comparison at Launch Angle: ', num2str(target_angle), '°']);
        view(60, 20);
        axis tight; 
        ylim([-1 1]); % Keep lateral view tight since we are mostly moving in X-Z
        legend('show', 'Location', 'northeastoutside');
        
        % Optional: Highlight the peak of each trajectory
        for i = 1:height(subset)
            plot3(subset.DisAtMaxHeight(i), 0, subset.Apogee(i), 'ko', 'MarkerSize', 4, 'HandleVisibility', 'off');
        end
    end
end
