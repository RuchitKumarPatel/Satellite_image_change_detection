function main()
    % MAIN - Computer Vision Challenge with Change Detection Algorithms
    
    fprintf('=== Computer Vision Challenge - Change Detection Implementation ===\n');
    fprintf('Starting application with CV algorithms...\n');
    
    % Check MATLAB version
    matlabVersion = version('-release');
    fprintf('MATLAB Version: %s\n', matlabVersion);
    
    % Check available toolboxes
    [hasCV, hasIP, hasML] = checkAvailableToolboxes();
    
    % Create full-featured GUI
    createChangeDetectionGUI(hasCV, hasIP, hasML);
    
    fprintf('Change Detection application initialized successfully!\n');
end

function [hasCV, hasIP, hasML] = checkAvailableToolboxes()
    % Check toolbox availability
    fprintf('\nChecking toolbox availability...\n');
    
    hasCV = exist('detectSURFFeatures', 'file') == 2;   % Computer Vision Toolbox: Algorithm for feature extraction
    hasIP = exist('imresize', 'file') == 2;             % Image Processing Toolbox: fct. for image scaling
    hasML = exist('kmeans', 'file') == 2;               % Statistics and Machine Learning Toolbox: kmeans is a clustering algorithm
    
    % Output of the status of each toolbox
    if hasCV, fprintf('✓ Computer Vision Toolbox: Available\n');
    else, fprintf('✗ Computer Vision Toolbox: Not Available\n'); end
    
    if hasIP, fprintf('✓ Image Processing Toolbox: Available\n');
    else, fprintf('✗ Image Processing Toolbox: Not Available\n'); end
    
    if hasML, fprintf('✓ Statistics and Machine Learning Toolbox: Available\n');
    else, fprintf('✗ Statistics and Machine Learning Toolbox: Not Available\n'); end
    
    % sum up, if all toolboxes available
    if hasCV && hasIP && hasML
        fprintf('\n🎉 All toolboxes available - Full CV functionality enabled!\n');
    end
end

function createChangeDetectionGUI(hasCV, hasIP, hasML)
    % Create comprehensive change detection GUI
    
    fig = figure('Name', 'CV Challenge - Satellite Image Change Detection', ...
                 'Position', [30, 30, 1500, 1000], ... % Initial size in pixels
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'NumberTitle', 'off', ...
                 'CloseRequestFcn', @closeApp, ...
                 'Units', 'pixels', ... % Set figure units to pixels for SizeChangedFcn calculation
                 'SizeChangedFcn', @(src,evt) updateFontSizes(src)); % Callback for resizing
    
    % Store data and settings
    fig.UserData.hasCV = hasCV;
    fig.UserData.hasIP = hasIP;
    fig.UserData.hasML = hasML;
    fig.UserData.images = {};
    fig.UserData.currentFolder = '';
    fig.UserData.loadedImages = {};
    fig.UserData.alignedImages = {};
    fig.UserData.currentImagePair = [1, 2];
    fig.UserData.registrationData = [];
    fig.UserData.changeData = [];
    % Initialisierung der Axes-Handles in UserData
    fig.UserData.img1Axes = [];
    fig.UserData.img2Axes = [];
    fig.UserData.resultsAxes = []; % Axes-Handle für den Aligned Image Tab
    
    % Create all GUI components
    createControlPanel(fig);
    createVisualizationPanel(fig);
    createImageDisplayPanels(fig);
    createResultsPanel(fig);
    createStatusPanel(fig);

    % Initial font size update after all components are created
    updateFontSizes(fig);
    
    fprintf('Full change detection GUI created!\n');
end

function createControlPanel(fig)
    % Enhanced control panel with CV options
    
    % Position und Größe des 'Image Controls & Settings' Panels angepasst (Höhe und Y-Position)
    % Panel-Höhe auf 0.38 erhöht, Y-Position auf 0.59 angepasst
    controlPanel = uipanel('Parent', fig, ...
                          'Title', 'Image Controls & Settings', ...
                          'Units', 'normalized', ... % Set units to normalized
                          'Position', [0.01, 0.59, 0.22, 0.38], ... 
                          'FontSize', 11, ... % Base font size
                          'FontWeight', 'bold');
    
    % Abbruch-Knopf
    % Y-Position des Cancel-Buttons angepasst
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '❌ Cancel', ... 
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.855, 0.94, 0.08], ... % Normalized position
              'FontSize', 10, ... % Base font size
              'BackgroundColor', [0.9, 0.2, 0.2], ... 
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Callback', @(src,evt) closeApp(fig, evt)); 
    
    % File operations (Control panel to select image folder)
    % Y-Position angepasst (5 Pixel Abstand zum oberen Knopf)
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '📁 Select Image Folder', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.765, 0.94, 0.08], ... % Normalized position
              'FontSize', 10, ... % Base font size
              'BackgroundColor', [0.2, 0.6, 0.9], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Callback', @(src,evt) selectImageFolder(fig));
    
    % Control panel to load & process the images
    % Y-Position angepasst (5 Pixel Abstand zum oberen Knopf)
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '🔄 Load & Process', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.675, 0.94, 0.08], ... % Normalized position
              'FontSize', 10, ... % Base font size
              'Enable', 'off', ...
              'BackgroundColor', [0.2, 0.8, 0.2], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Tag', 'loadButton', ...
              'Callback', @(src,evt) loadAndProcessImages(fig));
    
    % Navigation
    % Y-Positionen der Navigationselemente angepasst, um Abstände zu reduzieren
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Image Navigation:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.62, 0.94, 0.04], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold');
    
    % Navigation for Image 1
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Image 1:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.56, 0.94, 0.04], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold');

    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '◄ Prev 1', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.485, 0.45, 0.065], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'Tag', 'prev1Button', ...
              'Enable', 'off', ...
              'Callback', @(src,evt) navigateSingleImage(fig, -1, 1)); 
    
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Next 1 ►', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.52, 0.485, 0.45, 0.065], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'Tag', 'next1Button', ...
              'Enable', 'off', ...
              'Callback', @(src,evt) navigateSingleImage(fig, 1, 1)); 

    % Navigation for Image 2
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Image 2:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.43, 0.94, 0.04], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold');

    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '◄ Prev 2', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.355, 0.45, 0.065], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'Tag', 'prev2Button', ...
              'Enable', 'off', ...
              'Callback', @(src,evt) navigateSingleImage(fig, -1, 2)); 
    
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', 'Next 2 ►', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.52, 0.355, 0.45, 0.065], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'Tag', 'next2Button', ...
              'Enable', 'off', ...
              'Callback', @(src,evt) navigateSingleImage(fig, 1, 2)); 

    % Current Pair display (previously "Pair: 1-2")
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Current Pair: 1-2', ... 
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.29, 0.94, 0.04], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'Tag', 'pairText', ... 
              'HorizontalAlignment', 'center');
    
    % Processing options
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Change Detection:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.23, 0.94, 0.04], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold');
    
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '🔧 Align Images', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.155, 0.45, 0.065], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Tag', 'alignButton', ...
              'Enable', 'off', ...
              'Callback', @(src,evt) alignCurrentImages(fig));
    
    uicontrol('Parent', controlPanel, ...
              'Style', 'pushbutton', ...
              'String', '🔍 Detect Changes', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.52, 0.155, 0.45, 0.065], ...
              'FontSize', 8, ... % Base font size
              'Tag', 'detectButton', ...
              'Enable', 'off', ...
              'Callback', @(src,evt) detectChanges(fig));
    
    % Status indicator
    uicontrol('Parent', controlPanel, ...
              'Style', 'text', ...
              'String', 'Ready - Select folder to begin', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.025, 0.94, 0.1], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Tag', 'statusIndicator', ...
              'HorizontalAlignment', 'left', ...
              'BackgroundColor', [0.95, 0.95, 0.95]);
