function generateReport(fig, outputPath)
    % GENERATEREPORT - Generate comprehensive PDF report of analysis results
    %
    % Input:
    %   fig        - Handle to main figure
    %   outputPath - Path for output PDF file
    
    if nargin < 2
        [filename, pathname] = uiputfile('*.pdf', 'Save Report As');
        if isequal(filename, 0)
            return;
        end
        outputPath = fullfile(pathname, filename);
    end
    
    % Get application data
    appData = getappdata(fig, 'AppData');
    
    % Create temporary figures for report
    reportFigs = [];
    
    try
        % Page 1: Overview
        reportFigs(1) = createOverviewPage(appData);
        
        % Page 2: Original Images
        reportFigs(2) = createImagesPage(appData);
        
        % Page 3: Alignment Results
        if ~isempty(appData.registrationData)
            reportFigs(3) = createAlignmentPage(appData);
        end
        
        % Page 4: Change Detection Results
        if ~isempty(appData.changeData)
            reportFigs(4) = createChangeDetectionPage(appData);
        end
        
        % Page 5: Statistical Analysis
        if ~isempty(appData.changeData)
            reportFigs(5) = createStatisticsPage(appData);
        end
        
        % Export all figures to PDF
        for i = 1:length(reportFigs)
            if ishandle(reportFigs(i))
                if i == 1
                    exportgraphics(reportFigs(i), outputPath, 'ContentType', 'vector');
                else
                    exportgraphics(reportFigs(i), outputPath, 'ContentType', 'vector', 'Append', true);
                end
            end
        end
        
        fprintf('Report saved to: %s\n', outputPath);
        
    catch ME
        warning('Error generating report: %s', ME.message);
    end
    
    % Close temporary figures
    for i = 1:length(reportFigs)
        if ishandle(reportFigs(i))
            close(reportFigs(i));
        end
    end
end

function fig = createOverviewPage(appData)
    % Create overview page
    
    fig = figure('Visible', 'off', 'Position', [100 100 800 1000], ...
                 'PaperType', 'A4', 'PaperOrientation', 'portrait');
    
    % Title
    annotation('textbox', [0.1, 0.9, 0.8, 0.05], ...
              'String', 'Satellite Change Detection Report', ...
              'FontSize', 20, 'FontWeight', 'bold', ...
              'HorizontalAlignment', 'center', ...
              'EdgeColor', 'none');
    
    % Date and time
    annotation('textbox', [0.1, 0.85, 0.8, 0.03], ...
              'String', sprintf('Generated: %s', datestr(now)), ...
              'FontSize', 12, ...
              'HorizontalAlignment', 'center', ...
              'EdgeColor', 'none');
    
    % Summary information
    summaryText = {
        'Analysis Summary:', '', ...
        sprintf('Number of images loaded: %d', length(appData.loadedImages)), ...
        sprintf('Current image pair: %d and %d', appData.currentImagePair(1), appData.currentImagePair(2))
    };
    
    if ~isempty(appData.registrationData)
        summaryText = [summaryText, ...
                      sprintf('Alignment method: %s', appData.registrationData.method), ...
                      sprintf('Alignment success: %s', mat2str(appData.registrationData.success))];
    end
    
    if ~isempty(appData.changeData)
        summaryText = [summaryText, ...
                      sprintf('Change detection method: %s', appData.changeData.stats.method), ...
                      sprintf('Change percentage: %.2f%%', appData.changeData.stats.changePercentage)];
    end
    
    annotation('textbox', [0.1, 0.3, 0.8, 0.5], ...
              'String', summaryText, ...
              'FontSize', 11, ...
              'EdgeColor', 'none');
end

function fig = createImagesPage(appData)
    % Create page showing original images
    
    fig = figure('Visible', 'off', 'Position', [100 100 800 1000], ...
                 'PaperType', 'A4', 'PaperOrientation', 'portrait');
    
    idx1 = appData.currentImagePair(1);
    idx2 = appData.currentImagePair(2);
    
    % Display first image
    subplot(2,1,1);
    if ~isempty(appData.preprocessedImages)
        imshow(appData.preprocessedImages{idx1});
    else
        imshow(appData.loadedImages{idx1});
    end
    title(sprintf('Image 1: %s', appData.images(idx1).name), ...
          'Interpreter', 'none', 'FontSize', 12);
    
    % Display second image
    subplot(2,1,2);
    if ~isempty(appData.preprocessedImages)
        imshow(appData.preprocessedImages{idx2});
    else
        imshow(appData.loadedImages{idx2});
    end
    title(sprintf('Image 2: %s', appData.images(idx2).name), ...
          'Interpreter', 'none', 'FontSize', 12);
    
    sgtitle('Original/Preprocessed Images', 'FontSize', 14, 'FontWeight', 'bold');
end

function fig = createAlignmentPage(appData)
    % Create page showing alignment results
    
    fig = figure('Visible', 'off', 'Position', [100 100 800 1000], ...
                 'PaperType', 'A4', 'PaperOrientation', 'portrait');
    
    regData = appData.registrationData;
    
    % Display aligned image
    subplot(2,1,1);
    if ~isempty(appData.alignedImages)
        imshow(appData.alignedImages{2});
        title('Aligned Image 2', 'FontSize', 12);
    end
    
    % Display feature matching if available
    if isfield(regData, 'matchedPoints1') && ~isempty(regData.matchedPoints1)
        subplot(2,1,2);
        
        idx1 = appData.currentImagePair(1);
        idx2 = appData.currentImagePair(2);
        
        img1 = appData.preprocessedImages{idx1};
        img2 = appData.preprocessedImages{idx2};
        
        if isfield(regData, 'inlierIdx')
            showMatchedFeatures(img1, img2, ...
                               regData.matchedPoints1(regData.inlierIdx), ...
                               regData.matchedPoints2(regData.inlierIdx), ...
                               'montage');
            title(sprintf('Feature Matching: %d inliers', sum(regData.inlierIdx)), ...
                  'FontSize', 12);
        end
    else
        % Show alignment statistics as text
        subplot(2,1,2);
        axis off;
        text(0.5, 0.5, sprintf('Alignment Method: %s\nSuccess: %s', ...
                               regData.method, mat2str(regData.success)), ...
             'HorizontalAlignment', 'center', ...
             'FontSize', 12);
    end
    
    sgtitle('Image Alignment Results', 'FontSize', 14, 'FontWeight', 'bold');
