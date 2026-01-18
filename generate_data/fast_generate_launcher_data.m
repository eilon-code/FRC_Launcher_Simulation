close all;
clear;
clc;
%% 1. אתחול והגדרת מודל
clear simInputs all_params num_sims; % מנקה את המשתנים הקריטיים
model = 'launcher_simulation';
if ~bdIsLoaded(model), load_system(model); end
load_system(model);

initial_params();

% הגדרת המודל למצב Rapid Accelerator
set_param(model, 'SimulationMode', 'rapid-accelerator');

% בניית קובץ המטרה (קומפילציה חד-פעמית)
fprintf('Compiling model for Rapid Accelerator...\n');
Simulink.BlockDiagram.buildRapidAcceleratorTarget(model);

%% 2. יצירת מרחב הפרמטרים (Grid Search)
a_list = 55:20:65;%85;      % זוויות ירי במעלות
v_list = 5:2:6;%15;         % מהירויות ירי במטר/שנייה
ratio_list = -4:4:4;        % יחס סיבוב לספין

v_x_robot_list = -2:2:2;    % מהירות רובוט בכיוון הירי
v_y_robot_list = -2:2:2;    % מהירות רובוט בניצב לכיוון הירי

% יצירת הגריד - כל שילוב אפשרי בין הרשימות
[V_grid, A_grid, R_grid, V_x_robot_grid, V_y_robot_grid] = ndgrid( ...
    v_list, a_list, ratio_list, v_x_robot_list, v_y_robot_list ...
    );
V_0_x = V_grid .* cos(deg2rad(A_grid)) + V_x_robot_grid;
V_0_y = V_y_robot_grid;
V_0_z = V_grid .* sin(deg2rad(A_grid));

Omega_grid = R_grid .* V_grid;

% ריכוז כל הנתונים למטריצה אחת שבה כל שורה היא סימולציה נפרדת
% עמודות: [Vx, Vy, Vz, V_mag, Ratio]
all_params = [V_0_x(:), V_0_y(:), V_0_z(:), Omega_grid(:)];

num_sims = size(all_params, 1);

fprintf('created %d different sets of parameters to simulate.\n', num_sims);

% יצירת מערך SimulationInput
% התיקון: יצירה מפורשת של המערך כדי למנוע שגיאות ModelName
simInputs(num_sims) = Simulink.SimulationInput(model); 
fprintf('Initializing Values for %d simulations...\n', num_sims);
for i = 1:num_sims
    simInputs(i) = Simulink.SimulationInput(model); % וידוא שם המודל בכל איבר
    simInputs(i) = simInputs(i).setVariable('Initial_Height', 0);
    simInputs(i) = simInputs(i).setVariable('V_0', [all_params(i, 1),all_params(i, 2),all_params(i, 3)]);
    simInputs(i) = simInputs(i).setVariable('omega_0', [0, all_params(i, 4), 0]);
end

%% 3. הרצה מקבילית
fprintf('Starting %d simulations on all available cores...\n', num_sims);
tic; % תזמון
simOuts = parsim(simInputs, 'ShowProgress', 'on', 'UseFastRestart', 'on');
totalTime = toc;
fprintf('Simulations complete in %.2f seconds.\n', totalTime);

%% 4. עיבוד תוצאות במקביל (Parallel Post-Processing)
dt = 0.06;
results = cell(num_sims, 1);

% שימוש ב-parfor במקום for
fprintf('Processing %d results in parallel...\n', num_sims);

parfor i = 1:num_sims
    v_out = V_grid(i);
    ang = A_grid(i);
    ratio = R_grid(i);
    omega_xyz = [0, (v_out * ratio), 0];
    v_robot = [V_x_robot_grid(i),V_y_robot_grid(i),0];
    
    % --- CHECK IF DATA EXISTS ---
    % isprop checks if the field 'simoutP' exists in the SimulationOutput object
    if isprop(simOuts(i), 'simoutP') && ~isempty(simOuts(i).simoutP)
        try
            % קריאה לפונקציית החילוץ שלך
            results{i} = intercept_simulation_output(0, v_out, ang, omega_xyz, v_robot, simOuts(i), dt);
        catch ME
            fprintf('Simulation %d failed during interception: %s\n', i, ME.message);
            results{i} = table(); 
        end
    else
        % אם הנתונים בפורמט Dataset, הגישה היא דרך logsout או ישירות
        % נסה להדפיס simOuts(1) בחלון הפקודות כדי לראות את המבנה המדויק
        results{i} = table(); 
        fprintf('Simulation %d: No data found in simoutP\n', i);
    end
end

%% Combine all rows into one table
masterTable = vertcat(results{:});

%% Save (or add to) DataBase
db_file = 'ShootingDatabase_3D.mat';
save_or_add_to(db_file, masterTable);
