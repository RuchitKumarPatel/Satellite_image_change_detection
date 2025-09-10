function vizResult = changeVisualization(img1, img2, changeMap, changeMask, method, params)
    % CHANGEVISUALIZATION - Create visualizations of detected changes
    %
    % Input:
    %   img1       - First image
    %   img2       - Second image
    %   changeMap  - Continuous change map
    %   changeMask - Binary change mask
    %   method     - Visualization method
    %   params     - Visualization parameters
    %
    % Output:
    %   vizResult  - Structure containing visualization results
    
    if nargin < 5
        method = 'heatmap';
    end
    if nargin < 6
        params = struct();
    end
    
    vizResult = struct();
    vizResult.method = method;
    
    switch lower(method)
        case 'heatmap'
            vizResult = createHeatmap(changeMap, params);
        case 'overlay'
            vizResult = createOverlay(img2, changeMask, params);
        case 'sidebyside'
            vizResult = createSideBySide(img1, img2, changeMask, params);
        case 'animation'
            vizResult = createAnimation(img1, img2, changeMap, params);
        case 'falsecolor'
            vizResult = createFalseColor(img1, img2, changeMap, params);
        case 'temporal'
            vizResult = createTemporalViz(img1, img2, changeMap, params);
        otherwise
            warning('Unknown visualization method. Using heatmap.');
            vizResult = createHeatmap(changeMap, params);
    end
end

function vizResult = createHeatmap(changeMap, params)
    % Create a heatmap visualization
    
    vizResult = struct();
    vizResult.type = 'heatmap';
    
    % Apply colormap
    if isfield(params, 'colormap')
        cmap = params.colormap;
    else
        cmap = 'jet';
    end
    
    % Scale change map
    scaledMap = mat2gray(changeMap);
    
    % Create figure
    fig = figure('Visible', 'off');
    imagesc(scaledMap);
    colormap(cmap);
    colorbar;
    title('Change Detection Heatmap');
    axis image;
    
    % Store results
    vizResult.figure = fig;
    vizResult.data = scaledMap;
    vizResult.colormap = cmap;
end

function vizResult = createOverlay(img, changeMask, params)
    % Create an overlay visualization
    
    vizResult = struct();
    vizResult.type = 'overlay';
    
    % Set overlay color
    if isfield(params, 'overlayColor')
        overlayColor = params.overlayColor;
    else
        overlayColor = [1, 0, 0]; % Red
    end
    
    % Set transparency
    if isfield(params, 'alpha')
        alpha = params.alpha;
    else
        alpha = 0.5;
    end
    
    % Convert to RGB if needed
    if size(img, 3) == 1
        imgRGB = cat(3, img, img, img);
    else
        imgRGB = img;
    end
    
    % Create overlay
    imgDouble = im2double(imgRGB);
    overlay = imgDouble;
    
    % Apply color to changed regions
    for c = 1:3
        channel = overlay(:,:,c);
        channel(changeMask) = (1-alpha) * channel(changeMask) + alpha * overlayColor(c);
        overlay(:,:,c) = channel;
    end
    
    % Create figure
    fig = figure('Visible', 'off');
    imshow(overlay);
    title('Change Overlay');
    
    % Store results
    vizResult.figure = fig;
    vizResult.data = overlay;
    vizResult.overlayColor = overlayColor;
    vizResult.alpha = alpha;
end

function vizResult = createSideBySide(img1, img2, changeMask, params)
    % Create side-by-side comparison
    
    vizResult = struct();
    vizResult.type = 'sidebyside';
    
    % Create figure with subplots
    fig = figure('Visible', 'off');
    
    subplot(1,3,1);
    imshow(img1);
    title('Before');
    
    subplot(1,3,2);
    imshow(img2);
    title('After');
    
    subplot(1,3,3);
    imshow(changeMask);
    title('Changes');
    
    % Store results
    vizResult.figure = fig;
    vizResult.images = {img1, img2, changeMask};
end

function vizResult = createAnimation(img1, img2, changeMap, params)
    % Create an animated transition
    
    vizResult = struct();
    vizResult.type = 'animation';
    
    % Number of frames
    if isfield(params, 'numFrames')
        numFrames = params.numFrames;
    else
        numFrames = 20;
    end
    
    % Create frames
    frames = cell(numFrames, 1);
    
    for i = 1:numFrames
        alpha = (i-1) / (numFrames-1);
        frame = (1-alpha) * im2double(img1) + alpha * im2double(img2);
        frames{i} = im2uint8(frame);
    end
    
    % Store results
    vizResult.frames = frames;
    vizResult.numFrames = numFrames;
end

function vizResult = createFalseColor(img1, img2, changeMap, params)
    % Create false color composite
    
    vizResult = struct();
    vizResult.type = 'falsecolor';
    
    % Convert to grayscale if needed
    if size(img1, 3) > 1
        gray1 = rgb2gray(img1);
    else
        gray1 = img1;
    end
    
    if size(img2, 3) > 1
        gray2 = rgb2gray(img2);
    else
        gray2 = img2;
    end
    
    % Create RGB composite
    % R: Image 2, G: Image 1, B: Change Map
    falseColor = cat(3, ...
                     mat2gray(gray2), ...
                     mat2gray(gray1), ...
                     mat2gray(changeMap));
    
    % Create figure
    fig = figure('Visible', 'off');
    imshow(falseColor);
    title('False Color Composite (R: After, G: Before, B: Changes)');
    
    % Store results
    vizResult.figure = fig;
    vizResult.data = falseColor;
end

function vizResult = createTemporalViz(img1, img2, changeMap, params)
    % Create temporal change visualization
    
    vizResult = struct();
    vizResult.type = 'temporal';
    
    % Calculate temporal statistics
    if size(img1, 3) > 1
        gray1 = rgb2gray(img1);
        gray2 = rgb2gray(img2);
    else
        gray1 = img1;
        gray2 = img2;
    end
    
    % Difference image
    diffImg = double(gray2) - double(gray1);
    
    % Separate positive and negative changes
    increaseMap = max(diffImg, 0);
    decreaseMap = max(-diffImg, 0);
    
    % Normalize
    increaseMap = mat2gray(increaseMap);
    decreaseMap = mat2gray(decreaseMap);
    
    % Create visualization
    temporalViz = cat(3, decreaseMap, zeros(size(diffImg)), increaseMap);
    
    % Create figure
    fig = figure('Visible', 'off');
    imshow(temporalViz);
    title('Temporal Changes (Red: Decrease, Blue: Increase)');
    
    % Store results
    vizResult.figure = fig;
    vizResult.data = temporalViz;
    vizResult.increaseMap = increaseMap;
    vizResult.decreaseMap = decreaseMap;
end
