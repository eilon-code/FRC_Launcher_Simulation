%% Visualize Trajectories by Velocity for a Shared Angle
load('ShootingDatabase.mat'); % Load your generated data

% 1. Settings
for target_angle = 55:1:70   % The "shared angle" you want to inspect
    tol = 0.1;              % Tolerance (in case of floating point precision)
    
    % 2. Filter the table
    % We find all rows where the Angle is approximately our target
    subset = masterTable(abs(masterTable.Angle - target_angle) < tol, :);
    
    % 3. Sort by Velocity (important for the legend and color gradient)
    subset = sortrows(subset, 'Velocity'); % Sort so legend/colors align

    % 3. Setup Colors
    unique_v = unique(subset.Velocity);
    v_colors = jet(length(unique_v)); % One distinct color per velocity
    max_omega = max(abs(cellfun(@(x) x(2), subset.Omega)));
    
    if isempty(subset)
        fprintf('No data found for Angle = %.1f. Check your database ranges.', target_angle);
    else
        % 4. Visualization
        figure('Color', 'w', 'Name', sprintf('Trajectories at Angle = %.1f', target_angle));
        hold on; grid on;
        
        for i = 1:height(subset)
            % Extract Parameters
            v_val = subset.Velocity(i);
            omega_vec = subset.Omega{i};
            omega_y = omega_vec(2);
            traj = subset.Trajectory{i};
            
            % Find color for this velocity
            c_idx = find(unique_v == v_val);
            this_color = v_colors(c_idx, :);
            
            % --- CALCULATE OPACITY ---
            % Map omega to opacity: Higher spin = more solid, Low spin = more ghost-like
            % Adding 0.2 base so 0-spin isn't completely invisible
            opacity = 0.3 + 0.7 * (abs(omega_y) / max_omega);
            
            % --- THE PLOTTING TRICK ---
            % Since plot3 doesn't support Alpha, we use 'patch'
            % We create a line by treating segments as a path
            x = traj(:,1);
            y = ones(size(x)) * omega_y;
            z = traj(:,3);
            
            patch([x' NaN], [y' NaN], [z' NaN], 'r', ...
                'EdgeColor', this_color, ...
                'EdgeAlpha', opacity, ...
                'LineWidth', 1.5, ...
                'HandleVisibility', 'on'); 
        end
        
        % 5. Polish
        view(0,0);
        xlabel('Distance (X) [m]');
        ylabel('Spin (\omega_y) [rad/s]');
        zlabel('Height (Z) [m]');
        title(['Launch Profile at ', num2str(target_angle), '° (Color=Vel, Opacity=Spin)']);
        
        % Create a custom legend for Velocities only
        temp_lines = [];
        for k = 1:length(unique_v)
            temp_lines(k) = plot(NaN, NaN, 'Color', v_colors(k,:), 'LineWidth', 2);
        end
        legend(temp_lines, string(unique_v) + " m/s", 'Location', 'northeastoutside');
        
        axis tight;
    end
end
