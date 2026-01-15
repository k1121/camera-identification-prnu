# Camera Identification via PRNU

Supplementary MATLAB scripts for camera source identification using Photo Response Non-Uniformity (PRNU) analysis.

## Overview

This repository contains MATLAB scripts for extracting and analyzing the PRNU fingerprint—a unique camera identifier resulting from manufacturing variations in pixel sensitivity. The implementation includes comprehensive image filtering and metric computation for camera forensics and source identification.

## Features

✅ **PRNU Extraction**
- Automated pipeline for computing camera fingerprints from reference images
- Extraction from 400+ light frames and 320+ dark frames

✅ **Multi-Filter Analysis**
- 11 different filtering methods for noise suppression
- Systematic parameter search and optimization

✅ **Metric Computation**
- 7 correlation metrics: PCC, NSKO, NSKO1, PCE, POC, SER, SSIM
- Quality assessment and validation

✅ **Batch Processing**
- Systematic evaluation across multiple parameter configurations
- CSV export for statistical analysis

✅ **Complete Documentation**
- Comprehensive English documentation
- Usage examples and troubleshooting guide
- Parameter customization instructions

## Repository Structure

```
camera-identification-prnu/
├── scripts/
│   ├── 01_Light_Image_DSNU.m          # Load and average reference images
│   ├── 02_MedFilt.m                   # Median filter evaluation function
│   ├── 03_MedTable.m                  # Parameter sweep for median filtering
│   ├── 04_PRNU_DSNU.m                 # PRNU fingerprint extraction
│   └── 05_calculate_metrics_new.m     # Main analysis pipeline
│
├── docs/
│   └── FILE_STRUCTURE.md              # File organization documentation
│
├── data/                              # Image data (see below)
│   ├── light_images/                  # 400+ frames under uniform illumination
│   ├── dark_images/                   # 320+ frames with lens cap on
│   └── test_images/                   # Test scene images
│
├── results/                           # Auto-generated analysis outputs
│   ├── Light_image.mat                # Average illumination pattern
│   ├── DSNU.mat                       # Dark signal non-uniformity
│   ├── PRNU.mat                       # Camera fingerprint
│   └── Results_*.csv                  # Analysis results
│
└── README.md                          # This file
```

## Dataset Access

**Note:** The image datasets are not stored in this GitHub repository due to file size constraints.

### Accessing the Datasets

The required image datasets (light reference images, dark reference images, and test images) are hosted on a cloud drive:

🔗 **[Download Datasets from Cloud Drive](LINK_TO_YOUR_CLOUD_DRIVE_HERE)**

Replace `LINK_TO_YOUR_CLOUD_DRIVE_HERE` with your actual cloud drive link (Google Drive, Dropbox, OneDrive, etc.)

### Dataset Organization

After downloading, organize the datasets as follows:

```
data/
├── light_images/          # 400+ .tif files (16-bit recommended)
├── dark_images/           # 320+ .tif files (16-bit recommended)
└── test_images/           # Variable number of .tiff files
```

## System Requirements

### Hardware
- Minimum: 4 GB RAM
- Recommended: 8+ GB RAM

### Software
- MATLAB R2016b or newer

### MATLAB Toolboxes
**Required:**
- Image Processing Toolbox
- Signal Processing Toolbox

**Optional:**
- Wavelet Toolbox (for wavelet denoising)

## Quick Start

### Step 1: Compute Reference Images

```matlab
run('01_Light_Image_DSNU.m');
```

**Output:** `Light_image.mat`, `DSNU.mat`  
**Time:** 5-10 minutes

### Step 2: Extract PRNU Fingerprint

```matlab
run('04_PRNU_DSNU.m');
```

**Output:** `PRNU.mat`, `DSNU_S.mat`  
**Time:** 2-3 minutes

### Step 3: Analyze Test Images

```matlab
calculatePRNUCorrelation_FinalWithNSKO();
```

**Output:** `Results_[CameraName].csv`  
**Time:** 10-30 minutes (depends on image count)

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
- **Size:** ~1200 lines with comments

