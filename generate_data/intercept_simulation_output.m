%% Generate data-row from simulation result
function dataRow = intercept_simulation_output(v, ang, h0, omega_xyz, simOut, dt)
    % 1. Extract Trajectory and Time
    pos_raw = squeeze(simOut.simout.Data);
    if size(pos_raw,1) == 3, pos_raw = pos_raw'; end
    t_raw = simOut.tout;
    
    % Clip at ground (z < 0)
    ground_idx = find(pos_raw(:,3) < 0, 1);
    if ~isempty(ground_idx)
        pos_raw = pos_raw(1:ground_idx, :);
        t_raw = t_raw(1:ground_idx);
    end
    
    % --- NEW: RESAMPLING STEP (dt) ---
    t_resampled = (0:dt:t_raw(end))'; % Create new time vector
    % Interp1 handles the X, Y, and Z columns simultaneously
    pos = interp1(t_raw, pos_raw, t_resampled, 'linear');
    
    % --- CALCULATIONS (on resampled data) ---
    [max_height, peak_idx] = max(pos(:,3));
    dis_at_max_height = pos(peak_idx, 1);
    time_to_peak = t_resampled(peak_idx);

    % 2. Package data
    dataRow = table(v, ang, h0, {omega_xyz}, {pos}, max_height, dis_at_max_height, time_to_peak, ...
        'VariableNames', {'Velocity', 'Angle', 'Height', 'Omega', 'Trajectory', 'Apogee', 'DisAtMaxHeight', 'TTP'});
end
