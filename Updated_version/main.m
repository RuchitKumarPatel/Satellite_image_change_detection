function main()
    % MAIN - Satellite Change Detection System Launcher
    % This is the main entry point for the application
    %
    % Usage:
    %   main()
    %
    % The system will:
    %   1. Check for required MATLAB toolboxes
    %   2. Initialize the GUI
    %   3. Load all necessary modules
    %
    % Required files:
    %   - gui/createMainGUI.m
    %   - utils/checkToolboxes.m
    %   - All other module files in their respective directories
    
    fprintf('=================================================================\n');
    fprintf('    SATELLITE CHANGE DETECTION SYSTEM v2.0                      \n');
    fprintf('    Multi-Algorithm Adaptive Processing for Global Imagery      \n');
    fprintf('=================================================================\n\n');
    
    % Add all subdirectories to path
    addpath(genpath(pwd));
    
    % Check system requirements
    fprintf('Checking system requirements...\n');
    [hasCV, hasIP, hasML] = checkToolboxes();
    
    if ~hasCV && ~hasIP
        warning('Critical toolboxes missing. Some features will be limited.');
        fprintf('Please install Computer Vision and/or Image Processing Toolbox for full functionality.\n');
    end
    
    % Initialize the GUI
    fprintf('\nInitializing graphical user interface...\n');
    try
        fig = createMainGUI(hasCV, hasIP, hasML);
        fprintf('\n✓ System successfully initialized!\n');
        fprintf('Ready for satellite image analysis.\n\n');
    catch ME
        fprintf('\n✗ Error during initialization:\n');
        fprintf('  %s\n', ME.message);
        fprintf('\nPlease ensure all required files are in the correct directories.\n');
        rethrow(ME);
    end
end
