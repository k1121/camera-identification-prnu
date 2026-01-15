================================================================================
                    CAMERA IDENTIFICATION VIA PRNU
                  Supplementary MATLAB Scripts and Code
================================================================================

PROJECT OVERVIEW
================================================================================

This repository contains MATLAB scripts for extracting and analyzing the PRNU 
fingerprint (Photo Response Non-Uniformity) - a unique camera identifier 
resulting from manufacturing variations in pixel sensitivity.

The implementation includes comprehensive image filtering and metric computation 
for camera forensics and source identification.

SUPPORTED FEATURES
================================================================================

PRNU Extraction
  - Automated pipeline for computing camera fingerprints from reference images
  - Extraction from 400+ light frames and 320+ dark frames

Multi-Filter Analysis  
  - 11 different filtering methods for noise suppression
  - Systematic parameter search and optimization
  
Metric Computation
  - 7 correlation metrics: PCC, NSKO, NSKO1, PCE, POC, SER, SSIM
  - Quality assessment and validation

Batch Processing
  - Systematic evaluation across multiple parameter configurations
  - CSV export for statistical analysis


REPOSITORY STRUCTURE
================================================================================

camera-identification-prnu/
├── scripts/
│   ├── 01_Light_Image_DSNU.m          Load and average reference images
│   ├── 02_MedFilt.m                   Median filter evaluation function
│   ├── 03_MedTable.m                  Parameter sweep for median filtering
│   ├── 04_PRNU_DSNU.m                 PRNU fingerprint extraction
│   └── 05_calculate_metrics_new.m     Main analysis pipeline
│
│
├── data/                              (image data)
│
├── results/                           (auto-generated analysis outputs)
│   ├── Light_image.mat                Average illumination pattern
│   ├── DSNU.mat                       Dark signal non-uniformity
│   ├── PRNU.mat                       Camera fingerprint
│   └── Results_*.csv                  Analysis results
│
└── README.txt                         This file

REQUIRED DATA
================================================================================

The analysis requires three datasets from each camera:

1. LIGHT REFERENCE IMAGES (data/light_images/)
   - Format: .tif files (16-bit recommended)
   - Count: 400+ images
   - Condition: Uniform illumination, fixed aperture/focus
   - Purpose: Estimate illumination pattern and pixel sensitivity

2. DARK REFERENCE IMAGES (data/dark_images/)
   - Format: .tif files (same as light images)
   - Count: 320+ images  
   - Condition: Complete darkness (lens cap on)
   - Purpose: Measure dark signal non-uniformity and read noise

3. TEST IMAGES (data/test_images/)
   - Format: .tiff files (any scene content)
   - Count: Variable
   - Condition: Any natural scene
   - Purpose: Test camera identification accuracy

SYSTEM REQUIREMENTS
================================================================================

SOFTWARE:
  - MATLAB R2016b or newer
  
MATLAB TOOLBOXES (Required):
  - Image Processing Toolbox
  - Signal Processing Toolbox
  
MATLAB TOOLBOXES (Optional):
  - Wavelet Toolbox (for wavelet denoising)

QUICK START
================================================================================

STEP 1: Compute Reference Images
  1. Open MATLAB
  2. Run: 01_Light_Image_DSNU.m
  3. Output: Light_image.mat, DSNU.mat

STEP 2: Extract PRNU Fingerprint
  1. Open MATLAB
  2. Run: 04_PRNU_DSNU.m
  3. Output: PRNU.mat, DSNU_S.mat

STEP 3: Analyze Test Images
  1. Open MATLAB
  2. Run: calculatePRNUCorrelation_FinalWithNSKO()
  3. Output: Results_[CameraName].csv

CONFIGURATION
================================================================================

Before running scripts, update these paths:

IN SCRIPT 01 (01_Light_Image_DSNU.m):
  ImageFolder = 'data/light_images/';    % Update path to light images
  DarkFolder = 'data/dark_images/';      % Update path to dark images

IN SCRIPT 05 (05_calculate_metrics_new.m):
  config.ParentFolder = 'data/test_images/';    % Update path
  config.CameraName = 'Camera_Name';             % Camera identifier
  config.ImageFormat = '.tiff';                  % Image format

PIXEL NORMALIZATION:
  In script 01, check normalization factor (typically 64 for 16-bit cameras):
  CurrentImage = CurrentImage ./ 64;     % Adjust based on your camera

MATLAB SCRIPTS OVERVIEW
================================================================================

01_LIGHT_IMAGE_DSNU.M
  Purpose: Load and average camera reference images
  Input: 400+ light frames + 320+ dark frames
  Output: Light_image.mat, DSNU.mat
  Features:
    - Automatic image normalization
    - Visualization of results
    - Statistical analysis

