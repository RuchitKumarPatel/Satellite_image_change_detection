function main()
    % MAIN - Computer Vision Challenge with Change Detection Algorithms
    
    % Start message in the console
    fprintf('=== Computer Vision Challenge - Change Detection Implementation ===\n');
    fprintf('Starting application with CV algorithms...\n');
    
    % Check MATLAB version
    matlabVersion = version('-release');
    fprintf('MATLAB Version: %s\n', matlabVersion);
    
    % Check available toolboxes
    [hasCV, hasIP, hasML] = checkAvailableToolboxes();
    
    % Create GUI
    createChangeDetectionGUI(hasCV, hasIP, hasML);
    
    % Concluding message in the console
    fprintf('Change Detection application initialized successfully!\n');
end

function [hasCV, hasIP, hasML] = checkAvailableToolboxes()
    % checkAvailableToolboxes - Checks the availability of necessary MATLAB toolboxes.
    % Returns logical values indicating whether the Computer Vision, Image Processing
    % and Statistics and Machine Learning Toolboxes are available.
    
    fprintf('\nChecking toolbox availability...\n');
    
    % Check if Computer Vision Toolbox is available (e.g., via SURF function)
    hasCV = exist('detectSURFFeatures', 'file') == 2;
    % Check if Image Processing Toolbox is available (e.g., via imresize function)
    hasIP = exist('imresize', 'file') == 2;
    % Check if Statistics and Machine Learning Toolbox is available (e.g., via kmeans function)
    hasML = exist('kmeans', 'file') == 2;
    
    % Output the status of each toolbox
    if hasCV, fprintf('✓ Computer Vision Toolbox: Available\n');
    else, fprintf('✗ Computer Vision Toolbox: Not Available\n'); end
    
    if hasIP, fprintf('✓ Image Processing Toolbox: Available\n');
    else, fprintf('✗ Image Processing Toolbox: Not Available\n'); end
    
    if hasML, fprintf('✓ Statistics and Machine Learning Toolbox: Available\n');
    else, fprintf('✗ Statistics and Machine Learning Toolbox: Not Available\n'); end
    
    % Summary if all toolboxes are available
    if hasCV && hasIP && hasML
        fprintf('\n All toolboxes available - Full CV functionality enabled!\n');
    end
end

function createChangeDetectionGUI(hasCV, hasIP, hasML)
    % createChangeDetectionGUI - Creates the main GUI for change detection.
    % Initializes the figure, stores user data, and creates all GUI components.
    
    % Create the main figure (window)
    fig = figure('Name', 'CV Challenge - Satellite Image Change Detection', ...
                 'Position', [30, 30, 1500, 1000], ... % Initial position and size
                 'MenuBar', 'none', ...               % No menu bar
                 'ToolBar', 'none', ...               % No toolbar
                 'NumberTitle', 'off', ...            % No number in window title
                 'CloseRequestFcn', @closeApp, ...    % Callback when closing the window
                 'Units', 'pixels', ...               % Set units to pixels
                 'SizeChangedFcn', @(src,evt) updateFontSizes(src)); % Callback on resize
    
    % Initialize and store user data (UserData) for the figure
    fig.UserData.hasCV = hasCV;
    fig.UserData.hasIP = hasIP;
    fig.UserData.hasML = hasML;
    fig.UserData.images = {};           % Information about loaded image files
    fig.UserData.currentFolder = '';    % Current image folder
    fig.UserData.loadedImages = {};     % Loaded image data
    fig.UserData.alignedImages = {};    % Aligned images
    fig.UserData.currentImagePair = [1, 2]; % Currently displayed image pair
    fig.UserData.registrationData = []; % Image registration data
    fig.UserData.changeData = [];       % Change detection data
    % Store handles for all axes in UserData for easy access
    fig.UserData.img1Axes = [];
    fig.UserData.img2Axes = [];
    fig.UserData.resultsAxes = [];
    fig.UserData.vizAxes = [];
    fig.UserData.histogramAxes = [];
    fig.UserData.scatterAxes = [];
    fig.UserData.featuresAxes = [];
    fig.UserData.changeMapAxes = [];
    
    % Create all GUI panels and their components
    createControlPanel(fig);
    createVisualizationPanel(fig);
    createImageDisplayPanels(fig);
    createResultsPanel(fig);
    createStatusPanel(fig);

    % Adjust font sizes after all components are created
    updateFontSizes(fig);
    
    fprintf('Full change detection GUI created!\n');
end

function createControlPanel(fig)
    % createControlPanel - Creates the control panel for image control and settings.
    
    % Create panel for control elements
    controlPanel = uipanel('Parent', fig, ...
                          'Title', 'Image Controls & Settings', ...
                          'Units', 'normalized', ...
                          'Position', [0.01, 0.59, 0.22, 0.38], ... % Position and size
                          'FontSize', 11, ...
                          'FontWeight', 'bold');
    
    % "Cancel" button to exit the application
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Cancel', ... 
              'Units', 'normalized', ...
              'Position', [0.03, 0.9, 0.94, 0.05], ...
              'FontSize', 10, ...
              'BackgroundColor', [0.9, 0.2, 0.2], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Callback', @(src,evt) closeApp(fig, evt)); 
    
    % "Select Image Folder" button to choose the image folder
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Select Image Folder', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.825, 0.94, 0.05], ...
              'FontSize', 10, ...
              'BackgroundColor', [0.2, 0.6, 0.9], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Callback', @(src,evt) selectImageFolder(fig));
    
    % "Load & Process" button to load and process images
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Load & Process', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.75, 0.94, 0.05], ...
              'FontSize', 10, ...
              'Enable', 'off', ... % Initially disabled
              'BackgroundColor', [0.2, 0.8, 0.2], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Tag', 'loadButton', ...
              'Callback', @(src,evt) loadAndProcessImages(fig));

    % "Timelaps" button to create a timelaps
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Timelapse', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.675, 0.94, 0.05], ...
              'FontSize', 10, ...
              'Enable', 'off', ... % Initially disabled
              'BackgroundColor', [0.9, 0.4, 0.2], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Tag', 'timelapseButton', ...
              'Callback', @(src, evt) timelapseCallback(fig));
    
    % Text label for image navigation
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Image Navigation:', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.62, 0.94, 0.04], ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    % Text label for Image 1 navigation
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Image 1:', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.56, 0.94, 0.04], ...
              'FontSize', 9, ...
              'FontWeight', 'bold');

    % "Prev 1" button for Image 1
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '◄ Prev 1', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.485, 0.45, 0.065], ...
              'FontSize', 9, ...
              'Tag', 'prev1Button', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) navigateSingleImage(fig, -1, 1)); 
    
    % "Next 1" button for Image 1
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Next 1 ►', ...
              'Units', 'normalized', ...
              'Position', [0.52, 0.485, 0.45, 0.065], ...
              'FontSize', 9, ...
              'Tag', 'next1Button', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) navigateSingleImage(fig, 1, 1)); 

    % Text label for Image 2 navigation
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Image 2:', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.43, 0.94, 0.04], ...
              'FontSize', 9, ...
              'FontWeight', 'bold');

    % "Prev 2" button for Image 2
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '◄ Prev 2', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.355, 0.45, 0.065], ...
              'FontSize', 9, ...
              'Tag', 'prev2Button', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) navigateSingleImage(fig, -1, 2)); 
    
    % "Next 2" button for Image 2
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Next 2 ►', ...
              'Units', 'normalized', ...
              'Position', [0.52, 0.355, 0.45, 0.065], ...
              'FontSize', 9, ...
              'Tag', 'next2Button', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) navigateSingleImage(fig, 1, 2)); 

    % Text label to display the current image pair
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Current Pair: 1-2', ... 
              'Units', 'normalized', ...
              'Position', [0.03, 0.29, 0.94, 0.04], ...
              'FontSize', 9, ...
              'Tag', 'pairText', ...
              'HorizontalAlignment', 'center');
    
    % Text label for change detection
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Change Detection:', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.23, 0.94, 0.04], ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    % "Align Images" button for image alignment
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Align Images', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.155, 0.45, 0.065], ...
              'FontSize', 8, ...
              'Tag', 'alignButton', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) alignCurrentImages(fig));
    
    % "Detect Changes" button for change detection
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Detect Changes', ...
              'Units', 'normalized', ...
              'Position', [0.52, 0.155, 0.45, 0.065], ...
              'FontSize', 8, ...
              'Tag', 'detectButton', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) detectChanges(fig));

    % Checkbox for median filter (noise reduction)
    uicontrol('Parent', controlPanel, ...
              'Style', 'checkbox', ...
              'String', 'Apply Median Filter (Noise Reduction)', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.10, 0.94, 0.04], ...
              'FontSize', 8, ...
              'Tag', 'medianFilterCheckbox', ...
              'Value', 0); % Default to off
    
    % Status indicator
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Ready - Select folder to begin', ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.025, 0.94, 0.06], ...
              'FontSize', 8, ...
              'Tag', 'statusIndicator', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.95, 0.95, 0.95]);
