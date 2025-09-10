function preprocessedImg = imagePreprocessing(img, method, params)
    % IMAGEPREPROCESSING - Adaptive preprocessing for satellite images
    %
    % Input:
    %   img    - Input image (can be RGB, grayscale, or multispectral)
    %   method - Preprocessing method ('auto', 'enhance', 'denoise', 'normalize')
    %   params - Structure with method-specific parameters
    %
    % Output:
    %   preprocessedImg - Preprocessed image
    
    if nargin < 2
        method = 'auto';
    end
    if nargin < 3
        params = struct();
    end
    
    switch lower(method)
        case 'auto'
            preprocessedImg = autoPreprocess(img, params);
        case 'enhance'
            preprocessedImg = enhanceContrast(img, params);
        case 'denoise'
            preprocessedImg = denoiseImage(img, params);
        case 'normalize'
            preprocessedImg = normalizeImage(img, params);
        case 'multispectral'
            preprocessedImg = processMultispectral(img, params);
        otherwise
            warning('Unknown preprocessing method. Using auto.');
            preprocessedImg = autoPreprocess(img, params);
    end
end

function processedImg = autoPreprocess(img, params)
    % Automatic adaptive preprocessing based on image characteristics
    
    % Convert data type if needed
    if isa(img, 'uint16')
        img = im2uint8(img);
    elseif isa(img, 'int16')
        img = uint8(255 * (double(img) - double(min(img(:)))) / ...
                    (double(max(img(:))) - double(min(img(:)))));
    end
    
    processedImg = img;
    
    % Determine image type and apply appropriate processing
    if size(img, 3) == 1
        % Grayscale image
        processedImg = processSingleBand(processedImg, params);
    elseif size(img, 3) == 3
        % RGB image
        processedImg = processRGB(processedImg, params);
    else
        % Multispectral image
        processedImg = processMultispectral(processedImg, params);
    end
    
    % Apply denoising if image is noisy
    if isNoisy(processedImg)
        processedImg = denoiseImage(processedImg, params);
    end
    
    % Enhance contrast
    processedImg = enhanceContrast(processedImg, params);
end

function processedImg = processSingleBand(img, params)
    % Process single-band (grayscale) images
    
    if ~isfield(params, 'clipLimit')
        params.clipLimit = 0.02;
    end
    
    % Apply adaptive histogram equalization
    try
        processedImg = adapthisteq(img, ...
                                  'ClipLimit', params.clipLimit, ...
                                  'Distribution', 'uniform', ...
                                  'NumTiles', [8 8]);
    catch
        % Fallback to simple histogram equalization
        processedImg = histeq(img);
    end
end

function processedImg = processRGB(img, params)
    % Process RGB images
    
    processedImg = img;
    
    % Convert to LAB color space for better processing
    try
        lab = rgb2lab(img);
        
        % Process L channel (lightness)
        L = lab(:,:,1);
        L = mat2gray(L);
        L = adapthisteq(L, 'ClipLimit', 0.02, 'NumTiles', [8 8]);
        lab(:,:,1) = L * 100; % Scale back to LAB range
        
        % Convert back to RGB
        processedImg = lab2rgb(lab);
        processedImg = im2uint8(processedImg);
    catch
        % Fallback: process each channel separately
        for c = 1:3
            processedImg(:,:,c) = processSingleBand(img(:,:,c), params);
        end
    end
end

function processedImg = processMultispectral(img, params)
    % Process multispectral images
    
    numBands = size(img, 3);
    
    if numBands >= 4
        % Common band combinations for satellite imagery
        % Assuming bands: Blue, Green, Red, NIR, ...
        
        if ~isfield(params, 'bandCombination')
            % Default: False color composite (NIR, Red, Green)
            params.bandCombination = [4, 3, 2];
        end
        
        % Extract selected bands
        if max(params.bandCombination) <= numBands
            processedImg = img(:, :, params.bandCombination);
        else
            % Use first 3 bands if specified bands not available
            processedImg = img(:, :, 1:min(3, numBands));
        end
    else
        % Use all available bands (up to 3)
        processedImg = img(:, :, 1:min(3, numBands));
    end
    
    % Normalize each band
    for b = 1:size(processedImg, 3)
        band = double(processedImg(:,:,b));
        band = (band - min(band(:))) / (max(band(:)) - min(band(:)) + eps);
        processedImg(:,:,b) = uint8(255 * band);
    end
    
    % Apply contrast enhancement
    processedImg = enhanceContrast(processedImg, params);
