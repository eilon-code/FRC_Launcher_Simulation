function score = evaluate_trajectory_3D(row, targetX, targetY, targetZ, ...
        R_out, R_in, BallR_out, ...
        angle_penalty, vel_penalty, distance_from_center_penalty)
%EVALUATE_TRAJECTORY_3D
% Computes a continuous quality score (0–1) for a 3D projectile trajectory
% that successfully scores a goal.
%
% The score accounts for:
%   - Entry angle (verticality)
%   - Impact velocity
%   - Lateral precision (distance from target center)
%
% If the trajectory does not satisfy the binary goal conditions,
% the score is zero.

    %% --- Stage 1: Binary goal validation ---
    if ~check_goal_projectile_3D(row, targetX, targetY, targetZ, ...
                                 R_out, R_in, BallR_out)
        score = 0;
        return;
    end

    %% --- Stage 2: Extract trajectory data ---
    pos = row.Trajectory{1};     % Nx3 matrix: [X, Y, Z]
    vel = row.Trajectory{2};     % Nx3 matrix: [Vx, Vy, Vz]

    X = pos(:,1);
    Y = pos(:,2);
    Z = pos(:,3);

    %% --- Stage 3: Detect scoring event (Z = targetZ crossing) ---
    idx = find(Z(1:end-1) >= targetZ & Z(2:end) <= targetZ, 1, 'first');

    if isempty(idx)
        score = 0;
        return;
    end

    %% --- Stage 4: Impact velocity ---
    v_vec = vel(idx, :);
    v_mag = norm(v_vec);

    %% --- Stage 5: Entry angle quality (verticality) ---
    % Angle between velocity vector and vertical axis
    v_horizontal = norm(v_vec(1:2));
    v_vertical   = abs(v_vec(3));

    % Entry angle: 0 rad = perfectly vertical, pi/2 = horizontal
    entry_angle = atan2(v_horizontal, v_vertical);

    quality_of_angle = evaluate_distance_from_zero( ...
        entry_angle * angle_penalty);

    %% --- Stage 6: Impact speed quality ---
    quality_of_velocity = evaluate_distance_from_zero( ...
        v_mag * vel_penalty);

    %% --- Stage 7: Lateral precision (distance from center) ---
    ratio = (Z(idx) - targetZ) / (Z(idx) - Z(idx+1));

    x_cross = X(idx) + ratio * (X(idx+1) - X(idx));
    y_cross = Y(idx) + ratio * (Y(idx+1) - Y(idx));

    dist_from_center = hypot(x_cross - targetX, y_cross - targetY);

    normalized_dist = dist_from_center / R_in;

    quality_of_distance = evaluate_distance_from_zero_divider( ...
        normalized_dist * distance_from_center_penalty);

    %% --- Stage 8: Final combined score ---
    score = quality_of_angle * quality_of_velocity * quality_of_distance;
end