end

function createVisualizationPanel(fig)
    % createVisualizationPanel - Creates the panel for visualization options.
    
    % Create panel for visualization methods
    vizPanel = uipanel('Parent', fig, ...
                      'Title', 'Visualization Methods', ...
                      'Units', 'normalized', ...
                      'Position', [0.01, 0.33, 0.22, 0.26], ... 
                      'FontSize', 11, ...
                      'FontWeight', 'bold');
    
    % Text label for visualization type
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', 'Visualization Type:', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.85, 0.9, 0.06], ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    % Button group for visualization types (Radio Buttons)
    vizGroup = uibuttongroup('Parent', vizPanel, ...
                            'Units', 'normalized', ...
                            'Position', [0.05, 0.55, 0.9, 0.28], ...
                            'Tag', 'vizGroup', ...
                            'SelectionChangedFcn', @(src,evt) updateVisualization(fig));
    
    % Radio Button: Difference Heatmap
    uicontrol('Parent', vizGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Difference Heatmap', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.7, 0.9, 0.25], ...
              'FontSize', 9, ...
              'Tag', 'heatmapRadio', ...
              'Value', 1);  % Default selection
    
    % Radio Button: Side-by-Side Overlay
    uicontrol('Parent', vizGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Side-by-Side Overlay', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.35, 0.9, 0.25], ...
              'FontSize', 9, ...
              'Tag', 'overlayRadio');
    
    % Radio Button: Change Highlights
    uicontrol('Parent', vizGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Change Highlights', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.05, 0.9, 0.25], ...
              'FontSize', 9, ...
              'Tag', 'highlightRadio');
    
    % Text label for change type
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', 'Change Type Focus:', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.45, 0.9, 0.06], ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    % Dropdown menu for change types
    uicontrol('Parent', vizPanel, ...
              'Style', 'popupmenu', ...
              'String', {'All Changes', 'Geometric Changes (Size/Shape)', 'Intensity Changes (Brightness)', 'Structural Changes (Texture)'}, ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.35, 0.9, 0.09], ...
              'FontSize', 9, ...
              'Tag', 'changeTypeDropdown', ...
              'Callback', @(src,evt) updateVisualization(fig));
    
    % Text label for sensitivity
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', 'Change Sensitivity:', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.25, 0.9, 0.06], ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    % Slider for sensitivity
    uicontrol('Parent', vizPanel, ...
              'Style', 'slider', ...
              'Min', 0.1, 'Max', 2.0, 'Value', 1.0, ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.17, 0.7, 0.08], ...
              'Tag', 'sensitivitySlider', ...
              'Callback', @(src,evt) updateVisualization(fig));
    
    % Text field to display the slider value
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', '1.0', ...
              'Units', 'normalized', ...
              'Position', [0.78, 0.17, 0.17, 0.08], ...
              'FontSize', 8, ...
              'Tag', 'sensitivityText');
    
    % "Apply Visualization" button
    uicontrol('Parent', vizPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Apply Visualization', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.05, 0.9, 0.09], ...
              'FontSize', 9, ...
              'BackgroundColor', [0.8, 0.2, 0.8], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Tag', 'applyVizButton', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) applyVisualization(fig));
end

function createImageDisplayPanels(fig)
    % createImageDisplayPanels - Creates the panels for displaying original images and results.
    
    % Panel for original images
    origPanel = uipanel('Parent', fig, ...
                       'Title', 'Original Images', ...
                       'Units', 'normalized', ...
                       'Position', [0.25, 0.505, 0.48, 0.48], ...
                       'FontSize', 11, ...
                       'FontWeight', 'bold');
    
    % Axes for Image 1 (earlier)
    img1Axes = axes('Parent', origPanel, ...
         'Units', 'normalized', ...
         'Position', [0.02, 0.1, 0.46, 0.85], ...
         'Tag', 'img1Axes', ...
         'XTick', [], 'YTick', []);
    fig.UserData.img1Axes = img1Axes; % Store handle in UserData
    
    % Axes for Image 2 (later)
    img2Axes = axes('Parent', origPanel, ...
         'Units', 'normalized', ...
         'Position', [0.52, 0.1, 0.46, 0.85], ...
         'Tag', 'img2Axes', ...
         'XTick', [], 'YTick', []);
    fig.UserData.img2Axes = img2Axes; % Store handle in UserData
    
    % Panel for results (contains tab group)
    resultsPanel = uipanel('Parent', fig, ...
                           'Title', 'Results', ...
                           'Units', 'normalized', ...
                           'Position', [0.75, 0.505, 0.24, 0.48], ...
                           'FontSize', 11, ...
                           'FontWeight', 'bold');

    % Tab group for results
    resultsTabGroup = uitabgroup('Parent', resultsPanel, ...
                                 'Units', 'normalized', ...
                                 'Position', [0.01, 0.01, 0.98, 0.98], ...
                                 'Tag', 'resultsTabGroup');

    % Tab: Aligned Image
    alignedImageTab = uitab('Parent', resultsTabGroup, ...
                            'Title', 'Aligned Image', ...
                            'Units', 'normalized', ...
                            'Tag', 'alignedImageTab');

    % Axes for the "Aligned Image" tab
    resultsAxes = axes('Parent', alignedImageTab, ...
         'Units', 'normalized', ...
         'Position', [0.05, 0.15, 0.9, 0.8], ...
         'Tag', 'resultsAxes', ...
         'XTick', [], 'YTick', []);
    fig.UserData.resultsAxes = resultsAxes; % Store handle in UserData

    % "Save Results" button in the "Aligned Image" tab
    uicontrol('Parent', alignedImageTab, ...
              'Style', 'pushbutton', ...
              'String', 'Save Results', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.02, 0.4, 0.08], ...
              'FontSize', 8, ...
              'Tag', 'saveButtonAligned', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) saveResults(fig));

    % "Detailed Report" button in the "Aligned Image" tab
    uicontrol('Parent', alignedImageTab, ...
              'Style', 'pushbutton', ...
              'String', 'Detailed Report', ...
              'Units', 'normalized', ...
              'Position', [0.55, 0.02, 0.4, 0.08], ...
              'FontSize', 8, ...
              'Tag', 'reportButtonAligned', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) generateReport(fig));

    % Tab: Statistics
    statisticsTab = uitab('Parent', resultsTabGroup, ...
                          'Title', 'Statistics', ...
                          'Units', 'normalized', ...
                          'Tag', 'statisticsTab');

    % Text label for change statistics
    uicontrol('Parent', statisticsTab, ...
              'Style', 'text', ...
              'String', 'Change Statistics:', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.9, 0.9, 0.03], ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left');

    % Edit field for change statistics
    uicontrol('Parent', statisticsTab, ...
              'Style', 'edit', ...
              'String', 'No analysis performed yet', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.55, 0.9, 0.35], ...
              'FontSize', 8, ...
              'Max', 12, ...
              'Tag', 'statsText', ...
              'HorizontalAlignment', 'left');

    % Text label for features and alignment
    uicontrol('Parent', statisticsTab, ...
              'Style', 'text', ...
              'String', 'Features & Alignment:', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.5, 0.9, 0.03], ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left');

    % Edit field for feature detection information
    uicontrol('Parent', statisticsTab, ...
              'Style', 'edit', ...
              'String', 'Load images to begin analysis', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.15, 0.9, 0.35], ...
              'FontSize', 8, ...
              'Max', 12, ...
              'Tag', 'featuresText', ...
              'HorizontalAlignment', 'left');

    % "Save Results" button in the "Statistics" tab
    uicontrol('Parent', statisticsTab, ...
              'Style', 'pushbutton', ...
              'String', 'Save Results', ...
              'Units', 'normalized', ...
              'Position', [0.05, 0.02, 0.4, 0.08], ...
              'FontSize', 8, ...
              'Tag', 'saveButtonStats', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) saveResults(fig));

    % "Detailed Report" button in the "Statistics" tab
    uicontrol('Parent', statisticsTab, ...
              'Style', 'pushbutton', ...
              'String', 'Detailed Report', ...
              'Units', 'normalized', ...
              'Position', [0.55, 0.02, 0.4, 0.08], ...
              'FontSize', 8, ...
              'Tag', 'reportButtonStats', ...
              'Enable', 'off', ... % Initially disabled
              'Callback', @(src,evt) generateReport(fig));
end

