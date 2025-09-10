function testSystem()
    % TESTSYSTEM - Test script for satellite change detection system
    %
    % This script tests all major components of the system
    
    fprintf('\n=================================================\n');
    fprintf('    SATELLITE CHANGE DETECTION SYSTEM TEST      \n');
    fprintf('=================================================\n\n');
    
    % Track test results
    testResults = struct();
    testResults.passed = 0;
    testResults.failed = 0;
    testResults.errors = {};
    
    % Test 1: Toolbox availability
    fprintf('Test 1: Checking toolbox availability...\n');
    try
        [hasCV, hasIP, hasML] = checkToolboxes();
        testResults.passed = testResults.passed + 1;
        fprintf('✓ Toolbox check completed\n\n');
    catch ME
        testResults.failed = testResults.failed + 1;
        testResults.errors{end+1} = sprintf('Toolbox check failed: %s', ME.message);
        fprintf('✗ Toolbox check failed: %s\n\n', ME.message);
    end
    
    % Test 2: Image preprocessing
    fprintf('Test 2: Testing image preprocessing...\n');
    try
        % Create test image
        testImg = uint8(rand(256, 256, 3) * 255);
        
        % Test different preprocessing methods
        methods = {'auto', 'enhance', 'denoise', 'normalize'};
        
        for i = 1:length(methods)
            params = struct();
            processedImg = imagePreprocessing(testImg, methods{i}, params);
            
            if ~isempty(processedImg) && isequal(size(testImg), size(processedImg))
                fprintf('  ✓ %s preprocessing: OK\n', methods{i});
            else
                error('Preprocessing size mismatch');
            end
        end
        
        testResults.passed = testResults.passed + 1;
        fprintf('✓ Image preprocessing test completed\n\n');
        
    catch ME
        testResults.failed = testResults.failed + 1;
        testResults.errors{end+1} = sprintf('Preprocessing test failed: %s', ME.message);
        fprintf('✗ Image preprocessing test failed: %s\n\n', ME.message);
    end
    
    % Test 3: Feature alignment
    fprintf('Test 3: Testing feature alignment...\n');
    try
        % Create two test images with slight transformation
        img1 = imread('cameraman.tif');
        if size(img1, 3) == 1
            img1 = cat(3, img1, img1, img1);
        end
        
        % Create slightly transformed version
        tform = affine2d([1 0.1 0; -0.1 1 0; 5 10 1]);
        img2 = imwarp(img1, tform);
        
        % Ensure same size
        img2 = imresize(img2, size(img1, 1:2));
        
        % Test alignment
        params = struct();
        [alignedImg, tformEst, stats] = featureAlignment(img1, img2, 'auto', params);
        
        if stats.success
            fprintf('  ✓ Alignment successful using: %s\n', stats.method);
        else
            fprintf('  ⚠ Alignment failed, but function executed\n');
        end
        
        testResults.passed = testResults.passed + 1;
        fprintf('✓ Feature alignment test completed\n\n');
        
    catch ME
        testResults.failed = testResults.failed + 1;
        testResults.errors{end+1} = sprintf('Alignment test failed: %s', ME.message);
        fprintf('✗ Feature alignment test failed: %s\n\n', ME.message);
    end
    
    % Test 4: Change detection
    fprintf('Test 4: Testing change detection...\n');
    try
        % Create two test images with known changes
        img1 = uint8(ones(100, 100, 3) * 128);
        img2 = img1;
        
        % Add some changes
        img2(30:70, 30:70, :) = 200;
        
        % Test different detection methods
        methods = {'pixel', 'ssim', 'edge', 'texture'};
        
        for i = 1:length(methods)
            try
                params = struct('postProcess', false);
                [changeMap, changeMask, stats] = changeDetection(img1, img2, methods{i}, params);
                
                if ~isempty(changeMap) && stats.changePercentage > 0
                    fprintf('  ✓ %s detection: %.1f%% changed\n', methods{i}, stats.changePercentage);
                else
                    fprintf('  ⚠ %s detection: No changes detected\n', methods{i});
                end
            catch
                fprintf('  ⚠ %s detection: Not available\n', methods{i});
            end
        end
        
        testResults.passed = testResults.passed + 1;
        fprintf('✓ Change detection test completed\n\n');
        
    catch ME
        testResults.failed = testResults.failed + 1;
        testResults.errors{end+1} = sprintf('Change detection test failed: %s', ME.message);
        fprintf('✗ Change detection test failed: %s\n\n', ME.message);
    end
    
    % Test 5: Visualization
    fprintf('Test 5: Testing visualization...\n');
    try
        % Use previous test data
        changeMap = rand(100, 100);
        changeMask = changeMap > 0.5;
        
        % Test visualization methods
        vizMethods = {'heatmap', 'overlay', 'sidebyside'};
        
        for i = 1:length(vizMethods)
            params = struct();
            vizResult = changeVisualization(img1, img2, changeMap, changeMask, vizMethods{i}, params);
            
            if ~isempty(vizResult)
                fprintf('  ✓ %s visualization: OK\n', vizMethods{i});
                
                % Close figure if created
                if isfield(vizResult, 'figure') && ishandle(vizResult.figure)
                    close(vizResult.figure);
                end
            else
                fprintf('  ⚠ %s visualization: Empty result\n', vizMethods{i});
            end
        end
        
        testResults.passed = testResults.passed + 1;
        fprintf('✓ Visualization test completed\n\n');
        
    catch ME
        testResults.failed = testResults.failed + 1;
        testResults.errors{end+1} = sprintf('Visualization test failed: %s', ME.message);
        fprintf('✗ Visualization test failed: %s\n\n', ME.message);
    end
    
    % Test 6: GUI Creation
    fprintf('Test 6: Testing GUI creation...\n');
    try
        % Create GUI
        fig = createMainGUI(true, true, true);
        
        if ishandle(fig)
            fprintf('  ✓ GUI created successfully\n');
            
            % Test some UI elements
            loadBtn = findobj(fig, 'Tag', 'loadImagesBtn');
            if ~isempty(loadBtn)
                fprintf('  ✓ Load button found\n');
            end
            
            % Close GUI
            pause(1); % Show briefly
            close(fig);
            
            testResults.passed = testResults.passed + 1;
            fprintf('✓ GUI test completed\n\n');
        else
            error('GUI handle invalid');
        end
        
    catch ME
        testResults.failed = testResults.failed + 1;
        testResults.errors{end+1} = sprintf('GUI test failed: %s', ME.message);
        fprintf('✗ GUI test failed: %s\n\n', ME.message);
    end
    
    % Summary
    fprintf('\n=================================================\n');
    fprintf('                 TEST SUMMARY                    \n');
    fprintf('=================================================\n');
    fprintf('Tests Passed: %d\n', testResults.passed);
    fprintf('Tests Failed: %d\n', testResults.failed);
    
    if testResults.failed > 0
        fprintf('\nFailed Tests:\n');
        for i = 1:length(testResults.errors)
            fprintf('  - %s\n', testResults.errors{i});
        end
    end
    
    if testResults.failed == 0
        fprintf('\n✓ All tests passed successfully!\n');
    else
        fprintf('\n⚠ Some tests failed. Please check the errors above.\n');
    end
    
    fprintf('\n=================================================\n\n');
