%% Generate data-row from simulation result
function dataRow = intercept_simulation_output(h0, v_out, ang, omega_xyz, v_robot, simOut, dt)
    % 1. Extract Trajectory and Time
    pos_raw = squeeze(simOut.simoutP.Data);
    if size(pos_raw,1) == 3, pos_raw = pos_raw'; end
    vel_raw = squeeze(simOut.simoutV.Data);
    if size(vel_raw,1) == 3, vel_raw = vel_raw'; end
    omega_raw = squeeze(simOut.simoutOmega.Data);
    if size(omega_raw,1) == 3, omega_raw = omega_raw'; end
    t_raw = simOut.tout;
    
    % Clip at ground (z < 0)
    ground_idx = find(pos_raw(:,3) < 0, 1);
    if ~isempty(ground_idx)
        pos_raw = pos_raw(1:ground_idx, :);
        vel_raw = vel_raw(1:ground_idx, :);
        omega_raw = omega_raw(1:ground_idx, :);
        t_raw = t_raw(1:ground_idx);
    end
    
    % --- NEW: RESAMPLING STEP (dt) ---
    t_resampled = (0:dt:t_raw(end))'; % Create new time vector
    % Interp1 handles the X, Y, and Z columns simultaneously
    pos = interp1(t_raw, pos_raw, t_resampled, 'linear');
    vel = interp1(t_raw, vel_raw, t_resampled, 'linear');
    omega = interp1(t_raw, omega_raw, t_resampled, 'linear');
    
    % --- CALCULATIONS (on resampled data) ---
    [max_height, peak_idx] = max(pos(:,3));
    X_peak = pos(peak_idx, 1);
    Y_peak = pos(peak_idx, 2);
    Z_peak = max_height;

    % 2. Package data
    dataRow = table(h0, v_out, ang, {omega_xyz}, {v_robot}, {pos, vel, omega}, Z_peak, X_peak, Y_peak, peak_idx, dt, ...
        'VariableNames', {'InitialHeight', 'V_out', 'Angle', 'Omega0', 'V_robot', 'Trajectory', 'Apogee', 'Xpeak', 'Ypeak', 'PeakIndex', 'dt'});
end