function createResultsPanel(fig)
    % createResultsPanel - Creates the panel for detailed analyses and comparisons.
    
    % Panel for detailed analysis
    detailPanel = uipanel('Parent', fig, ...
                         'Title', 'Detailed Analysis & Comparisons', ...
                         'Units', 'normalized', ...
                         'Position', [0.25, 0.01, 0.74, 0.47], ...
                         'FontSize', 11, ...
                         'FontWeight', 'bold');
    
    % Tab group for various analysis views
    tabGroup = uitabgroup('Parent', detailPanel, ...
                         'Units', 'normalized', ...
                         'Position', [0.01, 0.01, 0.98, 0.98], ...
                         'Tag', 'analysisTabGroup');
    
    % Tab: Visualization
    vizTab = uitab('Parent', tabGroup, ...
                   'Title', 'Visualization', ...
                   'Units', 'normalized', ...
                   'Tag', 'vizTab');
    fig.UserData.vizAxes = axes('Parent', vizTab, ...
                                'Units', 'normalized', ...
                                'Position', [0.05, 0.1, 0.9, 0.85], ...
                                'Tag', 'vizAxes', ...
                                'XTick', [], 'YTick', []);

    % Tab: Feature Matching
    featuresTab = uitab('Parent', tabGroup, ...
                       'Title', 'Feature Matching', ...
                       'Units', 'normalized', ...
                       'Tag', 'featuresTab');
    featuresAxes = axes('Parent', featuresTab, ...
         'Units', 'normalized', ...
         'Position', [0.05, 0.1, 0.9, 0.85], ...
         'Tag', 'featuresAxes', ...
         'XTick', [], 'YTick', []);
    fig.UserData.featuresAxes = featuresAxes; % Store handle in UserData

    % Tab: Statistics & Metrics
    statsTab = uitab('Parent', tabGroup, ...
                    'Title', 'Statistics & Metrics', ...
                    'Units', 'normalized', ...
                    'Tag', 'statsTab');
    
    % Axes for Histogram (top-left)
    histogramAxes = axes('Parent', statsTab, ...
         'Units', 'normalized', ...
         'Position', [0.07, 0.55, 0.40, 0.40], ...
         'Tag', 'histogramAxes');
    fig.UserData.histogramAxes = histogramAxes; % Store handle in UserData
    
    % Edit field for detailed statistics (bottom-left)
    uicontrol('Parent', statsTab, ...
              'Style', 'edit', ...
              'String', 'Detailed statistics will appear here after analysis...', ...
              'Units', 'normalized', ...
              'Position', [0.07, 0.05, 0.40, 0.30], ...
              'FontSize', 10, ...
              'Max', 40, ...
              'Tag', 'detailedStatsText');

    % Axes for Scatter Plot (right)
    scatterAxes = axes('Parent', statsTab, ...
         'Units', 'normalized', ...
         'Position', [0.52, 0.10, 0.45, 0.80], ...
         'Tag', 'scatterAxes');
    fig.UserData.scatterAxes = scatterAxes; % Store handle in UserData

end

function createStatusPanel(fig)
    % createStatusPanel - Creates the panel for status messages and system information.
    
    % Panel for status, logs, and system information
    statusPanel = uipanel('Parent', fig, ...
                         'Title', 'Status, Logs & System Information', ...
                         'Units', 'normalized', ...
                         'Position', [0.01, 0.01, 0.22, 0.32], ...
                         'FontSize', 11, ...
                         'FontWeight', 'bold');
    
    % Edit field to display status messages and instructions
    uicontrol('Parent', statusPanel, ...
              'Style', 'edit', ...
              'String', {['Computer Vision Challenge - Change Detection Ready!'], [''], ...
                        ['Instructions:'], ...
                        ['1. Select folder with satellite images (YYYY_MM.ext)'], ...
                        ['2. Load & process images'], ...
                        ['3. Navigate between image pairs'], ...
                        ['4. Align images for better comparison'], ...
                        ['5. Detect changes using CV algorithms'], ...
                        ['6. Choose visualization method'], ...
                        ['7. Apply visualization to see results'], [''], ...
                        ['Tip: Use images from same location, different times'], ...
                        ['Expected format: 2020_01.jpg, 2020_12.png, etc.']}, ...
              'Units', 'normalized', ...
              'Position', [0.03, 0.03, 0.94, 0.94], ...
              'FontSize', 9, ...
              'Max', 50, ...
              'Tag', 'statusArea', ...
              'HorizontalAlignment', 'left', ...
              'FontName', 'Courier New');
end

% CORE COMPUTER VISION FUNCTIONS

function selectImageFolder(fig)
    % selectImageFolder - Allows the user to select an image folder.
    
    % Opens a dialog for folder selection
    folder = uigetdir(pwd, 'Select folder with satellite images (YYYY_MM.ext format)');
    if folder ~= 0 % If a folder was selected
        fig.UserData.currentFolder = folder; % Store folder path
        
        clearAnalysisResults(fig); % Clear previous analysis results

        % Supported image extensions
        imageExtensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tiff', '*.tif'};
        allFiles = [];
        % Collect all image files in the folder
        for ext = imageExtensions
            files = dir(fullfile(folder, ext{1}));
            allFiles = [allFiles; files];
        end
        
        % Update status
        updateStatus(fig, {sprintf('Folder: %s', folder), ...
                          sprintf('Found %d images', length(allFiles))});
        
        % Enable "Load & Process" button
        set(findobj(fig, 'Tag', 'loadButton'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'statusIndicator'), 'String', ...
            sprintf('Ready: %d files found', length(allFiles)));
    end
end

function loadAndProcessImages(fig)
    % loadAndProcessImages - Loads images from the selected folder and optionally applies median filter.
    
    folder = fig.UserData.currentFolder;
    updateStatus(fig, {'Loading images...', ''});
    
    clearAnalysisResults(fig); % Clear previous analysis results

    % Supported image extensions
    imageExtensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tiff', '*.tif'};
    allFiles = [];
    % Collect all image files in the folder
    for ext = imageExtensions
        files = dir(fullfile(folder, ext{1}));
        allFiles = [allFiles; files];
    end
    
    % Check if enough images were found
    if length(allFiles) < 2
        updateStatus(fig, {sprintf('Need at least 2 images, found %d', length(allFiles))});
        return;
    end
    
    % Sort image files by name
    [~, sortIdx] = sort({allFiles.name});
    imageFiles = allFiles(sortIdx);
    
    loadedImages = {};
    % Query status of median filter checkbox
    medianFilterEnabled = get(findobj(fig, 'Tag', 'medianFilterCheckbox'), 'Value');

    % Load images and optionally apply median filter
    for i = 1:length(imageFiles)
        try
            imgPath = fullfile(folder, imageFiles(i).name);
            img = imread(imgPath);

            % Apply median filter if enabled
            if medianFilterEnabled
                if size(img, 3) == 3 % Color image
                    img = medfilt3(img); % Median filter for 3D data (color images)
                else % Grayscale image
                    img = medfilt2(img); % Median filter for 2D data (grayscale images)
                end
                updateStatus(fig, {sprintf('✓ Applied median filter to: %s', imageFiles(i).name)});
            end

            loadedImages{i} = img;
            updateStatus(fig, {sprintf('✓ Loaded: %s', imageFiles(i).name)});
        catch ME
            updateStatus(fig, {sprintf('Failed to load or process %s: %s', imageFiles(i).name, ME.message)});
        end
    end
    
    % Store loaded images and current image pair in UserData
    fig.UserData.images = imageFiles;
    fig.UserData.loadedImages = loadedImages;
    fig.UserData.currentImagePair = [1, min(2, length(loadedImages))];
    
    % Display image pair
    displayImagePair(fig);
    % Enable processing buttons
    enableProcessingButtons(fig, true);
    
    updateStatus(fig, {'Images loaded successfully!', ...
                      sprintf('Total: %d images ready for analysis', length(loadedImages))});

    % Enable the Timelaps button after processing
    timelapseBtn = findobj(fig, 'Tag', 'timelapseButton');
    if ~isempty(timelapseBtn)
        set(timelapseBtn, 'Enable', 'on');
    end
end

