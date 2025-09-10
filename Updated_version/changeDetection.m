function [changeMap, changeMask, stats] = changeDetection(img1, img2, method, params)
    % CHANGEDETECTION - Detect changes between two aligned satellite images
    %
    % Input:
    %   img1   - First image (reference)
    %   img2   - Second image (should be aligned to img1)
    %   method - Detection method ('fusion', 'pixel', 'ssim', 'edge', 'texture', 'spectral')
    %   params - Structure with method-specific parameters
    %
    % Output:
    %   changeMap  - Continuous change probability map [0,1]
    %   changeMask - Binary change mask
    %   stats      - Statistics about the changes detected
    
    if nargin < 3
        method = 'fusion';
    end
    if nargin < 4
        params = struct();
    end
    
    % Ensure images are same size
    if ~isequal(size(img1), size(img2))
        error('Images must be the same size for change detection');
    end
    
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
    
    % Initialize stats
    stats = struct();
    stats.method = method;
    
    switch lower(method)
        case 'fusion'
            [changeMap, changeMask, stats] = fusionDetection(img1, img2, gray1, gray2, params);
        case 'pixel'
            [changeMap, changeMask, stats] = pixelDifference(gray1, gray2, params);
        case 'ssim'
            [changeMap, changeMask, stats] = ssimDetection(gray1, gray2, params);
        case 'edge'
            [changeMap, changeMask, stats] = edgeDetection(gray1, gray2, params);
        case 'texture'
            [changeMap, changeMask, stats] = textureDetection(gray1, gray2, params);
        case 'spectral'
            [changeMap, changeMask, stats] = spectralDetection(img1, img2, params);
        otherwise
            warning('Unknown detection method. Using fusion.');
            [changeMap, changeMask, stats] = fusionDetection(img1, img2, gray1, gray2, params);
    end
    
    % Post-process the change mask
    if isfield(params, 'postProcess') && params.postProcess
        changeMask = postProcessMask(changeMask, params);
    end
    
    % Calculate final statistics
    stats.totalPixels = numel(changeMask);
    stats.changedPixels = sum(changeMask(:));
    stats.changePercentage = 100 * stats.changedPixels / stats.totalPixels;
end

function [changeMap, changeMask, stats] = fusionDetection(img1, img2, gray1, gray2, params)
    % Multi-algorithm fusion for robust change detection
    
    stats = struct();
    stats.method = 'Multi-Algorithm Fusion';
    
    % Get individual change maps
    [pixelMap, ~, ~] = pixelDifference(gray1, gray2, params);
    
    % Initialize fusion map
    fusionMap = pixelMap;
    numMethods = 1;
    
    % Add SSIM if available
    try
        [ssimMap, ~, ~] = ssimDetection(gray1, gray2, params);
        fusionMap = fusionMap + ssimMap;
        numMethods = numMethods + 1;
        stats.usedSSIM = true;
    catch
        stats.usedSSIM = false;
    end
    
    % Add edge detection
    try
        [edgeMap, ~, ~] = edgeDetection(gray1, gray2, params);
        fusionMap = fusionMap + 0.5 * edgeMap;
        numMethods = numMethods + 0.5;
        stats.usedEdge = true;
    catch
        stats.usedEdge = false;
    end
    
    % Add texture detection
    try
        [textureMap, ~, ~] = textureDetection(gray1, gray2, params);
        fusionMap = fusionMap + 0.5 * textureMap;
        numMethods = numMethods + 0.5;
        stats.usedTexture = true;
    catch
        stats.usedTexture = false;
    end
    
    % Normalize fusion map
    changeMap = fusionMap / numMethods;
    changeMap = mat2gray(changeMap);
    
    % Apply adaptive thresholding
    threshold = adaptiveThreshold(changeMap, params);
    changeMask = changeMap > threshold;
    
    stats.threshold = threshold;
    stats.numMethodsFused = numMethods;
end

function [changeMap, changeMask, stats] = pixelDifference(gray1, gray2, params)
    % Simple pixel-wise difference
    
    stats = struct();
    stats.method = 'Pixel Difference';
    
    % Calculate absolute difference
    diffImg = abs(double(gray2) - double(gray1));
    
    % Normalize difference
    changeMap = mat2gray(diffImg);
    
    % Apply threshold
    if isfield(params, 'threshold')
        threshold = params.threshold;
    else
        threshold = graythresh(changeMap);
    end
    
    changeMask = changeMap > threshold;
    
    stats.threshold = threshold;
    stats.meanDifference = mean(diffImg(:));
    stats.stdDifference = std(diffImg(:));
end

function [changeMap, changeMask, stats] = ssimDetection(gray1, gray2, params)
    % Structural Similarity Index based detection
    
    stats = struct();
    stats.method = 'SSIM';
    
    % Calculate SSIM map
    [ssimValue, ssimMap] = ssim(gray1, gray2);
    
    % Convert to change map (1 - similarity = dissimilarity)
    changeMap = 1 - ssimMap;
    changeMap = mat2gray(changeMap);
    
    % Apply threshold
    if isfield(params, 'ssimThreshold')
        threshold = params.ssimThreshold;
    else
        threshold = graythresh(changeMap);
    end
    
    changeMask = changeMap > threshold;
    
    stats.threshold = threshold;
    stats.overallSSIM = ssimValue;
