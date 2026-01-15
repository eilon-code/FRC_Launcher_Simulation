%% Multi-Simulation Runner for FRC Ballistics
model_name = 'launcher_simulation'; % Replace with your actual .slx filename
load_system(model_name);

% --- Define Parameter Sets ---
% Example: Testing different launch velocities
v_test_range = [6,7]; 
colors = jet(length(v_test_range)); % Generate a color gradient

% Setup Figure
fig = figure('Color', 'w', 'Name', 'FRC 2026 Comparison');
hold on; grid on;
view(60, 20);
axis([0 10 -2 2 0 4]);
xlabel('X[m]'); ylabel('Y[m]'); zlabel('Z[m]');

Initial_Height = 0;

% --- Add Target Reference (The Hub) ---
hub_dist = 5;
[th, zh] = meshgrid(linspace(0, 2*pi, 20), linspace(0, 2.5, 2));
hx = 0.6*cos(th) + hub_dist; hy = 0.6*sin(th);
mesh(hx, hy, zh, 'EdgeColor', [0 0 0], 'EdgeAlpha', 0.1, 'FaceAlpha', 0, 'HandleVisibility', 'off');

% --- Loop through simulations ---
for i = 1:length(v_test_range)
    % 1. Update Workspace Variables
    % These names must match the variable names used in your Simulink blocks
    V_mag = v_test_range(i); 
    AngleDegrees = 85; % Fixed angle for this test
    Angle = AngleDegrees * (pi/180); % convert to radians
    
    % 2. Run Simulation
    % 'CaptureErrors' ensures the script doesn't crash if one sim fails
    simOut = sim(model_name, 'SimulationMode', 'normal');
    
    % 3. Extract and Clean Data
    pos_raw = simOut.simout.Data;
    pos = squeeze(pos_raw);
    if size(pos, 1) == 3, pos = pos'; end
    
    % Ground collision clipping
    ground_idx = find(pos(:,3) < 0, 1);
    if ~isempty(ground_idx), pos = pos(1:ground_idx, :); end
    
    % 4. Plot this specific run
    plot3(pos(:,1), pos(:,2), pos(:,3), 'Color', colors(i,:), ...
          'LineWidth', 1.5, 'DisplayName', sprintf('V = %0.1f m/s', V_mag));
end

legend('show', 'Location', 'northeast');
title('Comparison of Launch Velocities');