### 02_MedFilt.m
- **Purpose:** Apply median filter and compute quality metrics
- **Input:** Image with noise, window size, reference image
- **Output:** Filtered image and 4 metrics (NSKO, PSNR, SSIM, Correlation)
- **Features:** Complete MATLAB help documentation
- **Size:** ~250 lines

### 03_MedTable.m
- **Purpose:** Systematic evaluation of median filter parameters
- **Input:** Image, reference, min/max window sizes
- **Output:** 4×N metrics table, optimal filtered image
- **Features:** Parameter sweep, performance comparison
- **Size:** ~200 lines

### 04_PRNU_DSNU.m
- **Purpose:** Extract camera fingerprint (PRNU)
- **Input:** Light_image.mat, DSNU.mat
- **Output:** PRNU.mat, DSNU_S.mat
- **Features:** Theoretical explanation, automatic filtering, 6-panel visualization
- **Size:** ~400 lines

### 05_calculate_metrics_new.m
- **Purpose:** Main camera identification analysis pipeline
- **Input:** Test image folder, PRNU.mat
- **Output:** CSV file with metrics for all filter/parameter combinations
- **Features:** 11 filters, 7 metrics, batch processing, error handling
- **Size:** ~1600 lines

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

### Interpretation

**Same Camera Identification:**
- PCC: 0.3-0.5+ (high correlation)
- NSKO: 0.15-0.35 (low error)
- SSIM: 0.70-0.90 (good structure preservation)

**Different Camera Detection:**
- PCC: -0.05 to 0.15 (low/no correlation)
- NSKO: 0.70-1.00 (high error)
- SSIM: 0.10-0.40 (poor structure match)

## Metric Definitions

### PCC (Pearson Correlation Coefficient)
```
PCC = Cov(Image, PRNU) / (σ_Image × σ_PRNU)
```
Linear correlation between high-frequency image and PRNU.  
**Range:** [-1, 1] | **Better:** Higher

### NSKO (Normalized Squared Kernel Output)
```
NSKO = sqrt(sum((Filtered - α×PRNU)²) / sum(Filtered²))
```
Normalized residual after optimal scaling.  
**Range:** [0, 1] | **Better:** Lower

### NSKO1 (Complement of NSKO)
```
NSKO1 = 1 - NSKO
```
**Range:** [0, 1] | **Better:** Higher

### PCE (Peak Correlation Energy)
```
PCE = max(correlation)² / sum(correlation²)
```
Concentration of correlation energy at peak.  
**Range:** [0, Inf] | **Better:** Higher

### POC (Peak Output Correlation)
```
POC = max(correlation) / sum(abs(correlation))
```
Normalized peak correlation.  
**Range:** [0, 1] | **Better:** Higher

### SER (Signal-to-Error Ratio)
```
SER = mean² / variance
```
Signal strength relative to variation.  
**Range:** [0, Inf] | **Better:** Higher

### SSIM (Structural Similarity Index)
Perceived quality based on luminance, contrast, and structure.  
**Range:** [-1, 1] | **Better:** Higher

## Usage Examples

### Basic Analysis

```matlab
% Load and process reference images
run('01_Light_Image_DSNU.m');

% Extract PRNU fingerprint
run('04_PRNU_DSNU.m');

% Analyze test images
calculatePRNUCorrelation_FinalWithNSKO();

% Load and examine results
results = readtable('Results_Camera_1.csv');
disp(results(results.PCC > 0.3, :));  % Show good matches
```

### Finding Optimal Filter Parameters

```matlab
% Load results
results = readtable('Results_Camera_1.csv');

% Group by filter method
filters = unique(results.Filter);

for f = 1:length(filters)
    subset = results(strcmp(results.Filter, filters{f}), :);
    [maxPCC, idx] = max(subset.PCC);
    fprintf('Optimal %s: PCC = %.4f\n', filters{f}, maxPCC);
end
```

### Comparing Multiple Cameras

