This documentation provides a comprehensive guide and technical description of the 
developed MATLAB application for satellite image change detection. It serves as a basis for the poster presentation of the Computer 
Vision Challenge SoSe 2025.


1. Quick start guide

Follow these steps for a test tour of the application:
- In the top-left panel named "Image Controls & Settings", click on "Select Image Folder" 
  to choose a folder with images from a same location and different dates.
  Make sure your images are named in the format YYYY_MM.ext (e.g., 2020_11.jpg) and
  there are at least two images per folder.
- Click on the "Load & Process" button below. You can then navigate between the images
  displayed in the "Original Images" panel.
- Click on the "Align images" button then "Detect changes" at the bottom of the
  top-left panel. The aligned second image is displayed in the top-right "Results" panel.
  Feature matching can be viewed in the corresponding window of the bottom-right panel.
  Click on "Detailed Report" in the top-right panel to generate graphs in the 
  "Statistics & Metrics" window of the bottom-right panel.
- Click on "Apply Visualization" in the middle-left panel "Visualization Methods" to 
  generate a difference heatmap in the bottom-right panel.
- You can download a PDF report with the "Save Results" button in the top-right panel.
  (The PDF will be saved in the folder of the program.)
- Finally, you can close the application by clicking on the "Cancel" button in the 
  top-left panel.

For a more detailed description of the application, please refer to the sections below.


2. Program Overview and Functions 

The GUI is divided into several panels that allow for a logical sequence of work steps: 

2.1 Image Controls & Settings 

This panel contains the basic functions for loading and navigating images, as well as 
for initializing change detection. 
● Select Image Folder: Allows selecting a folder containing satellite images. 
  The images should be named in the format YYYY_MM.ext (e.g., 2020_11.jpg) and 
  include at least two images per "Location". 
● Load & Process: Loads the images from the selected folder into the 
  application. After loading, the first image pair (by default, Image 1 and Image 2) 
  will be displayed. 
● ◄ Prev 1 / Next 1 ►: Navigates through the image list for the first image of the 
  current pair. 
● ◄ Prev 2 / Next 2 ►: Navigates through the image list for the second image of 
  the current pair. 
● Current Pair: X-Y: Displays the indices of the currently shown images. 
● Apply Median Filter (Noise Reduction): A checkbox that, when activated, 
  applies a median filter to the loaded images to reduce noise. This can improve the 
  quality of subsequent analyses. 
● Align Images: Aligns the second image (later) to the first image (earlier). This 
  is a crucial step to ensure that the images are correctly superimposed and 
  changes can be precisely detected. 
● Detect Changes: Performs the actual change detection after the images have 
been aligned. 
● Cancel: Closes the entire application. 
● Status Indicator: A text field that displays the current status of the application 
  and important messages. 

2.2 Visualization Methods 

This panel offers options for adjusting the display of detected changes. 
● Visualization Type: A selection of radio buttons to switch between different 
  visualization methods: 
  ○ Difference Heatmap: Displays the intensity of changes as a colored 
    heatmap, where different colors represent the magnitude of pixel differences. 
  ○ Side-by-Side Overlay: Overlays the aligned second image with a colored 
    mask that highlights the detected changes. 
  ○ Change Highlights: Displays the aligned second image with change areas 
    highlighted in color to make them clearly visible. 
● Change Type Focus: A dropdown menu to focus the analysis on specific types of 
  changes: 
  ○ All Changes: Displays all detected changes. 
  ○ Geometric Changes (Size/Shape): Focuses on changes in the size or shape 
    of objects, often filtered by morphological operations. 
  ○ Intensity Changes (Brightness): Primarily highlights brightness differences. 
  ○ Structural Changes (Texture): Identifies changes in the texture of areas, 
    e.g., by analyzing the local standard deviation. 
● Change Sensitivity: A slider to adjust the sensitivity of change detection and the 
  intensity of the visualization. A higher value makes even smaller changes visible. 
● Apply Visualization: Applies the currently selected visualization and 
  sensitivity settings and updates the display in the "Visualization" tab. 

2.3 Original Images 

This panel displays the two selected original images side-by-side. 
● Image 1 (Earlier): The first image of the pair. 
● Image 2 (Later): The second image of the pair. 

2.4 Results 

This panel presents the results of image alignment and basic statistics. 
● Aligned Image: Displays the second image after geometric alignment to the first 
  image. 
● Statistics: Displays text summaries of change detection and feature matching 
  results. 
● Save Results: Exports a comprehensive PDF report with all relevant images 
  and statistics (see Section 3.2). 
● Detailed Report: Generates and updates detailed statistics and plots in the 
  "Statistics & Metrics" tab of the "Detailed Analysis & Comparisons" panel. 

2.5 Detailed Analysis & Comparisons 

This panel provides more detailed views of the analysis results in a tabbed structure. 
● Visualization: Displays the results of the applied visualization method (heatmap, 
  overlay, highlights). 
● Feature Matching: Displays the matched features (inliers) between the two 
  images used for alignment. This illustrates the quality of image registration. 