end

function createVisualizationPanel(fig)
    % Panel for visualization options (Project Requirement: 3 visualization types)
    
    % Position und Größe des 'Visualization Methods' Panels angepasst
    % Es füllt nun den Raum zwischen controlPanel (bottom 0.59) und statusPanel (top 0.33)
    % Neue Y-Position: 0.33 (gleich dem Top des statusPanel)
    % Neue Höhe: 0.59 (bottom controlPanel) - 0.33 (top statusPanel) = 0.26
    vizPanel = uipanel('Parent', fig, ...
                      'Title', 'Visualization Methods', ...
                      'Units', 'normalized', ... % Set units to normalized
                      'Position', [0.01, 0.33, 0.22, 0.26], ... 
                      'FontSize', 11, ... % Base font size
                      'FontWeight', 'bold');
    
    % Visualization type selection (Radio Buttons)
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', 'Visualization Type:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.85, 0.9, 0.06], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold');
    
    % Radio buttons for visualization types
    vizGroup = uibuttongroup('Parent', vizPanel, ...
                            'Units', 'normalized', ... % Set units to normalized
                            'Position', [0.05, 0.55, 0.9, 0.28], ... % Normalized position
                            'Tag', 'vizGroup', ...
                            'SelectionChangedFcn', @(src,evt) updateVisualization(fig));
    
    % visualize Change-Intensity via color gradiations
    uicontrol('Parent', vizGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Difference Heatmap', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.7, 0.9, 0.25], ... % Normalized position relative to vizGroup
              'FontSize', 9, ... % Base font size
              'Tag', 'heatmapRadio', ...
              'Value', 1);  % Default selection
    
    % highlight the changes as an overlaid mask or contours 
    uicontrol('Parent', vizGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Side-by-Side Overlay', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.35, 0.9, 0.25], ... % Normalized position relative to vizGroup
              'FontSize', 9, ... % Base font size
              'Tag', 'overlayRadio');
    
    uicontrol('Parent', vizGroup, ...
              'Style', 'radiobutton', ...
              'String', 'Change Highlights', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.05, 0.9, 0.25], ... % Normalized position relative to vizGroup
              'FontSize', 9, ... % Base font size
              'Tag', 'highlightRadio');
    
    % Change type classification
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', 'Change Type Focus:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.45, 0.9, 0.06], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold');
    
    % Dropdown for change types (Project Requirement: 3 change types)
    uicontrol('Parent', vizPanel, ...
              'Style', 'popupmenu', ...
              'String', {'All Changes', 'Geometric Changes (Size/Shape)', 'Intensity Changes (Brightness)', 'Structural Changes (Texture)'}, ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.35, 0.9, 0.09], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'Tag', 'changeTypeDropdown', ...
              'Callback', @(src,evt) updateVisualization(fig));
    
    % Sensitivity slider
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', 'Change Sensitivity:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.25, 0.9, 0.06], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold'); % Textlabel
    
    uicontrol('Parent', vizPanel, ...
              'Style', 'slider', ...
              'Min', 0.1, 'Max', 2.0, 'Value', 1.0, ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.17, 0.7, 0.08], ... % Normalized position
              'Tag', 'sensitivitySlider', ...
              'Callback', @(src,evt) updateVisualization(fig)); % Slider
    
    uicontrol('Parent', vizPanel, ...
              'Style', 'text', ...
              'String', '1.0', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.78, 0.17, 0.17, 0.08], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Tag', 'sensitivityText'); % Textfield to display current slider value
    
    % Apply visualization button
    uicontrol('Parent', vizPanel, ...
              'Style', 'pushbutton', ...
              'String', '🎨 Apply Visualization', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.05, 0.9, 0.09], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'BackgroundColor', [0.8, 0.2, 0.8], ...
              'ForegroundColor', 'white', ...
              'FontWeight', 'bold', ...
              'Tag', 'applyVizButton', ...
              'Enable', 'off', ...
              'Callback', @(src,evt) applyVisualization(fig));
end