```matlab
% Run analysis for each camera
cameras = {'Camera_1', 'Camera_2', 'Camera_3'};

for c = 1:length(cameras)
    % Update config.CameraName in script
    calculatePRNUCorrelation_FinalWithNSKO();
end

% Compare results
data1 = readtable('Results_Camera_1.csv');
data2 = readtable('Results_Camera_2.csv');

% Same camera should show high PCC
% Different cameras should show low PCC
```

## Troubleshooting

### Out of Memory Error
- Reduce number of test images
- Close other MATLAB windows
- Increase MATLAB heap size (Preferences → Memory)

### PRNU Not Loading
- Verify `PRNU.mat` exists in current directory
- Run script 04 first to generate PRNU.mat
- Check file permissions

### Low Correlation Scores
- Verify images are from the same camera
- Check image resolution (should match reference)
- Use well-lit scenes with good content diversity
- Try different filter methods
- Check script configuration paths

### CSV File Write Error
- Verify `data/test_images/` directory exists
- Check write permissions
- Use absolute paths instead of relative

### "Permission denied" Error
- Close files that might be locked
- Check if PRNU.mat is open in another program
- Run MATLAB as administrator

## Installation and Setup

### Step 1: Verify MATLAB Installation
```matlab
>> ver
```
Check for Image Processing Toolbox and Signal Processing Toolbox.

### Step 2: Download Scripts
- Copy all 5 .m files to your working directory
- Or clone this repository

### Step 3: Download Datasets
- Download image datasets from the cloud drive link above
- Extract to `data/` directory

### Step 4: Create Directory Structure
```bash
mkdir data
mkdir data/light_images
mkdir data/dark_images
mkdir data/test_images
mkdir results
```

### Step 5: Update Configuration
- Update paths in scripts (see Configuration section)
- Adjust pixel normalization if needed

### Step 6: Run Analysis
- Execute scripts in order: 01 → 04 → 05
- Examine results in `Results_*.csv`

## Advanced Usage

### Custom Filter Parameters

Edit `config.FilterParamsList` in script 05:

```matlab
config.FilterParamsList = struct(...
    'Gaussian', struct('Sigma', {num2cell(1:1:10)}), ...
    'Median', struct('Window', {num2cell(3:2:15)}), ...
);
```

### Different Image Formats

```matlab
config.ImageFormat = '.jpg';    % For JPEG images
config.ImageFormat = '.png';    % For PNG images
config.ImageFormat = '.raw';    % For RAW images
```

### Custom Normalization

```matlab
CurrentImage = CurrentImage ./ 32;  % 8-bit camera
CurrentImage = CurrentImage ./ 256; % Different normalization
```

## Citation

If you use this code in research, please cite:

```bibtex
@article{YourAuthor2024,
  title={Your Paper Title},
  author={Your Name},
  year={2024}
}
```

## References

1. Fridrich, J., Soukal, D., & Lukin, A. J. (2003). "Detection of copy-move forgery in digital images." *Proceedings of the Digital Forensic Research Workshop*.

2. Chen, M., Fridrich, J., Goljan, M., & Lukáš, J. (2007). "Determining image origin and integrity using sensor noise." *IEEE Transactions on Information Forensics and Security*.

3. Lukas, J., Fridrich, J., & Goljan, M. (2006). "Digital camera identification from sensor pattern noise." *IEEE Transactions on Information Forensics and Security*.

## License

This code is released under the MIT License. See [LICENSE](LICENSE) file for full terms.

## Contact and Support

For questions or issues:
- Review documentation files (FILE_STRUCTURE.md, etc.)
- Check the troubleshooting section above
- Open GitHub issues if code is on GitHub

For research collaboration:
- Contact information available on GitHub profile

## Changelog

### Version 1.0.0 (January 2026)
- Initial release
- 5 core MATLAB scripts
- 11 filtering methods
- 7 correlation metrics
- Complete documentation
- Multiple installation guides

---

**Last updated:** January 15, 2026  
**Language:** English  
**Status:** Ready for production use

For more information, see accompanying documentation files:
- `FILE_STRUCTURE.md` - Detailed file and folder descriptions
- `GITHUB_WEB_UPLOAD.md` - Instructions for GitHub upload
- `SUMMARY.md` - Complete project summary
