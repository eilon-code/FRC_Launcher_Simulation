function isGoal = check_goal_projectile_3D(row, targetX, targetY, targetZ, R_out, R_in, BallR_out)
%CHECK_GOAL_PROJECTILE_3D Determines whether a projectile scores a goal in 3D.
%
% INPUTS:
%   row         - A row from masterTable containing trajectory data
%   targetX,Y,Z - Center of the target in 3D space
%   R_out       - Radius of the entry ring (outer ring)
%   R_in        - Radius of the scoring ring (inner ring)
%   BallR_out   - Vertical tolerance above the entry ring before scoring
%
% OUTPUT:
%   isGoal      - Logical flag indicating whether the projectile scores

    %% Extract trajectory data
    positions = row.Trajectory{1};     % Nx3 matrix: [X, Y, Z]
    X = positions(:,1);
    Y = positions(:,2);
    Z = positions(:,3);

    %% --- Stage 1: Fast feasibility checks (early exits) ---

    % If the projectile never reaches sufficient height, it cannot score
    if row.Apogee < (targetZ + BallR_out)
        isGoal = false;
        return;
    end

    % Squared horizontal distance from target center
    dist2_xy = (X - targetX).^2 + (Y - targetY).^2;

    % If the projectile never gets close enough to the scoring ring
    if min(dist2_xy) > R_in^2
        isGoal = false;
        return;
    end

    %% --- Stage 2: Entry-ring requirement (XY plane) ---

    % Points inside the entry ring
    in_entry_ring = dist2_xy < R_out^2;

    if ~any(in_entry_ring)
        isGoal = false;
        return;
    end

    % First index where the projectile enters the entry ring
    entry_idx = find(in_entry_ring, 1, 'first');

    %% --- Stage 3: Entry height requirement ---

    % Projectile must enter the ring while sufficiently above the target
    if Z(entry_idx) < (targetZ + BallR_out)
        isGoal = false;
        return;
    end

    %% --- Stage 4: Prevent "ghost goals" ---
    % The projectile must not leave the entry ring while still above targetZ

    after_entry = (1:length(Z))' > entry_idx;
    outside_entry_ring = ~in_entry_ring;

    % Any point that is:
    %  - after entering the ring
    %  - outside the entry ring
    %  - still above the target height
    ghost_goal = after_entry & outside_entry_ring & (Z >= targetZ);

    if any(ghost_goal)
        isGoal = false;
        return;
    end

    %% --- Stage 5: Scoring-ring crossing in Z ---

    % Points inside the scoring ring
    in_scoring_ring = dist2_xy < R_in^2;

    if ~any(in_scoring_ring)
        isGoal = false;
        return;
    end

    % Z-values while inside the scoring ring
    Z_scoring = Z(in_scoring_ring);

    % Must cross targetZ from above to below (or vice versa)
    isGoal = any(Z_scoring >= targetZ) && any(Z_scoring <= targetZ);
end