function createImageDisplayPanels(fig)
    % Enhanced image display with results
    
    % Original images panel
    origPanel = uipanel('Parent', fig, ...
                       'Title', 'Original Images', ...
                       'Units', 'normalized', ... % Set units to normalized
                       'Position', [0.25, 0.5, 0.48, 0.48], ...
                       'FontSize', 11, ... % Base font size
                       'FontWeight', 'bold');
    
    % Image 1 (Earlier)
    img1Axes = axes('Parent', origPanel, ...
         'Units', 'normalized', ... % Set units to normalized
         'Position', [0.02, 0.1, 0.46, 0.85], ... % Normalized position
         'Tag', 'img1Axes', ...
         'XTick', [], 'YTick', []);
    fig.UserData.img1Axes = img1Axes; % Handle in UserData speichern
    
    % Image 2 (Later)  
    img2Axes = axes('Parent', origPanel, ...
         'Units', 'normalized', ... % Set units to normalized
         'Position', [0.52, 0.1, 0.46, 0.85], ... % Normalized position
         'Tag', 'img2Axes', ...
         'XTick', [], 'YTick', []);
    fig.UserData.img2Axes = img2Axes; % Handle in UserData speichern
    
    % Results/Analysis panel (now a tab group)
    resultsTabGroup = uitabgroup('Parent', fig, ...
                          'Units', 'normalized', ... % Set units to normalized
                          'Position', [0.75, 0.5, 0.24, 0.48], ... % Normalized position
                          'Tag', 'resultsTabGroup');

    % Tab 1: Aligned Image
    alignedImageTab = uitab('Parent', resultsTabGroup, ...
                            'Title', 'Aligned Image', ...
                            'Units', 'normalized', ... % Set units to normalized
                            'Tag', 'alignedImageTab');

    % Axes for Aligned Image tab
    resultsAxes = axes('Parent', alignedImageTab, ...
         'Units', 'normalized', ... % Set units to normalized
         'Position', [0.05, 0.15, 0.9, 0.8], ... % Normalized position
         'Tag', 'resultsAxes', ...
         'XTick', [], 'YTick', []);
    fig.UserData.resultsAxes = resultsAxes; % Store handle for direct access

    % Buttons for Aligned Image tab
    uicontrol('Parent', alignedImageTab, ...
              'Style', 'pushbutton', ...
              'String', '💾 Save Results', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.02, 0.4, 0.08], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Tag', 'saveButtonAligned', ... % Unique tag
              'Enable', 'off', ...
              'Callback', @(src,evt) saveResults(fig));

    uicontrol('Parent', alignedImageTab, ...
              'Style', 'pushbutton', ...
              'String', '📊 Detailed Report', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.55, 0.02, 0.4, 0.08], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Tag', 'reportButtonAligned', ... % Unique tag
              'Enable', 'off', ...
              'Callback', @(src,evt) generateReport(fig));

    % Tab 2: Statistics
    statisticsTab = uitab('Parent', resultsTabGroup, ...
                          'Title', 'Statistics', ...
                          'Units', 'normalized', ... % Set units to normalized
                          'Tag', 'statisticsTab');

    % Statistics display (larger)
    uicontrol('Parent', statisticsTab, ...
              'Style', 'text', ...
              'String', 'Change Statistics:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.9, 0.9, 0.03], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left');

    uicontrol('Parent', statisticsTab, ...
              'Style', 'edit', ...
              'String', 'No analysis performed yet', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.55, 0.9, 0.35], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Max', 12, ... % Max lines beibehalten
              'Tag', 'statsText', ...
              'HorizontalAlignment', 'left');

    % Feature detection info (larger)
    uicontrol('Parent', statisticsTab, ...
              'Style', 'text', ...
              'String', 'Features & Alignment:', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.5, 0.9, 0.03], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left');

    uicontrol('Parent', statisticsTab, ...
              'Style', 'edit', ...
              'String', 'Load images to begin analysis', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.15, 0.9, 0.35], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Max', 12, ... % Max lines beibehalten
              'Tag', 'featuresText', ...
              'HorizontalAlignment', 'left');

    % Buttons for Statistics tab
    uicontrol('Parent', statisticsTab, ...
              'Style', 'pushbutton', ...
              'String', '💾 Save Results', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.05, 0.02, 0.4, 0.08], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Tag', 'saveButtonStats', ... % Unique tag
              'Enable', 'off', ...
              'Callback', @(src,evt) saveResults(fig));

    uicontrol('Parent', statisticsTab, ...
              'Style', 'pushbutton', ...
              'String', '📊 Detailed Report', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.55, 0.02, 0.4, 0.08], ... % Normalized position
              'FontSize', 8, ... % Base font size
              'Tag', 'reportButtonStats', ... % Unique tag
              'Enable', 'off', ...
              'Callback', @(src,evt) generateReport(fig));
end

function createResultsPanel(fig)
    % Panel for detailed results and comparisons
    % This panel is now primarily for the lower tab group, not the top-right results.
    
    detailPanel = uipanel('Parent', fig, ...
                         'Title', 'Detailed Analysis & Comparisons', ...
                         'Units', 'normalized', ... % Set units to normalized
                         'Position', [0.25, 0.01, 0.74, 0.47], ... % Normalized position
                         'FontSize', 11, ... % Base font size
                         'FontWeight', 'bold');
    
    % Create tabbed interface for different analysis views
    tabGroup = uitabgroup('Parent', detailPanel, ...
                         'Units', 'normalized', ... % Set units to normalized
                         'Position', [0.01, 0.01, 0.98, 0.98], ... % Normalized position
                         'Tag', 'analysisTabGroup');
    
    % Tab 1: Change Map
    changeTab = uitab('Parent', tabGroup, ...
                     'Title', 'Change Map', ...
                     'Units', 'normalized', ... % Set units to normalized
                     'Tag', 'changeTab');
    
    axes('Parent', changeTab, ...
         'Units', 'normalized', ... % Set units to normalized
         'Position', [0.05, 0.1, 0.9, 0.85], ... % Normalized position
         'Tag', 'changeMapAxes', ...
         'XTick', [], 'YTick', []);
    
    % Tab 2: Feature Matching
    featuresTab = uitab('Parent', tabGroup, ...
                       'Title', 'Feature Matching', ...
                       'Units', 'normalized', ... % Set units to normalized
                       'Tag', 'featuresTab');
    
    axes('Parent', featuresTab, ...
         'Units', 'normalized', ... % Set units to normalized
         'Position', [0.05, 0.1, 0.9, 0.85], ... % Normalized position
         'Tag', 'featuresAxes', ...
         'XTick', [], 'YTick', []);
    
    % Tab 3: Statistics
    statsTab = uitab('Parent', tabGroup, ...
                    'Title', 'Statistics & Metrics', ...
                    'Units', 'normalized', ... % Set units to normalized
                    'Tag', 'statsTab');
    
    axes('Parent', statsTab, ...
         'Units', 'normalized', ... % Set units to normalized
         'Position', [0.05, 0.55, 0.4, 0.4], ... % Normalized position
         'Tag', 'histogramAxes');
    
    axes('Parent', statsTab, ...
         'Units', 'normalized', ... % Set units to normalized
         'Position', [0.55, 0.55, 0.4, 0.4], ... % Normalized position
         'Tag', 'scatterAxes');
    
    uicontrol('Parent', statsTab, ...
              'Style', 'edit', ...
              'String', 'Detailed statistics will appear here after analysis...', ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.02, 0.02, 0.96, 0.4], ... % Normalized position
              'FontSize', 10, ... % Base font size
              'Max', 15, ...
              'Tag', 'detailedStatsText');
