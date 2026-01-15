%% PHOTO RESPONSE NON-UNIFORMITY (PRNU) AND DSNU EXTRACTION
%
% This script extracts the Photo Response Non-Uniformity (PRNU) fingerprint,
% which serves as a unique identifier for camera devices.
%
% PRNU represents pixel-level sensitivity variations caused by manufacturing
% imperfections. It is computed from the difference between actual and
% expected pixel responses using appropriate filtering.

clear all; close all; clc;

%% STEP 1: LOAD REFERENCE IMAGES
% Load previously computed light and dark reference images

fprintf('Loading reference images...\n');
load('Light_image.mat', 'Light_Image');  % Illumination pattern
load('DSNU.mat', 'DSNU');                 % Dark signal non-uniformity

if ~exist('Light_Image', 'var') || ~exist('DSNU', 'var')
    error('Reference images not found. Run 01_Light_Image_DSNU.m first.');
end

fprintf('Light image size: %d x %d\n', size(Light_Image, 1), size(Light_Image, 2));
fprintf('DSNU size: %d x %d\n', size(DSNU, 1), size(DSNU, 2));

%% STEP 2: COMPUTE PRNU FROM ILLUMINATION PATTERN
% 
% Theory: PRNU is the multiplicative noise component in the image formation model:
%   I = L + D + (L * K)
% where:
%   I = observed pixel intensity
%   L = expected illumination (light reference)
%   D = additive noise (DSNU)
%   K = multiplicative noise (PRNU)
%
% We extract PRNU using the formula:
%   PRNU = ((L - D) / Smooth(L - D)) - 1
%
% The smooth function removes noise while preserving the PRNU pattern.

fprintf('\nExtracting PRNU from illumination pattern...\n');

% Compute illumination pattern (light image minus dark signal)
IlluminationPattern = Light_Image - DSNU;

% Apply median filtering to smooth the image
% This removes high-frequency noise while preserving PRNU structure
fprintf('Applying median filter (9x9 kernel)...\n');
[MedianFiltersMetrics, SmoothImage] = MedTable(IlluminationPattern, IlluminationPattern, 9, 9);

% Alternative: Could use other filters like Gaussian, guided, etc.
% See calculate_metrics_new.m for advanced filtering options

% Extract PRNU as the residual pattern
PRNU = (IlluminationPattern ./ SmoothImage) - 1;

fprintf('PRNU extracted: %d x %d\n', size(PRNU, 1), size(PRNU, 2));
fprintf('PRNU range: [%.6f, %.6f]\n', min(PRNU(:)), max(PRNU(:)));
fprintf('PRNU mean: %.6e\n', mean(PRNU(:)));
fprintf('PRNU std: %.6e\n', std(PRNU(:)));

% Save PRNU fingerprint
save('PRNU.mat', 'PRNU');
fprintf('Saved: PRNU.mat\n');

%% STEP 3: COMPUTE FILTERED DSNU
%
% Similar to PRNU extraction, compute a smoothed version of DSNU
% for use in correlation analysis with test images.

fprintf('\nExtracting filtered DSNU...\n');

% Apply median filtering to DSNU
fprintf('Applying median filter (9x9 kernel)...\n');
[DsUniformityMetrics, SmoothedDSNU] = MedTable(DSNU, DSNU, 9, 9);

% Extract smoothed DSNU pattern
DSNU_Smoothed = (DSNU ./ SmoothedDSNU) - 1;

fprintf('DSNU_Smoothed extracted: %d x %d\n', size(DSNU_Smoothed, 1), size(DSNU_Smoothed, 2));
fprintf('DSNU_Smoothed range: [%.6f, %.6f]\n', min(DSNU_Smoothed(:)), max(DSNU_Smoothed(:)));

% Save filtered DSNU
save('DSNU_S.mat', 'DSNU_Smoothed');
fprintf('Saved: DSNU_S.mat\n');

%% STEP 4: VISUALIZATION OF EXTRACTED PATTERNS

figure('Name', 'PRNU and DSNU Extraction', 'NumberTitle', 'off');

