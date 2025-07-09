function cv_challenge()
    % This function creates a more user-friendly GUI for advanced image alignment and timelapse creation.
    % REQUIRES: MATLAB and the Computer Vision Toolbox.
    
    % --- Main Figure Window Setup ---
    fig = figure('Name', 'Computer Vision Challenge', ...
        'Position', [100 100 1200 700], ... % [x,y,width,height]
        'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off', ...
        'Color', [0.94 0.94 0.94]);

    % --- UI Panels for Organization ---
    panelControl = uipanel('Parent', fig, 'Title', '1. Load & Select', ...
        'FontSize', 11, 'FontWeight', 'bold', 'Position', [0.02 0.78 0.96 0.20]);
        
    panelView = uipanel('Parent', fig, 'Title', '2. Align & View', ...
        'FontSize', 11, 'FontWeight', 'bold', 'Position', [0.25 0.05 0.5 0.71]);

    % --- Image Display Axes ---
    axImg1 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.02 0.35 0.21 0.35]);
    title(axImg1, 'Image 1'); axis(axImg1, 'off');

    axImg2 = axes('Parent', fig, 'Units', 'normalized', 'Position', [0.77 0.35 0.21 0.35]);
    title(axImg2, 'Image 2'); axis(axImg2, 'off');

    axResult = axes('Parent', panelView, 'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.85]);
    title(axResult, 'Load a folder to begin'); axis(axResult, 'off');

    % --- Control Buttons (Top Panel) ---
    btnLoadFolder = uicontrol('Parent', panelControl, 'Style', 'pushbutton', 'String', 'Load Image Folder', ...
        'Units', 'normalized', 'Position', [0.02 0.2 0.15 0.6], 'FontSize', 10, ...
        'Callback', @loadFolderCallback);

    btnAlign = uicontrol('Parent', panelControl, 'Style', 'pushbutton', 'String', 'Align Selected Images', ...
        'Units', 'normalized', 'Position', [0.20 0.2 0.18 0.6], 'FontSize', 10, ...
        'Callback', @alignCallback, 'Enable', 'off');

    btnNextDisplay = uicontrol('Parent', panelControl, 'Style', 'pushbutton', 'String', 'Next Display Mode', ...
        'Units', 'normalized', 'Position', [0.41 0.2 0.18 0.6], 'FontSize', 10, ...
        'Callback', @nextDisplayCallback, 'Enable', 'off');

    btnTimelapse = uicontrol('Parent', panelControl, 'Style', 'pushbutton', 'String', 'Create Timelapse Video', ...
        'Units', 'normalized', 'Position', [0.62 0.2 0.18 0.6], 'FontSize', 10, ...
        'Callback', @timelapseCallback, 'Enable', 'off');
        
    % --- Image Selection Controls ---
    uicontrol('Style', 'text', 'String', 'Select Image 1:', 'Units', 'normalized', ...
        'Position', [0.02 0.28 0.21 0.05], 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    btnUp1 = uicontrol('Style', 'pushbutton', 'String', '▲', 'FontSize', 12, ...
        'Units', 'normalized', 'Position', [0.02 0.23 0.1 0.05], ...
        'Callback', {@buttonCallback, -1, 1}, 'Enable', 'off');
    btnDown1 = uicontrol('Style', 'pushbutton', 'String', '▼', 'FontSize', 12, ...
        'Units', 'normalized', 'Position', [0.13 0.23 0.1 0.05], ...
        'Callback', {@buttonCallback, 1, 1}, 'Enable', 'off');
    label1 = uicontrol('Style', 'text', 'String', '...', 'Units', 'normalized', ...
        'Position', [0.02 0.17 0.21 0.05], 'FontSize', 9);

    uicontrol('Style', 'text', 'String', 'Select Image 2:', 'Units', 'normalized', ...
        'Position', [0.77 0.28 0.21 0.05], 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    btnUp2 = uicontrol('Style', 'pushbutton', 'String', '▲', 'FontSize', 12, ...
        'Units', 'normalized', 'Position', [0.77 0.23 0.1 0.05], ...
        'Callback', {@buttonCallback, -1, 2}, 'Enable', 'off');
    btnDown2 = uicontrol('Style', 'pushbutton', 'String', '▼', 'FontSize', 12, ...
        'Units', 'normalized', 'Position', [0.88 0.23 0.1 0.05], ...
        'Callback', {@buttonCallback, 1, 2}, 'Enable', 'off');
    label2 = uicontrol('Style', 'text', 'String', '...', 'Units', 'normalized', ...
        'Position', [0.77 0.17 0.21 0.05], 'FontSize', 9);
    
    overlaySlider = uicontrol('Style', 'slider', 'Units', 'normalized', ...
        'Position', [0.35 0.06 0.3 0.04], 'Min', 0, 'Max', 1, 'Value', 0.5, ...
        'Callback', @overlaySliderChanged, 'Visible', 'off');
    labelOverlay1 = uicontrol('Style','text','Units','normalized',...
        'Position',[0.30 0.06 0.05 0.04],'String','Img 1','Visible','off');
    labelOverlay2 = uicontrol('Style','text','Units','normalized',...
        'Position',[0.65 0.06 0.05 0.04],'String','Img 2','Visible','off');

    % --- Application State Variables ---
    imgs = {}; imgFiles = {}; img1 = []; img2 = []; img2_aligned = [];
    folderPath = ''; idx1 = 1; idx2 = 1; numImgs = 0; displayMode = 1;
    
    % --- Callback Functions ---
    function loadFolderCallback(~,~)
        folder = uigetdir();
        if folder == 0, return; end
        folderPath = folder;
        
        exts = {'*.png','*.jpg','*.jpeg','*.bmp','*.tif','*.tiff'};
        files = [];
        for e = 1:length(exts), files = [files; dir(fullfile(folder, exts{e}))]; end
        
        if ~isempty(files)
            [~, sortOrder] = sort({files.name});
            files = files(sortOrder);
        end
        if isempty(files), errordlg('No images found in folder!','Error'); return; end
        
        hWait = waitbar(0, 'Loading images...', 'Name', 'Loading');
        numImgs = length(files);
        imgs = cell(numImgs,1); imgFiles = cell(numImgs,1);
        
        for k=1:numImgs
            waitbar(k/numImgs, hWait, sprintf('Loading %s', files(k).name));
            imgFiles{k} = files(k).name;
            imgs{k} = imread(fullfile(folder, files(k).name));
        end
        close(hWait);
        
        set([btnUp1, btnDown1, btnUp2, btnDown2, btnAlign, btnTimelapse], 'Enable', 'on');
        set(overlaySlider,'Visible','off'); set([labelOverlay1, labelOverlay2],'Visible','off');
        
        idx1 = 1; 
        idx2 = min(2, numImgs);
        if numImgs == 1, idx2 = 1; end
        updateImageSelection();
    end

    % --- Button Callback Function ---
    function buttonCallback(~, ~, direction, panel)
        % This function calculates the next index.
        if panel == 1
            new_idx = idx1 + direction;
        else % panel == 2
            new_idx = idx2 + direction;
        end
        
        % Handle wrap-around (from last to first image and vice-versa)
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
            idx1 = new_idx;
        else
            idx2 = new_idx;
        end
        
        updateImageSelection();
    end

    function updateImageSelection()
        if isempty(imgs), return; end
    
        img1 = imgs{idx1}; 
        img2 = imgs{idx2};
    
        imshow(img1, 'Parent', axImg1); title(axImg1, 'Image 1');
        imshow(img2, 'Parent', axImg2); title(axImg2, 'Image 2');
        set(label1, 'String', imgFiles{idx1});
        set(label2, 'String', imgFiles{idx2});
    
        img2_aligned = [];
        btnNextDisplay.Enable = 'off';
        set(overlaySlider,'Visible','off'); 
        set([labelOverlay1, labelOverlay2],'Visible','off');
        displayMode = 1;
        
        cla(axResult);
        title(axResult, 'Select two different images and press "Align"');
        axis(axResult, 'off');
    end

    function overlaySliderChanged(~,~), showDisplay(); end
    
    function [tform, success] = alignImagesRobust(imgFixed, imgMoving)
        tform = affine2d(eye(3)); 
        success = false;
        
        % Method 1: Feature-Based (SURF)
        try 
            pointsFixed = detectSURFFeatures(imgFixed, 'MetricThreshold', 500);
            pointsMoving = detectSURFFeatures(imgMoving, 'MetricThreshold', 500);
            if pointsFixed.Count < 10 || pointsMoving.Count < 10, error('Not enough features.'); end
            
            [featuresFixed, validPtsFixed] = extractFeatures(imgFixed, pointsFixed);
            [featuresMoving, validPtsMoving] = extractFeatures(imgMoving, pointsMoving);
            
            indexPairs = matchFeatures(featuresFixed, featuresMoving, 'Unique', true, 'MaxRatio', 0.6);
            
            matchedMoving = validPtsMoving(indexPairs(:,1));
            matchedFixed = validPtsFixed(indexPairs(:,2));
            
            if matchedMoving.Count < 4, error('Not enough matches.'); end
            
            [tform_cand, ~] = estimateGeometricTransform2D(matchedMoving, matchedFixed, 'rigid', ...
                'MaxNumTrials', 2000, 'MaxDistance', 2.5);
            
            if abs(det(tform_cand.T) - 1.0) > 0.05, error('Transform not rigid.'); end
            
            tform = tform_cand; success = true; disp('Alignment: Feature-based OK.'); return;
        catch ME
            warning('Feature-based alignment failed: %s. Trying intensity-based method.', ME.message);
        end
        
        try 
            [optimizer, metric] = imregconfig('monomodal');
            optimizer.MaximumIterations = 300;
            tform_cand = imregtform(imgMoving, imgFixed, 'rigid', optimizer, metric);
            if abs(det(tform_cand.T) - 1.0) > 0.05, error('Transform not rigid.'); end
            tform = tform_cand; success = true; disp('Alignment: Intensity-based OK.');
        catch ME
            warning('Intensity-based alignment also failed: %s.', ME.message);
            tform = affine2d(eye(3)); success = false;
        end
    end

    function alignCallback(~,~)
        if isempty(img1) || isempty(img2) || idx1 == idx2
            errordlg('Select two different images!','Error'); return; 
        end
        
        hWait = waitbar(0.5, 'Aligning images...', 'Name', 'Aligning');
        img1_gray = im2single(im2gray(img1)); 
        img2_gray = im2single(im2gray(img2));
        
        [tform, success] = alignImagesRobust(img1_gray, img2_gray);
        close(hWait);
        
        if ~success, msgbox('Image alignment failed.', 'Error', 'error'); return; end
        
        Rfixed = imref2d(size(img1_gray));
        img2_aligned = imwarp(img2, tform, 'OutputView', Rfixed);
        
        displayMode = 1;
        btnNextDisplay.Enable = 'on';
        showDisplay();
    end

    function nextDisplayCallback(~,~)
        displayMode = mod(displayMode, 4) + 1; 
        showDisplay(); 
    end

    function showDisplay()
        cla(axResult); axis(axResult, 'on');
        set(overlaySlider,'Visible','off'); set([labelOverlay1, labelOverlay2],'Visible','off'); 
        
        switch displayMode
            case 1 % Show side-by-side original images
                imshowpair(img1, img2, 'montage', 'Parent', axResult);
                title(axResult, sprintf('Original Images: %s (Left) vs %s (Right)', imgFiles{idx1}, imgFiles{idx2}));
                
            case 2 % Show matched features
                gray1 = im2single(im2gray(img1)); gray2 = im2single(im2gray(img2));
                points1 = detectSURFFeatures(gray1); points2 = detectSURFFeatures(gray2);
                [features1, validPts1] = extractFeatures(gray1, points1);
                [features2, validPts2] = extractFeatures(gray2, points2);
                indexPairs = matchFeatures(features1, features2, 'Unique', true, 'MaxRatio', 0.6);
                
                if size(indexPairs, 1) < 4
                    title(axResult, 'Could not find enough matching features.');
                    imshowpair(img1, img2, 'montage', 'Parent', axResult);
                else
                    matched1 = validPts1(indexPairs(:,1));
                    matched2 = validPts2(indexPairs(:,2));
                    showMatchedFeatures(img1, img2, matched1, matched2, 'montage', 'Parent', axResult);
                    title(axResult, sprintf('Matched Features from SURF (%d) between %s and %s', ...
                        size(indexPairs,1), imgFiles{idx1}, imgFiles{idx2}));
                end

            case 3 % Show Overlay of aligned images
                if isempty(img2_aligned)
                    msgbox('Align images first.','Info'); displayMode=1; showDisplay(); return; 
                end
                set(overlaySlider,'Visible','on'); set([labelOverlay1, labelOverlay2],'Visible','on');
                alpha = get(overlaySlider, 'Value');
                blendedImg = imadd(im2double(img1) * (1-alpha), im2double(img2_aligned) * alpha);
                imshow(blendedImg, 'Parent', axResult);
                title(axResult, sprintf('Aligned Overlay (%.0f%% / %.0f%%)', (1-alpha)*100, alpha*100));
                
            case 4 % Show Difference heatmap
                if isempty(img2_aligned)
                    msgbox('Align images first.','Info'); displayMode=1; showDisplay(); return; 
                end
                diffImg = imabsdiff(im2single(img1), im2single(img2_aligned));
                diffGray = im2gray(diffImg);
                imshow(diffGray, 'Parent', axResult);
                colormap(axResult, 'hot'); colorbar(axResult);
                title(axResult, 'Difference Heatmap');
        end
        axis(axResult, 'off');
    end


    function timelapseCallback(~,~)
        if isempty(imgs), errordlg('Load a folder first!', 'Error'); return; end
    
        [file, path] = uiputfile('timelapse_aligned.mp4', 'Save Video As');
        if isequal(file, 0), return; end
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
    
            [tform, success] = alignImagesRobust(ref_gray, cur_gray);
            
            if success
                last_tform = tform;
            else
                tform = last_tform; 
            end
    
            alignedImgs{k} = imwarp(curImg, tform, 'OutputView', Rfixed);
        end
    
        if getappdata(hWait, 'canceling')
            delete(hWait); msgbox('Timelapse creation canceled.', 'Canceled', 'warn'); return;
        end
    
        waitbar(1, hWait, 'Writing video file...');
        try
            v = VideoWriter(videoName, 'MPEG-4'); v.FrameRate = 10;
            open(v);
            for k = 1:numel(alignedImgs)
                if getappdata(hWait,'canceling'), break; end

                writeVideo(v, im2uint8(alignedImgs{k})); 
            end
            close(v);
        catch ME
            delete(hWait); errordlg(['Failed to save video: ' ME.message], 'Error'); return;
        end
    
        delete(hWait);
        msgbox(sprintf('Timelapse video saved to:\n%s', videoName), 'Done');
    end
end