end

function createStatusPanel(fig)
    % Comprehensive status panel
    
    % Höhe des 'Status, Logs & System Information' Panels von oben her reduziert
    statusPanel = uipanel('Parent', fig, ...
                         'Title', 'Status, Logs & System Information', ...
                         'Units', 'normalized', ... % Set units to normalized
                         'Position', [0.01, 0.01, 0.22, 0.32], ... % Normalized position
                         'FontSize', 11, ... % Base font size
                         'FontWeight', 'bold');
    
    % Position und Max-Lines des Status-Textfeldes angepasst, um den Inhalt sauber zu platzieren
    % Panel-Dimensionen (relativ zur Figur): Breite 0.22, Höhe 0.32
    % Angenommene Figurgröße: 1500x1000 Pixel
    % Panel-Pixel-Dimensionen: Breite = 0.22 * 1500 = 330px, Höhe = 0.32 * 1000 = 320px

    % Gewünschte Ränder:
    % textAreaWidth = 330 - (2 * sideMargin); % Panel-Breite - 2 * Seitenrand
    % textAreaHeight = 320 - topMargin - bottomMargin; % Panel-Höhe - Oberer Rand - Unterer Rand

    % Max-Eigenschaft basierend auf der neuen Höhe und Schriftgröße (ca. 15px pro Zeile bei FontSize 9)
    % maxLines = floor(textAreaHeight / 15); % Ungefähre Anzahl der Zeilen

    uicontrol('Parent', statusPanel, ...
              'Style', 'edit', ...
              'String', {['Computer Vision Challenge - Change Detection Ready!'], [''], ...
                        ['📋 Instructions:'], ...
                        ['1. Select folder with satellite images (YYYY_MM.ext)'], ...
                        ['2. Load & process images'], ...
                        ['3. Navigate between image pairs'], ...
                        ['4. Align images for better comparison'], ...
                        ['5. Detect changes using CV algorithms'], ...
                        ['6. Choose visualization method'], ...
                        ['7. Apply visualization to see results'], [''], ...
                        ['💡 Tip: Use images from same location, different times'], ...
                        ['📁 Expected format: 2020_01.jpg, 2020_12.png, etc.']}, ...
              'Units', 'normalized', ... % Set units to normalized
              'Position', [0.03, 0.03, 0.94, 0.94], ... % Normalized position
              'FontSize', 9, ... % Base font size
              'Max', 50, ... % Maximale Zeilenanzahl festlegen, da Höhe normalized ist
              'Tag', 'statusArea', ...
              'HorizontalAlignment', 'left', ... % Text bleibt linksbündig, wie im Bild
              'FontName', 'Courier New');
end

% CORE COMPUTER VISION FUNCTIONS

function selectImageFolder(fig) % selects all images in the folder
    folder = uigetdir(pwd, 'Select folder with satellite images (YYYY_MM.ext format)');
    if folder ~= 0
        fig.UserData.currentFolder = folder;
        
        %% --- Start of changes (Added clearDetailedAnalysisTabs) ---
        % Reset all analysis results when a new folder is selected
        clearAnalysisResults(fig); 
        clearDetailedAnalysisTabs(fig); % Also clear the detailed analysis tabs
        %% --- End of changes ---

        % Scan for images
        imageExtensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tiff', '*.tif'};
        allFiles = [];
        % Iterates over each defined image file extension
        for ext = imageExtensions
            files = dir(fullfile(folder, ext{1}));
            allFiles = [allFiles; files]; % Adds the files found to the total array 'allFiles'
        end
        
        % Updates the status area in the GUI
        updateStatus(fig, {sprintf('📁 Folder: %s', folder), ...
                          sprintf('📊 Found %d images', length(allFiles))});
        
        % Enable load button
        set(findobj(fig, 'Tag', 'loadButton'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'statusIndicator'), 'String', ...
            sprintf('Ready: %d files found', length(allFiles)));
    end
end

