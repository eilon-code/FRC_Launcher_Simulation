function initial_params()
    C_d = 0.5;              % drag coefficient
    C_l = 0.2;              % lift coefficient
    rho = 1.225;            % air density kg/m^3
    g = 9.81;               % Earth Gravity facotor
    m = 0.230;              % Mass of projectile
    r = 0.075;              % radius of projectile

    % Assign parameters to the base workspace for further calculations
    assignin('base', 'g', g);  % gravitational acceleration m/s^2
    assignin('base', 'mass', m);  % mass in kg
    assignin('base', 'radius', r);  % gravitational acceleration m/s^2
    assignin('base', 'rho', rho);
    assignin('base', 'C_d', C_d);
    assignin('base', 'C_l', C_l);
    % --- הוספת משתני דמה כדי שהקומפילציה תעבור ---
    assignin('base', 'V_mag', 1);
    assignin('base', 'Angle', 0.1);
    assignin('base', 'Initial_Height', 0);
    assignin('base', 'omega_val', [0, 0, 0]);
    % ---------------------------------------------
end
