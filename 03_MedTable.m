%% MEDIAN FILTER PARAMETER TABLE GENERATION
%
% This script systematically evaluates median filtering with varying window sizes
% and computes quality metrics for each configuration.
%
% It creates a lookup table of performance metrics across a range of
% median filter kernel sizes, useful for finding optimal parameters.
%

function [MetricsTable, OptimalFilteredImage] = ...
         MedTable(NoiseImage, ReferenceImage, MinWindowSize, MaxWindowSize)
    %
    % MEDTABLE - Generate performance table for median filter variants
    %
    % Syntax:
    %   [MetricsTable, Ft] = MedTable(ImN, ImI, MinCore, MaxCore)
    %
    % Input Arguments:
    %   NoiseImage         - Input image (typically PRNU estimate or noisy image)
    %   ReferenceImage     - Reference image for comparison
    %   MinWindowSize      - Minimum median filter kernel size (e.g., 3)
    %   MaxWindowSize      - Maximum median filter kernel size (e.g., 21)
    %
    % Output Arguments:
    %   MetricsTable       - 4 x N table where N = MaxCore - MinCore + 1
    %                        Row 1: NSKO values
    %                        Row 2: PSNR values
    %                        Row 3: SSIM values
    %                        Row 4: Correlation values
    %
    %   OptimalFilteredImage - Filtered image at best configuration
    %                          (currently returns last filtered result)
    %
    % Table Structure:
    %   MetricsTable(1, :)  = NSKO for each window size
    %   MetricsTable(2, :)  = PSNR for each window size
    %   MetricsTable(3, :)  = SSIM for each window size
    %   MetricsTable(4, :)  = Correlation for each window size
    %
    % Column index mapping:
    %   Column k corresponds to window size = MinCore + k - 1
    %
    % Example:
    %   % Test median filters with kernel sizes 3 to 21 (odd numbers)
    %   load('Light_image.mat');
    %   load('DSNU.mat');
    %   [Table, Ft] = MedTable(Light_image - DSNU, ...
    %                          Light_image - DSNU, 3, 21);
    %   
    %   % Plot NSKO values
    %   windowSizes = 3:2:21;
    %   plot(windowSizes, Table(1, :), 'o-', 'LineWidth', 2);
    %   xlabel('Median Filter Window Size');
    %   ylabel('NSKO');
    %   grid on;
    %
    % Notes on Interpretation:
    %   1. NSKO (Row 1):
    %      - Decreases with larger window sizes (noise suppression)
    %      - Lower values are better
    %      - Eventually plateaus when all signal is smoothed
    %
    %   2. PSNR (Row 2):
    %      - Increases with filtering (quality improvement)
    %      - Higher values indicate better reconstruction
    %
    %   3. SSIM (Row 3):
    %      - Often peaks at intermediate window sizes
    %      - Indicates best perceptual quality
    %
    %   4. Correlation (Row 4):
    %      - Measures pattern preservation
    %      - Important for PRNU recovery
    %
    % Typical Results:
    %   - Small kernels (3-5): Moderate noise reduction, good pattern preservation
    %   - Medium kernels (7-9): Strong noise reduction, acceptable pattern loss
    %   - Large kernels (11+): Aggressive smoothing, risk of pattern destruction
    %
    % See also: MedFilt, PRNU_DSNU, calculate_metrics_new
    
    % Initialize metrics table: 4 metrics x (MaxCore - MinCore + 1) configurations
    NumConfigurations = MaxWindowSize - MinWindowSize + 1;
    MetricsTable = zeros(4, NumConfigurations);
    
    % Test each window size
    for windowIdx = MinWindowSize:MaxWindowSize
        % Compute column index in output table
        TableCol = windowIdx + (1 - MinWindowSize);
        
        % Apply median filter and compute metrics
        [NSKO, PSNR, SSIM, Correlation, FilteredOutput] = ...
            MedFilt(NoiseImage, windowIdx, windowIdx, ReferenceImage);
        
        % Store metrics in table
        MetricsTable(1, TableCol) = NSKO;      % Normalized Squared Kernel Output
        MetricsTable(2, TableCol) = PSNR;      % Peak Signal-to-Noise Ratio
        MetricsTable(3, TableCol) = SSIM;      % Structural Similarity Index
        MetricsTable(4, TableCol) = Correlation; % Pearson Correlation
        
        % Keep last filtered image for output
        OptimalFilteredImage = FilteredOutput;
        
        % Progress indicator
        fprintf('Window size %d: NSKO=%.4f, PSNR=%.2f dB, SSIM=%.4f, Corr=%.4f\n', ...
                windowIdx, NSKO, PSNR, SSIM, Correlation);
    end
    
end

%% HELPER FUNCTION: FIND OPTIMAL PARAMETERS
%
% function [OptWindowSize, OptMetrics] = findOptimalParams(MetricsTable, MinCore, MaxCore)
%     % Find window size with lowest NSKO
%     [MinNSKO, MinIdx] = min(MetricsTable(1, :));
%     OptWindowSize = MinCore + MinIdx - 1;
%     OptMetrics.NSKO = MetricsTable(1, MinIdx);
%     OptMetrics.PSNR = MetricsTable(2, MinIdx);
%     OptMetrics.SSIM = MetricsTable(3, MinIdx);
%     OptMetrics.Corr = MetricsTable(4, MinIdx);
% end

%% USAGE EXAMPLE
%
% % Step 1: Load reference images
% load('Light_image.mat');
% load('DSNU.mat');
%
% % Step 2: Generate metrics table for window sizes 3 to 21
% [Table, FilteredImg] = MedTable(Light_image - DSNU, ...
%                                 Light_image - DSNU, 3, 21);
%
% % Step 3: Analyze results
% windowSizes = 3:21;
% figure;
%
% % Plot NSKO (noise suppression)
% subplot(2, 2, 1);
% plot(windowSizes, Table(1, :), 'o-', 'LineWidth', 2);
% xlabel('Window Size');
% ylabel('NSKO');
% title('Noise Suppression vs Window Size');
% grid on;
%
% % Plot PSNR (reconstruction quality)
% subplot(2, 2, 2);
% plot(windowSizes, Table(2, :), 's-', 'LineWidth', 2);
% xlabel('Window Size');
% ylabel('PSNR (dB)');
% title('PSNR vs Window Size');
% grid on;
%
% % Plot SSIM (perceived quality)
% subplot(2, 2, 3);
% plot(windowSizes, Table(3, :), '^-', 'LineWidth', 2);
% xlabel('Window Size');
% ylabel('SSIM');
% title('SSIM vs Window Size');
% grid on;
%
% % Plot Correlation (pattern preservation)
% subplot(2, 2, 4);
% plot(windowSizes, Table(4, :), 'd-', 'LineWidth', 2);
% xlabel('Window Size');
% ylabel('Correlation');
% title('Pattern Preservation vs Window Size');
% grid on;
%
% % Find and print optimal window size
% [minNSKO, idx] = min(Table(1, :));
% optWindowSize = windowSizes(idx);
% fprintf('Optimal window size: %d (NSKO = %.4f)\n', optWindowSize, minNSKO);
