function imageCallbacks()
    % IMAGECALLBACKS - Collection of callback functions for image operations
    % This function returns a structure of function handles
end

function selectImageFolder(fig)
    % Callback for selecting image folder
    
    folder = uigetdir(pwd, 'Select folder with satellite images');
    
    if folder ~= 0
        appData = getappdata(fig, 'AppData');
        appData.currentFolder = folder;
        setappdata(fig, 'AppData', appData);
        
        % Update status
        updateStatusLog(fig, sprintf('Selected folder: %s', folder));
        
        % Find images in folder
        imageFiles = findImageFiles(folder);
        updateStatusLog(fig, sprintf('Found %d image files', length(imageFiles)));
        
        % Enable load button
        set(findobj(fig, 'Tag', 'loadImagesBtn'), 'Enable', 'on');
    end
end

function loadImages(fig)
    % Callback for loading images
    
    appData = getappdata(fig, 'AppData');
    folder = appData.currentFolder;
    
    if isempty(folder)
        errordlg('Please select a folder first', 'No Folder Selected');
        return;
    end
    
    updateStatusLog(fig, 'Loading images...');
    
    % Find and load images
    imageFiles = findImageFiles(folder);
    
    if isempty(imageFiles)
        errordlg('No images found in selected folder', 'No Images');
        return;
    end
    
    loadedImages = {};
    imageMetadata = {};
    
    for i = 1:length(imageFiles)
        try
            imgPath = fullfile(folder, imageFiles(i).name);
            img = imread(imgPath);
            
            % Store metadata
            metadata.filename = imageFiles(i).name;
            metadata.size = size(img);
            metadata.type = class(img);
            
            loadedImages{i} = img;
            imageMetadata{i} = metadata;
            
            updateStatusLog(fig, sprintf('Loaded: %s', imageFiles(i).name));
        catch ME
            updateStatusLog(fig, sprintf('Error loading %s: %s', ...
                                       imageFiles(i).name, ME.message));
        end
    end
    
    % Update app data
    appData.images = imageFiles;
    appData.loadedImages = loadedImages;
    appData.imageMetadata = imageMetadata;
    setappdata(fig, 'AppData', appData);
    
    % Update UI
    updateImageSelectors(fig);
    
    % Enable preprocessing button
    set(findobj(fig, 'Tag', 'preprocessBtn'), 'Enable', 'on');
    
    updateStatusLog(fig, sprintf('Successfully loaded %d images', length(loadedImages)));
end

function preprocessImages(fig)
    % Callback for preprocessing images
    
    appData = getappdata(fig, 'AppData');
    
    if isempty(appData.loadedImages)
        errordlg('No images loaded', 'No Images');
        return;
    end
    
    updateStatusLog(fig, 'Preprocessing images...');
    
    preprocessedImages = {};
    
    % Preprocess each image
    for i = 1:length(appData.loadedImages)
        img = appData.loadedImages{i};
        
        % Call preprocessing function
        params = struct('clipLimit', 0.02, 'stretchLimits', [0.01 0.99]);
        preprocessedImg = imagePreprocessing(img, 'auto', params);
        
        preprocessedImages{i} = preprocessedImg;
        
        updateStatusLog(fig, sprintf('Preprocessed image %d/%d', ...
                                    i, length(appData.loadedImages)));
    end
    
    % Update app data
    appData.preprocessedImages = preprocessedImages;
    setappdata(fig, 'AppData', appData);
    
    % Display current pair
    displayCurrentPair(fig);
    
    % Enable alignment button
    set(findobj(fig, 'Tag', 'alignBtn'), 'Enable', 'on');
    
    updateStatusLog(fig, 'Preprocessing complete');
end

function alignImages(fig)
    % Callback for aligning images
    
    appData = getappdata(fig, 'AppData');
    
    if isempty(appData.preprocessedImages) || length(appData.preprocessedImages) < 2
        errordlg('Need at least 2 preprocessed images', 'Insufficient Images');
        return;
    end
    
    % Get current image pair
    idx1 = appData.currentImagePair(1);
    idx2 = appData.currentImagePair(2);
    
    img1 = appData.preprocessedImages{idx1};
    img2 = appData.preprocessedImages{idx2};
    
    updateStatusLog(fig, 'Aligning images...');
    
    % Perform alignment
    params = struct();
    [alignedImg, tform, stats] = featureAlignment(img1, img2, 'auto', params);
    
    if stats.success
        % Store aligned images
        appData.alignedImages = {img1, alignedImg};
        appData.registrationData = stats;
        setappdata(fig, 'AppData', appData);
        
        % Display results
        displayAlignmentResults(fig, alignedImg, stats);
        
        % Enable change detection
        set(findobj(fig, 'Tag', 'detectBtn'), 'Enable', 'on');
        
        updateStatusLog(fig, sprintf('Alignment successful using %s', stats.method));
    else
        errordlg('Alignment failed', 'Alignment Error');
        updateStatusLog(fig, 'Alignment failed');
    end
