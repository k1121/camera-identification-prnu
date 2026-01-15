# Camera Identification via PRNU

Supplementary MATLAB scripts for camera source identification using Photo Response Non-Uniformity (PRNU) analysis.

## Overview

This repository contains MATLAB scripts for extracting and analyzing the PRNU fingerprint—a unique camera identifier resulting from manufacturing variations in pixel sensitivity. The implementation includes comprehensive image filtering and metric computation for camera forensics and source identification.

## Features

**PRNU Extraction**
- Automated pipeline for computing camera fingerprints from reference images
- Extraction from 400+ light frames and 320+ dark frames

**Multi-Filter Analysis**
- 11 different filtering methods for noise suppression
- Systematic parameter search and optimization

**Metric Computation**
- 6 correlation metrics: PCC, NSTD, PCE, POC, SER, SSIM
- Quality assessment and validation

**Batch Processing**
- Systematic evaluation across multiple parameter configurations
- CSV export for statistical analysis

## Dataset Access

**Note:** The image datasets are not stored in this GitHub repository due to file size constraints.

### Accessing the Datasets

The required image datasets (light reference images, dark reference images, and test images) are hosted on a cloud drive:

LINK

## System Requirements

### Software
- MATLAB R2016b or newer

### MATLAB Toolboxes
**Required:**
- Image Processing Toolbox
- Signal Processing Toolbox

**Optional:**
- Wavelet Toolbox (for wavelet denoising)

## Configuration

Before running scripts, update these paths:

### In Script 01 (`01_Light_Image_DSNU.m`):
```matlab
ImageFolder = 'data/light_images/';    % Update path to light images
DarkFolder = 'data/dark_images/';      % Update path to dark images
```

### In Script 05 (`05_calculate_metrics_new.m`):
```matlab
config.ParentFolder = 'data/test_images/';    % Path to test images
config.CameraName = 'Camera_Name';             % Camera identifier
config.ImageFormat = '.tiff';                  % Image format
```

### Pixel Normalization

In script 01, adjust the normalization factor based on your camera (typically 64 for 16-bit cameras):
```matlab
CurrentImage = CurrentImage ./ 64;     % Adjust as needed
```

## MATLAB Scripts Overview

### 01_Light_Image_DSNU.m
- **Purpose:** Load and average camera reference images
- **Input:** 400+ light frames + 320+ dark frames
- **Output:** Light_image.mat, DSNU.mat
- **Features:** Automatic normalization, visualization, statistical analysis

### 02_MedFilt.m
- **Purpose:** Apply median filter and compute quality metrics
- **Input:** Image with noise, window size, reference image
- **Output:** Filtered image and 4 metrics (NSKO, PSNR, SSIM, Correlation)

### 03_MedTable.m
- **Purpose:** Systematic evaluation of median filter parameters
- **Input:** Image, reference, min/max window sizes
- **Output:** 4×N metrics table, optimal filtered image
- **Features:** Parameter sweep, performance comparison
- 
### 04_PRNU_DSNU.m
- **Purpose:** Extract camera fingerprint (PRNU)
- **Input:** Light_image.mat, DSNU.mat
- **Output:** PRNU.mat, DSNU_S.mat
- **Features:** Theoretical explanation, automatic filtering, 6-panel visualization

### 05_calculate_metrics_new.m
- **Purpose:** Main camera identification analysis pipeline
- **Input:** Test image folder, PRNU.mat
- **Output:** CSV file with metrics for all filter/parameter combinations
- **Features:** 11 filters, 7 metrics, batch processing, error handling

#### Supported Filters (11)
1. Gaussian - Gaussian blur smoothing
2. Median - Rank-based noise suppression
3. Average - Mean-based smoothing
4. NLM - Non-local means denoising
5. Frost - Speckle reduction
6. Lee - Adaptive speckle filter
7. Guided - Edge-preserving smoothing
8. TV - Total variation denoising
9. Bilateral - Edge-aware smoothing
10. Wavelet - Frequency-domain denoising
11. Wiener - Optimal noise suppression

#### Computed Metrics (7)
- **PCC** - Pearson Correlation Coefficient (range: [-1, 1])
- **NSKO** - Normalized Squared Kernel Output (range: [0, 1])
- **NSKO1** - Complement of NSKO (range: [0, 1])
- **PCE** - Peak Correlation Energy (range: [0, Inf])
- **POC** - Peak Output Correlation (range: [0, 1])
- **SER** - Signal-to-Error Ratio (range: [0, Inf])
- **SSIM** - Structural Similarity Index (range: [-1, 1])

## Output Format

### CSV Results File: `Results_[CameraName].csv`

| Column | Description |
|--------|-------------|
| Camera | Camera identifier |
| ImageName | Test image filename |
| Filter | Filtering method used |
| PCC | Pearson Correlation Coefficient |
| NSKO | Normalized Squared Kernel Output |
| NSKO1 | Complement of NSKO |
| PCE | Peak Correlation Energy |
| POC | Peak Output Correlation |
| SER | Signal-to-Error Ratio |
| SSIM | Structural Similarity Index |
| Param_* | Filter-specific parameters |


## Contact and Support

For research collaboration:
- Contact information available on GitHub profile
