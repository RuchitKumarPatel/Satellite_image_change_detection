function so_cv_challenge()
    % This function creates a GUI for advanced image alignment and timelapse creation
    % Requires MATLAB and the Computer Vision Toolbox
    
    % --- Main Figure Window Setup ---
    % Create the main figure window with specified properties
    fig = figure('Name', 'Advanced Image Alignment & Timelapse', ...
        'Position', [100 100 900 650], ... % [x,y,width,height] in pixels
        'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off');
    
    % --- Result Display Area ---
    % Create axes for displaying results in the center of the window
    axResult = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.25 0.15 0.5 0.75]);
    title(axResult, 'No images loaded');  % Initial title
    axis(axResult, 'off');  % Turn off axis lines and labels
    
    % --- Control Buttons (Top Row) ---
    % Button to load image folder
    btnLoadFolder = uicontrol('Style', 'pushbutton', 'String', 'Load Folder', ...
        'Units', 'normalized', 'Position', [0.05 0.92 0.15 0.06], ...
        'Callback', @loadFolderCallback);
    
    % Button to align selected images
    btnAlign = uicontrol('Style', 'pushbutton', 'String', 'Align Images', ...
        'Units', 'normalized', 'Position', [0.25 0.92 0.15 0.06], ...
        'Callback', @alignCallback, 'Enable', 'off');  % Initially disabled
    
    % Button to cycle through display modes
    btnNextDisplay = uicontrol('Style', 'pushbutton', 'String', 'Next Display', ...
        'Units', 'normalized', 'Position', [0.45 0.92 0.15 0.06], ...
        'Callback', @nextDisplayCallback, 'Enable', 'off');  % Initially disabled
    
    % Button to create timelapse video
    btnTimelapse = uicontrol('Style', 'pushbutton', 'String', 'Create Timelapse', ...
        'Units', 'normalized', 'Position', [0.65 0.92 0.25 0.06], ...
        'Callback', @timelapseCallback, 'Enable', 'off');  % Initially disabled
    
    % --- Image Selection Panel 1 (Left Side) ---
    panel1_x = 0.05; panel_width = 0.15;
    
    % Up button for Image 1 selection
    btnUp1 = uicontrol('Style', 'pushbutton', 'String', '▲', ...
        'Units', 'normalized', 'Position', [panel1_x 0.7 panel_width 0.1], ...
        'Callback', {@buttonCallback, -1, 1}, 'Enable', 'off');  % Initially disabled
    
    % Label showing current Image 1 selection
    label1 = uicontrol('Style', 'text', 'String', 'Image 1', ...
        'Units', 'normalized', 'Position', [panel1_x 0.4 0.15 0.3]);
    
    % Down button for Image 1 selection
    btnDown1 = uicontrol('Style', 'pushbutton', 'String', '▼', ...
        'Units', 'normalized', 'Position', [panel1_x 0.3 panel_width 0.1], ...
        'Callback', {@buttonCallback, 1, 1}, 'Enable', 'off');  % Initially disabled

    % --- Image Selection Panel 2 (Right Side) ---
    panel2_x = 0.8;
    
    % Up button for Image 2 selection
    btnUp2 = uicontrol('Style', 'pushbutton', 'String', '▲', ...
        'Units', 'normalized', 'Position', [panel2_x 0.7 panel_width 0.1], ...
        'Callback', {@buttonCallback, -1, 2}, 'Enable', 'off');  % Initially disabled
    
    % Label showing current Image 2 selection
    label2 = uicontrol('Style', 'text', 'String', 'Image 2', ...
        'Units', 'normalized', 'Position', [panel2_x 0.4 panel_width 0.3]);
    
    % Down button for Image 2 selection
    btnDown2 = uicontrol('Style', 'pushbutton', 'String', '▼', ...
        'Units', 'normalized', 'Position', [panel2_x 0.3 panel_width 0.1], ...
        'Callback', {@buttonCallback, 1, 2}, 'Enable', 'off');  % Initially disabled

    % --- Overlay Control Slider ---
    % Slider to adjust blending between two images
    overlaySlider = uicontrol('Style', 'slider', ...
        'Units', 'normalized', 'Position', [0.25 0.05 0.5 0.05], ...
        'Min', 0, 'Max', 1, 'Value', 0.5, ...
        'Callback', @overlaySliderChanged, 'Visible', 'off');  % Initially hidden
    
    % Label for Image 1 side of slider
    labelOverlay1 = uicontrol('Style','text','Units','normalized',...
        'Position',[0.20 0.05 0.05 0.05],'String','Img 1','Visible','off');
    
    % Label for Image 2 side of slider
    labelOverlay2 = uicontrol('Style','text','Units','normalized',...
        'Position',[0.75 0.05 0.05 0.05],'String','Img 2','Visible','off');

    % --- Application State Variables ---
    imgs = {};          % Cell array to store loaded images
    imgFiles = {};      % Cell array to store image filenames
    img1 = [];          % Currently selected image 1
    img2 = [];          % Currently selected image 2
    img2_aligned = [];  % Aligned version of image 2
    folderPath = '';    % Path to the loaded image folder
    idx1 = 1;           % Index of currently selected image 1
    idx2 = 1;           % Index of currently selected image 2
    numImgs = 0;        % Total number of loaded images
    displayMode = 1;    % Current display mode (1=img1, 2=img2, 3=overlay, 4=difference)
    figImg1 = [];       % Handle to separate figure for image 1
    figImg2 = [];       % Handle to separate figure for image 2
    
    % --- Callback Functions ---

    function loadFolderCallback(~,~)
        % Callback for Load Folder button
        % Opens folder selection dialog and loads all images
        
        folder = uigetdir();  % Show folder selection dialog
        if folder == 0, return; end  % User cancelled
        folderPath = folder;
        
        % Supported image extensions
        exts = {'*.png','*.jpg','*.jpeg','*.bmp','*.tif','*.tiff'};
        files = [];
        
        % Find all image files in the selected folder
        for e = 1:length(exts)
            files = [files; dir(fullfile(folder, exts{e}))];
        end
        
        % Sort files by name to ensure correct timelapse order
        if ~isempty(files)
            fileNames = {files.name};
            [~, sortOrder] = sort(fileNames);
            files = files(sortOrder);
        end
        
        % Check if any images were found
        if isempty(files)
            errordlg('No images found in folder!','Error'); 
            return; 
        end
        
        % Show progress bar while loading images
        hWait = waitbar(0, 'Loading images...', 'Name', 'Loading');
        numImgs = length(files);
        imgs = cell(numImgs,1); 
        imgFiles = cell(numImgs,1);
        
        % Load each image
        for k=1:numImgs
            waitbar(k/numImgs, hWait, sprintf('Loading %s', files(k).name));
            imgFiles{k} = files(k).name;
            imgs{k} = imread(fullfile(folder, files(k).name));
        end
        close(hWait);  % Close progress bar

        % Enable controls now that images are loaded
        set([btnUp1, btnDown1, btnUp2, btnDown2, btnAlign, btnTimelapse], 'Enable', 'on');
        set(overlaySlider,'Visible','off'); 
        set([labelOverlay1, labelOverlay2],'Visible','off');

        % Set initial image selections
        idx1 = 1; 
        idx2 = min(2, numImgs);
        if numImgs == 1, idx2 = 1; end  % Handle case with only one image
        updateImageSelection();  % Update display with selected images
    end

    function buttonCallback(~, ~, direction, panel)
        % Callback for image selection buttons (up/down)
        % direction: +1 for down, -1 for up
        % panel: 1 for left panel, 2 for right panel
        
        % Calculate new index based on button pressed
        if panel == 1
            new_idx = idx1 + direction;  % Left panel
        else
            new_idx = idx2 + direction;  % Right panel
        end
        
        % Handle wrap-around (circular navigation)
        if new_idx > numImgs, new_idx = 1; end
        if new_idx < 1, new_idx = numImgs; end
        
        % Prevent selecting the same image in both panels
        if (panel == 1 && new_idx == idx2) || (panel == 2 && new_idx == idx1)
            new_idx = new_idx + direction;
            if new_idx > numImgs, new_idx = 1; end
            if new_idx < 1, new_idx = numImgs; end
        end
        
        % Update the appropriate index
        if panel == 1
            idx1 = new_idx;  % Update left panel selection
        else
            idx2 = new_idx;  % Update right panel selection
        end
        
        updateImageSelection();  % Refresh display with new selections
    end

    function updateImageSelection()
        % Updates the display when image selections change
        
        if isempty(imgs), return; end  % No images loaded
        
        % Get currently selected images
        img1 = imgs{idx1}; 
        img2 = imgs{idx2};
        
        % Update panel labels with filenames
        set(label1, 'String', sprintf('Image 1:\n%s', imgFiles{idx1}));
        set(label2, 'String', sprintf('Image 2:\n%s', imgFiles{idx2}));
        
        % Reset alignment and display state
        img2_aligned = [];
        btnNextDisplay.Enable = 'off';
        set(overlaySlider,'Visible','off'); 
        set([labelOverlay1, labelOverlay2],'Visible','off');
        displayMode = 1;
        
        % Update displays
        showImageInFigures();
        showImage(img1, sprintf('Image 1: %s', imgFiles{idx1}));
    end

    function overlaySliderChanged(~,~)
        % Callback for overlay slider movement
        % Triggers display update to show new blending ratio
        showDisplay();
    end
    
    function [tform, success] = alignImagesRobust(imgFixed, imgMoving)
        % Attempts to align imgMoving to imgFixed using multiple methods
        % First tries feature-based alignment, falls back to intensity-based
        
        % Initialize default (identity) transform
        tform = affine2d(eye(3)); 
        success = false;
        
        % --- Method 1: Feature-Based Alignment (SURF) ---
        try 
            % Detect SURF features in both images
            pointsFixed = detectSURFFeatures(imgFixed, 'MetricThreshold', 500);
            pointsMoving = detectSURFFeatures(imgMoving, 'MetricThreshold', 500);
            
            % Check if enough features were found
            if pointsFixed.Count < 10 || pointsMoving.Count < 10
                error('Not enough features.');
            end
            
            % Extract features
            [featuresFixed, validPtsFixed] = extractFeatures(imgFixed, pointsFixed);
            [featuresMoving, validPtsMoving] = extractFeatures(imgMoving, pointsMoving);
            
            % Match features between images
            indexPairs = matchFeatures(featuresFixed, featuresMoving, 'Unique', true, 'MaxRatio', 0.6);
            
            % Get matched points
            matchedMoving = validPtsMoving(indexPairs(:,1),:);
            matchedFixed = validPtsFixed(indexPairs(:,2),:);
            
            % Need at least 4 points to estimate transform
            if size(matchedMoving, 1) < 4
                error('Not enough matches.');
            end
            
            % Estimate rigid transform
            [tform_cand, ~] = estimateGeometricTransform2D(matchedMoving, matchedFixed, 'rigid', 'MaxNumTrials', 2000, 'MaxDistance', 2.5);
            
            % Check if transform is valid (close to rigid)
            if abs(det(tform_cand.T) - 1.0) > 0.05
                error('Transform not rigid.');
            end
            
            % Success - return feature-based transform
            tform = tform_cand; 
            success = true; 
            disp('Alignment: Feature-based OK.'); 
            return;
            
        catch ME
            warning('Feature-based alignment failed: %s. Trying intensity-based method.', ME.message);
        end
        
        % --- Method 2: Intensity-Based Alignment ---
        try 
            % Configure intensity-based registration
            [optimizer, metric] = imregconfig('monomodal');
            optimizer.MaximumIterations = 300;
            
            % Perform registration
            tform_cand = imregtform(imgMoving, imgFixed, 'rigid', optimizer, metric);
            
            % Check if transform is valid
            if abs(det(tform_cand.T) - 1.0) > 0.05
                error('Transform not rigid.');
            end
            
            % Success - return intensity-based transform
            tform = tform_cand; 
            success = true; 
            disp('Alignment: Intensity-based OK.');
            
        catch ME
            warning('Intensity-based alignment also failed: %s.', ME.message);
            tform = affine2d(eye(3)); 
            success = false;
        end
    end

    function alignCallback(~,~)
        % Callback for Align Images button
        
        % Check if we have two different images selected
        if isempty(img1) || isempty(img2) || idx1 == idx2
            errordlg('Select two different images!','Error'); 
            return; 
        end
        
        % Show progress bar during alignment
        hWait = waitbar(0.5, 'Aligning images...', 'Name', 'Aligning');
        
        % Convert images to grayscale and single precision for processing
        img1_gray = im2single(im2gray(img1)); 
        img2_gray = im2single(im2gray(img2));
        
        % Perform alignment
        [tform, success] = alignImagesRobust(img1_gray, img2_gray);
        close(hWait);  % Close progress bar
        
        % Check if alignment succeeded
        if ~success
            msgbox('Image alignment failed.', 'Error', 'error'); 
            return; 
        end
        
        % Apply the transform to align image 2 to image 1
        Rfixed = imref2d(size(img1_gray));
        img2_aligned = imwarp(img2, tform, 'OutputView', Rfixed);
        
        % Update display state
        displayMode = 3;  % Show overlay mode
        btnNextDisplay.Enable = 'on';
        showDisplay();
    end

    function nextDisplayCallback(~,~)
        % Callback for Next Display button
        % Cycles through display modes (1-4)
        displayMode = mod(displayMode,4)+1; 
        showDisplay(); 
    end

    function showDisplay()
        % Updates the main display based on current display mode
        
        cla(axResult);  % Clear current display
        axis(axResult, 'on');
        
        % Hide overlay controls by default (shown only in overlay mode)
        set(overlaySlider,'Visible','off'); 
        set([labelOverlay1, labelOverlay2],'Visible','off'); 
        
        switch displayMode
            case 1  % Show Image 1
                imshow(img1, 'Parent', axResult); 
                title(axResult, sprintf('Image 1: %s', imgFiles{idx1}));
                
            case 2  % Show Image 2
                imshow(img2, 'Parent', axResult); 
                title(axResult, sprintf('Image 2: %s', imgFiles{idx2}));
                
            case 3  % Show Overlay of aligned images
                if isempty(img2_aligned)
                    msgbox('Align first','Info'); 
                    displayMode=1; 
                    showDisplay(); 
                    return; 
                end
                
                % Show overlay controls
                set(overlaySlider,'Visible','on'); 
                set([labelOverlay1, labelOverlay2],'Visible','on');
                
                % Get current blend ratio from slider
                alpha = get(overlaySlider, 'Value');
                
                % Create blended image
                blendedImg = imadd(im2double(img1) * (1-alpha), im2double(img2_aligned) * alpha);
                
                % Display blended image
                imshow(blendedImg, 'Parent', axResult);
                title(axResult, sprintf('Aligned Overlay (%.0f%% / %.0f%%)', (1-alpha)*100, alpha*100));
                
            case 4  % Show Difference heatmap
                if isempty(img2_aligned)
                    msgbox('Align first','Info'); 
                    displayMode=1; 
                    showDisplay(); 
                    return; 
                end
                
                % Calculate absolute difference between images
                diffRGB = abs(double(img1) - double(img2_aligned));
                
                % Display as heatmap
                imagesc(axResult, mat2gray(sum(diffRGB,3)));
                colormap(axResult, 'hot'); 
                colorbar(axResult); 
                axis(axResult, 'image'); 
                title(axResult, 'Difference Heatmap');
        end
        
        axis(axResult, 'off');  % Turn off axis for cleaner display
    end

    function showImage(img, t)
        % Helper function to display a single image with title
        cla(axResult); 
        imshow(img, 'Parent', axResult); 
        title(axResult, t); 
        axis(axResult, 'off'); 
    end

    function showImageInFigures()
        % Displays the current images in separate figure windows
        
        % Create or reuse figure for Image 1
        if isempty(figImg1)||~isvalid(figImg1)
            figImg1=figure('Name','Image 1','NumberTitle','off'); 
            movegui(figImg1,'west');  % Position on left side of screen
        end
        figure(figImg1); 
        imshow(img1); 
        title(sprintf('Image 1: %s', imgFiles{idx1}));
        
        % Create or reuse figure for Image 2
        if isempty(figImg2)||~isvalid(figImg2)
            figImg2=figure('Name','Image 2','NumberTitle','off'); 
            movegui(figImg2,'east');  % Position on right side of screen
        end
        figure(figImg2); 
        imshow(img2); 
        title(sprintf('Image 2: %s', imgFiles{idx2}));
    end

    function timelapseCallback(~,~)
        % Callback for Create Timelapse button
        
        % Check if images are loaded
        if isempty(imgs)
            errordlg('Load a folder first!','Error'); 
            return; 
        end
        
        % Set up progress bar with cancel button
        hWait = waitbar(0,'Preparing for timelapse...', 'Name', 'Please wait', ...
            'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
        setappdata(hWait,'canceling',0);
        
        % Use first image as reference
        refImg = imgs{1}; 
        ref_gray = im2single(im2gray(refImg)); 
        Rfixed = imref2d(size(ref_gray));
        
        % Initialize cell array for aligned images
        alignedImgs = cell(size(imgs)); 
        alignedImgs{1} = refImg;  % First image doesn't need alignment
        last_tform = affine2d(eye(3));  % Store last successful transform
        
        % Align each subsequent image to the reference
        for k = 2:length(imgs)
            % Check for cancel
            if getappdata(hWait,'canceling')
                close(hWait); 
                return; 
            end
            
            % Update progress
            waitbar((k-1)/length(imgs), hWait, sprintf('Aligning image %d/%d', k, length(imgs)));
            
            % Get current image
            curImg = imgs{k}; 
            cur_gray = im2single(im2gray(curImg));
            
            % Try to align current image to reference
            [tform, success] = alignImagesRobust(ref_gray, cur_gray);
            
            % Use last successful transform if current alignment failed
            if success
                last_tform = tform; 
            else
                tform = last_tform; 
            end
            
            % Apply transform
            alignedImgs{k} = imwarp(curImg, tform, 'OutputView', Rfixed);
        end
        
        % Prompt for output video file
        waitbar(1, hWait, 'Writing video file...');
        [file, path] = uiputfile('timelapse_aligned.mp4', 'Save Video As');
        if isequal(file,0)||isequal(path,0)
            close(hWait); 
            return; 
        end
        
        % Create and configure video writer
        videoName = fullfile(path, file);
        v = VideoWriter(videoName, 'MPEG-4'); 
        v.FrameRate = 10;  % 10 frames per second
        open(v);
        
        % Write each aligned frame to video
        for k = 1:length(alignedImgs)
            if getappdata(hWait,'canceling')
                break; 
            end
            writeVideo(v, alignedImgs{k});
        end
        
        % Clean up
        close(v); 
        close(hWait);
        
        % Show completion message
        msgbox(sprintf('Timelapse video saved to:\n%s', videoName), 'Done');
    end
end