function loadAndProcessImages(fig) % loads and processes the selected images
    folder = fig.UserData.currentFolder;
    updateStatus(fig, {'🔄 Loading images...', ''});
    
    %% --- Start of changes (Added clearDetailedAnalysisTabs) ---
    % Reset all analysis results when images are reloaded/processed
    clearAnalysisResults(fig); 
    clearDetailedAnalysisTabs(fig); % Also clear the detailed analysis tabs
    %% --- End of changes ---

    % Find and sort images
    imageExtensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tiff', '*.tif'};
    allFiles = [];
    % Iterates over each defined image file extension
    for ext = imageExtensions
        files = dir(fullfile(folder, ext{1}));
        allFiles = [allFiles; files];
    end
    
    % Checks whether at least two images have been found
    if length(allFiles) < 2
        updateStatus(fig, {sprintf('❌ Need at least 2 images, found %d', length(allFiles))});
        return;
    end
    
    % Sort by filename (assuming date format)
    [~, sortIdx] = sort({allFiles.name});
    imageFiles = allFiles(sortIdx); % Renamed allFiles to imageFiles for clarity
    
    % Load images
    loadedImages = {}; % Initializes an empty cell array to store the loaded image matrices
    for i = 1:length(imageFiles)
        try
            imgPath = fullfile(folder, imageFiles(i).name);
            img = imread(imgPath); % load image to workspace
            loadedImages{i} = img; % save image matrix in cell array
            updateStatus(fig, {sprintf('✓ Loaded: %s', imageFiles(i).name)});
        catch ME
            updateStatus(fig, {sprintf('❌ Failed: %s', imageFiles(i).name)});
            % To Do: ggf. detailliertere Fehlerinformationen anzeigen (ME.message)
        end
    end
    
    % Store data 
    fig.UserData.images = imageFiles;           % store the file structures (name, date, etc.)
    fig.UserData.loadedImages = loadedImages;   % store the actual image data (matrices)
    fig.UserData.currentImagePair = [1, min(2, length(loadedImages))];
    
    % Display first pair
    displayImagePair(fig);
    enableProcessingButtons(fig, true);
    
    % Final status message
    updateStatus(fig, {'✅ Images loaded successfully!', ...
                      sprintf('📊 Total: %d images ready for analysis', length(loadedImages))});
end

function displayImagePair(fig)
    %  Retrieves the necessary data from the UserData of the main window.
    loadedImages = fig.UserData.loadedImages;
    imageFiles = fig.UserData.images;
    currentPair = fig.UserData.currentImagePair;
    
    % Cancels the function if no images are loaded.
    if isempty(loadedImages), return; end
    
    % Extracts the indices of the two images to be displayed.
    idx1 = currentPair(1); % "earlier" picture 
    idx2 = currentPair(2); % "later" picture
    
    % Direkte Verwendung der in fig.UserData gespeicherten Axes-Handles
    axes1 = fig.UserData.img1Axes;
    axes2 = fig.UserData.img2Axes;
    
    % Display images
    if idx1 <= length(loadedImages)                 % Checks whether the index of the first image is valid
        if ~isempty(axes1) && isgraphics(axes1, 'axes') % Überprüfen, ob axes1 gültig ist
            cla(axes1);                                 % Deletes all content (plots, images) from the axes to remove old displays.
            imshow(loadedImages{idx1}, 'Parent', axes1); % display image in the specified axes
            title(axes1, sprintf('Earlier: %s', imageFiles(idx1).name), 'Interpreter', 'none'); % Sets the title of the axes with the file name of the image.
        else
            updateStatus(fig, {'Error: img1Axes handle is invalid or not found. Cannot display image 1.'});
        end
    end
    
    if idx2 <= length(loadedImages)
        if ~isempty(axes2) && isgraphics(axes2, 'axes') % Überprüfen, ob axes2 gültig ist
            cla(axes2);
            imshow(loadedImages{idx2}, 'Parent', axes2);
            title(axes2, sprintf('Later: %s', imageFiles(idx2).name), 'Interpreter', 'none');
        else
            updateStatus(fig, {'Error: img2Axes handle is invalid or not found. Cannot display image 2.'});
        end
    end
    
    % Update displays
    set(findobj(fig, 'Tag', 'pairText'), 'String', sprintf('Current Pair: %d-%d', idx1, idx2)); % update text field
    updateNavigationButtons(fig);
    
    %% --- Start of changes (Added clearDetailedAnalysisTabs) ---
    % Clear previous analysis
    clearAnalysisResults(fig); % This will now also clear the detailed analysis tabs
    clearDetailedAnalysisTabs(fig); % Also clear the detailed analysis tabs
    %% --- End of changes ---
end

function alignCurrentImages(fig)
    %% --- Start of changes (Added clearDetailedAnalysisTabs) ---
    % Reset all analysis results before performing new alignment
    clearAnalysisResults(fig); 
    clearDetailedAnalysisTabs(fig); % Also clear the detailed analysis tabs
    %% --- End of changes ---

    % Align current image pair using SURF features
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    hasCV = fig.UserData.hasCV;
    
    % Check: Are images loaded and is the Computer Vision Toolbox available?
    if isempty(loadedImages) || ~hasCV, updateStatus(fig, {'❌ Need loaded images and Computer Vision Toolbox'}); return; end
    
    % Status message
    updateStatus(fig, {'🔄 Aligning images using SURF features...'});
    
    try
        idx1 = currentPair(1);
        idx2 = currentPair(2);
        
        img1 = loadedImages{idx1};
        img2 = loadedImages{idx2};
        
        % Convert to grayscale if needed
        if size(img1, 3) == 3, gray1 = rgb2gray(img1); else, gray1 = img1; end
        if size(img2, 3) == 3, gray2 = rgb2gray(img2); else, gray2 = img2; end
        
        % Detect SURF features
        points1 = detectSURFFeatures(gray1);
        points2 = detectSURFFeatures(gray2);
        
        % Extract features
        [features1, validPoints1] = extractFeatures(gray1, points1);
        [features2, validPoints2] = extractFeatures(gray2, points2);
        
        % Match features
        indexPairs = matchFeatures(features1, features2);
        matchedPoints1 = validPoints1(indexPairs(:, 1));
        matchedPoints2 = validPoints2(indexPairs(:, 2));
        
        % Estimate geometric transformation
        if length(matchedPoints1) >= 4
            [tform, inlierIdx] = estimateGeometricTransform2D(...
                matchedPoints1, matchedPoints2, 'similarity');
            
            % Apply transformation to align img2 to img1
            alignedImg2 = imwarp(img2, tform, 'OutputView', imref2d(size(img1)));
            
            % Store results
            fig.UserData.alignedImages = {img1, alignedImg2};
            fig.UserData.registrationData = struct(...
                'tform', tform, ...
                'matchedPoints1', matchedPoints1, ...
                'matchedPoints2', matchedPoints2, ...
                'inlierIdx', inlierIdx, ...
                'numMatches', length(matchedPoints1), ...
                'numInliers', sum(inlierIdx));
            
            % Update displays
            resultsAxes = fig.UserData.resultsAxes; % Direkten Handle verwenden
            if ~isempty(resultsAxes) && isgraphics(resultsAxes, 'axes')
                cla(resultsAxes);
                imshow(alignedImg2, 'Parent', resultsAxes);
                title(resultsAxes, 'Aligned Image', 'Color', [0, 0.7, 0]);
            else
                updateStatus(fig, {'Error: resultsAxes handle is invalid or not found. Cannot display aligned image.'});
            end
            
            % Update feature info
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
            
            % Show feature matching in features tab
            displayFeatureMatching(fig);
            
            % Enable change detection
            set(findobj(fig, 'Tag', 'detectButton'), 'Enable', 'on');
            
            updateStatus(fig, {'✅ Image alignment completed!', ...
                              sprintf('🎯 %d features matched, %d inliers', ...
                                     length(matchedPoints1), sum(inlierIdx))});
        else
            updateStatus(fig, {'❌ Insufficient feature matches for alignment'});
        end
        
    catch ME
        updateStatus(fig, {sprintf('❌ Alignment failed: %s', ME.message)});
    end
