%% Generate Best-Shot Quality PDF Reports
load('ShootingDatabase.mat'); 

% --- Configuration ---
shooter_height = 0.5;           
targetZ = 1.8288;               
tolX = 1.12; 
radiusX = 0.626;
BallRadius = 0.075;
dt = 0.06; % Make sure this matches your simulation time step
targetZ_rel = targetZ - shooter_height;

%% parameters to decide evaluation quality:
slope_penalty = 0.4;
vel_penalty = 0.05;
distance_from_center_penalty = 1.2;

%% Generate PDF-s
outputDir = 'Quality_Analysis_PDFs/quality_results';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

% Pre-calculate Ratio once
all_omegas = cellfun(@(x) x(2), masterTable.Omega);
masterTable.Ratio = round(all_omegas ./ masterTable.Velocity, 4);

unique_angles = unique(masterTable.Angle)';
distanceToTarget = 0.8:0.1:8; 
unique_ratios = unique(masterTable.Ratio);

fprintf('Generating Quality Heatmaps...\n');

for ang = unique_angles
    % Subset for current angle
    angle_subset = masterTable(abs(masterTable.Angle - ang) < 0.01, :);
    if isempty(angle_subset), continue; end
    
    % Initialize the grid for "Best Quality Score"
    Quality_Grid = zeros(length(unique_ratios), length(distanceToTarget));
    
    % Parallel loop over distance columns
    dist_vec = distanceToTarget;
    num_ratios = length(unique_ratios);
    
    parfor j = 1:length(dist_vec)
        curr_dist = dist_vec(j);
        col_quality = zeros(num_ratios, 1);
        
        for i = 1:num_ratios
            curr_ratio = unique_ratios(i);
            
            % Match ratio
            idx = abs(angle_subset.Ratio - curr_ratio) < 1e-4;
            cand_rows = angle_subset(idx, :);
            
            if isempty(cand_rows), continue; end
            
            % Find the HIGHEST score among all velocities for this specific (Dist, Ratio)
            best_score = 0;
            for r = 1:height(cand_rows)
                % Pass all 10 arguments to your refined function
                score = evaluate_goal_projectile(cand_rows(r,:), curr_dist, ...
                         targetZ_rel, tolX, radiusX, BallRadius, dt, ...
                         slope_penalty, vel_penalty, distance_from_center_penalty);
                if score > best_score
                    best_score = score;
                end
            end
            col_quality(i) = best_score;
        end
        Quality_Grid(:, j) = col_quality;
    end
    
    % --- Visualization & PDF Export ---
    fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'inches', 'Position', [1 1 11 8.5]);
    
    % Use imagesc for efficient, high-quality 2D maps
    imagesc(distanceToTarget, unique_ratios, Quality_Grid);
    set(gca, 'YDir', 'normal'); % Flip axis to show Ratio increasing upwards
    
    % Setup Colormap (Blue = Poor/Miss, Yellow/Red = Optimized Shot)
    colormap(jet); 
    c = colorbar;
    c.Label.String = 'Quality Score (Verticality × Softness × Centering)';
    clim([0 1]);
    
    xlabel('Distance to Target (m)');
    ylabel('Spin-to-Velocity Ratio (rad/m)');
    title({sprintf('Best-Shot Quality Map | Launch Angle: %.1f°', ang), ...
           'Optimized for Vertical Entry, Low Impact Speed, and Horizontal Accuracy'});
    grid on;
    
    % Export to high-quality vector PDF
    fileName = sprintf('%s/QualityMap_Angle_%.1f.pdf', outputDir, ang);
    exportgraphics(fig, fileName, 'ContentType', 'vector');
    
    close(fig); % Free memory
    fprintf('Saved: %s\n', fileName);
end

fprintf('All PDF reports generated in: %s\n', outputDir);