end

function detectChanges(fig)
    % Callback for change detection
    
    appData = getappdata(fig, 'AppData');
    
    if isempty(appData.alignedImages)
        errordlg('Please align images first', 'No Aligned Images');
        return;
    end
    
    img1 = appData.alignedImages{1};
    img2 = appData.alignedImages{2};
    
    % Get selected algorithm
    algorithmSelector = findobj(fig, 'Tag', 'algorithmSelector');
    algorithms = get(algorithmSelector, 'String');
    selectedIdx = get(algorithmSelector, 'Value');
    selectedAlgorithm = algorithms{selectedIdx};
    
    % Map algorithm name to method
    switch selectedAlgorithm
        case 'Multi-Algorithm Fusion'
            method = 'fusion';
        case 'Pixel Difference'
            method = 'pixel';
        case 'SSIM-based'
            method = 'ssim';
        case 'Edge Detection'
            method = 'edge';
        case 'Texture Analysis'
            method = 'texture';
        case 'Spectral Analysis'
            method = 'spectral';
        otherwise
            method = 'fusion';
    end
    
    updateStatusLog(fig, sprintf('Detecting changes using %s...', selectedAlgorithm));
    
    % Perform change detection
    params = struct('postProcess', true);
    [changeMap, changeMask, stats] = changeDetection(img1, img2, method, params);
    
    % Store results
    appData.changeData = struct('changeMap', changeMap, ...
                                'changeMask', changeMask, ...
                                'stats', stats);
    setappdata(fig, 'AppData', appData);
    
    % Display results
    displayChangeResults(fig, changeMap, changeMask, stats);
    
    % Enable export
    set(findobj(fig, 'Tag', 'exportBtn'), 'Enable', 'on');
    
    updateStatusLog(fig, sprintf('Change detection complete: %.2f%% changed', ...
                                stats.changePercentage));
end

function exportResults(fig)
    % Callback for exporting results
    
    appData = getappdata(fig, 'AppData');
    
    if isempty(appData.changeData)
        errordlg('No results to export', 'No Results');
        return;
    end
    
    [filename, pathname] = uiputfile({'*.mat', 'MATLAB Data'; ...
                                      '*.png', 'PNG Image'; ...
                                      '*.tif', 'TIFF Image'; ...
                                      '*.pdf', 'PDF Report'}, ...
                                     'Export Results');
    
    if isequal(filename, 0)
        return;
    end
    
    fullPath = fullfile(pathname, filename);
    [~, ~, ext] = fileparts(fullPath);
    
    switch lower(ext)
        case '.mat'
            % Export all data
            changeData = appData.changeData;
            registrationData = appData.registrationData;
            save(fullPath, 'changeData', 'registrationData');
            
        case {'.png', '.tif'}
            % Export change mask as image
            imwrite(appData.changeData.changeMask, fullPath);
            
        case '.pdf'
            % Generate PDF report
            generateReport(fig, fullPath);
            
        otherwise
            errordlg('Unsupported file format', 'Export Error');
            return;
    end
    
    updateStatusLog(fig, sprintf('Results exported to: %s', fullPath));
end

function updateImagePair(fig, imageIndex)
    % Callback for updating image pair selection
    
    appData = getappdata(fig, 'AppData');
    
    if imageIndex == 1
        selector = findobj(fig, 'Tag', 'image1Selector');
    else
        selector = findobj(fig, 'Tag', 'image2Selector');
    end
    
    selectedIdx = get(selector, 'Value');
    appData.currentImagePair(imageIndex) = selectedIdx;
    setappdata(fig, 'AppData', appData);
    
    % Display updated pair
    displayCurrentPair(fig);
end

% Helper functions

