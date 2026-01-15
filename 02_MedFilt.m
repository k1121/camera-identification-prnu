%% MEDIAN FILTER EVALUATION
%
% This function applies 2D median filtering and computes quality metrics
% for assessing filter performance in image denoising tasks.
%
% The function evaluates how well a filtered image preserves the reference
% image characteristics using multiple quality metrics.
%
function [NSKO, PSNR, SSIM, Correlation, FilteredImage, ...
          NSKO0, PSNR0, SSIM0, Correlation0] = ...
         MedFilt(NoiseImage, WindowSize1, WindowSize2, ReferenceImage)
    %
    % MEDIANFILTER - Apply median filter and evaluate quality
    %
    % Syntax:
    %   [NSKO, PSNR, SSIM, Corr, Ft] = MedFilt(ImN, Sz1, Sz2, ImI)
    %   [NSKO, PSNR, SSIM, Corr, Ft, NSKO0, PSNR0, SSIM0, Corr0] = ...
    %       MedFilt(ImN, Sz1, Sz2, ImI)
    %
    % Input Arguments:
    %   NoiseImage         - Input image with noise/PRNU (matrix)
    %   WindowSize1        - Median filter kernel height (odd number recommended)
    %   WindowSize2        - Median filter kernel width (odd number recommended)
    %   ReferenceImage     - Ground truth/reference image
    %
    % Output Arguments:
    %   NSKO               - Normalized Squared Kernel Output after filtering
    %   PSNR               - Peak Signal-to-Noise Ratio (dB)
    %   SSIM               - Structural Similarity Index
    %   Correlation        - Linear correlation coefficient
    %   FilteredImage      - Output image after median filtering
    %
    % Optional Outputs (unfiltered metrics):
    %   NSKO0              - NSKO of original noisy image
    %   PSNR0              - PSNR of original noisy image
    %   SSIM0              - SSIM of original noisy image
    %   Correlation0       - Correlation of original noisy image
    %
    % Metric Definitions:
    %
    %   NSKO (Normalized Squared Kernel Output):
    %       NSKO = sqrt( sum((Filtered - alpha*Reference)^2) / sum(Filtered^2) )
    %       where alpha is the linear regression coefficient
    %       Range: [0, 1], Lower is better
    %
    %   PSNR (Peak Signal-to-Noise Ratio):
    %       PSNR = 20 * log10(MAX / RMSE)
    %       where MAX is maximum pixel value, RMSE is mean squared error
    %       Range: [0, Inf] dB, Higher is better
    %
    %   SSIM (Structural Similarity Index):
    %       Measures perceived quality based on luminance, contrast, structure
    %       Range: [-1, 1], Higher is better (1 = identical)
    %
    %   Correlation:
    %       Pearson correlation coefficient between filtered and reference
    %       Range: [-1, 1], Higher is better (1 = perfect positive correlation)
    %
    % Example:
    %   Load reference and noisy images
    %   load('Light_image.mat');
    %   load('DSNU.mat');
    %   [NSKO, PSNR, SSIM, Corr, Ft] = MedFilt(Light_image-DSNU, 5, 5, Light_image);
    %
    % References:
    %   - Median filter: Standard image processing technique for salt-and-pepper noise
    %   - PRNU: Photo Response Non-Uniformity in camera forensics
    %
    % See also: medfilt2, MedTable, PRNU_DSNU
    
    %% COMPUTE UNFILTERED METRICS (Original noisy image)
    
    % Linear regression coefficient: alpha = (Im*Ir) / (Ir*Ir)
    % This normalizes for multiplicative scaling between images
    AlphaUnfiltered = sum(sum(NoiseImage .* ReferenceImage)) / sum(sum(ReferenceImage .^ 2));
    
    % NSKO: Normalized error measure
    NSKO0 = sqrt(sum(sum((NoiseImage - AlphaUnfiltered .* ReferenceImage) .^ 2))) / ...
            sqrt(sum(sum(NoiseImage .^ 2)));
    
    % PSNR: Logarithmic error measure (requires normalization)
    PSNR0 = psnr(NoiseImage ./ max(NoiseImage(:)), ...
                 ReferenceImage ./ max(ReferenceImage(:)));
    
    % SSIM: Structural similarity
    SSIM0 = ssim(NoiseImage ./ max(NoiseImage(:)), ...
                 ReferenceImage ./ max(ReferenceImage(:)));
    
    % Pearson correlation coefficient
    Correlation0 = corr2(NoiseImage ./ max(NoiseImage(:)), ...
                         ReferenceImage ./ max(ReferenceImage(:)));
    
    %% APPLY MEDIAN FILTER
    
    FilteredImage = medfilt2(NoiseImage, [WindowSize1, WindowSize2]);
    
    %% COMPUTE FILTERED METRICS
    
    % Regression coefficient for filtered image
    AlphaFiltered = sum(sum(FilteredImage .* ReferenceImage)) / sum(sum(ReferenceImage .^ 2));
    
    % NSKO after filtering
    NSKO = sqrt(sum(sum((FilteredImage - AlphaFiltered .* ReferenceImage) .^ 2))) / ...
           sqrt(sum(sum(FilteredImage .^ 2)));
    
    % PSNR after filtering
    PSNR = psnr(FilteredImage ./ max(FilteredImage(:)), ...
                ReferenceImage ./ max(ReferenceImage(:)));
    
    % SSIM after filtering
    SSIM = ssim(FilteredImage ./ max(FilteredImage(:)), ...
                ReferenceImage ./ max(ReferenceImage(:)));
    
    % Correlation after filtering
    Correlation = corr2(FilteredImage ./ max(FilteredImage(:)), ...
                        ReferenceImage ./ max(ReferenceImage(:)));
    
end

%% USAGE NOTES
%
% 1. Window Size Selection:
%    - Odd numbers work best: 3, 5, 7, 9, 11, etc.
%    - Larger windows = more smoothing (PRNU suppression)
%    - Smaller windows = better detail preservation
%    - Square windows (Sz1 == Sz2) are typically used
%
% 2. Expected Behavior:
%    - NSKO decreases with larger window sizes (noise suppression)
%    - PSNR increases with filtering (image quality improvement)
%    - At some point, over-filtering can reduce correlation with reference
%
% 3. For PRNU Extraction:
%    - Filter should suppress noise without destroying PRNU pattern
%    - Optimal window size varies by camera model
%    - Typically window sizes 5-9 are effective for PRNU extraction
%
% 4. Normalization:
%    - Images are divided by their maximum value before metric computation
%    - This allows comparison across images with different ranges
%    - Critical for proper SSIM and correlation calculation
%