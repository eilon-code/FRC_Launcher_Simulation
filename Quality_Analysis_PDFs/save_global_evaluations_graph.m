%% Generate Global Maximum Quality and Optimal Angle Maps
load('ShootingDatabase.mat'); 

% --- Configuration (Must match your evaluation parameters) ---
shooter_height = 0.5; targetZ = 1.8288; tolX = 1.12; 
radiusX = 0.626; BallRadius = 0.075; dt = 0.06;
targetZ_rel = targetZ - shooter_height;

slope_p = 0.4; vel_p = 0.05; dist_p = 1.2;

outputDir = 'Quality_Analysis_PDFs/Global_Analysis_Results';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

% Pre-calculate Ratio
all_omegas = cellfun(@(x) x(2), masterTable.Omega);
masterTable.Ratio = round(all_omegas ./ masterTable.Velocity, 4);

unique_angles = unique(masterTable.Angle)';
distanceToTarget = 0.8:0.1:8; 
unique_ratios = unique(masterTable.Ratio);

% Initialize Global Grids
Global_Max_Quality = zeros(length(unique_ratios), length(distanceToTarget));
Global_Best_Angle  = zeros(length(unique_ratios), length(distanceToTarget));

fprintf('Processing global comparison across %d angles...\n', length(unique_angles));

for ang = unique_angles
    angle_subset = masterTable(abs(masterTable.Angle - ang) < 0.01, :);
    if isempty(angle_subset), continue; end
    
    % Temporary grid for current angle
    Current_Grid = zeros(length(unique_ratios), length(distanceToTarget));
    
    parfor j = 1:length(distanceToTarget)
        curr_dist = distanceToTarget(j);
        col_q = zeros(length(unique_ratios), 1);
        for i = 1:length(unique_ratios)
            curr_ratio = unique_ratios(i);
            idx = abs(angle_subset.Ratio - curr_ratio) < 1e-4;
            cand_rows = angle_subset(idx, :);
            
            best_s = 0;
            for r = 1:height(cand_rows)
                % Using your 10-argument function signature
                s = evaluate_goal_projectile(cand_rows(r,:), curr_dist, ...
                         targetZ_rel, tolX, radiusX, BallRadius, dt, ...
                         slope_p, vel_p, dist_p);
                if s > best_s, best_s = s; end
            end
            col_q(i) = best_s;
        end
        Current_Grid(:, j) = col_q;
    end
    
    % Update Global Maps: Logic to keep the highest quality found so far
    mask = Current_Grid > Global_Max_Quality;
    Global_Max_Quality(mask) = Current_Grid(mask);
    Global_Best_Angle(mask) = ang;
    
    fprintf('Processed Angle: %.1f\n', ang);
end

%% --- Visualization 1: Global Maximum Quality Map ---
fig1 = figure('Color', 'w', 'Visible', 'off', 'Units', 'inches', 'Position', [1 1 11 8.5]);
imagesc(distanceToTarget, unique_ratios, Global_Max_Quality);
set(gca, 'YDir', 'normal'); colormap(jet); colorbar; clim([0 1]);
xlabel('Distance (m)'); ylabel('Ratio (rad/m)');
title('Global Maximum Quality (Best Performance Possible at any Angle)');
exportgraphics(fig1, fullfile(outputDir, 'Global_Quality_Envelope.pdf'), 'ContentType', 'vector');

%% --- Visualization 2: Optimal Angle Map ---
fig2 = figure('Color', 'w', 'Visible', 'off', 'Units', 'inches', 'Position', [1 1 11 8.5]);
imagesc(distanceToTarget, unique_ratios, Global_Best_Angle);
set(gca, 'YDir', 'normal'); 
% Discrete colormap for angles
cmap = jet(length(unique_angles)); colormap(cmap);
c = colorbar; c.Label.String = 'Optimal Launch Angle (deg)';
xlabel('Distance (m)'); ylabel('Ratio (rad/m)');
title('Optimal Angle Decision Map (Which angle to choose for best quality)');
exportgraphics(fig2, fullfile(outputDir, 'Global_Angle_Selection.pdf'), 'ContentType', 'vector');

close all;
fprintf('Global Optimization reports saved in: %s\n', outputDir);