end

function [changeMap, changeMask, stats] = edgeDetection(gray1, gray2, params)
    % Edge-based change detection
    
    stats = struct();
    stats.method = 'Edge Detection';
    
    % Detect edges in both images
    if isfield(params, 'edgeMethod')
        edgeMethod = params.edgeMethod;
    else
        edgeMethod = 'Canny';
    end
    
    edges1 = edge(gray1, edgeMethod);
    edges2 = edge(gray2, edgeMethod);
    
    % Find edge changes
    edgeAdded = edges2 & ~edges1;    % New edges
    edgeRemoved = edges1 & ~edges2;  % Removed edges
    
    % Combine edge changes
    edgeChanges = edgeAdded | edgeRemoved;
    
    % Dilate to create regions around edges
    se = strel('disk', 3);
    changeMap = imdilate(double(edgeChanges), se);
    changeMap = mat2gray(changeMap);
    
    % Apply threshold
    threshold = 0.1; % Lower threshold for edge maps
    changeMask = changeMap > threshold;
    
    stats.threshold = threshold;
    stats.edgesAdded = sum(edgeAdded(:));
    stats.edgesRemoved = sum(edgeRemoved(:));
end

function [changeMap, changeMask, stats] = textureDetection(gray1, gray2, params)
    % Texture-based change detection
    
    stats = struct();
    stats.method = 'Texture Analysis';
    
    % Calculate texture features using standard deviation filter
    if isfield(params, 'windowSize')
        windowSize = params.windowSize;
    else
        windowSize = 7;
    end
    
    % Calculate local standard deviation (texture measure)
    texture1 = stdfilt(gray1, ones(windowSize));
    texture2 = stdfilt(gray2, ones(windowSize));
    
    % Calculate texture difference
    textureDiff = abs(texture2 - texture1);
    
    % Normalize
    changeMap = mat2gray(textureDiff);
    
    % Apply threshold
    if isfield(params, 'textureThreshold')
        threshold = params.textureThreshold;
    else
        threshold = graythresh(changeMap);
    end
    
    changeMask = changeMap > threshold;
    
    stats.threshold = threshold;
    stats.meanTextureChange = mean(textureDiff(:));
end

function [changeMap, changeMask, stats] = spectralDetection(img1, img2, params)
    % Spectral change detection for multispectral images
    
    stats = struct();
    stats.method = 'Spectral Analysis';
    
    numBands = size(img1, 3);
    
    if numBands == 1
        % Fall back to pixel difference for grayscale
        [changeMap, changeMask, stats] = pixelDifference(img1, img2, params);
        return;
    end
    
    % Calculate spectral angle mapper (SAM)
    changeMap = zeros(size(img1, 1), size(img1, 2));
    
    for i = 1:size(img1, 1)
        for j = 1:size(img1, 2)
            vec1 = double(squeeze(img1(i, j, :)));
            vec2 = double(squeeze(img2(i, j, :)));
            
            % Calculate spectral angle
            cosAngle = dot(vec1, vec2) / (norm(vec1) * norm(vec2) + eps);
            angle = acos(min(max(cosAngle, -1), 1));
            changeMap(i, j) = angle;
        end
    end
    
    % Normalize
    changeMap = mat2gray(changeMap);
    
    % Apply threshold
    if isfield(params, 'spectralThreshold')
        threshold = params.spectralThreshold;
    else
        threshold = graythresh(changeMap);
    end
    
    changeMask = changeMap > threshold;
    
    stats.threshold = threshold;
    stats.numBands = numBands;
    stats.meanSpectralAngle = mean(changeMap(:));
end

function threshold = adaptiveThreshold(changeMap, params)
    % Calculate adaptive threshold using Otsu's method or custom method
    
    if isfield(params, 'thresholdMethod')
        switch params.thresholdMethod
            case 'otsu'
                threshold = graythresh(changeMap);
            case 'percentile'
                if isfield(params, 'percentileValue')
                    pct = params.percentileValue;
                else
                    pct = 95;
                end
                threshold = prctile(changeMap(:), pct);
            case 'kmeans'
                % Use k-means with k=2 to find threshold
                values = changeMap(:);
                [idx, C] = kmeans(double(values), 2);
                threshold = mean(C);
            otherwise
                threshold = graythresh(changeMap);
        end
    else
        % Default to Otsu's method
        threshold = graythresh(changeMap);
    end
    
    % Apply bounds to threshold
    threshold = max(0.1, min(0.9, threshold));
end

function mask = postProcessMask(mask, params)
    % Post-process the change mask to remove noise and fill gaps
    
    % Remove small objects
    if isfield(params, 'minArea')
        minArea = params.minArea;
    else
        minArea = 50;
    end
    mask = bwareaopen(mask, minArea);
    
    % Fill holes
    if isfield(params, 'fillHoles') && params.fillHoles
        mask = imfill(mask, 'holes');
    end
    
    % Morphological closing
    if isfield(params, 'closingRadius')
        radius = params.closingRadius;
    else
        radius = 2;
    end
    se = strel('disk', radius);
    mask = imclose(mask, se);
    
    % Morphological opening
    if isfield(params, 'openingRadius')
        radius = params.openingRadius;
    else
        radius = 1;
    end
    se = strel('disk', radius);
    mask = imopen(mask, se);
end