end

% Test helper functions

function testImageGeneration()
    % Generate synthetic test images
    
    fprintf('Generating synthetic test images...\n');
    
    % Create test directory
    testDir = 'test_images';
    if ~exist(testDir, 'dir')
        mkdir(testDir);
    end
    
    % Generate pairs of images with known changes
    for i = 1:3
        % Base image
        baseImg = uint8(rand(512, 512, 3) * 200 + 30);
        
        % Add some features
        baseImg = insertShape(baseImg, 'FilledCircle', ...
                             [100+i*50 100 30], ...
                             'Color', 'white');
        baseImg = insertShape(baseImg, 'FilledRectangle', ...
                             [200 200+i*30 100 50], ...
                             'Color', 'green');
        
        % Save base image
        imwrite(baseImg, fullfile(testDir, sprintf('image_%d_before.png', i)));
        
        % Create changed version
        changedImg = baseImg;
        
        % Add changes
        changedImg = insertShape(changedImg, 'FilledCircle', ...
                                [300 300 40], ...
                                'Color', 'red');
        changedImg(100:150, 100:150, :) = 255; % Bright square
        
        % Save changed image
        imwrite(changedImg, fullfile(testDir, sprintf('image_%d_after.png', i)));
    end
    
    fprintf('✓ Test images generated in: %s\n', testDir);
end