function displayImagePair(fig)
    % displayImagePair - Displays the currently selected image pair in the corresponding axes.
    
    loadedImages = fig.UserData.loadedImages;
    imageFiles = fig.UserData.images;
    currentPair = fig.UserData.currentImagePair;
    
    if isempty(loadedImages), return; end
    
    idx1 = currentPair(1);
    idx2 = currentPair(2);
    
    axes1 = fig.UserData.img1Axes;
    axes2 = fig.UserData.img2Axes;
    
    % Display Image 1
    if idx1 <= length(loadedImages)
        if ~isempty(axes1) && isgraphics(axes1, 'axes')
            cla(axes1); % Clear axes
            imshow(loadedImages{idx1}, 'Parent', axes1); % Display image
            title(axes1, sprintf('Image 1: %s', imageFiles(idx1).name), 'Interpreter', 'none'); % Set title
        else
            updateStatus(fig, {'Error: img1Axes handle is invalid or not found. Cannot display image 1.'});
        end
    end
    
    % Display Image 2
    if idx2 <= length(loadedImages)
        if ~isempty(axes2) && isgraphics(axes2, 'axes')
            cla(axes2); % Clear axes
            imshow(loadedImages{idx2}, 'Parent', axes2); % Display image
            title(axes2, sprintf('Image 2: %s', imageFiles(idx2).name), 'Interpreter', 'none'); % Set title
        else
            updateStatus(fig, {'Error: img2Axes handle is invalid or not found. Cannot display image 2.'});
        end
    end
    
    % Update current pair text
    set(findobj(fig, 'Tag', 'pairText'), 'String', sprintf('Current Pair: %d-%d', idx1, idx2));
    % Update navigation buttons
    updateNavigationButtons(fig);
    
    clearAnalysisResults(fig); % Clear analysis results as new pair is displayed
end

function alignCurrentImages(fig)
    % alignCurrentImages - Aligns the current image pair using SURF features.
    
    clearAnalysisResults(fig); % Clear previous analysis results

    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    hasCV = fig.UserData.hasCV;
    
    % Check if images are loaded and Computer Vision Toolbox is available
    if isempty(loadedImages) || ~hasCV, updateStatus(fig, {'Need loaded images and Computer Vision Toolbox'}); return; end
    
    updateStatus(fig, {'Aligning images using SURF features...'});
    
    try
        idx1 = currentPair(1);
        idx2 = currentPair(2);
        
        img1 = loadedImages{idx1};
        img2 = loadedImages{idx2};
        
        % Convert images to grayscale if they are color images
        if size(img1, 3) == 3, gray1 = rgb2gray(img1); else, gray1 = img1; end
        if size(img2, 3) == 3, gray2 = rgb2gray(img2); else, gray2 = img2; end
        
        % Detect SURF features. 'MetricThreshold' was lowered to find more features.
        points1 = detectSURFFeatures(gray1, 'MetricThreshold', 500); % Default is 1000
        points2 = detectSURFFeatures(gray2, 'MetricThreshold', 500); % Default is 1000
        
        % Extract features
        [features1, validPoints1] = extractFeatures(gray1, points1);
        [features2, validPoints2] = extractFeatures(gray2, points2);
        
        % Match features
        indexPairs = matchFeatures(features1, features2);
        matchedPoints1 = validPoints1(indexPairs(:, 1));
        matchedPoints2 = validPoints2(indexPairs(:, 2));
        
        % If enough matching points are found (at least 4 for similarity transform)
        if length(matchedPoints1) >= 4
            % Estimate geometric transformation (similarity transform)
            % 'MaxNumTrials' increased to allow more RANSAC attempts.
            % 'MaxDistance' increased to be more tolerant to noise.
            [tform, inlierIdx] = estimateGeometricTransform2D(...
                matchedPoints2, matchedPoints1, 'similarity', ...
                'MaxNumTrials', 2000, ... % Increased from default 1000
                'MaxDistance', 3); % Increased from default 1.5
            
            % Align Image 2 to Image 1
            alignedImg2 = imwarp(img2, tform, 'OutputView', imref2d(size(img1)));
            
            % Store aligned images and registration data
            fig.UserData.alignedImages = {img1, alignedImg2};
            fig.UserData.registrationData = struct(...
                'tform', tform, ...
                'matchedPoints1', matchedPoints1, ...
                'matchedPoints2', matchedPoints2, ...
                'inlierIdx', inlierIdx, ...
                'numMatches', length(matchedPoints1), ...
                'numInliers', sum(inlierIdx));
            
            % Display aligned image
            resultsAxes = fig.UserData.resultsAxes;
            if ~isempty(resultsAxes) && isgraphics(resultsAxes, 'axes')
                cla(resultsAxes);
                imshow(alignedImg2, 'Parent', resultsAxes);
                title(resultsAxes, 'Image 2 aligned to Image 1', 'Color', [0, 0.7, 0]);
            else
                updateStatus(fig, {'Error: resultsAxes handle is invalid or not found. Cannot display aligned image.'});
            end
            
            % Update feature information in the text field
            featuresText = findobj(fig, 'Tag', 'featuresText');
            featureInfo = {
                sprintf('SURF Features Detected:');
                sprintf('  Image 1: %d features', length(points1));
                sprintf('  Image 2: %d features', length(points2));
                sprintf('Feature Matches: %d', length(matchedPoints1));
                sprintf('Inliers: %d (%.1f%%)', sum(inlierIdx), 100*sum(inlierIdx)/length(inlierIdx));
                sprintf('Alignment: SUCCESS');
            };
            set(featuresText, 'String', featureInfo);
            
            % Display feature matching visualization
            displayFeatureMatching(fig);
            
            % Enable "Detect Changes" button
            set(findobj(fig, 'Tag', 'detectButton'), 'Enable', 'on');
            
            updateStatus(fig, {'Image alignment completed!', ...
                              sprintf(' %d features matched, %d inliers', ...
                                     length(matchedPoints1), sum(inlierIdx))});
        else
            updateStatus(fig, {'Insufficient feature matches for alignment'});
        end
        
    catch ME
        updateStatus(fig, {sprintf('Alignment failed: %s', ME.message)});
    end
end

function displayFeatureMatching(fig)
    % displayFeatureMatching - Displays the matched features between the images.
    
    regData = fig.UserData.registrationData;
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    
    if isempty(regData), return; end
    
    img1 = loadedImages{currentPair(1)};
    img2 = loadedImages{currentPair(2)};
    
    featuresAxes = fig.UserData.featuresAxes; % Use axes handle
    axes(featuresAxes); cla; % Clear axes
    
    % Display matched features (inliers only)
    showMatchedFeatures(img1, img2, ...
                       regData.matchedPoints1(regData.inlierIdx), ...
                       regData.matchedPoints2(regData.inlierIdx), ...
                       'montage'); % Display images side-by-side
    title(sprintf('Feature Matching: %d inliers of %d matches', ...
          regData.numInliers, regData.numMatches)); % Set title
    drawnow;
end

function detectChanges(fig)
    % detectChanges - Performs change detection between the aligned images.
    
    alignedImages = fig.UserData.alignedImages;
    hasIP = fig.UserData.hasIP;
    
    if isempty(alignedImages), updateStatus(fig, {'Please align images first'}); return; end
    
    updateStatus(fig, {'Detecting changes...'});
    
    try
        img1 = alignedImages{1};
        img2 = alignedImages{2};
        
        % Convert images to grayscale
        if size(img1, 3) == 3
            img1_gray = rgb2gray(img1);
            img2_gray = rgb2gray(img2);
        else
            img1_gray = img1;
            img2_gray = img2;
        end
        
        % Convert images to double format for calculations
        img1_double = double(img1_gray);
        img2_double = double(img2_gray);
        
        % Calculate absolute pixel difference image
        diffImg = abs(img2_double - img1_double);
        
        % Apply Gaussian filter if Image Processing Toolbox is available
        if hasIP
            diffImg = imgaussfilt(diffImg, 1.5);
        end
        
        % Threshold for change detection
        threshold = 30;
        changeMask = diffImg > threshold; % Binary mask of changes
        
        % Calculate change statistics
        totalPixels = numel(changeMask);
        changedPixels = sum(changeMask(:));
        changePercentage = (changedPixels / totalPixels) * 100;
        
        % Store change data
        fig.UserData.changeData = struct(...
            'diffImg', diffImg, ...
            'changeMask', changeMask, ...
            'changePercentage', changePercentage, ...
            'threshold', threshold, ...
            'totalPixels', totalPixels, ...
            'changedPixels', changedPixels, ...
            'img1_gray', img1_gray, ...
            'img2_gray', img2_gray);
        
        % Update statistics text field
        statsText = findobj(fig, 'Tag', 'statsText');
        statsInfo = {
            sprintf('Change Detection Results:');
            sprintf('  Total pixels: %d', totalPixels);
            sprintf('  Changed pixels: %d', changedPixels);
            sprintf('  Change percentage: %.2f%%', changePercentage);
            sprintf('  Threshold used: %d', threshold);
            sprintf('  Status: COMPLETED');
        };
        set(statsText, 'String', statsInfo);
        
        % Enable visualization and report buttons
        set(findobj(fig, 'Tag', 'applyVizButton'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'saveButtonAligned'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'reportButtonAligned'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'reportButtonStats'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'saveButtonStats'), 'Enable', 'on');
        
        updateStatus(fig, {'Change detection completed!', ...
                          sprintf(' %.2f%% of image area changed', changePercentage)});
        drawnow;
                      
    catch ME
        updateStatus(fig, {sprintf('Change detection failed: %s', ME.message)});
    end
end

