function initial_params()
    g = 9.81;               % Earth Gravity facotor
    m = 0.230;              % Mass of projectile
    r = 0.075;              % radius of projectile
    rho = 1.225;            % air density kg/m^3
    
    C_d = 0.4;              % drag coefficient
    C_l = 0.2;              % lift (base) coefficient
    k_lift = 1.2;           % lift decay
    C_m = 0.01;             % Change of omega according to moment tau

    % Assign parameters to the base workspace for further calculations
    assignin('base', 'g', g);  % gravitational acceleration m/s^2
    assignin('base', 'mass', m);  % mass in kg
    assignin('base', 'radius', r);  % gravitational acceleration m/s^2
    assignin('base', 'rho', rho);
    assignin('base', 'C_d', C_d);
    assignin('base', 'C_l', C_l);
    assignin('base', 'k_lift', k_lift);
    assignin('base', 'C_m', C_m);
    % --- הוספת משתני דמה כדי שהקומפילציה תעבור ---
    assignin('base', 'Initial_Height', 0);
    assignin('base', 'V_0', [0,0,0]);           % initial velocity
    assignin('base', 'omega_0', [0, 0, 0]);     % initial (internal) rotation velocity
    % ---------------------------------------------
end