function imageFiles = findImageFiles(folder)
    % Find all image files in folder
    
    extensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', ...
                  '*.tif', '*.tiff', '*.jp2', '*.hdf'};
    imageFiles = [];
    
    for i = 1:length(extensions)
        files = dir(fullfile(folder, extensions{i}));
        imageFiles = [imageFiles; files];
    end
    
    % Sort by name
    if ~isempty(imageFiles)
        [~, idx] = sort({imageFiles.name});
        imageFiles = imageFiles(idx);
    end
end

function updateImageSelectors(fig)
    % Update image selector dropdowns
    
    appData = getappdata(fig, 'AppData');
    
    if isempty(appData.images)
        return;
    end
    
    % Create list of image names
    imageNames = {appData.images.name};
    
    % Update selectors
    selector1 = findobj(fig, 'Tag', 'image1Selector');
    selector2 = findobj(fig, 'Tag', 'image2Selector');
    
    set(selector1, 'String', imageNames, 'Value', 1);
    set(selector2, 'String', imageNames, 'Value', min(2, length(imageNames)));
    
    % Update current pair
    appData.currentImagePair = [1, min(2, length(imageNames))];
    setappdata(fig, 'AppData', appData);
end

function displayCurrentPair(fig)
    % Display current image pair
    
    appData = getappdata(fig, 'AppData');
    
    if isempty(appData.preprocessedImages)
        if isempty(appData.loadedImages)
            return;
        end
        images = appData.loadedImages;
    else
        images = appData.preprocessedImages;
    end
    
    idx1 = appData.currentImagePair(1);
    idx2 = appData.currentImagePair(2);
    
    % Display images
    axes(appData.axes.img1);
    imshow(images{idx1});
    title(sprintf('Image 1: %s', appData.images(idx1).name), 'Interpreter', 'none');
    
    axes(appData.axes.img2);
    imshow(images{idx2});
    title(sprintf('Image 2: %s', appData.images(idx2).name), 'Interpreter', 'none');
end

function displayAlignmentResults(fig, alignedImg, stats)
    % Display alignment results
    
    appData = getappdata(fig, 'AppData');
    
    % Display aligned image
    axes(appData.axes.results);
    imshow(alignedImg);
    title('Aligned Image 2');
    
    % Update statistics text
    statsText = findobj(fig, 'Tag', 'statsText');
    statsStr = sprintf(['Alignment Statistics:\n', ...
                       'Method: %s\n', ...
                       'Success: %s\n'], ...
                       stats.method, ...
                       mat2str(stats.success));
    
    if isfield(stats, 'numInliers')
        statsStr = [statsStr, sprintf('Inliers: %d/%d\n', ...
                                     stats.numInliers, stats.numMatches)];
    end
    
    set(statsText, 'String', statsStr);
end

function displayChangeResults(fig, changeMap, changeMask, stats)
    % Display change detection results
    
    appData = getappdata(fig, 'AppData');
    
    % Display change map
    axes(appData.axes.results);
    imagesc(changeMap);
    colormap(jet);
    colorbar;
    title('Change Map');
    
    % Display visualization
    axes(appData.axes.visualization);
    imshow(changeMask);
    title('Change Mask');
    
    % Update statistics
    statsText = findobj(fig, 'Tag', 'statsText');
    statsStr = sprintf(['Change Detection Statistics:\n', ...
                       'Method: %s\n', ...
                       'Changed Pixels: %d\n', ...
                       'Change Percentage: %.2f%%\n', ...
                       'Threshold: %.3f'], ...
                       stats.method, ...
                       stats.changedPixels, ...
                       stats.changePercentage, ...
                       stats.threshold);
    set(statsText, 'String', statsStr);
end

function updateStatusLog(fig, message)
    % Update status log
    
    statusLog = findobj(fig, 'Tag', 'statusLog');
    currentMessages = get(statusLog, 'String');
    
    % Add timestamp
    timestamp = datestr(now, 'HH:MM:SS');
    newMessage = sprintf('[%s] %s', timestamp, message);
    
    % Add to log
    if iscell(currentMessages)
        currentMessages = [currentMessages; {newMessage}];
    else
        currentMessages = {currentMessages; newMessage};
    end
    
    % Limit to last 50 messages
    if length(currentMessages) > 50
        currentMessages = currentMessages(end-49:end);
    end
    
    set(statusLog, 'String', currentMessages, 'Value', length(currentMessages));
end