end

function displayFeatureMatching(fig)
    % Display feature matching results
    regData = fig.UserData.registrationData;
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    
    if isempty(regData), return; end
    
    % Get images
    img1 = loadedImages{currentPair(1)};
    img2 = loadedImages{currentPair(2)};
    
    % Display in features tab
    featuresAxes = findobj(fig, 'Tag', 'featuresAxes');
    axes(featuresAxes); cla;
    
    %% --- Start of changes (Fixed matchedPoints1 filtering) ---
    % Filter both sets of matched points by inlierIdx
    showMatchedFeatures(img1, img2, ...
                       regData.matchedPoints1(regData.inlierIdx), ...
                       regData.matchedPoints2(regData.inlierIdx), ...
                       'montage');
    %% --- End of changes ---
    title(sprintf('Feature Matching: %d inliers of %d matches', ...
          regData.numInliers, regData.numMatches));
    drawnow; % Force redraw
end

function detectChanges(fig)
    %% --- Start of changes (Modified clear call and added tab selection) ---
    % Clear only the detailed analysis tabs before performing new detection
    clearDetailedAnalysisTabs(fig); 
    %% --- End of changes ---

    % Detect changes between aligned images
    alignedImages = fig.UserData.alignedImages;
    hasIP = fig.UserData.hasIP;
    
    % Check: Are images already aligned?
    if isempty(alignedImages), updateStatus(fig, {'❌ Please align images first'}); return; end
    
    updateStatus(fig, {'🔄 Detecting changes...'}); % status update
    
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
        
        % Convert to double for processing
        img1_double = double(img1_gray);
        img2_double = double(img2_gray);
        
        % Compute basic difference
        diffImg = abs(img2_double - img1_double);
        
        % Apply Gaussian smoothing if available
        if hasIP
            diffImg = imgaussfilt(diffImg, 1.5);
        end
        
        % Threshold for change detection
        threshold = 30; % Adjustable
        changeMask = diffImg > threshold;
        
        % Compute change statistics
        totalPixels = numel(changeMask);
        changedPixels = sum(changeMask(:));
        changePercentage = (changedPixels / totalPixels) * 100;
        
        % Create colored change map
        changeMap = zeros(size(img1));
        changeMap(:,:,1) = img1_gray;  % Red channel: original
        changeMap(:,:,2) = img1_gray;  % Green channel: original
        changeMap(:,:,3) = img1_gray;  % Blue channel: original
        
        % Highlight changes in red
        changeMap(:,:,1) = changeMap(:,:,1) + double(changeMask) * 100;
        changeMap = uint8(min(changeMap, 255));
        
        % Store results
        fig.UserData.changeData = struct(...
            'diffImg', diffImg, ...
            'changeMask', changeMask, ...
            'changeMap', changeMap, ...
            'changePercentage', changePercentage, ...
            'threshold', threshold, ...
            'totalPixels', totalPixels, ...
            'changedPixels', changedPixels);
        
        % Display change map
        changeMapAxes = findobj(fig, 'Tag', 'changeMapAxes');
        if ~isempty(changeMapAxes) && isgraphics(changeMapAxes, 'axes')
            %% --- Start of changes (Explicitly delete image object and set active tab) ---
            % Explicitly delete any existing image objects in the axes
            delete(findobj(changeMapAxes, 'Type', 'image')); 
            
            imshow(changeMap, 'Parent', changeMapAxes); % Display new change map
            title(changeMapAxes, sprintf('Changes: %.2f%%', changePercentage));
            
            % Ensure the correct tab is selected if it's not already
            analysisTabGroup = findobj(fig, 'Tag', 'analysisTabGroup');
            changeTab = findobj(analysisTabGroup, 'Tag', 'changeTab');
            set(analysisTabGroup, 'SelectedTab', changeTab);
            
            drawnow; % Force redraw
            %% --- End of changes ---
        else
            updateStatus(fig, {'Error: changeMapAxes handle is invalid or not found. Cannot display change map.'});
        end
        
        % Update statistics
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
        
        % Enable visualization controls
        set(findobj(fig, 'Tag', 'applyVizButton'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'saveButtonAligned'), 'Enable', 'on'); % Update both sets of buttons
        set(findobj(fig, 'Tag', 'reportButtonAligned'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'saveButtonStats'), 'Enable', 'on');
        set(findobj(fig, 'Tag', 'reportButtonStats'), 'Enable', 'on');
        
        updateStatus(fig, {'✅ Change detection completed!', ...
                          sprintf('📊 %.2f%% of image area changed', changePercentage)});
        drawnow; % Force redraw
                      
    catch ME
        updateStatus(fig, {sprintf('❌ Change detection failed: %s', ME.message)});
    end
end

