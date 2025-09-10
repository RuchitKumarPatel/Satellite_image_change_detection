function [alignedImg, tform, stats] = featureAlignment(img1, img2, method, params)
    % FEATUREALIGNMENT - Align satellite images using feature-based methods
    %
    % Input:
    %   img1   - Reference image
    %   img2   - Image to be aligned
    %   method - Alignment method ('auto', 'surf', 'orb', 'harris', 'sift', 'intensity')
    %   params - Structure with method-specific parameters
    %
    % Output:
    %   alignedImg - Aligned version of img2
    %   tform      - Geometric transformation
    %   stats      - Statistics about the alignment process
    
    if nargin < 3
        method = 'auto';
    end
    if nargin < 4
        params = struct();
    end
    
    % Convert to grayscale for feature detection
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
    stats.success = false;
    
    switch lower(method)
        case 'auto'
            [alignedImg, tform, stats] = autoAlign(img1, img2, gray1, gray2, params);
        case 'surf'
            [alignedImg, tform, stats] = surfAlign(img1, img2, gray1, gray2, params);
        case 'orb'
            [alignedImg, tform, stats] = orbAlign(img1, img2, gray1, gray2, params);
        case 'harris'
            [alignedImg, tform, stats] = harrisAlign(img1, img2, gray1, gray2, params);
        case 'sift'
            [alignedImg, tform, stats] = siftAlign(img1, img2, gray1, gray2, params);
        case 'intensity'
            [alignedImg, tform, stats] = intensityAlign(img1, img2, gray1, gray2, params);
        otherwise
            warning('Unknown alignment method. Using auto.');
            [alignedImg, tform, stats] = autoAlign(img1, img2, gray1, gray2, params);
    end
end

function [alignedImg, tform, stats] = autoAlign(img1, img2, gray1, gray2, params)
    % Try multiple methods automatically
    
    methods = {'surf', 'orb', 'harris', 'intensity'};
    
    for i = 1:length(methods)
        try
            fprintf('Trying %s alignment...\n', upper(methods{i}));
            
            switch methods{i}
                case 'surf'
                    [alignedImg, tform, stats] = surfAlign(img1, img2, gray1, gray2, params);
                case 'orb'
                    [alignedImg, tform, stats] = orbAlign(img1, img2, gray1, gray2, params);
                case 'harris'
                    [alignedImg, tform, stats] = harrisAlign(img1, img2, gray1, gray2, params);
                case 'intensity'
                    [alignedImg, tform, stats] = intensityAlign(img1, img2, gray1, gray2, params);
            end
            
            if stats.success
                stats.method = ['auto-' methods{i}];
                fprintf('Successfully aligned using %s\n', upper(methods{i}));
                return;
            end
        catch
            continue;
        end
    end
    
    % If all methods fail, return original image
    warning('All alignment methods failed. Returning original image.');
    alignedImg = img2;
    tform = affine2d(eye(3));
    stats.success = false;
end

