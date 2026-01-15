%% CALCULATE LIGHT IMAGE AND DARK SIGNAL NON-UNIFORMITY (DSNU)
%
% This script computes reference images for camera identification using PRNU.
% It processes raw camera images to extract:
%   - Light reference image (averaged over multiple light frames)
%   - Dark signal non-uniformity (DSNU) component
%
% These outputs are used as inputs for PRNU extraction and camera fingerprinting.
%

clear all; close all; clc;

%% STEP 1: LOAD AND AVERAGE LIGHT IMAGES
% Process light frames to create reference illumination pattern

% Configure path to light images directory
ImageFolder = 'data/light_images/';  % Update with your light images path
ImageFormat = '.tif';

% List all light images
LightImages = dir(fullfile(ImageFolder, ['*' ImageFormat]));
TotalLightFrames = min(400, length(LightImages));  % Use up to 400 frames

fprintf('Processing %d light frames...\n', TotalLightFrames);

% Initialize accumulator for light frames
LightAccumulator = [];

% Loop through light images
for frameIdx = 1:TotalLightFrames
    % Read image
    CurrentImage = double(imread(fullfile(ImageFolder, LightImages(frameIdx).name)));
    
    % Normalize pixel values (adjust divisor based on camera bit depth)
    % For 16-bit cameras: typically divide by 64 (2^6)
    CurrentImage = CurrentImage ./ 64;
    
    % Accumulate for averaging
    if frameIdx == 1
        LightAccumulator = CurrentImage;
    else
        LightAccumulator = LightAccumulator + CurrentImage;
    end
end

% Compute average light image
Light_Image = LightAccumulator ./ TotalLightFrames;

fprintf('Light image computed: %d x %d pixels\n', size(Light_Image, 1), size(Light_Image, 2));

% Save light reference image
save('Light_image.mat', 'Light_Image');
fprintf('Saved: Light_image.mat\n');

%% STEP 2: LOAD AND AVERAGE DARK IMAGES
% Process dark frames to extract DSNU (zero-light response)

DarkFolder = 'data/dark_images/';  % Update with your dark images path
DarkImages = dir(fullfile(DarkFolder, ['*' ImageFormat]));
TotalDarkFrames = min(320, length(DarkImages));  % Use up to 320 frames

fprintf('\nProcessing %d dark frames...\n', TotalDarkFrames);

% Initialize accumulator for dark frames
DarkAccumulator = [];

% Loop through dark images
for frameIdx = 1:TotalDarkFrames
    % Read image
    CurrentImage = double(imread(fullfile(DarkFolder, DarkImages(frameIdx).name)));
    
    % Apply same normalization as light frames
    CurrentImage = CurrentImage ./ 64;
    
    % Accumulate for averaging
    if frameIdx == 1
        DarkAccumulator = CurrentImage;
    else
        DarkAccumulator = DarkAccumulator + CurrentImage;
    end
end

% Compute average dark signal (DSNU)
DSNU = DarkAccumulator ./ TotalDarkFrames;

fprintf('DSNU computed: %d x %d pixels\n', size(DSNU, 1), size(DSNU, 2));

% Save DSNU
save('DSNU.mat', 'DSNU');
fprintf('Saved: DSNU.mat\n');

%% STEP 3: VISUALIZATION (Optional)

figure('Name', 'Light Image and DSNU Analysis', 'NumberTitle', 'off');

% Display light reference
subplot(2, 2, 1);
imagesc(Light_Image);
colormap(gca, gray);
colorbar;
title('Light Reference Image');
xlabel('Pixel X');
ylabel('Pixel Y');

% Display DSNU
subplot(2, 2, 2);
imagesc(DSNU);
colormap(gca, gray);
colorbar;
title('Dark Signal Non-Uniformity (DSNU)');
xlabel('Pixel X');
ylabel('Pixel Y');

% Display difference (illumination pattern)
subplot(2, 2, 3);
imagesc(Light_Image - DSNU);
colormap(gca, gray);
colorbar;
title('Illumination Pattern (Light - DSNU)');
xlabel('Pixel X');
ylabel('Pixel Y');

% Display histograms
subplot(2, 2, 4);
histogram(Light_Image(:), 50, 'FaceAlpha', 0.6, 'DisplayName', 'Light');
hold on;
histogram(DSNU(:), 50, 'FaceAlpha', 0.6, 'DisplayName', 'DSNU');
legend;
xlabel('Normalized Pixel Value');
ylabel('Frequency');
title('Pixel Value Distributions');
grid on;

sgtitle('Camera Reference Image Analysis');

%% NOTES FOR USAGE
% 
% 1. Input Requirements:
%    - Light images: 400+ frames under uniform illumination
%    - Dark images: 320+ frames with lens cap on (zero light)
%    - All images should be from the same camera model
%
% 2. Output Files:
%    - Light_image.mat: Average illumination pattern
%    - DSNU.mat: Dark current and read noise pattern
%
% 3. Next Steps:
%    - Use these outputs in PRNU_DSNU.m to extract camera fingerprint
%    - Run calculate_metrics_new.m for correlation analysis
%
% 4. Parameter Tuning:
%    - TotalLightFrames: Increase for better averaging (reduces noise)
%    - TotalDarkFrames: Should match light frames for consistency
%    - Normalization divisor: Depends on camera (check data sheet)
%