02_MEDFILT.M
  Purpose: Apply median filter and compute quality metrics
  Type: Function (called by other scripts)
  Input: Image with noise, window size, reference image
  Output: Filtered image and metrics (NSKO, PSNR, SSIM, Correlation)
  Features:
    - 4 quality metrics per image
    - Both filtered and unfiltered results
    - Complete MATLAB help documentation

03_MEDTABLE.M
  Purpose: Systematic evaluation of median filter parameters
  Type: Parameter sweep function
  Input: Image, reference, min/max window sizes
  Output: 4×N metrics table, optimal filtered image
  Features:
    - Tests range of window sizes
    - Performance comparison
    - Usage examples

04_PRNU_DSNU.M
  Purpose: Extract camera fingerprint (PRNU)
  Input: Light_image.mat, DSNU.mat
  Output: PRNU.mat, DSNU_S.mat
  Features:
    - Complete theoretical explanation
    - Automatic filtering and smoothing
    - Statistical analysis
    - 6-panel visualization

05_CALCULATE_METRICS_NEW.M
  Purpose: Main camera identification analysis pipeline
  Input: Test image folder, PRNU.mat
  Output: CSV file with metrics for all filter/parameter combinations
  Features:
    - 11 filtering methods
    - 7 correlation metrics
    - Batch processing of images
    - Progress bar and error handling
    - CSV export for analysis
  
  Supported Filters (11):
    1. Gaussian        (smoothing)
    2. Median          (rank-based noise suppression)
    3. Average         (mean-based smoothing)
    4. NLM             (non-local means denoising)
    5. Frost           (speckle reduction)
    6. Lee             (adaptive speckle filter)
    7. Guided          (edge-preserving smoothing)
    8. TV              (total variation denoising)
    9. Bilateral       (edge-aware smoothing)
    10. Wavelet        (frequency-domain denoising)
    11. Wiener         (optimal noise suppression)

  Computed Metrics (7):
    - PCC:   Pearson Correlation Coefficient (range: [-1, 1])
    - NSKO:  Normalized Squared Kernel Output (range: [0, 1])
    - NSKO1: Complement of NSKO (range: [0, 1])
    - PCE:   Peak Correlation Energy (range: [0, Inf])
    - POC:   Peak Output Correlation (range: [0, 1])
    - SER:   Signal-to-Error Ratio (range: [0, Inf])
    - SSIM:  Structural Similarity Index (range: [-1, 1])

OUTPUT FORMAT
================================================================================

CSV Results File: Results_[CameraName].csv

Columns:
  Camera          - Camera identifier
  ImageName       - Test image filename
  Filter          - Filtering method used
  PCC             - Pearson Correlation Coefficient
  NSKO            - Normalized Squared Kernel Output
  NSKO1           - Complement of NSKO
  PCE             - Peak Correlation Energy
  POC             - Peak Output Correlation
  SER             - Signal-to-Error Ratio
  SSIM            - Structural Similarity Index
  Param_*         - Filter-specific parameters

METRIC DEFINITIONS
================================================================================

PCC (Pearson Correlation Coefficient)
  PCC = Cov(Image, PRNU) / (σ_Image × σ_PRNU)
  Linear correlation between high-frequency image and PRNU
  Range: [-1, 1], Higher is better

NSKO (Normalized Squared Kernel Output)
  NSKO = sqrt(sum((Filtered - α×PRNU)²) / sum(Filtered²))
  where α is optimal scaling coefficient
  Normalized residual after optimal scaling
  Range: [0, 1], Lower is better

NSKO1 (Complement of NSKO)
  NSKO1 = 1 - NSKO
  Range: [0, 1], Higher is better

PCE (Peak Correlation Energy)
  PCE = max(correlation)² / sum(correlation²)
  Concentration of correlation energy at peak
  Range: [0, Inf], Higher is better

POC (Peak Output Correlation)
  POC = max(correlation) / sum(abs(correlation))
  Normalized peak correlation
  Range: [0, 1], Higher is better

SER (Signal-to-Error Ratio)
  SER = mean² / variance
  Signal strength relative to variation
  Range: [0, Inf], Higher is better

SSIM (Structural Similarity Index)
  Perceived quality based on luminance, contrast, structure
  Range: [-1, 1], Higher is better


CONTACT AND SUPPORT
================================================================================

For questions or issues:
  - Review troubleshooting section above
  - Open GitHub issues if code is on GitHub

For research collaboration:
  - Contact information available on GitHub profile