%% HELPER FUNCTIONS
function navigateImagePair(fig, direction)
    % navigateImagePair - Navigates between image pairs (not used in GUI, but as an example)
    
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    
    if isempty(loadedImages) || length(loadedImages) < 2, return; end
    
    newIdx1 = currentPair(1) + direction;
    newIdx2 = currentPair(2) + direction;
    
    if newIdx1 < 1 || newIdx2 > length(loadedImages), return; end
    
    fig.UserData.currentImagePair = [newIdx1, newIdx2];
    displayImagePair(fig);
end

function navigateSingleImage(fig, direction, imageIndex)
    % navigateSingleImage - Navigates a single image forward or backward.
    
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;

    if isempty(loadedImages), return; end

    % Navigate Image 1
    if imageIndex == 1
        newIdx = currentPair(1) + direction;
        if newIdx < 1, newIdx = length(loadedImages); end % Wrap around
        if newIdx > length(loadedImages), newIdx = 1; end % Wrap around
        fig.UserData.currentImagePair(1) = newIdx;
    % Navigate Image 2
    elseif imageIndex == 2
        newIdx = currentPair(2) + direction;
        if newIdx < 1, newIdx = length(loadedImages); end % Wrap around
        if newIdx > length(loadedImages), newIdx = 1; end % Wrap around
        fig.UserData.currentImagePair(2) = newIdx;
    end
    
    displayImagePair(fig);
end

function updateNavigationButtons(fig)
    % updateNavigationButtons - Updates the enabled state of the navigation buttons.
    
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    numImgs = length(loadedImages);
    
    % Buttons for pair navigation (not used in this GUI, but present in code)
    prevPairBtn = findobj(fig, 'Tag', 'prevButton');
    nextPairBtn = findobj(fig, 'Tag', 'nextButton');
    
    if ~isempty(prevPairBtn)
        if currentPair(1) <= 1, set(prevPairBtn, 'Enable', 'off');
        else, set(prevPairBtn, 'Enable', 'on'); end
    end
    
    if ~isempty(nextPairBtn)
        if currentPair(2) >= numImgs, set(nextPairBtn, 'Enable', 'off');
        else, set(nextPairBtn, 'Enable', 'on'); end
    end

    % Buttons for single image navigation
    prev1Btn = findobj(fig, 'Tag', 'prev1Button');
    next1Btn = findobj(fig, 'Tag', 'next1Button');

    if numImgs > 0
        if ~isempty(prev1Btn), set(prev1Btn, 'Enable', 'on'); end
        if ~isempty(next1Btn), set(next1Btn, 'Enable', 'on'); end
    else
        if ~isempty(prev1Btn), set(prev1Btn, 'Enable', 'off'); end
        if ~isempty(next1Btn), set(next1Btn, 'Enable', 'off'); end
    end

    prev2Btn = findobj(fig, 'Tag', 'prev2Button');
    next2Btn = findobj(fig, 'Tag', 'next2Button');

    if numImgs > 0
        if ~isempty(prev2Btn), set(prev2Btn, 'Enable', 'on'); end
        if ~isempty(next2Btn), set(next2Btn, 'Enable', 'on'); end
    else
        if ~isempty(prev2Btn), set(prev2Btn, 'Enable', 'off'); end
        if ~isempty(next2Btn), set(next2Btn, 'Enable', 'off'); end
    end
end

function enableProcessingButtons(fig, enable)
    % enableProcessingButtons - Enables or disables processing buttons.
    
    buttons = {'alignButton', 'detectButton'};
    enableStr = 'off'; if enable, enableStr = 'on'; end
    
    % Main processing buttons
    for i = 1:length(buttons)
        btn = findobj(fig, 'Tag', buttons{i});
        if ~isempty(btn), set(btn, 'Enable', enableStr); end
    end
    
    % Save and report buttons
    saveBtnAligned = findobj(fig, 'Tag', 'saveButtonAligned');
    reportBtnAligned = findobj(fig, 'Tag', 'reportButtonAligned');
    saveBtnStats = findobj(fig, 'Tag', 'saveButtonStats');
    reportBtnStats = findobj(fig, 'Tag', 'reportButtonStats');

    if ~isempty(saveBtnAligned), set(saveBtnAligned, 'Enable', enableStr); end
    if ~isempty(reportBtnAligned), set(reportBtnAligned, 'Enable', enableStr); end
    if ~isempty(saveBtnStats), set(saveBtnStats, 'Enable', enableStr); end
    if ~isempty(reportBtnStats), set(reportBtnStats, 'Enable', enableStr); end
end