● Statistics & Metrics: 
  ○ Histogram of Pixel Differences: A histogram showing the distribution of pixel 
    differences between the aligned images. 
  ○ Pixel Intensity Comparison (Image 1 vs Aligned Image 2): A scatter plot 
    that plots the pixel intensities of the first image against those of the aligned 
    second image to visualize correlations and deviations. 
  ○ Detailed Statistics Text: A detailed text report with quantitative data on 
    image information, alignment statistics, and change detection. 
● Change Map: A placeholder for future advanced change maps. 

2.6 Status, Logs & System Information 

This panel displays detailed log messages and instructions for the user. 


3. Technical Details and Algorithms 

The application is based on robust computer vision algorithms and methods, which 
are briefly explained below: 

3.1 Used Methods and Approaches 

● Toolboxes: The application uses functions from MATLAB's Computer Vision 
  Toolbox, Image Processing Toolbox, and Statistics and Machine Learning 
  Toolbox. 
● Image Preprocessing: 
  ○ Median Filter: Optional for noise reduction on the loaded images to improve 
    subsequent feature detection and change analysis. 
● Image Registration (Alignment): 
  ○ SURF (Speeded Up Robust Features): Used for detecting and extracting 
    local image features in both images. SURF is robust to scaling, rotation, and 
    brightness changes. 
  ○ Feature Matching: The extracted SURF features are matched between the 
    two images to find correspondences. 
  ○ RANSAC (Random Sample Consensus): An iterative algorithm used to 
    estimate the geometric transformation (similarity transform) between the 
    matched features. RANSAC is robust to outliers (incorrectly matched 
    features). The parameters MaxNumTrials (number of trials) and MaxDistance 
    (maximum distance for inliers) have been adjusted to increase robustness in 
    challenging alignment scenarios and minimize warnings such as "Maximum 
    number of trials reached". 
  ○ imwarp: Applies the estimated geometric transformation to align the second 
    image to the first. 
● Change Detection: 
  ○ Pixel Difference: The fundamental method for detecting changes is 
    calculating the absolute difference between the pixel intensities of the two 
    aligned grayscale images. 
  ○ Gaussian Filter: Optionally applied to smooth the difference image and 
    reduce high-frequency noise, which improves the detection of larger, 
    coherent change areas. 
  ○ Thresholding: A binary mask of changes is generated by applying a threshold 
    to the difference image. 
● Change Types (Focus): 
  ○ Geometric Changes: Identified by applying morphological operations (e.g., 
    bwareaopen, imclose, imopen) to the binary change mask to remove small, 
    isolated pixel groups and highlight larger, connected areas. 
  ○ Structural Changes: Detected by comparing local texture (measured, e.g., by 
    standard deviation (stdfilt)) between the two images. This helps identify 
    changes in surface characteristics. 

3.2 Data Processing Pipeline 

The application follows a clear pipeline for processing satellite images: 
1. Image Selection and Loading: The user selects a folder, and the images are 
   loaded. Optionally, a median filter can be applied. 
2. Image Alignment: The later image is aligned to the earlier image to enable 
   precise pixel-to-pixel analysis. 
3. Change Detection: Absolute pixel differences are calculated, smoothed, and 
   converted into a binary change mask based on a threshold. 
4. Visualization: Detected changes are displayed as a heatmap, overlay, or 
   highlights, depending on the user's selection. Sensitivity and change type can be 
   adjusted. 
5. Reporting: Detailed statistics and plots (histogram, scatter plot) are generated to 
   quantify and visualize the analysis results. 

3.3 Results and Outcomes 

The application provides the following results: 
● Visual Representation: Clear and customizable visualizations of changes, 
  allowing for quick identification of where and how the landscape has changed. 
● Quantitative Statistics: Calculation of the percentage of changed pixels, total 
  pixels, and thresholds used for detection. 
● Alignment Metrics: Information on the number of detected features, matches, 
  and inliers, which evaluate the quality of image registration. 
● PDF Report: A summary PDF file (ChangeDetectionReport.pdf) containing the 
  aligned image, feature matching visualization, current change visualization, pixel 
  difference histogram, pixel intensity comparison (scatter plot), and detailed 
  statistics text. This provides comprehensive documentation of the analysis 
  results. 

3.4 Problems and Challenges (and their Solutions) 

During development, challenges arose with the robustness of image alignment, 
especially for images with low texture, strong brightness differences, or complex 
transformations. This manifested in warnings such as "Maximum number of trials 
reached" or "Matrix is close to singular or badly scaled". 
Solution: The parameters of the estimateGeometricTransform2D algorithm were 
adjusted: 
● MaxNumTrials (maximum number of RANSAC trials) was increased from 1000 to 
  2000 to give the algorithm more opportunities to find a correct transformation 
  model. 
● MaxDistance (maximum distance for inlier points) was increased from 1.5 to 3 to 
  make the algorithm more tolerant to small inaccuracies in feature coordinates. 
  These adjustments significantly improved the stability and accuracy of image 
  alignment and reduced the mentioned warnings.