% Original illumination pattern
subplot(2, 3, 1);
imagesc(IlluminationPattern);
colormap(gca, gray);
colorbar;
title('Original Illumination (Light - Dark)');
xlabel('Pixel X');
ylabel('Pixel Y');

% Smoothed pattern
subplot(2, 3, 2);
imagesc(SmoothImage);
colormap(gca, gray);
colorbar;
title('Smoothed Pattern (Median Filtered)');
xlabel('Pixel X');
ylabel('Pixel Y');

% PRNU fingerprint
subplot(2, 3, 3);
imagesc(PRNU);
colormap(gca, gray);
colorbar;
title('Extracted PRNU');
xlabel('Pixel X');
ylabel('Pixel Y');

% DSNU pattern
subplot(2, 3, 4);
imagesc(DSNU);
colormap(gca, gray);
colorbar;
title('Dark Signal Non-Uniformity');
xlabel('Pixel X');
ylabel('Pixel Y');

% Smoothed DSNU
subplot(2, 3, 5);
imagesc(SmoothedDSNU);
colormap(gca, gray);
colorbar;
title('Smoothed DSNU');
xlabel('Pixel X');
ylabel('Pixel Y');

% Filtered DSNU
subplot(2, 3, 6);
imagesc(DSNU_Smoothed);
colormap(gca, gray);
colorbar;
title('Extracted DSNU Fingerprint');
xlabel('Pixel X');
ylabel('Pixel Y');

sgtitle('PRNU and DSNU Fingerprint Extraction');

%% STEP 5: STATISTICAL ANALYSIS

fprintf('\n========== STATISTICAL SUMMARY ==========\n');

% Analyze PRNU characteristics
prnu_mean = mean(PRNU(:));
prnu_std = std(PRNU(:));
prnu_min = min(PRNU(:));
prnu_max = max(PRNU(:));
prnu_range = prnu_max - prnu_min;

fprintf('\nPRNU Statistics:\n');
fprintf('  Mean:        %.6e\n', prnu_mean);
fprintf('  Std Dev:     %.6e\n', prnu_std);
fprintf('  Min:         %.6e\n', prnu_min);
fprintf('  Max:         %.6e\n', prnu_max);
fprintf('  Range:       %.6e\n', prnu_range);
fprintf('  Signal-to-Noise Ratio: %.2f (std/max)\n', 100 * prnu_std / prnu_range);

% Analyze DSNU characteristics
dsnu_s_mean = mean(DSNU_Smoothed(:));
dsnu_s_std = std(DSNU_Smoothed(:));
dsnu_s_min = min(DSNU_Smoothed(:));
dsnu_s_max = max(DSNU_Smoothed(:));

fprintf('\nFiltered DSNU Statistics:\n');
fprintf('  Mean:        %.6e\n', dsnu_s_mean);
fprintf('  Std Dev:     %.6e\n', dsnu_s_std);
fprintf('  Min:         %.6e\n', dsnu_s_min);
fprintf('  Max:         %.6e\n', dsnu_s_max);

fprintf('\n=========================================\n\n');

%% NOTES
%
% 1. PRNU Extraction Method:
%    - This script uses median filtering for smoothing
%    - Alternative filters (Gaussian, guided, Wiener) can be substituted
%    - See calculate_metrics_new.m for advanced filtering options
%
% 2. Quality Parameters:
%    - Median filter window size: 9x9 (adjust if needed)
%    - Larger windows = more aggressive smoothing
%    - Window size should be odd number for symmetry
%
% 3. Output Files:
%    - PRNU.mat: Camera fingerprint for forensic analysis
%    - DSNU_S.mat: Filtered dark signal pattern
%
% 4. Usage in Testing:
%    - These extracted fingerprints are used in calculate_metrics_new.m
%    - Correlate PRNU with test images to identify camera source
%    - Compare with DSNU for additional validation
%
% 5. Camera Identification:
%    - PRNU is unique per camera device (manufacturing variation)
%    - Different cameras will have different PRNU patterns
%    - Same camera will produce consistent PRNU across images
%
% 6. Typical PRNU Characteristics:
%    - Standard deviation: 0.001 - 0.01 (camera dependent)
%    - Approximately zero mean
%    - Random spatial distribution
%    - Consistent across images from same device
%