%% HELPER FUNCTIONS
% Updates the indices of the current image pair to be displayed and then calls 'displayImagePair' to display the new images.
function navigateImagePair(fig, direction) % Funktion umbenannt
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    
    % Aborts if no or not enough images are loaded.
    if isempty(loadedImages) || length(loadedImages) < 2, return; end
    
    % Calculates the new indices for the image pair
    newIdx1 = currentPair(1) + direction;
    newIdx2 = currentPair(2) + direction;
    
    % Checks whether the new indices are within the valid limits
    if newIdx1 < 1 || newIdx2 > length(loadedImages), return; end
    
    % Saves the new image pair in the UserData.
    fig.UserData.currentImagePair = [newIdx1, newIdx2];
    displayImagePair(fig);
end

% Funktion für die unabhängige Navigation einzelner Bilder
function navigateSingleImage(fig, direction, imageIndex)
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;

    if isempty(loadedImages), return; end

    if imageIndex == 1 % Navigiere Bild 1
        newIdx = currentPair(1) + direction;
        if newIdx < 1, newIdx = length(loadedImages); end % Wrap around
        if newIdx > length(loadedImages), newIdx = 1; end % Wrap around
        fig.UserData.currentImagePair(1) = newIdx;
    elseif imageIndex == 2 % Navigiere Bild 2
        newIdx = currentPair(2) + direction;
        if newIdx < 1, newIdx = length(loadedImages); end % Wrap around
        if newIdx > length(loadedImages), newIdx = 1; end % Wrap around
        fig.UserData.currentImagePair(2) = newIdx;
    end
    
    displayImagePair(fig);
end

% Activates or deactivates the "Previous" and "Next" buttons
function updateNavigationButtons(fig)
    loadedImages = fig.UserData.loadedImages;
    currentPair = fig.UserData.currentImagePair;
    numImgs = length(loadedImages);
    
    % Pair Navigation Buttons
    prevPairBtn = findobj(fig, 'Tag', 'prevButton');
    nextPairBtn = findobj(fig, 'Tag', 'nextButton');
    
    if currentPair(1) <= 1, set(prevPairBtn, 'Enable', 'off');
    else, set(prevPairBtn, 'Enable', 'on'); end
    
    if currentPair(2) >= numImgs, set(nextPairBtn, 'Enable', 'off');
    else, set(nextPairBtn, 'Enable', 'on'); end

    % Individual Image 1 Navigation Buttons
    prev1Btn = findobj(fig, 'Tag', 'prev1Button');
    next1Btn = findobj(fig, 'Tag', 'next1Button');

    if numImgs > 0 % Nur aktivieren, wenn Bilder geladen sind
        set(prev1Btn, 'Enable', 'on');
        set(next1Btn, 'Enable', 'on');
    else
        set(prev1Btn, 'Enable', 'off');
        set(next1Btn, 'Enable', 'off');
    end

    % Individual Image 2 Navigation Buttons
    prev2Btn = findobj(fig, 'Tag', 'prev2Button');
    next2Btn = findobj(fig, 'Tag', 'next2Button');

    if numImgs > 0 % Nur aktivieren, wenn Bilder geladen sind
        set(prev2Btn, 'Enable', 'on');
        set(next2Btn, 'Enable', 'on');
    else
        set(prev2Btn, 'Enable', 'off');
        set(next2Btn, 'Enable', 'off');
    end
end

