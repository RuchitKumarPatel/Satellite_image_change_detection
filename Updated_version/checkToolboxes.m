function [hasCV, hasIP, hasML] = checkToolboxes()
    % CHECKTOOLBOXES - Check availability of required MATLAB toolboxes
    %
    % Output:
    %   hasCV - Boolean indicating Computer Vision Toolbox availability
    %   hasIP - Boolean indicating Image Processing Toolbox availability
    %   hasML - Boolean indicating Statistics and Machine Learning Toolbox availability
    
    fprintf('\nChecking installed toolboxes...\n');
    fprintf('--------------------------------\n');
    
    % Check Computer Vision Toolbox
    hasCV = license('test', 'Video_and_Image_Blockset') || ...
            exist('detectSURFFeatures', 'file') == 2 || ...
            exist('detectORBFeatures', 'file') == 2 || ...
            exist('detectHarrisFeatures', 'file') == 2;
    
    % Check Image Processing Toolbox
    hasIP = license('test', 'Image_Toolbox') || ...
            exist('imresize', 'file') == 2 || ...
            exist('imgaussfilt', 'file') == 2;
    
    % Check Statistics and Machine Learning Toolbox
    hasML = license('test', 'Statistics_Toolbox') || ...
            exist('kmeans', 'file') == 2;
    
    % Display results
    if hasCV
        fprintf('✓ Computer Vision Toolbox: Available\n');
    else
        fprintf('✗ Computer Vision Toolbox: Not Available\n');
        fprintf('  (Feature-based alignment will be limited)\n');
    end
    
    if hasIP
        fprintf('✓ Image Processing Toolbox: Available\n');
    else
        fprintf('✗ Image Processing Toolbox: Not Available\n');
        fprintf('  (Some image filters will be unavailable)\n');
    end
    
    if hasML
        fprintf('✓ Statistics and Machine Learning Toolbox: Available\n');
    else
        fprintf('✗ Statistics and Machine Learning Toolbox: Not Available\n');
        fprintf('  (Advanced clustering features disabled)\n');
    end
    
    fprintf('--------------------------------\n');
    
    % Check overall status
    if hasCV && hasIP && hasML
        fprintf('✓ All toolboxes available - Full functionality enabled!\n');
    elseif hasCV || hasIP
        fprintf('⚠ Partial functionality available\n');
    else
        fprintf('⚠ Basic functionality only - Consider installing toolboxes\n');
    end
end
