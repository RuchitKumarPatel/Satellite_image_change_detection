# Satellite Change Detection System

A comprehensive MATLAB-based system for detecting and analyzing changes in satellite imagery using multiple computer vision algorithms.

## Features

- **Multi-algorithm change detection**: Fusion of multiple detection methods for robust results
- **Adaptive image preprocessing**: Automatic adjustment for different satellite image types
- **Feature-based alignment**: Multiple feature detection methods (SURF, ORB, Harris)
- **Flexible visualization**: Various visualization methods for change analysis
- **Comprehensive reporting**: PDF generation with statistical analysis
- **Global compatibility**: Works with various satellite image formats and landscapes

## Repository Structure

```
satellite-change-detection/
│
├── main.m                          # Main launcher file
├── README.md                       # This file
│
├── gui/                           # GUI components
│   └── createMainGUI.m           # Main GUI creation and layout
│
├── preprocessing/                 # Image preprocessing modules
│   └── imagePreprocessing.m     # Adaptive preprocessing algorithms
│
├── alignment/                     # Image alignment modules
│   └── featureAlignment.m       # Feature-based alignment methods
│
├── detection/                     # Change detection algorithms
│   └── changeDetection.m        # Multiple detection methods
│
├── visualization/                 # Visualization modules
│   └── changeVisualization.m    # Various visualization methods
│
├── callbacks/                     # GUI callback functions
│   └── imageCallbacks.m         # Event handlers for GUI
│
├── utils/                        # Utility functions
│   ├── checkToolboxes.m         # Check MATLAB toolbox availability
│   └── reportGeneration.m       # PDF report generation
│
└── tests/                        # Test scripts
    └── testSystem.m              # Comprehensive system tests
```

## Installation

1. Clone or download this repository
2. Ensure MATLAB is installed (R2019b or later recommended)
3. Required toolboxes:
   - Image Processing Toolbox (highly recommended)
   - Computer Vision Toolbox (recommended for feature-based alignment)
   - Statistics and Machine Learning Toolbox (optional)

## Usage

### Quick Start

1. Open MATLAB and navigate to the repository folder
2. Run the main launcher:
```matlab
main()
```
3. The GUI will open automatically
4. Follow the on-screen instructions:
   - Click "Select Folder" to choose a folder with satellite images
   - Click "Load Images" to load the images
   - Select image pairs using the dropdown menus
   - Click "Preprocess" to apply adaptive preprocessing
   - Click "Align" to align the images
   - Click "Detect Changes" to run change detection
   - Click "Export Results" to save your analysis

### Command Line Usage

You can also use the modules programmatically:

```matlab
% Load and preprocess images
img1 = imread('satellite_2020.jpg');
img2 = imread('satellite_2021.jpg');

% Preprocess images
params = struct('clipLimit', 0.02);
img1_processed = imagePreprocessing(img1, 'auto', params);
img2_processed = imagePreprocessing(img2, 'auto', params);

% Align images
[alignedImg2, tform, stats] = featureAlignment(img1_processed, img2_processed, 'auto', []);

% Detect changes
[changeMap, changeMask, changeStats] = changeDetection(img1_processed, alignedImg2, 'fusion', []);

% Visualize results
vizResult = changeVisualization(img1_processed, alignedImg2, changeMap, changeMask, 'heatmap', []);
```

## Algorithm Details

### Preprocessing Methods
- **Auto**: Automatic adjustment based on image characteristics
- **Enhance**: Contrast enhancement using adaptive histogram equalization
- **Denoise**: Noise reduction using guided or median filtering
- **Normalize**: Dynamic range normalization
- **Multispectral**: Special handling for multispectral imagery

### Alignment Methods
- **SURF**: Speeded-Up Robust Features
- **ORB**: Oriented FAST and Rotated BRIEF
- **Harris**: Harris corner detection
- **SIFT**: Scale-Invariant Feature Transform (if available)
- **Intensity**: Intensity-based registration

### Change Detection Methods
- **Fusion**: Multi-algorithm fusion for robust detection
- **Pixel Difference**: Simple pixel-wise comparison
- **SSIM**: Structural Similarity Index
- **Edge Detection**: Edge-based change analysis
- **Texture Analysis**: Texture feature comparison
- **Spectral Analysis**: Spectral angle mapping for multispectral images

### Visualization Methods
- **Heatmap**: Color-coded change intensity map
- **Overlay**: Changes overlaid on original image
- **Side-by-side**: Before/after comparison
- **Animation**: Animated transition between images
- **False Color**: RGB composite visualization
- **Temporal**: Temporal change direction visualization

## Testing

Run the test suite to verify system functionality:

```matlab
cd tests
testSystem()
```

This will test all major components and report any issues.

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- TIFF (.tif, .tiff)
- BMP (.bmp)
- JPEG 2000 (.jp2)
- HDF (.hdf)
- GeoTIFF (.geotiff)

## System Requirements

- MATLAB R2019b or later
- Minimum 4GB RAM (8GB recommended for large images)
- Windows, macOS, or Linux

## Performance Tips

1. **For large images**: Consider downsampling before processing
2. **For batch processing**: Use the command-line interface
3. **For faster alignment**: Start with SURF or ORB methods
4. **For highest accuracy**: Use multi-algorithm fusion

## Troubleshooting

### Common Issues

1. **"Feature detection failed"**
   - Ensure images have sufficient texture/features
   - Try adjusting the metric threshold parameters
   - Use intensity-based alignment as fallback

2. **"Insufficient memory"**
   - Downsample large images before processing
   - Close other applications
   - Process images in smaller batches

3. **"Toolbox not available"**
   - The system will still work with limited functionality
   - Consider installing recommended toolboxes for full features

## Citation

If you use this system in your research, please cite:
```
Satellite Change Detection System
MATLAB Implementation
Version 2.0, 2024
```

## License

This project is provided for educational and research purposes.

## Contributing

Contributions are welcome! Please ensure:
- Code follows the existing structure
- Functions are well-documented
- Tests are included for new features

## Support

For issues or questions:
1. Check the troubleshooting section
2. Run the test script to identify problems
3. Review the example usage in the documentation

## Acknowledgments

This system implements various computer vision algorithms from the literature and MATLAB's toolboxes for comprehensive satellite image analysis.
