%% CAMERA IDENTIFICATION AND METRIC EVALUATION
%
% This is the main analysis script for camera source identification.
% It systematically processes test images with various filtering methods,
% correlates them against the camera PRNU fingerprint, and computes 
% comprehensive quality metrics for validation.
%
% The script evaluates 11 different filtering approaches across 
% multiple parameter configurations to find optimal settings for 
% camera identification accuracy.
%

function calculatePRNUCorrelation()
    
    %% STEP 1: CONFIGURATION
    
    % Define analysis parameters
    config.ParentFolder = 'data/test_images/';      % Path to test images (modify as needed)
    config.PRNU_File = 'PRNU.mat';                  % Pre-extracted PRNU fingerprint
    config.CameraName = 'TestCamera';               % Camera identifier for results
    config.ImageFormat = '.tiff';                   % Image file format
    config.OutputFile = fullfile(config.ParentFolder, ...
                                 sprintf('Results_%s.csv', config.CameraName));
    
    % Define filter methods to evaluate
    config.FilterMethods = {
        'Gaussian',     % Gaussian blur (smoothing)
        'Median',       % Median filtering (noise removal)
        'Average',      % Mean filtering (averaging)
        'NLM',          % Non-Local Means (advanced denoising)
        'Frost',        % Frost adaptive filter (speckle reduction)
        'Lee',          % Lee adaptive filter (speckle reduction)
        'Guided',       % Guided filter (edge-preserving)
        'TV',           % Total Variation (denoising)
        'Bilateral',    % Bilateral filter (edge-preserving smoothing)
        'Wavelet',      % Wavelet denoising (frequency domain)
        'Wiener'        % Wiener filter (noise suppression)
    };
    
    % Define parameter ranges for each filter method
    config.FilterParamsList = struct(...
        'Gaussian', struct(...
            'Sigma', {num2cell(1:2:21)}), ...
        ...
        'Median', struct(...
            'Window', {num2cell(3:2:21)}), ...
        ...
        'Average', struct(...
            'Window', {num2cell(3:2:21)}), ...
        ...
        'NLM', struct(...
            'Degree', {num2cell([0.01, 0.02, 0.04, 0.06, 0.08, 0.1, 0.15, 0.2, 0.25, 0.3])}), ...
        ...
        'Frost', struct(...
            'Window', {num2cell([3, 5, 7, 9])}, ...
            'Damping', {num2cell([0.5, 1.0, 1.5, 2.0])}), ...
        ...
        'Lee', struct(...
            'Window', {num2cell(3:2:21)}), ...
        ...
        'Guided', struct(...
            'Window', {num2cell(5)}, ...
            'Degree', {num2cell([0.001, 0.005, 0.01, 0.02, 0.04, 0.08, 0.1, 0.2, 0.4, 0.8])}), ...
        ...
        'TV', struct(...
            'Lambda', {num2cell([0.01, 0.02, 0.03, 0.05, 0.08, 0.1, 0.15, 0.2, 0.25, 0.3])}), ...
        ...
        'Bilateral', struct(...
            'SigmaSpatial', {num2cell([2, 2, 3, 3, 4, 5])}, ...
            'SigmaRange', {num2cell([0.02, 0.05, 0.05, 0.1, 0.1, 0.15])}), ...
        ...
        'Wavelet', struct(...
            'WaveletType', {'db2', 'sym4', 'coif2'}, ...
            'Level', {num2cell([2, 3])}), ...
        ...
        'Wiener', struct(...
            'Window', {num2cell(3:2:21)}) ...
    );
    
    fprintf('======== CAMERA IDENTIFICATION ANALYSIS ========\n');
    fprintf('Configuration:\n');
    fprintf('  Parent folder: %s\n', config.ParentFolder);
    fprintf('  PRNU file: %s\n', config.PRNU_File);
    fprintf('  Camera: %s\n', config.CameraName);
    fprintf('  Image format: %s\n', config.ImageFormat);
    fprintf('  Output: %s\n', config.OutputFile);
    fprintf('  Total filters: %d\n', length(config.FilterMethods));
    
    %% STEP 2: VALIDATION AND PREPARATION
    
    fprintf('\n========== VERIFICATION ==========\n');
    
    % Check that required folder and files exist
    if ~exist(config.ParentFolder, 'dir')
        error('Parent folder not found: %s\nPlease update config.ParentFolder', config.ParentFolder);
    end
    fprintf('1. Parent folder verified: OK\n');
    
    if ~exist(config.PRNU_File, 'file')
        error('PRNU file not found: %s\nRun 04_PRNU_DSNU.m first', config.PRNU_File);
    end
    fprintf('2. PRNU file verified: OK\n');
    
    % Load and validate PRNU
    fprintf('3. Loading PRNU...\n');
    load(config.PRNU_File, 'PRNU');
    PRNU = double(PRNU);
    
    if isempty(PRNU) || ~isnumeric(PRNU)
        error('PRNU is empty or not numeric');
    end
    
    [PRNU_Height, PRNU_Width] = size(PRNU);
    fprintf('   PRNU size: %d x %d\n', PRNU_Height, PRNU_Width);
    fprintf('   PRNU range: [%.6e, %.6e]\n', min(PRNU(:)), max(PRNU(:)));
    
    %% STEP 3: BUILD FILE LIST
    
    fprintf('\n========== FILE DISCOVERY ==========\n');
    
    % Recursively find all images in subdirectories
    AllImageFiles = {};
    SubFolders = dir(config.ParentFolder);
    SubFolders = SubFolders([SubFolders.isdir] & ~startsWith({SubFolders.name}, '.'));
    
    for folderIdx = 1:length(SubFolders)
        FullSubfolderPath = fullfile(config.ParentFolder, SubFolders(folderIdx).name);
        ImageFiles = dir(fullfile(FullSubfolderPath, ['*' config.ImageFormat]));
        
        for fileIdx = 1:length(ImageFiles)
            AllImageFiles{end+1} = fullfile(FullSubfolderPath, ImageFiles(fileIdx).name);
        end
    end
    
    if isempty(AllImageFiles)
        error('No images found in %s\nExpected format: *%s', config.ParentFolder, config.ImageFormat);
    end
    
    fprintf('Found %d test images\n', length(AllImageFiles));
    
    %% STEP 4: CREATE PROCESSING TASKS
    
    fprintf('\n========== TASK CREATION ==========\n');
    
    % Build list of all (image, filter, parameters) combinations
    TaskCount = 0;
    
    for filterIdx = 1:length(config.FilterMethods)
        FilterMethod = config.FilterMethods{filterIdx};
        ParamStruct = config.FilterParamsList.(FilterMethod);
        ParamFields = fieldnames(ParamStruct);
        ParamValues = cellfun(@(f) ParamStruct.(f), ParamFields, 'UniformOutput', false);
        
        % Generate all parameter combinations
        ParamGrid = ndims_comb(ParamValues{:});
        TaskCount = TaskCount + size(ParamGrid, 1) * length(AllImageFiles);
    end
    
    fprintf('Total tasks to process: %d\n', TaskCount);
    fprintf('  (images × filter methods × parameter combinations)\n');
    
    % Build task array
    TaskList = {};
    TaskCounter = 1;
    
    for filterIdx = 1:length(config.FilterMethods)
        FilterMethod = config.FilterMethods{filterIdx};
        ParamStruct = config.FilterParamsList.(FilterMethod);
        ParamFields = fieldnames(ParamStruct);
        ParamValues = cellfun(@(f) ParamStruct.(f), ParamFields, 'UniformOutput', false);
        ParamGrid = ndims_comb(ParamValues{:});
        
        for paramIdx = 1:size(ParamGrid, 1)
            CurrentParams = struct();
            for paramFieldIdx = 1:length(ParamFields)
                FieldValue = ParamGrid{paramIdx, paramFieldIdx};
                if iscell(FieldValue) && numel(FieldValue) == 1
                    FieldValue = FieldValue{1};
                end
                CurrentParams.(ParamFields{paramFieldIdx}) = FieldValue;
            end
            
            for imgIdx = 1:length(AllImageFiles)
                Task.ImagePath = AllImageFiles{imgIdx};
                Task.FilterMethod = FilterMethod;
                Task.Parameters = CurrentParams;
                TaskList{TaskCounter} = Task;
                TaskCounter = TaskCounter + 1;
            end
        end
    end
    
    if isempty(TaskList)
        Tasks = struct([]);
    else
        Tasks = [TaskList{:}];
    end
    
    TotalTasks = length(Tasks);
    fprintf('Final task count: %d\n', TotalTasks);
    
    %% STEP 5: INITIALIZE OUTPUT FILE
    
    fprintf('\n========== OUTPUT SETUP ==========\n');
    
    % Create output CSV file with header
    fid = fopen(config.OutputFile, 'w');
    if fid == -1
        error('Cannot write to output file: %s', config.OutputFile);
    end
    
    % Define metric names
    MetricNames = {'PCC', 'NSKO', 'NSKO1', 'PCE', 'POC', 'SER', 'SSIM'};
    
    % Build header row
    HeaderCells = {'Camera', 'ImageName', 'Filter', MetricNames{:}};
    
    % Add parameter columns
    AllParamNames = {};
    for filterIdx = 1:length(config.FilterMethods)
        FieldNames = fieldnames(config.FilterParamsList.(config.FilterMethods{filterIdx}));
        AllParamNames = [AllParamNames; FieldNames];
    end
    UniqueParamNames = unique(AllParamNames, 'stable');
    
    for paramIdx = 1:length(UniqueParamNames)
        HeaderCells = [HeaderCells, ['Param_' UniqueParamNames{paramIdx}]];
    end
    
    % Write header
    fprintf(fid, '%s\n', strjoin(HeaderCells, ','));
    fclose(fid);
    
    fprintf('Output file initialized: %s\n', config.OutputFile);
    
    %% STEP 6: MAIN PROCESSING LOOP
    
    fprintf('\n========== PROCESSING ==========\n');
    
    fid = fopen(config.OutputFile, 'a');
    WaitbarHandle = waitbar(0, 'Initializing...', 'Name', 'Camera Identification Analysis');
    
    for taskIdx = 1:TotalTasks
        Task = Tasks(taskIdx);
        
        try
            % Read image file
            [~, ImageBaseName, ImageExt] = fileparts(Task.ImagePath);
            ImageName = [ImageBaseName, ImageExt];
            
            % Load and convert to grayscale
            OriginalImage = imread(Task.ImagePath);
            
            if ndims(OriginalImage) == 3
                try
                    GrayImage = rgb2gray(OriginalImage);
                catch
                    GrayImage = OriginalImage(:, :, 1);
                end
            else
                GrayImage = OriginalImage;
            end
            
            % Convert to double and normalize
            ImageDouble = double(GrayImage);
            if ~isempty(ImageDouble)
                ImageDouble = ImageDouble ./ 5.586;  % Adjust based on camera
            end
            
            [ImageHeight, ImageWidth] = size(ImageDouble);
            
            % Adjust sizes to match PRNU dimensions
            MatchHeight = min(PRNU_Height, ImageHeight);
            MatchWidth = min(PRNU_Width, ImageWidth);
            
            PRNU_Cropped = PRNU(1:MatchHeight, 1:MatchWidth);
            ImageCropped = ImageDouble(1:MatchHeight, 1:MatchWidth);
            ImageCropped = mat2gray(ImageCropped);
            
            % Apply filter to extract high-frequency component
            [HighFreqImage, ~] = applyFilter(ImageCropped, Task.FilterMethod, Task.Parameters);
            
            % Ensure size match
            if ~isequal(size(HighFreqImage), size(PRNU_Cropped))
                MinH = min(size(HighFreqImage, 1), size(PRNU_Cropped, 1));
                MinW = min(size(HighFreqImage, 2), size(PRNU_Cropped, 2));
                HighFreqImage = HighFreqImage(1:MinH, 1:MinW);
                PRNU_Cropped = PRNU_Cropped(1:MinH, 1:MinW);
            end
            
            % Remove non-finite values
            HighFreqImage(~isfinite(HighFreqImage)) = 0;
            PRNU_Cropped(~isfinite(PRNU_Cropped)) = 0;
            
            % Initialize metrics
            for m = 1:length(MetricNames)
                Metrics.(MetricNames{m}) = 0;
            end
            
            % Check for degenerate cases
            if isempty(HighFreqImage) || isempty(PRNU_Cropped) || ...
               std(HighFreqImage(:)) < 1e-9 || std(PRNU_Cropped(:)) < 1e-9
                warning('SKIP: Degenerate image or PRNU for %s', ImageName);
                Metrics.NSKO = 1;
                Metrics.NSKO1 = 0;
                Metrics.PCC = 0;
                Metrics.SSIM = 0;
            else
                % COMPUTE METRICS
                
                % PCC: Pearson Correlation Coefficient
                try
                    CorrMatrix = corrcoef(HighFreqImage(:), PRNU_Cropped(:));
                    if any(isnan(CorrMatrix(:)))
                        Metrics.PCC = 0;
                    else
                        Metrics.PCC = CorrMatrix(1, 2);
                    end
                catch
                    Metrics.PCC = 0;
                end
                
                % NSKO and NSKO1: Normalized Squared Kernel Output
                Numerator = (sum(sum(HighFreqImage .* PRNU_Cropped)) ^ 2);
                Denominator = sum(sum(HighFreqImage .^ 2)) * sum(sum(PRNU_Cropped .^ 2));
                
                if Denominator == 0
                    Metrics.NSKO = 1;
                else
                    Ratio = Numerator / Denominator;
                    Ratio = max(0, min(1, Ratio));
                    Metrics.NSKO = sqrt(1 - Ratio);
                end
                Metrics.NSKO1 = 1 - Metrics.NSKO;
                
                % PCE: Peak Correlation Energy
                try
                    Metrics.PCE = calculatePCE(HighFreqImage, PRNU_Cropped);
                    if ~isfinite(Metrics.PCE)
                        Metrics.PCE = 0;
                    end
                catch
                    Metrics.PCE = 0;
                end
                
                % POC: Peak-to-Output Correlation
                try
                    Metrics.POC = calculatePOC(HighFreqImage, PRNU_Cropped);
                    if ~isfinite(Metrics.POC)
                        Metrics.POC = 0;
                    end
                catch
                    Metrics.POC = 0;
                end
                
                % SER: Signal-to-Error Ratio
                try
                    Metrics.SER = calculateSER(HighFreqImage);
                    if ~isfinite(Metrics.SER)
                        Metrics.SER = 0;
                    end
                catch
                    Metrics.SER = 0;
                end
                
                % SSIM: Structural Similarity Index
                try
                    Metrics.SSIM = ssim(HighFreqImage, PRNU_Cropped);
                    if ~isfinite(Metrics.SSIM)
                        Metrics.SSIM = 0;
                    end
                catch
                    Metrics.SSIM = 0;
                end
            end
            
            % WRITE RESULTS TO CSV
            
            RowCells = {};
            RowCells{end+1} = config.CameraName;
            RowCells{end+1} = ImageName;
            RowCells{end+1} = Task.FilterMethod;
            
            for m = 1:length(MetricNames)
                MetricValue = Metrics.(MetricNames{m});
                if isempty(MetricValue) || ~isfinite(MetricValue)
                    RowCells{end+1} = 'NaN';
                else
                    RowCells{end+1} = num2str(MetricValue, '%.6f');
                end
            end
            
            for p = 1:length(UniqueParamNames)
                ParamName = UniqueParamNames{p};
                if isfield(Task.Parameters, ParamName)
                    ParamValue = Task.Parameters.(ParamName);
                    if isempty(ParamValue)
                        RowCells{end+1} = '';
                    elseif ischar(ParamValue) || isstring(ParamValue)
                        RowCells{end+1} = char(ParamValue);
                    elseif isnumeric(ParamValue)
                        RowCells{end+1} = num2str(ParamValue);
                    else
                        try
                            RowCells{end+1} = num2str(double(ParamValue));
                        catch
                            RowCells{end+1} = '';
                        end
                    end
                else
                    RowCells{end+1} = '';
                end
            end
            
            % Write row to file
            Line = strjoin(RowCells, ',');
            fprintf(fid, '%s\n', Line);
            
        catch ME
            warning('SKIP: Error processing %s with %s: %s', ...
                    Task.ImagePath, Task.FilterMethod, ME.message);
        end
        
        % Update progress bar
        if exist('WaitbarHandle', 'var') && ishandle(WaitbarHandle)
            waitbar(taskIdx / TotalTasks, WaitbarHandle, ...
                    sprintf('Processed %d/%d (%.1f%%)', taskIdx, TotalTasks, 100*taskIdx/TotalTasks));
        end
    end
    
    %% STEP 7: CLEANUP
    
    fclose(fid);
    if exist('WaitbarHandle', 'var') && ishandle(WaitbarHandle)
        close(WaitbarHandle);
    end
    
    fprintf('\n========== COMPLETE ==========\n');
    fprintf('Results saved to: %s\n', config.OutputFile);
    fprintf('Total tasks completed: %d\n', TotalTasks);
    