function [alignedImg, tform, stats] = surfAlign(img1, img2, gray1, gray2, params)
    % SURF feature-based alignment
    
    stats = struct();
    stats.method = 'SURF';
    
    % Set default parameters
    if ~isfield(params, 'metricThreshold')
        params.metricThreshold = 100;
    end
    if ~isfield(params, 'numOctaves')
        params.numOctaves = 4;
    end
    
    % Detect SURF features
    points1 = detectSURFFeatures(gray1, ...
                                 'MetricThreshold', params.metricThreshold, ...
                                 'NumOctaves', params.numOctaves);
    points2 = detectSURFFeatures(gray2, ...
                                 'MetricThreshold', params.metricThreshold, ...
                                 'NumOctaves', params.numOctaves);
    
    stats.numPoints1 = points1.Count;
    stats.numPoints2 = points2.Count;
    
    if points1.Count < 20 || points2.Count < 20
        error('Insufficient SURF features detected');
    end
    
    % Extract features
    [features1, validPoints1] = extractFeatures(gray1, points1);
    [features2, validPoints2] = extractFeatures(gray2, points2);
    
    % Match features
    indexPairs = matchFeatures(features1, features2, ...
                               'Unique', true, ...
                               'MaxRatio', 0.7, ...
                               'MatchThreshold', 10);
    
    stats.numMatches = size(indexPairs, 1);
    
    if size(indexPairs, 1) < 4
        error('Insufficient feature matches');
    end
    
    matchedPoints1 = validPoints1(indexPairs(:,1));
    matchedPoints2 = validPoints2(indexPairs(:,2));
    
    % Estimate transformation
    [tform, inlierIdx] = estimateGeometricTransform2D(matchedPoints2, matchedPoints1, ...
                                                      'affine', ...
                                                      'MaxNumTrials', 3000, ...
                                                      'MaxDistance', 3, ...
                                                      'Confidence', 99.9);
    
    stats.numInliers = sum(inlierIdx);
    stats.inlierRatio = stats.numInliers / stats.numMatches;
    stats.matchedPoints1 = matchedPoints1;
    stats.matchedPoints2 = matchedPoints2;
    stats.inlierIdx = inlierIdx;
    
    % Apply transformation
    alignedImg = imwarp(img2, tform, 'OutputView', imref2d(size(img1)));
    stats.success = true;
end

function [alignedImg, tform, stats] = orbAlign(img1, img2, gray1, gray2, params)
    % ORB feature-based alignment
    
    stats = struct();
    stats.method = 'ORB';
    
    % Set default parameters
    if ~isfield(params, 'scaleFactor')
        params.scaleFactor = 1.2;
    end
    if ~isfield(params, 'numLevels')
        params.numLevels = 8;
    end
    
    % Detect ORB features
    points1 = detectORBFeatures(gray1, ...
                               'ScaleFactor', params.scaleFactor, ...
                               'NumLevels', params.numLevels);
    points2 = detectORBFeatures(gray2, ...
                               'ScaleFactor', params.scaleFactor, ...
                               'NumLevels', params.numLevels);
    
    stats.numPoints1 = points1.Count;
    stats.numPoints2 = points2.Count;
    
    if points1.Count < 20 || points2.Count < 20
        error('Insufficient ORB features detected');
    end
    
    % Extract features
    [features1, validPoints1] = extractFeatures(gray1, points1);
    [features2, validPoints2] = extractFeatures(gray2, points2);
    
    % Match features
    indexPairs = matchFeatures(features1, features2, ...
                               'Unique', true, ...
                               'MaxRatio', 0.8, ...
                               'MatchThreshold', 40);
    
    stats.numMatches = size(indexPairs, 1);
    
    if size(indexPairs, 1) < 4
        error('Insufficient feature matches');
    end
    
    matchedPoints1 = validPoints1(indexPairs(:,1));
    matchedPoints2 = validPoints2(indexPairs(:,2));
    
    % Estimate transformation
    [tform, inlierIdx] = estimateGeometricTransform2D(matchedPoints2, matchedPoints1, ...
                                                      'affine', ...
                                                      'MaxNumTrials', 3000, ...
                                                      'MaxDistance', 5, ...
                                                      'Confidence', 99);
    
    stats.numInliers = sum(inlierIdx);
    stats.inlierRatio = stats.numInliers / stats.numMatches;
    stats.matchedPoints1 = matchedPoints1;
    stats.matchedPoints2 = matchedPoints2;
    stats.inlierIdx = inlierIdx;
    
    % Apply transformation
    alignedImg = imwarp(img2, tform, 'OutputView', imref2d(size(img1)));
    stats.success = true;
end

