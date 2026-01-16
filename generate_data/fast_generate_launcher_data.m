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
a_list = 55:0.5:85;
v_list = 4.4:0.2:9;
ratio_list = -4:0.25:4;

[V, A, R] = ndgrid(v_list, a_list, ratio_list);
all_params = [V(:), A(:), R(:)];
num_sims = size(all_params, 1);

% יצירת מערך SimulationInput
% התיקון: יצירה מפורשת של המערך כדי למנוע שגיאות ModelName
simInputs(num_sims) = Simulink.SimulationInput(model); 
fprintf('Initializing Values for %d simulations...\n', num_sims);
for i = 1:num_sims
    simInputs(i) = Simulink.SimulationInput(model); % וידוא שם המודל בכל איבר
    simInputs(i) = simInputs(i).setVariable('V_mag', all_params(i, 1));
    simInputs(i) = simInputs(i).setVariable('Angle', all_params(i, 2) * (pi/180));
    simInputs(i) = simInputs(i).setVariable('Initial_Height', 0);
    simInputs(i) = simInputs(i).setVariable('omega_val', [0, all_params(i, 1)*all_params(i, 3), 0]);
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

% פירוק המערך למשתנים נפרדים לפני הלולאה יוצר "Slicing" אוטומטי
V_all = all_params(:,1);
A_all = all_params(:,2);
R_all = all_params(:,3);

% שימוש ב-parfor במקום for
fprintf('Processing %d results in parallel...\n', num_sims);

parfor i = 1:num_sims
    v = V_all(i);
    ang = A_all(i);
    ratio = R_all(i);
    omega_xyz = [0, (v * ratio), 0]; 
    
    % --- THE FIX: CHECK IF DATA EXISTS ---
    % isprop checks if the field 'simout' exists in the SimulationOutput object
    if isprop(simOuts(i), 'simout') && ~isempty(simOuts(i).simout)
        try
            results{i} = intercept_simulation_output(v, ang, 0, omega_xyz, simOuts(i), dt);
        catch
            fprintf('Simulation number %d Collapsed...\n', i);
            results{i} = table(); % Handle internal function errors
        end
    else
        % If simulation failed to produce data, return an empty table row
        % so the vertcat later doesn't fail
        results{i} = table(); 
        fprintf('Simulation %d failed to produce data\n', i);
    end
end
 
%% Combine all rows into one table
masterTable = vertcat(results{:});

%% Save (or add to) DataBase
db_file = 'ShootingDatabase.mat';
save_or_add_to(db_file, masterTable);