end

function fig = createChangeDetectionPage(appData)
    % Create page showing change detection results
    
    fig = figure('Visible', 'off', 'Position', [100 100 800 1000], ...
                 'PaperType', 'A4', 'PaperOrientation', 'portrait');
    
    changeData = appData.changeData;
    
    % Display change map
    subplot(2,2,1);
    imagesc(changeData.changeMap);
    colormap(jet);
    colorbar;
    title('Change Probability Map', 'FontSize', 11);
    axis image;
    
    % Display binary change mask
    subplot(2,2,2);
    imshow(changeData.changeMask);
    title('Binary Change Mask', 'FontSize', 11);
    
    % Display overlay on image 2
    subplot(2,2,3);
    if ~isempty(appData.alignedImages)
        img = appData.alignedImages{2};
    else
        idx2 = appData.currentImagePair(2);
        img = appData.preprocessedImages{idx2};
    end
    
    % Create overlay visualization
    if size(img, 3) == 1
        imgRGB = cat(3, img, img, img);
    else
        imgRGB = img;
    end
    overlayImg = im2double(imgRGB);
    overlayImg(:,:,1) = overlayImg(:,:,1) + 0.3 * double(changeData.changeMask);
    overlayImg = min(overlayImg, 1);
    
    imshow(overlayImg);
    title('Change Overlay', 'FontSize', 11);
    
    % Display statistics text
    subplot(2,2,4);
    axis off;
    statsText = {
        'Change Statistics:', '', ...
        sprintf('Method: %s', changeData.stats.method), ...
        sprintf('Total pixels: %d', changeData.stats.totalPixels), ...
        sprintf('Changed pixels: %d', changeData.stats.changedPixels), ...
        sprintf('Change percentage: %.2f%%', changeData.stats.changePercentage), ...
        sprintf('Threshold: %.3f', changeData.stats.threshold)
    };
    
    text(0.1, 0.9, statsText, ...
         'VerticalAlignment', 'top', ...
         'FontSize', 10);
    
    sgtitle('Change Detection Results', 'FontSize', 14, 'FontWeight', 'bold');
end

function fig = createStatisticsPage(appData)
    % Create page with statistical analysis
    
    fig = figure('Visible', 'off', 'Position', [100 100 800 1000], ...
                 'PaperType', 'A4', 'PaperOrientation', 'portrait');
    
    changeData = appData.changeData;
    
    % Histogram of change map values
    subplot(3,2,1);
    histogram(changeData.changeMap(:), 50);
    xlabel('Change Probability');
    ylabel('Frequency');
    title('Distribution of Change Values', 'FontSize', 11);
    grid on;
    
    % Pie chart of changed vs unchanged
    subplot(3,2,2);
    changedPixels = changeData.stats.changedPixels;
    unchangedPixels = changeData.stats.totalPixels - changedPixels;
    pie([unchangedPixels, changedPixels], ...
        {'Unchanged', 'Changed'});
    title('Change Proportion', 'FontSize', 11);
    
    % If we have aligned images, show pixel intensity comparison
    if ~isempty(appData.alignedImages)
        subplot(3,2,[3,4]);
        
        img1 = appData.alignedImages{1};
        img2 = appData.alignedImages{2};
        
        if size(img1, 3) > 1
            gray1 = rgb2gray(img1);
            gray2 = rgb2gray(img2);
        else
            gray1 = img1;
            gray2 = img2;
        end
        
        % Sample pixels for scatter plot
        nSamples = min(5000, numel(gray1));
        idx = randperm(numel(gray1), nSamples);
        
        scatter(double(gray1(idx)), double(gray2(idx)), 1, '.');
        xlabel('Image 1 Intensity');
        ylabel('Image 2 Intensity');
        title('Pixel Intensity Correlation', 'FontSize', 11);
        hold on;
        plot([0 255], [0 255], 'r-', 'LineWidth', 1);
        hold off;
        grid on;
        axis equal;
        xlim([0 255]);
        ylim([0 255]);
    end
    
    % Additional statistics
    subplot(3,2,[5,6]);
    axis off;
    
    additionalStats = {
        'Additional Analysis:', '', ...
        sprintf('Mean change value: %.3f', mean(changeData.changeMap(:))), ...
        sprintf('Std deviation: %.3f', std(changeData.changeMap(:))), ...
        sprintf('Max change value: %.3f', max(changeData.changeMap(:))), ...
        sprintf('Min change value: %.3f', min(changeData.changeMap(:)))
    };
    
    if isfield(changeData.stats, 'numMethodsFused')
        additionalStats = [additionalStats, '', ...
                          sprintf('Methods fused: %.1f', changeData.stats.numMethodsFused)];
    end
    
    text(0.1, 0.9, additionalStats, ...
         'VerticalAlignment', 'top', ...
         'FontSize', 10);
    
    sgtitle('Statistical Analysis', 'FontSize', 14, 'FontWeight', 'bold');
end