end

%% HELPER FUNCTIONS

% Generate all combinations of parameter values
function ParamGrid = ndims_comb(varargin)
    NumArgs = length(varargin);
    if NumArgs == 0
        ParamGrid = {};
        return;
    end
    
    for i = 1:NumArgs
        if ~iscell(varargin{i})
            varargin{i} = num2cell(varargin{i});
        end
        varargin{i} = varargin{i}(:);
    end
    
    ParamGrid = varargin{1};
    for i = 2:NumArgs
        CurrentValues = varargin{i};
        PrevGrid = ParamGrid;
        NumPrev = size(PrevGrid, 1);
        NumNew = numel(CurrentValues);
        
        ParamGrid = repmat(PrevGrid, NumNew, 1);
        NewCol = repelem(CurrentValues, NumPrev, 1);
        ParamGrid = [ParamGrid, NewCol];
    end
end

% Apply specified filter and extract high-frequency component
function [HighFreqImage, FilterInfo] = applyFilter(InputImage, FilterMethod, Params)
    % Detailed implementation of 11 filter methods
    % Returns high-frequency component and filter information
    
    InputImage = double(InputImage);
    if isempty(InputImage)
        HighFreqImage = [];
        FilterInfo = 'Empty input';
        return;
    end
    
    [H, W] = size(InputImage);
    ClampWindow = @(s) max(1, min(round(s), min(H, W)));
    MakeOdd = @(x) x + (1 - mod(round(x), 2));
    
    % Nested function to get parameter with default
    function value = getParamDefault(struct_obj, fieldname, default_val)
        if isstruct(struct_obj) && isfield(struct_obj, fieldname)
            value = struct_obj.(fieldname);
        else
            value = default_val;
        end
    end
    
    FilterInfo = sprintf('Filter=%s', FilterMethod);
    
    switch lower(FilterMethod)
        case 'gaussian'
            Sigma = getParamDefault(Params, 'Sigma', 1);
            try
                SmoothImage = imgaussfilt(InputImage, Sigma, 'Padding', 'symmetric');
            catch
                SmoothImage = imgaussfilt(InputImage, Sigma);
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Gaussian (σ=%.2f)', Sigma);
            
        case 'median'
            WinSize = ClampWindow(getParamDefault(Params, 'Window', 3));
            WinSize = MakeOdd(WinSize);
            SmoothImage = medfilt2(InputImage, [WinSize, WinSize], 'symmetric');
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Median [%dx%d]', WinSize, WinSize);
            
        case 'average'
            WinSize = ClampWindow(getParamDefault(Params, 'Window', 3));
            Kernel = fspecial('average', [WinSize, WinSize]);
            SmoothImage = imfilter(InputImage, Kernel, 'replicate', 'conv');
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Average [%dx%d]', WinSize, WinSize);
            
        case 'nlm'
            Degree = getParamDefault(Params, 'Degree', 0.05);
            try
                SmoothImage = imnlmfilt(InputImage, 'DegreeOfSmoothing', Degree);
            catch
                try
                    SmoothImage = imbilatfilt(InputImage);
                catch
                    SmoothImage = imgaussfilt(InputImage, 1);
                end
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('NLM (DoS=%.4f)', Degree);
            
        case 'frost'
            WinSize = getParamDefault(Params, 'Window', 3);
            Damping = getParamDefault(Params, 'Damping', 1.0);
            try
                SmoothImage = imgaussfilt(InputImage, Damping, 'FilterSize', [WinSize, WinSize]);
            catch
                SmoothImage = imgaussfilt(InputImage, 1);
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Frost [%d, damping=%.1f]', WinSize, Damping);
            
        case 'lee'
            WinSize = ClampWindow(getParamDefault(Params, 'Window', 3));
            WinSize = MakeOdd(WinSize);
            SmoothImage = imgaussfilt(InputImage, 1, 'FilterSize', [WinSize, WinSize]);
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Lee [%dx%d]', WinSize, WinSize);
            
        case 'guided'
            WinSize = ClampWindow(getParamDefault(Params, 'Window', 5));
            Degree = getParamDefault(Params, 'Degree', 0.01);
            try
                SmoothImage = imguidedfilter(InputImage, 'NeighborhoodSize', [WinSize, WinSize], ...
                                             'DegreeOfSmoothing', Degree);
            catch
                SmoothImage = imgaussfilt(InputImage, 1);
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Guided [%dx%d, DoS=%.4f]', WinSize, WinSize, Degree);
            
        case 'tv'
            Lambda = getParamDefault(Params, 'Lambda', 0.02);
            try
                SmoothImage = tvdenoise(InputImage, Lambda, 50);
            catch
                SmoothImage = imgaussfilt(InputImage, 1);
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('TV (λ=%.4f)', Lambda);
            
        case 'bilateral'
            SigmaRange = getParamDefault(Params, 'SigmaRange', 0.05);
            SigmaSpatial = getParamDefault(Params, 'SigmaSpatial', 2);
            try
                SmoothImage = imbilatfilt(InputImage, SigmaRange, SigmaSpatial);
            catch
                SmoothImage = imgaussfilt(InputImage, 1);
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Bilateral (σS=%.2f, σR=%.3f)', SigmaSpatial, SigmaRange);
            
        case 'wavelet'
            WaveletType = getParamDefault(Params, 'WaveletType', 'db2');
            Level = getParamDefault(Params, 'Level', 2);
            try
                [C, S] = wavedec2(InputImage, Level, WaveletType);
                SigmaEst = median(abs(C(~isnan(C) & ~isinf(C)))) / 0.6745;
                Threshold = SigmaEst * sqrt(2 * log(numel(InputImage)));
                C_Thresh = wthresh(C, 's', Threshold);
                SmoothImage = waverec2(C_Thresh, S, WaveletType);
                SmoothImage = SmoothImage(1:H, 1:W);
            catch
                SmoothImage = imgaussfilt(InputImage, 1);
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Wavelet (%s, level=%d)', WaveletType, Level);
            
        case 'wiener'
            WinSize = ClampWindow(getParamDefault(Params, 'Window', 3));
            WinSize = MakeOdd(WinSize);
            try
                SmoothImage = wiener2(InputImage, [WinSize, WinSize]);
            catch
                SmoothImage = imgaussfilt(InputImage, 1);
            end
            HighFreqImage = InputImage - SmoothImage;
            FilterInfo = sprintf('Wiener [%dx%d]', WinSize, WinSize);
            
        otherwise
            HighFreqImage = InputImage;
            FilterInfo = sprintf('Unknown filter: %s', FilterMethod);
    end
end

% PCE: Peak Correlation Energy
function PCE = calculatePCE(Img1, Img2)
    Corr = xcorr2(Img1, Img2);
    Numerator = max(Corr(:)) ^ 2;
    Denominator = sum(Corr(:) .^ 2);
    if Denominator == 0
        PCE = 0;
    else
        PCE = Numerator / Denominator;
    end
end

% POC: Peak Output Correlation
function POC = calculatePOC(Img1, Img2)
    Corr = xcorr2(Img1, Img2);
    POC = max(Corr(:)) / sum(abs(Corr(:)));
end

% SER: Signal-to-Error Ratio
function SER = calculateSER(Img)
    MeanVal = mean(Img(:));
    ErrorVal = mean((Img(:) - MeanVal) .^ 2);
    if ErrorVal == 0
        SER = 0;
    else
        SER = MeanVal ^ 2 / ErrorVal;
    end
end
