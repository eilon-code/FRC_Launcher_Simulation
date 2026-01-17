%% Optimized Batch Visualization & Export to PDF
load('ShootingDatabase.mat'); 

% יצירת תיקייה לשמירה אם לא קיימת
outputDir = 'Trajectory_Plots/trajectories';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

angle_vals_list = unique(masterTable.Angle)';
tol = 0.1;

fprintf('Starting PDF generation for %d angles...\n', length(angle_vals_list));

for target_angle = angle_vals_list
    % 1. סינון מהיר של הטבלה
    subset = masterTable(abs(masterTable.Angle - target_angle) < tol, :);
    if isempty(subset), continue; end
    
    subset = sortrows(subset, 'Velocity');
    unique_v = unique(subset.Velocity);
    v_colors = jet(length(unique_v));
    
    % מציאת מקסימום אומגה לנרמול (שימוש ב-abs למקרה של ספין שלילי)
    omegas = cellfun(@(x) abs(x(2)), subset.Omega);
    max_omega = max(omegas);
    if max_omega == 0, max_omega = 1; end % מניעת חילוק ב-0
    
    % 2. יצירת פיגר מוסתר (חיוני למהירות!)
    fig = figure('Color', 'w', 'Visible', 'off', 'Units', 'pixels', 'Position', [100 100 1200 800]);
    ax = axes('Parent', fig);
    hold(ax, 'on'); grid(ax, 'on');
    
    % 3. ציור מסלולים
    for i = 1:height(subset)
        v_val = subset.Velocity(i);
        omega_y = subset.Omega{i}(2);
        traj = subset.Trajectory{i};
        
        c_idx = (unique_v == v_val);
        this_color = v_colors(c_idx, :);
        
        % חישוב שקיפות
        opacity = 0.2 + 0.8 * (abs(omega_y) / max_omega);
        
        % שימוש ב-line במקום patch עבור מהירות (אם לא חייבים שקיפות משתנה בתוך הקו)
        % הערה: ב-MATLAB, אובייקט 'line' מהיר יותר מ-'patch'
        p = plot(ax, traj(:,1), traj(:,3), 'Color', [this_color, opacity], 'LineWidth', 0.8);
    end
    
    % 4. עיצוב מהיר
    xlabel(ax, 'Distance (X) [m]');
    ylabel(ax, 'Height (Z) [m]');
    title(ax, sprintf('Launch Profile at %.1f° (Color=Vel, Alpha=Spin)', target_angle));
    
    % יצירת Legend רק עבור המהירויות הייחודיות
    h_lgd = [];
    for k = 1:length(unique_v)
        h_lgd(k) = plot(ax, NaN, NaN, 'Color', v_colors(k,:), 'LineWidth', 2);
    end
    legend(ax, h_lgd, string(unique_v) + " m/s", 'Location', 'northeastoutside');
    
    % 5. שמירה ל-PDF
    fileName = sprintf('%s/Trajectories_Angle_%.1f.pdf', outputDir, target_angle);
    % exportgraphics הרבה יותר מהירה ואיכותית מ-saveas עבור PDF
    exportgraphics(fig, fileName, 'ContentType', 'vector');
    
    % 6. סגירת הפיגר לשחרור זיכרון
    close(fig);
    
    fprintf('Saved: %s\n', fileName);
end

fprintf('Done! All plots saved to: %s\n', outputDir);