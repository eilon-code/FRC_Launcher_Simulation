function dataRow = run_sim_only(model_name, v, ang, h0, omega_xyz, filename, save_row)
    % 1. Set variables
    assignin('base', 'V_mag', v);
    assignin('base', 'Angle', ang * (pi/180)); % convert to radians
    assignin('base', 'Initial_Height', h0);
    assignin('base', 'omega_val', omega_xyz);
    
    % 2. Run simulation
    simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');
    
    % 3. Extract Trajectory and Time
    pos_raw = squeeze(simOut.simout.Data);
    if size(pos_raw,1) == 3, pos_raw = pos_raw'; end
    t_raw = simOut.tout;
    
    % Clip at ground (z < 0)
    ground_idx = find(pos_raw(:,3) < 0, 1);
    if ~isempty(ground_idx)
        pos_raw = pos_raw(1:ground_idx, :);
        t_raw = t_raw(1:ground_idx);
    end
    
    % --- NEW: RESAMPLING STEP (dt = 0.06) ---
    dt = 0.06;
    t_resampled = (0:dt:t_raw(end))'; % Create new time vector
    % Interp1 handles the X, Y, and Z columns simultaneously
    pos = interp1(t_raw, pos_raw, t_resampled, 'linear');
    
    % --- CALCULATIONS (on resampled data) ---
    [max_height, peak_idx] = max(pos(:,3));
    dis_at_max_height = pos(peak_idx, 1);
    time_to_peak = t_resampled(peak_idx);
    
    % 5. Package data
    dataRow = table(v, ang, h0, {omega_xyz}, {pos}, max_height, dis_at_max_height, time_to_peak, ...
        'VariableNames', {'Velocity', 'Angle', 'Height', 'Omega', 'Trajectory', 'Apogee', 'DisAtMaxHeight', 'TTP'});
    
    % 6. Optional Save
    if save_row
        if exist(filename, 'file'), temp = load(filename, 'masterTable'); masterTable = [temp.masterTable; dataRow];
        else, masterTable = dataRow; end
        save(filename, 'masterTable');
    end
end

%% Generate (or add to) DataBase
model = 'launcher_simulation';
db_file = 'ShootingDatabase.mat';

% Define your search grid
v_list = 5.5:0.5:10;      % FRC scale velocities
a_list = 55:1:70;       % FRC scale angles
omega_list = -10:2:10;

fprintf('Generating database...\n');

% Pre-allocate cell array for speed
num_sims = length(omega_list) * length(v_list) * length(a_list);
allRows = cell(num_sims, 1);
count = 1;

for omega = omega_list
    for v = v_list
        for ang = a_list
            % Call function: (model, v, ang, h0, omega, save_row, filename)
            % We pass 'false' for save_row to skip internal slow saving
            allRows{count} = run_sim_only(model, v, ang, 0, [0,omega,0], '', false);
            count = count + 1;
        end
    end
    % Progress update
    fprintf('Finished omega = %.1f (%d/%d)\n', omega, count-1, num_sims);
end

% Combine all rows into one table
masterTable = vertcat(allRows{:});

% Handle appending to existing file if it exists
if exist(db_file, 'file')
    oldData = load(db_file, 'masterTable');
    masterTable = [oldData.masterTable; masterTable];
end

save(db_file, 'masterTable');
fprintf('Done! Database saved with %d total entries.\n', height(masterTable));