function enableProcessingButtons(fig, enable)
    buttons = {'alignButton', 'detectButton'};
    enableStr = 'off'; if enable, enableStr = 'on'; end
    
    % Iterates over the buttons and sets their 'Enable' property.
    for i = 1:length(buttons)
        btn = findobj(fig, 'Tag', buttons{i});
        if ~isempty(btn), set(btn, 'Enable', enableStr); end
    end
    
    % Enable/Disable Save and Report buttons for both tabs
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
    % Clear previous analysis results and reset displays across all relevant panels
    % This function clears the core data and the top-right result panel.
    fig.UserData.alignedImages = {};
    fig.UserData.registrationData = [];
    fig.UserData.changeData = [];
    
    % --- Top-right Results Panel (Aligned Image & Statistics Tabs) ---
    % Reset Aligned Image tab axes
    resultsAxes = fig.UserData.resultsAxes;
    if ~isempty(resultsAxes) && isgraphics(resultsAxes, 'axes')
        cla(resultsAxes);
        text(resultsAxes, 0.5, 0.5, 'Aligned image will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
    end

    % Reset Statistics tab text fields
    set(findobj(fig, 'Tag', 'featuresText'), 'String', 'Load images and align for analysis');
    set(findobj(fig, 'Tag', 'statsText'), 'String', 'No analysis performed yet');

    % Disable visualization/report/save buttons
    set(findobj(fig, 'Tag', 'applyVizButton'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'saveButtonAligned'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'reportButtonAligned'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'saveButtonStats'), 'Enable', 'off');
    set(findobj(fig, 'Tag', 'reportButtonStats'), 'Enable', 'off');
end

%% --- Start of changes (New function clearDetailedAnalysisTabs) ---
function clearDetailedAnalysisTabs(fig)
    % This function specifically clears the contents of the lower "Detailed Analysis & Comparisons" panel's tabs.
    
    updateStatus(fig, {'🗑️ Clearing detailed analysis tabs...'}); % Added status update
    
    % Clear Change Map Axes
    changeMapAxes = findobj(fig, 'Tag', 'changeMapAxes');
    if ~isempty(changeMapAxes) && isgraphics(changeMapAxes, 'axes')
        cla(changeMapAxes);
        text(changeMapAxes, 0.5, 0.5, 'Change map will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow; % Force redraw after clearing
    end

    % Clear Feature Matching Axes
    featuresAxes = findobj(fig, 'Tag', 'featuresAxes');
    if ~isempty(featuresAxes) && isgraphics(featuresAxes, 'axes')
        cla(featuresAxes);
        text(featuresAxes, 0.5, 0.5, 'Feature matches will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow; % Force redraw after clearing
    end
    
    % Clear Statistics & Metrics Axes and Text
    histogramAxes = findobj(fig, 'Tag', 'histogramAxes');
    if ~isempty(histogramAxes) && isgraphics(histogramAxes, 'axes')
        cla(histogramAxes);
        text(histogramAxes, 0.5, 0.5, 'Histogram will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow; % Force redraw after clearing
    end

    scatterAxes = findobj(fig, 'Tag', 'scatterAxes');
    if ~isempty(scatterAxes) && isgraphics(scatterAxes, 'axes')
        cla(scatterAxes);
        text(scatterAxes, 0.5, 0.5, 'Scatter plot will appear here', 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
        drawnow; % Force redraw after clearing
    end

    set(findobj(fig, 'Tag', 'detailedStatsText'), 'String', 'Detailed statistics will appear here after analysis...');
    drawnow; % Force redraw for text update
    updateStatus(fig, {'✅ Detailed analysis tabs cleared.'}); % Added status update
end
%% --- End of changes (New function clearDetailedAnalysisTabs) ---


%% PLACEHOLDER FUNCTIONS (to be implemented in next step)
% Updates the display of the sensitivity slider
function updateVisualization(fig)
    % Update sensitivity slider display
    slider = findobj(fig, 'Tag', 'sensitivitySlider');
    text = findobj(fig, 'Tag', 'sensitivityText');
    
    % Updates the text with the current value of the slider
    if ~isempty(slider) && ~isempty(text)
        set(text, 'String', sprintf('%.1f', get(slider, 'Value')));
    end
end

% Platzhalterfunktion für das Anwenden der Visualisierung
function applyVisualization(fig)
    %% --- Start of changes (Removed clearAnalysisResults, added clearDetailedAnalysisTabs) ---
    clearDetailedAnalysisTabs(fig); % Clear detailed analysis tabs before applying new visualization
    %% --- End of changes ---
    updateStatus(fig, {'🎨 Advanced visualization features coming in Step 4!'});
end
% Platzhalterfunktion für das Speichern der Analyseergebnisse
function saveResults(fig)
    updateStatus(fig, {'💾 Save functionality coming in Step 4!'});
end
% Platzhalterfunktion für die Generierung eines detaillierten Berichts
function generateReport(fig)
    updateStatus(fig, {'📊 Report generation coming in Step 4!'});
end
% Updates the text in the status area of the GUI
function updateStatus(fig, messages)
    % Enhanced status update
    statusArea = findobj(fig, 'Tag', 'statusArea');
    currentTime = datestr(now, 'HH:MM:SS');
    
    % Ensures that 'messages' is a cell array
    if ~iscell(messages), messages = {messages}; end
    % Converts row vector to column vector if necessary
    if size(messages, 1) == 1 && size(messages, 2) > 1, messages = messages'; end
    
    % Adds the timestamp to the first message
    timestampedMessages = cell(length(messages), 1);
    timestampedMessages{1} = sprintf('[%s] %s', currentTime, messages{1});
    if length(messages) > 1
        for i = 2:length(messages)
            timestampedMessages{i} = messages{i};
        end
    end
    % Gets the current content of the status field
    currentContent = get(statusArea, 'String');
    if ischar(currentContent), currentContent = {currentContent}; end
    if ~isempty(currentContent) && size(currentContent, 1) == 1 && size(currentContent, 2) > 1, currentContent = currentContent'; end
    % Adds the new messages to the existing content
    if isempty(currentContent)
        newContent = timestampedMessages;
    else
        newContent = [timestampedMessages; {''}; currentContent];
    end
    % Limits the number of lines displayed 
    if length(newContent) > 50, newContent = newContent(1:50); end
    set(statusArea, 'String', newContent);
end

% Function to dynamically update font sizes based on figure size
function updateFontSizes(fig)
    % Reference figure height for base font sizes
    referenceHeight = 1000; % pixels, matches initial figure height

    % Get current figure height
    figPos = get(fig, 'Position');
    currentHeight = figPos(4);

    % Calculate scaling factor
    scalingFactor = currentHeight / referenceHeight;

    % Define base font sizes for different types of controls
    % These are the font sizes that look good at referenceHeight = 1000px
    baseFontSizes = struct(...
        'uipanel', 11, ...
        'pushbutton', 10, ...
        'text', 9, ...
        'edit', 8, ...
        'radiobutton', 9, ...
        'popupmenu', 9, ...
        'sliderText', 8 ... % For the sensitivity slider text
    );

    % Iterate through all UI controls and update their font sizes
    allControls = findall(fig, 'Type', 'uicontrol');
    for i = 1:length(allControls)
        control = allControls(i);
        style = get(control, 'Style');
        tag = get(control, 'Tag'); % Get tag to identify specific controls if needed

        currentBaseFontSize = -1; % Initialize with an invalid value

        switch style
            case {'pushbutton'}
                currentBaseFontSize = baseFontSizes.pushbutton;
            case {'text'}
                % Special handling for status indicator and pair text as they are smaller
                if strcmp(tag, 'statusIndicator') || strcmp(tag, 'pairText')
                    currentBaseFontSize = baseFontSizes.edit; % Use smaller font like edit fields
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
        
        % Handle uipanel titles
        if strcmp(get(control, 'Type'), 'uipanel')
            currentBaseFontSize = baseFontSizes.uipanel;
        end

        % Apply scaled font size, with a minimum limit
        if currentBaseFontSize ~= -1
            newFontSize = max(6, round(currentBaseFontSize * scalingFactor)); % Ensure minimum font size of 6
            set(control, 'FontSize', newFontSize);
        end
    end
    
    % Update axes titles (these are not uicontrols)
    allAxes = findall(fig, 'Type', 'axes');
    for i = 1:length(allAxes)
        ax = allAxes(i);
        titleHandle = get(ax, 'Title');
        if ~isempty(titleHandle) && isgraphics(titleHandle)
            currentTitleFontSize = get(titleHandle, 'FontSize');
            % Assuming a base font size for titles, e.g., 10 for 1000px height
            baseTitleFontSize = 10; % You might need to adjust this
            newTitleFontSize = max(8, round(baseTitleFontSize * scalingFactor));
            set(titleHandle, 'FontSize', newTitleFontSize);
        end
    end
end


function closeApp(fig, ~)
    fprintf('Closing Change Detection application...\n');
    delete(fig);
end