end

function processedImg = enhanceContrast(img, params)
    % Enhance image contrast
    
    if ~isfield(params, 'stretchLimits')
        params.stretchLimits = [0.01 0.99];
    end
    
    try
        % Use imadjust for contrast stretching
        if size(img, 3) == 1
            processedImg = imadjust(img, ...
                                   stretchlim(img, params.stretchLimits));
        else
            processedImg = img;
            for c = 1:size(img, 3)
                processedImg(:,:,c) = imadjust(img(:,:,c), ...
                    stretchlim(img(:,:,c), params.stretchLimits));
            end
        end
    catch
        % Simple contrast stretching
        processedImg = img;
        for c = 1:size(img, 3)
            channel = double(img(:,:,c));
            minVal = prctile(channel(:), 1);
            maxVal = prctile(channel(:), 99);
            channel = (channel - minVal) / (maxVal - minVal + eps);
            channel(channel < 0) = 0;
            channel(channel > 1) = 1;
            processedImg(:,:,c) = uint8(255 * channel);
        end
    end
end

function processedImg = denoiseImage(img, params)
    % Remove noise from image
    
    if ~isfield(params, 'filterSize')
        params.filterSize = 3;
    end
    
    processedImg = img;
    
    try
        % Try guided filter (best quality)
        if size(img, 3) == 3
            processedImg = imguidedfilter(img, ...
                                         'NeighborhoodSize', params.filterSize);
        else
            processedImg = imguidedfilter(img, img, ...
                                         'NeighborhoodSize', params.filterSize);
        end
    catch
        try
            % Fallback to median filter
            if size(img, 3) == 1
                processedImg = medfilt2(img, [params.filterSize params.filterSize]);
            else
                for c = 1:size(img, 3)
                    processedImg(:,:,c) = medfilt2(img(:,:,c), ...
                                                   [params.filterSize params.filterSize]);
                end
            end
        catch
            % Last resort: Gaussian filter
            for c = 1:size(img, 3)
                processedImg(:,:,c) = imgaussfilt(img(:,:,c), 1);
            end
        end
    end
end

function processedImg = normalizeImage(img, params)
    % Normalize image to standard range
    
    processedImg = img;
    
    % Convert to double for processing
    processedImg = im2double(processedImg);
    
    % Normalize each channel
    for c = 1:size(processedImg, 3)
        channel = processedImg(:,:,c);
        
        if isfield(params, 'normMethod')
            switch params.normMethod
                case 'minmax'
                    channel = (channel - min(channel(:))) / ...
                             (max(channel(:)) - min(channel(:)) + eps);
                case 'zscore'
                    channel = (channel - mean(channel(:))) / ...
                             (std(channel(:)) + eps);
                    % Clip to [0, 1]
                    channel(channel < 0) = 0;
                    channel(channel > 1) = 1;
            end
        else
            % Default: min-max normalization
            channel = (channel - min(channel(:))) / ...
                     (max(channel(:)) - min(channel(:)) + eps);
        end
        
        processedImg(:,:,c) = channel;
    end
    
    % Convert back to uint8
    processedImg = im2uint8(processedImg);
end

function noisy = isNoisy(img)
    % Check if image appears to be noisy
    
    % Convert to grayscale if needed
    if size(img, 3) > 1
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
    
    % Calculate noise estimate using Median Absolute Deviation
    h = fspecial('laplacian');
    responseImg = imfilter(double(grayImg), h);
    MAD = median(abs(responseImg(:) - median(responseImg(:))));
    noiseEstimate = MAD / 0.6745;
    
    % Threshold for considering image noisy
    noisy = noiseEstimate > 10;
end
