%% save or add data to file
function save_or_add_to(db_file, masterTable)
    % Handle appending to existing file if it exists
    if exist(db_file, 'file')
        oldData = load(db_file, 'masterTable');
        masterTable = [oldData.masterTable; masterTable];
    end
    
    save(db_file, 'masterTable');
    fprintf('Done! Database saved with %d total entries.\n', height(masterTable));
end