function [alignedImg, tform, stats] = harrisAlign(img1, img2, gray1, gray2, params)
    % Harris corner-based alignment
    
    stats = struct();
    stats.method = 'Harris';
    
    % Set default parameters
    if ~isfield(params, 'minQuality')
        params.minQuality = 0.001;
    end
    if ~isfield(params, 'filterSize')
        params.filterSize = 5;
    end
    
    % Detect Harris corners
    corners1 = detectHarrisFeatures(gray1, ...
                                   'MinQuality', params.minQuality, ...
                                   'FilterSize', params.filterSize);
    corners2 = detectHarrisFeatures(gray2, ...
                                   'MinQuality', params.minQuality, ...
                                   'FilterSize', params.filterSize);
    
    stats.numPoints1 = corners1.Count;
    stats.numPoints2 = corners2.Count;
    
    if corners1.Count < 20 || corners2.Count < 20
        error('Insufficient Harris corners detected');
    end
    
    % Extract features
    [features1, validPoints1] = extractFeatures(gray1, corners1);
    [features2, validPoints2] = extractFeatures(gray2, corners2);
    
    % Match features
    indexPairs = matchFeatures(features1, features2, ...
                               'Unique', true, ...
                               'MatchThreshold', 10);
    
    stats.numMatches = size(indexPairs, 1);
    
    if size(indexPairs, 1) < 4
        error('Insufficient feature matches');
    end
    
    matchedPoints1 = validPoints1(indexPairs(:,1));
    matchedPoints2 = validPoints2(indexPairs(:,2));
    
    % Estimate transformation
    [tform, inlierIdx] = estimateGeometricTransform2D(matchedPoints2, matchedPoints1, ...
                                                      'affine', ...
                                                      'MaxNumTrials', 2000, ...
                                                      'MaxDistance', 10);
    
    stats.numInliers = sum(inlierIdx);
    stats.inlierRatio = stats.numInliers / stats.numMatches;
    stats.matchedPoints1 = matchedPoints1;
    stats.matchedPoints2 = matchedPoints2;
    stats.inlierIdx = inlierIdx;
    
    % Apply transformation
    alignedImg = imwarp(img2, tform, 'OutputView', imref2d(size(img1)));
    stats.success = true;
end

function [alignedImg, tform, stats] = siftAlign(img1, img2, gray1, gray2, params)
    % SIFT feature-based alignment (if available)
    
    stats = struct();
    stats.method = 'SIFT';
    
    % Check if SIFT is available
    if ~exist('detectSIFTFeatures', 'file')
        error('SIFT features not available. Try SURF or ORB instead.');
    end
    
    % Detect SIFT features
    points1 = detectSIFTFeatures(gray1);
    points2 = detectSIFTFeatures(gray2);
    
    stats.numPoints1 = points1.Count;
    stats.numPoints2 = points2.Count;
    
    % Continue with similar process as SURF...
    % (Implementation similar to SURF but using SIFT features)
    
    alignedImg = img2;
    tform = affine2d(eye(3));
    stats.success = false;
end

function [alignedImg, tform, stats] = intensityAlign(img1, img2, gray1, gray2, params)
    % Intensity-based alignment using image registration
    
    stats = struct();
    stats.method = 'Intensity';
    
    % Set default parameters
    if ~isfield(params, 'transformType')
        params.transformType = 'affine';
    end
    if ~isfield(params, 'modality')
        params.modality = 'multimodal';
    end
    
    try
        % Configure optimizer and metric
        [optimizer, metric] = imregconfig(params.modality);
        
        % Adjust optimizer settings for better results
        if strcmp(params.modality, 'multimodal')
            optimizer.InitialRadius = 0.004;
            optimizer.Epsilon = 1.5e-4;
            optimizer.GrowthFactor = 1.01;
            optimizer.MaximumIterations = 300;
        else
            optimizer.MaximumIterations = 200;
            optimizer.RelaxationFactor = 0.5;
        end
        
        % Perform registration
        tform = imregtform(gray2, gray1, params.transformType, optimizer, metric);
        
        % Apply transformation
        alignedImg = imwarp(img2, tform, 'OutputView', imref2d(size(img1)));
        
        stats.success = true;
        stats.optimizer = optimizer;
        stats.metric = metric;
        
    catch ME
        warning('Intensity-based alignment failed: %s', ME.message);
        alignedImg = img2;
        tform = affine2d(eye(3));
        stats.success = false;
        stats.error = ME.message;
    end
end