function clearAnalysisResults(fig)
    % clearAnalysisResults - Clears all analysis results, plots, and text areas.
    
    % Reset user data related to analysis
    fig.UserData.alignedImages = {};
    fig.UserData.registrationData = [];
    fig.UserData.changeData = [];
    
    % Retrieve handles for all relevant axes and text areas
    resultsAxes = fig.UserData.resultsAxes;
    featuresAxes = fig.UserData.featuresAxes; 
    histogramAxes = fig.UserData.histogramAxes; 
    scatterAxes = fig.UserData.scatterAxes;     
    vizAxes = fig.UserData.vizAxes;
    changeMapAxes = fig.UserData.changeMapAxes; 
    
    detailedStatsText = findobj(fig, 'Tag', 'detailedStatsText');
    statsText = findobj(fig, 'Tag', 'statsText');
    featuresText = findobj(fig, 'Tag', 'featuresText');

    % Clear axes in "Aligned Image" tab
    if ~isempty(resultsAxes) && isgraphics(resultsAxes, 'axes')
        cla(resultsAxes);
        text(resultsAxes, 0.5, 0.5, 'Aligned image will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow;
    end

    % Clear axes in "Feature Matching" tab
    if ~isempty(featuresAxes) && isgraphics(featuresAxes, 'axes')
        cla(featuresAxes);
        text(featuresAxes, 0.5, 0.5, 'Feature matches will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow;
    end
    
    % Clear axes in "Statistics & Metrics" tab
    if ~isempty(histogramAxes) && isgraphics(histogramAxes, 'axes')
        cla(histogramAxes);
        text(histogramAxes, 0.5, 0.5, 'Histogram will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow;
    end

    if ~isempty(scatterAxes) && isgraphics(scatterAxes, 'axes')
        cla(scatterAxes);
        text(scatterAxes, 0.5, 0.5, 'Scatter plot will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow;
    end

    % Clear axes in "Visualization" tab
    if ~isempty(vizAxes) && isgraphics(vizAxes, 'axes')
        cla(vizAxes);
        text(vizAxes, 0.5, 0.5, 'Visualization will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow;
    end

    % Clear axes in "Change Map" tab
    if ~isempty(changeMapAxes) && isgraphics(changeMapAxes, 'axes')
        cla(changeMapAxes);
        text(changeMapAxes, 0.5, 0.5, 'Change map will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow;
    end

    % Reset text areas
    if ~isempty(detailedStatsText) && isgraphics(detailedStatsText, 'uicontrol')
        set(detailedStatsText, 'String', '');
        set(detailedStatsText, 'String', 'Detailed statistics will appear here after analysis...');
        drawnow;
    end
    if ~isempty(featuresText) && isgraphics(featuresText, 'uicontrol')
        set(featuresText, 'String', 'Load images and align for analysis');
        drawnow;
    end
    if ~isempty(statsText) && isgraphics(statsText, 'uicontrol')
        set(statsText, 'String', 'No analysis performed yet');
        drawnow;
    end

    % Disable relevant buttons
    set(findobj(fig, 'Tag', 'applyVizButton'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'saveButtonAligned'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'reportButtonAligned'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'saveButtonStats'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'reportButtonStats'), 'Enable', 'off');
    
    drawnow;
end


function updateVisualization(fig)
    % updateVisualization - Updates the displayed value of the sensitivity slider.
    
    slider = findobj(fig, 'Tag', 'sensitivitySlider');
    text = findobj(fig, 'Tag', 'sensitivityText');
    
    if ~isempty(slider) && ~isempty(text)
        set(text, 'String', sprintf('%.1f', get(slider, 'Value')));
    end
end

function applyVisualization(fig)
    % applyVisualization - Applies the selected visualization method to the change data.
    
    changeData = fig.UserData.changeData;
    alignedImages = fig.UserData.alignedImages;
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;

    % Check if data for visualization is available
    if isempty(changeData) || isempty(alignedImages)
        updateStatus(fig, {'Please align images and detect changes first to apply visualization.'});
        return;
    end

    % Retrieve selected visualization type
    vizGroup = findobj(fig, 'Tag', 'vizGroup');
    selectedVizType = get(get(vizGroup, 'SelectedObject'), 'Tag');
    
    % Retrieve selected change type
    changeTypeDropdown = findobj(fig, 'Tag', 'changeTypeDropdown');
    selectedChangeTypeIdx = get(changeTypeDropdown, 'Value');
    changeTypes = get(changeTypeDropdown, 'String');
    selectedChangeType = changeTypes{selectedChangeTypeIdx};

    % Retrieve sensitivity value
    sensitivitySlider = findobj(fig, 'Tag', 'sensitivitySlider');
    sensitivity = get(sensitivitySlider, 'Value');

    vizAxes = fig.UserData.vizAxes;
    analysisTabGroup = findobj(fig, 'Tag', 'analysisTabGroup');
    vizTab = findobj(analysisTabGroup, 'Tag', 'vizTab');

    % Switch to the Visualization tab
    set(analysisTabGroup, 'SelectedTab', vizTab);
    drawnow;

    updateStatus(fig, {sprintf('🎨 Applying %s visualization...', selectedVizType)});

    try
        % Get filtered change data based on type and sensitivity
        [processedDiffImg, processedChangeMask] = getFilteredChangeData(...
            changeData.diffImg, changeData.changeMask, ...
            changeData.img1_gray, changeData.img2_gray, ...
            sensitivity, selectedChangeType);

        % Display visualization based on the selected type
        switch selectedVizType
            case 'heatmapRadio'
                displayDifferenceHeatmap(fig, processedDiffImg, changeData.changePercentage, sensitivity, selectedChangeType);
            case 'overlayRadio'
                displaySideBySideOverlay(fig, loadedImages{currentPair(1)}, alignedImages{2}, processedChangeMask, sensitivity, selectedChangeType);
            case 'highlightRadio'
                displayChangeHighlights(fig, alignedImages{2}, processedChangeMask, sensitivity, selectedChangeType);
            otherwise
                updateStatus(fig, {'⚠️ Unknown visualization type selected.'});
        end
        updateStatus(fig, {'Visualization applied successfully!'});
    catch ME
        updateStatus(fig, {sprintf('Visualization failed: %s', ME.message)});
    end
end

function [finalDiffImgForHeatmap, finalChangeMaskForOverlay] = getFilteredChangeData(diffImg, originalChangeMask, img1_gray, img2_gray, sensitivity, changeType)
    % getFilteredChangeData - Filters and prepares change data based on type and sensitivity.
    
    finalDiffImgForHeatmap = diffImg;
    finalChangeMaskForOverlay = originalChangeMask;

    baseThreshold = 30; % Base threshold for difference images
    currentThreshold = baseThreshold / sensitivity; % Adjust threshold based on sensitivity

    switch changeType
        case 'All Changes'
            % All changes: Directly scale difference image and apply mask
            finalDiffImgForHeatmap = diffImg * sensitivity;
            finalChangeMaskForOverlay = diffImg > currentThreshold;
            
        case 'Geometric Changes (Size/Shape)'
            % Geometric changes: Apply morphological operations to mask
            tempMask = diffImg > currentThreshold;
            minArea = round(numel(tempMask) * 0.0001); 
            if minArea < 1, minArea = 1; end
            filteredMask = bwareaopen(tempMask, minArea); % Remove small objects
            
            filteredMask = imclose(filteredMask, strel('disk', 3)); % Close gaps
            filteredMask = imopen(filteredMask, strel('disk', 2)); % Remove small outliers

            finalChangeMaskForOverlay = filteredMask;
            finalDiffImgForHeatmap = double(filteredMask) * 255;
            finalDiffImgForHeatmap = finalDiffImgForHeatmap * sensitivity;
            
        case 'Intensity Changes (Brightness)'
            % Intensity changes: Same as "All Changes", as brightness changes are directly in diffImg
            finalDiffImgForHeatmap = diffImg * sensitivity;
            finalChangeMaskForOverlay = diffImg > currentThreshold;
            
        case 'Structural Changes (Texture)'
            % Structural changes: Based on texture differences (standard deviation)
            img1_double = im2double(img1_gray);
            img2_double = im2double(img2_gray);

            % Apply standard deviation filter to measure texture
            stdDev1 = stdfilt(img1_double, ones(7));
            stdDev2 = stdfilt(img2_double, ones(7));

            textureDiff = abs(stdDev2 - stdDev1); % Difference of texture measures
            
            textureDiff = mat2gray(textureDiff); % Normalize to 0-1 range

            textureThresholdBase = 0.1; 
            textureThreshold = textureThresholdBase / sensitivity; 
            textureThreshold = min(max(textureThreshold, 0.01), 0.5); % Threshold for texture

            filteredMask = textureDiff > textureThreshold; % Mask based on texture
            
            filteredMask = bwareaopen(filteredMask, round(numel(filteredMask) * 0.00005)); % Remove small objects
            filteredMask = imclose(filteredMask, strel('disk', 1)); % Close gaps

            finalChangeMaskForOverlay = filteredMask;
            finalDiffImgForHeatmap = textureDiff * sensitivity;
    end
end

function displayDifferenceHeatmap(fig, processedDiffImg, changePercentage, sensitivity, changeType)
    % displayDifferenceHeatmap - Displays a heatmap of pixel differences.
    
    vizAxes = fig.UserData.vizAxes;
    cla(vizAxes); % Clear axes
    
    displayImg = mat2gray(processedDiffImg); % Normalize image for display

    imshow(displayImg, 'Parent', vizAxes, 'Colormap', jet(256)); % Heatmap with Jet colormap
    colorbar(vizAxes); % Add color bar
    title(vizAxes, sprintf('Difference Heatmap (Changes: %.2f%%, Type: %s, Sens: %.1f)', changePercentage, changeType, sensitivity));
    drawnow;
end

function displaySideBySideOverlay(fig, img1, alignedImg2, processedChangeMask, sensitivity, changeType)
    % displaySideBySideOverlay - Displays an overlay of the aligned image with a colored mask.
    
    vizAxes = fig.UserData.vizAxes;
    cla(vizAxes); % Clear axes

    alpha = 0.5 * sensitivity; % Adjust transparency based on sensitivity
    alpha = min(max(alpha, 0.1), 0.8); % Limit alpha value

    img1_double = im2double(img1); % Convert images to double format
    alignedImg2_double = im2double(alignedImg2);

    highlightColor = [1 0 0]; % Highlight color (Red)
    
    % Create colored mask
    coloredMask = cat(3, highlightColor(1)*processedChangeMask, highlightColor(2)*processedChangeMask, highlightColor(3)*processedChangeMask);
    
    % Create overlay image
    overlayImg = (1 - alpha) * alignedImg2_double + alpha * coloredMask;
    overlayImg = im2uint8(overlayImg); % Convert to uint8 for display

    imshow(overlayImg, 'Parent', vizAxes); % Display overlay image
    title(vizAxes, sprintf('Side-by-Side Overlay (Type: %s, Sens: %.1f)', changeType, sensitivity));
    drawnow;
end

function displayChangeHighlights(fig, alignedImg2, processedChangeMask, sensitivity, changeType)
    % displayChangeHighlights - Highlights changes in the aligned image.
    
    vizAxes = fig.UserData.vizAxes;
    cla(vizAxes); % Clear axes

    % Convert image to grayscale if color image
    if size(alignedImg2, 3) == 3
        alignedImg2_gray = rgb2gray(alignedImg2);
    else
        alignedImg2_gray = alignedImg2;
    end
    
    % Duplicate grayscale image into 3 channels to add color
    highlightedImg = cat(3, alignedImg2_gray, alignedImg2_gray, alignedImg2_gray);
    
    highlightIntensity = 100 * sensitivity; % Adjust highlight intensity based on sensitivity
    highlightIntensity = min(max(highlightIntensity, 50), 200); % Limit intensity

    highlightColor = [255, 0, 255]; % Highlight color (Magenta)
    
    % Apply colored highlight to masked areas
    for c = 1:3
        channel = double(highlightedImg(:,:,c));
        channel(processedChangeMask) = min(255, channel(processedChangeMask) + highlightColor(c) * (highlightIntensity/255));
        highlightedImg(:,:,c) = uint8(channel);
    end

    imshow(highlightedImg, 'Parent', vizAxes); % Display highlighted image
    title(vizAxes, sprintf('Change Highlights (Type: %s, Sens: %.1f)', changeType, sensitivity));
    drawnow;
end

function generateReport(fig)
    % generateReport - Generates a detailed report with statistics and plots.
    
    updateStatus(fig, {'Generating detailed report...'});

    changeData = fig.UserData.changeData;
    registrationData = fig.UserData.registrationData;
    
    % Check if data for the report is available
    if isempty(changeData) || isempty(registrationData)
        updateStatus(fig, {'Cannot generate report: Please perform alignment and change detection first.'});
        return;
    end

    analysisTabGroup = findobj(fig, 'Tag', 'analysisTabGroup');
    statsTab = findobj(analysisTabGroup, 'Tag', 'statsTab');
    histogramAxes = fig.UserData.histogramAxes; % Use axes handle
    scatterAxes = fig.UserData.scatterAxes;     % Use axes handle
    detailedStatsText = findobj(statsTab, 'Tag', 'detailedStatsText');

    % Switch to the Statistics tab
    set(analysisTabGroup, 'SelectedTab', statsTab);
    drawnow;
    
    % Clear the detailed statistics text area
    set(detailedStatsText, 'String', ''); 

    % Draw histogram of pixel differences
    if ~isempty(histogramAxes) && isgraphics(histogramAxes, 'axes')
        cla(histogramAxes); % Clear axes
        diffImgFlat = changeData.diffImg(:); % Flatten difference image
        histogram(histogramAxes, diffImgFlat, 50); % Create histogram
        title(histogramAxes, 'Histogram of Pixel Differences');
        xlabel(histogramAxes, 'Pixel Difference Intensity');
        ylabel(histogramAxes, 'Frequency');
        grid(histogramAxes, 'on');
    else
        updateStatus(fig, {'Error: histogramAxes handle is invalid or not found.'});
    end

    % Draw scatter plot of pixel intensity comparison
    if ~isempty(scatterAxes) && isgraphics(scatterAxes, 'axes')
        cla(scatterAxes); % Clear axes
        img1_gray_flat = double(changeData.img1_gray(:)); % Flatten Image 1
        img2_gray_aligned_flat = double(changeData.img2_gray(:)); % Flatten Aligned Image 2
        scatter(scatterAxes, img1_gray_flat, img2_gray_aligned_flat, 1, '.'); % Create scatter plot
        hold(scatterAxes, 'on');
        refline(scatterAxes, 1, 0); % Add reference line (x=y)
        hold(scatterAxes, 'off');
        title(scatterAxes, 'Pixel Intensity Comparison (Image 1 vs Aligned Image 2)');
        xlabel(scatterAxes, 'Image 1 Pixel Intensity');
        ylabel(scatterAxes, 'Aligned Image 2 Pixel Intensity');
        grid(scatterAxes, 'on');
        axis(scatterAxes, 'tight');
        axis(scatterAxes, 'square');
    else
        updateStatus(fig, {'Error: scatterAxes handle is invalid or not found.'});
    end

    % Update detailed statistics text
    if ~isempty(detailedStatsText) && isgraphics(detailedStatsText, 'uicontrol')
        reportText = {
            '--- Detailed Change Analysis Report ---';
            '';
            sprintf('Date Generated: %s', datestr(now));
            '';
            'Image Information:';
            sprintf('  Image 1: %s', fig.UserData.images(fig.UserData.currentImagePair(1)).name);
            sprintf('  Image 2: %s (aligned)', fig.UserData.images(fig.UserData.currentImagePair(2)).name);
            sprintf('  Image Size: %d x %d pixels', size(changeData.img1_gray, 2), size(changeData.img1_gray, 1));
            '';
            'Alignment Statistics:';
            sprintf('  Features Detected (Img1): %d', length(registrationData.matchedPoints1));
            sprintf('  Features Detected (Img2): %d', length(registrationData.matchedPoints2));
            sprintf('  Matched Features: %d', registrationData.numMatches);
            sprintf('  Inlier Matches: %d (%.1f%%)', registrationData.numInliers, 100*registrationData.numInliers/registrationData.numMatches);
            '';
            'Change Detection Statistics:';
            sprintf('  Total Pixels Analyzed: %d', changeData.totalPixels);
            sprintf('  Changed Pixels (initial threshold): %d', changeData.changedPixels);
            sprintf('  Percentage Changed (initial threshold): %.2f%%', changeData.changePercentage);
            sprintf('  Initial Threshold Used: %d', changeData.threshold);
            sprintf('  Mean Absolute Pixel Difference: %.2f', mean(changeData.diffImg(:)));
            sprintf('  Max Absolute Pixel Difference: %.2f', max(changeData.diffImg(:)));
            '';
            'Note: "Change Type Focus" and "Sensitivity" are applied to visualizations, not reflected in raw statistics.';
        };
        set(detailedStatsText, 'String', reportText);
    else
        updateStatus(fig, {'Error: detailedStatsText handle is invalid or not found.'});
    end

    updateStatus(fig, {'Detailed report generated and displayed in "Statistics & Metrics" tab!'});
end

function saveResults(fig)
    % saveResults - Saves the analysis results and plots as a PDF report.
    
    updateStatus(fig, {'Generating PDF report...'});

    changeData = fig.UserData.changeData;
    registrationData = fig.UserData.registrationData;
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    
    % Check if all necessary data for the report is available
    if isempty(changeData) || isempty(registrationData) || isempty(loadedImages)
        updateStatus(fig, {'Cannot save report: Please perform alignment and change detection first.'});
        return;
    end

    outputFileName = 'ChangeDetectionReport.pdf';
    
    % --- Create temporary figures for each element and save to PDF ---
    
    % 1. Aligned Image
    % Check if axes handle is valid and has content
    if isgraphics(fig.UserData.resultsAxes, 'axes') && ~isempty(get(fig.UserData.resultsAxes, 'Children'))
        hFigAligned = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 800 600]); % Invisible figure
        hAxesAligned = copyobj(fig.UserData.resultsAxes, hFigAligned); % Copy axes
        set(hAxesAligned, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]); % Adjust position
        title(hAxesAligned, get(get(fig.UserData.resultsAxes, 'Title'), 'String')); % Copy title
        exportgraphics(hFigAligned, outputFileName); % Export to PDF (first page)
        close(hFigAligned); % Close temporary figure
    else
        updateStatus(fig, {'⚠️ Aligned Image not available for report.'});
    end

    % 2. Feature Matching Plot
    if isgraphics(fig.UserData.featuresAxes, 'axes') && ~isempty(get(fig.UserData.featuresAxes, 'Children'))
        hFigFeatures = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 800 600]);
        hAxesFeatures = copyobj(fig.UserData.featuresAxes, hFigFeatures);
        set(hAxesFeatures, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        title(hAxesFeatures, get(get(fig.UserData.featuresAxes, 'Title'), 'String'));
        exportgraphics(hFigFeatures, outputFileName, 'Append', true); % Append to PDF
        close(hFigFeatures);
    else
        updateStatus(fig, {'⚠️ Feature Matching Plot not available for report.'});
    end

    % 3. Current Visualization Plot
    if isgraphics(fig.UserData.vizAxes, 'axes') && ~isempty(get(fig.UserData.vizAxes, 'Children'))
        hFigViz = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 800 600]);
        hAxesViz = copyobj(fig.UserData.vizAxes, hFigViz);
        set(hAxesViz, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        title(hAxesViz, get(get(fig.UserData.vizAxes, 'Title'), 'String'));
        exportgraphics(hFigViz, outputFileName, 'Append', true);
        close(hFigViz);
    else
        updateStatus(fig, {'⚠️ Visualization Plot not available for report.'});
    end

    % 4. Histogram of Pixel Differences
    if isgraphics(fig.UserData.histogramAxes, 'axes') && ~isempty(get(fig.UserData.histogramAxes, 'Children'))
        hFigHist = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 800 600]);
        hAxesHist = copyobj(fig.UserData.histogramAxes, hFigHist);
        set(hAxesHist, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        title(hAxesHist, get(get(fig.UserData.histogramAxes, 'Title'), 'String'));
        xlabel(hAxesHist, get(get(fig.UserData.histogramAxes, 'XLabel'), 'String'));
        ylabel(hAxesHist, get(get(fig.UserData.histogramAxes, 'YLabel'), 'String'));
        exportgraphics(hFigHist, outputFileName, 'Append', true);
        close(hFigHist);
    else
        updateStatus(fig, {'⚠️ Histogram Plot not available for report.'});
    end

    % 5. Scatter Plot of Pixel Intensity Comparison
    if isgraphics(fig.UserData.scatterAxes, 'axes') && ~isempty(get(fig.UserData.scatterAxes, 'Children'))
        hFigScatter = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 800 600]);
        hAxesScatter = copyobj(fig.UserData.scatterAxes, hFigScatter);
        set(hAxesScatter, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
        title(hAxesScatter, get(get(fig.UserData.scatterAxes, 'Title'), 'String'));
        xlabel(hAxesScatter, get(get(fig.UserData.scatterAxes, 'XLabel'), 'String'));
        ylabel(hAxesScatter, get(get(fig.UserData.scatterAxes, 'YLabel'), 'String'));
        exportgraphics(hFigScatter, outputFileName, 'Append', true);
        close(hFigScatter);
    else
        updateStatus(fig, {'⚠️ Scatter Plot not available for report.'});
    end

    % 6. Detailed Statistics Text
    detailedStatsTextControl = findobj(fig, 'Tag', 'detailedStatsText');
    if ~isempty(detailedStatsTextControl) && isgraphics(detailedStatsTextControl, 'uicontrol')
        reportTextContent = get(detailedStatsTextControl, 'String');
        
        hFigText = figure('Visible', 'off', 'Units', 'pixels', 'Position', [100 100 800 600]);
        hAxesText = axes('Parent', hFigText, 'Units', 'normalized', 'Position', [0 0 1 1], 'Visible', 'off');
        text(hAxesText, 0.05, 0.95, reportTextContent, ...
             'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
             'FontSize', 10, 'Interpreter', 'none');
        title(hAxesText, 'Detailed Analysis Report');
        exportgraphics(hFigText, outputFileName, 'Append', true);
        close(hFigText);
    else
        updateStatus(fig, {'⚠️ Detailed Statistics Text not available for report.'});
    end

    updateStatus(fig, {sprintf('Report saved to: %s', outputFileName)});
end

function updateStatus(fig, messages)
    % updateStatus - Updates the status area in the GUI with new messages.
    
    statusArea = findobj(fig, 'Tag', 'statusArea');
    currentTime = datestr(now, 'HH:MM:SS'); % Current time for timestamp
    
    if ~iscell(messages), messages = {messages}; end % Ensure messages are a cell array
    if size(messages, 1) == 1 && size(messages, 2) > 1, messages = messages'; end % Convert to column vector
    
    % Add timestamp to the first message
    timestampedMessages = cell(length(messages), 1);
    timestampedMessages{1} = sprintf('[%s] %s', currentTime, messages{1});
    if length(messages) > 1
        for i = 2:length(messages)
            timestampedMessages{i} = messages{i};
        end
    end
    
    % Get current content of the status area
    currentContent = get(statusArea, 'String');
    if ischar(currentContent), currentContent = {currentContent}; end % If it's just one line
    if ~isempty(currentContent) && size(currentContent, 1) == 1 && size(currentContent, 2) > 1, currentContent = currentContent'; end
    
    % Add new messages to existing content
    if isempty(currentContent)
        newContent = timestampedMessages;
    else
        newContent = [timestampedMessages; {''}; currentContent]; % Empty line for better readability
    end
    
    % Limit content to maximum number of lines
    if length(newContent) > 50, newContent = newContent(1:50); end
    set(statusArea, 'String', newContent); % Update status area
end

function updateFontSizes(fig)
    % updateFontSizes - Dynamically adjusts the font sizes of all GUI elements to the window size.
    
    referenceHeight = 1000; % Reference height for scaling
    fPos = get(fig, 'Position'); % Current position and size of the figure
    currentHeight = fPos(4); % Current height
    scalingFactor = currentHeight / referenceHeight; % Scaling factor
    
    % Base font sizes for various UI elements
    baseFontSizes = struct(...
        'uipanel', 11, ...
        'pushbutton', 10, ...
        'text', 9, ...
        'edit', 8, ...
        'radiobutton', 9, ...
        'popupmenu', 9, ...
        'sliderText', 8 ...
    );

    % Find all UI controls and adjust font size
    allControls = findall(fig, 'Type', 'uicontrol');
    for i = 1:length(allControls)
        control = allControls(i);
        style = get(control, 'Style');
        tag = get(control, 'Tag');

        currentBaseFontSize = -1;

        switch style
            case {'pushbutton'}
                currentBaseFontSize = baseFontSizes.pushbutton;
            case {'text'}
                if strcmp(tag, 'statusIndicator') || strcmp(tag, 'pairText')
                    currentBaseFontSize = baseFontSizes.edit; % Special size for status/pair text
                else
                    currentBaseFontSize = baseFontSizes.text;
                end
            case {'edit'}
                currentBaseFontSize = baseFontSizes.edit;
            case {'radiobutton'}
                currentBaseFontSize = baseFontSizes.radiobutton;
            case {'popupmenu'}
                currentBaseFontSize = baseFontSizes.popupmenu;
        end
        
        % Special handling for uipanel titles
        if strcmp(get(control, 'Type'), 'uipanel')
            currentBaseFontSize = baseFontSizes.uipanel;
        end

        % Apply scaled font size (with minimum size)
        if currentBaseFontSize ~= -1
            newFontSize = max(6, round(currentBaseFontSize * scalingFactor)); % Minimum size 6
            set(control, 'FontSize', newFontSize);
        end
    end
    
    % Update axes titles and labels
    allAxes = findall(fig, 'Type', 'axes');
    for i = 1:length(allAxes)
        ax = allAxes(i);
        
        % Update title font size
        titleHandle = get(ax, 'Title');
        if ~isempty(titleHandle) && isgraphics(titleHandle)
            baseTitleFontSize = 10;
            newTitleFontSize = max(8, round(baseTitleFontSize * scalingFactor)); % Minimum size 8
            set(titleHandle, 'FontSize', newTitleFontSize);
        end

        % Update XLabel font size
        xlabelHandle = get(ax, 'XLabel');
        if ~isempty(xlabelHandle) && isgraphics(xlabelHandle)
            baseLabelFontSize = 9;
            newLabelFontSize = max(7, round(baseLabelFontSize * scalingFactor)); % Minimum size 7
            set(xlabelHandle, 'FontSize', newLabelFontSize);
        end

        % Update YLabel font size
        ylabelHandle = get(ax, 'YLabel');
        if ~isempty(ylabelHandle) && isgraphics(ylabelHandle)
            baseLabelFontSize = 9;
            newLabelFontSize = max(7, round(baseLabelFontSize * scalingFactor)); % Minimum size 7
            set(ylabelHandle, 'FontSize', newLabelFontSize);
        end
    end
end

function timelapseCallback(fig)
    imgs = fig.UserData.loadedImages;

    if isempty(imgs)
        errordlg('Load a folder first!', 'Error');
        return;
    end

    [file, path] = uiputfile('timelapse_aligned.mp4', 'Save Video As');
    if isequal(file, 0)
        return;
    end
    videoName = fullfile(path, file);

    hWait = waitbar(0, 'Initializing timelapse...', 'Name', 'Aligning Images', ...
        'CreateCancelBtn', @(src, ~) setappdata(hWait, 'canceling', true));
    setappdata(hWait, 'canceling', false);

    refImg = imgs{1};
    ref_gray = im2single(im2gray(refImg));
    Rfixed = imref2d(size(ref_gray));

    alignedImgs = cell(size(imgs));
    alignedImgs{1} = refImg;
    last_tform = affine2d(eye(3));

    for k = 2:numel(imgs)
        if getappdata(hWait, 'canceling'), break; end
        waitbar((k-1)/numel(imgs), hWait, sprintf('Aligning image %d of %d...', k, numel(imgs)));

        curImg = imgs{k};
        cur_gray = im2single(im2gray(curImg));

        % Feature-based alignment (SURF or other)
        try
            % Detect and match features
            ptsRef = detectSURFFeatures(ref_gray);
            ptsCur = detectSURFFeatures(cur_gray);
            [fRef, vRef] = extractFeatures(ref_gray, ptsRef);
            [fCur, vCur] = extractFeatures(cur_gray, ptsCur);
            indexPairs = matchFeatures(fRef, fCur, 'Unique', true);

            matchedRef = vRef(indexPairs(:,1), :);
            matchedCur = vCur(indexPairs(:,2), :);

            if size(indexPairs, 1) >= 4
                tform = estimateGeometricTransform2D(matchedCur, matchedRef, 'similarity');
                success = true;
            else
                warning('Insufficient matches for image %d. Using last transformation.', k);
                success = false;
            end
        catch
            warning('Alignment failed at image %d. Using last transformation.', k);
            success = false;
        end

        if success
            last_tform = tform;
        else
            tform = last_tform;
        end

        alignedImgs{k} = imwarp(curImg, tform, 'OutputView', Rfixed);
    end

    if getappdata(hWait, 'canceling')
        delete(hWait);
        msgbox('Timelapse creation canceled.', 'Canceled', 'warn');
        return;
    end

    waitbar(1, hWait, 'Writing video file...');
    try
        v = VideoWriter(videoName, 'MPEG-4');
        v.FrameRate = 10;
        open(v);
        for k = 1:numel(alignedImgs)
            if getappdata(hWait, 'canceling'), break; end
            writeVideo(v, im2uint8(alignedImgs{k}));
        end
        close(v);
    catch ME
        delete(hWait);
        errordlg(['Failed to save video: ' ME.message], 'Error');
        return;
    end

    delete(hWait);
    msgbox(sprintf('Timelapse video saved to:\n%s', videoName), 'Done');
end



function closeApp(fig, ~)
    % closeApp - Closes the application.
    
    fprintf('Closing Change Detection application...\n');
    delete(fig); % Delete figure
end
