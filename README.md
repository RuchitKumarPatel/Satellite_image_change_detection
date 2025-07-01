# Advanced Image Alignment & Timelapse Tool

![GUI Screenshot](screenshot.png)  
*Example of the GUI interface*

A MATLAB-based tool for aligning images and creating timelapse videos, featuring both feature-based and intensity-based alignment methods.

## Features

- **Dual Image Alignment**: Align two different images using robust algorithms
- **Multiple Display Modes**: 
  - Single image view
  - Blended overlay (with adjustable transparency)
  - Difference heatmap
- **Timelapse Creation**: Generate stabilized timelapse videos from image sequences
- **Interactive GUI**: Intuitive controls for image selection and processing

## System Requirements

- MATLAB R2018b or later
- Computer Vision Toolbox
- Image Processing Toolbox

## Installation

1. Clone this repository or download the `so_cv_challenge.m` file
2. Open MATLAB and navigate to the file location
3. Run the script by typing `so_cv_challenge` in the MATLAB command window

## Usage Guide

### Loading Images
1. Click **"Load Folder"** to select a directory containing your images
2. Supported formats: PNG, JPG/JPEG, BMP, TIFF

### Selecting Images
- Use the ▲/▼ buttons in the left panel to select Image 1
- Use the ▲/▼ buttons in the right panel to select Image 2

### Aligning Images
1. Select two different images using the navigation buttons
2. Click **"Align Images"** to perform alignment
3. The system will:
   - First attempt feature-based alignment using SURF
   - Fall back to intensity-based alignment if needed

### Viewing Results
- Click **"Next Display"** to cycle through viewing modes:
  1. Image 1 only
  2. Image 2 only
  3. Blended overlay (adjust blend with slider)
  4. Difference heatmap

### Creating Timelapses
1. Load a sequence of images
2. Click **"Create Timelapse"**
3. Select output location and filename (MP4 format)
4. The tool will:
   - Align all images to the first frame
   - Create a stabilized video at 10fps

## Technical Details

### Alignment Methods

#### 1. Feature-Based (SURF)
- Detects SURF features with threshold = 500
- Extracts and matches features between images
- Estimates rigid transform using RANSAC
- Validates transform quality

#### 2. Intensity-Based (Fallback)
- Uses monomodal registration configuration
- Optimizes for rigid transformation
- Maximum 300 iterations

### Timelapse Processing
- All frames aligned to first image's coordinate system
- Maintains last successful transform if alignment fails
- MPEG-4 video output at 10 frames per second

## Troubleshooting

**Problem**: Alignment fails  
**Solution**:
- Try images with more distinctive features
- Ensure images have sufficient overlap
- Check that images aren't too blurry

**Problem**: Error loading images  
**Solution**:
- Verify all files are valid images
- Check MATLAB has read permissions
- Ensure files have supported extensions

**Problem**: Poor timelapse quality  
**Solution**:
- Use images with consistent lighting
- Ensure sequence has sufficient frame-to-frame overlap
- Consider pre-processing images for consistency

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Developed using MATLAB's Computer Vision and Image Processing Toolboxes.
