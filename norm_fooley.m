clearvars
close all
clc

% Folder containing original Foley sounds
inputFolder = 'original_fooley/';
outputFolder = 'normalized_fooley/';
mkdir(outputFolder); % create the output folder if it doesn't exist

% Load a reference silence file to determine background noise threshold
[xSilence, fs] = audioread(fullfile("Sounds/AmbisonicPr_silence.wav"));
winLength = round(0.05 * fs);  % 50 ms analysis window
pwrSilence = ShortTermPower(xSilence, winLength);
silenceThreshold = pwrSilence(1);  % constant power in the silence file


% List all WAV files in the input folder
files = dir(fullfile(inputFolder, '*.wav'));
nFiles = length(files);

% Optional: pad signals to the same length (not strictly necessary if all signals are equal in duration)
maxLength = 0;
for k = 1:length(files)
    [x, ~] = audioread(fullfile(inputFolder, files(k).name));
    if size(x, 2) > 1
        x = mean(x, 2);  % convert stereo to mono
    end
    maxLength = max(maxLength, size(x, 1));
end

% Preallocate matrix for padded signals
allSignalsPadded = zeros(maxLength, nFiles);

% Load each file, convert to mono and pad to max length
for k = 1:nFiles
    [x, ~] = audioread(fullfile(inputFolder, files(k).name));
    if size(x, 2) > 1
        x = mean(x, 2);  % stereo to mono
    end
    padded = [x; zeros(maxLength - length(x), 1)];
    allSignalsPadded(:, k) = padded;
    
    fprintf('File %d (%s): %d samples → padded to %d\n', ...
        k, files(k).name, length(x), maxLength);
end

% Preallocate a binary mask indicating active (non-silent) samples
activeMask = false(size(allSignalsPadded));

% For each file, compute short-term power and mask active parts
for k = 1:nFiles
    xMono = allSignalsPadded(:, k);  % already mono and padded

    pwr = ShortTermPower(xMono, winLength);  % same length as signal
    activeMask(:, k) = pwr > silenceThreshold;

    % Print debugging info about how many samples are active
    fprintf('Source %d: %d active out of %d (%.2f%%)\n', ...
        k, sum(activeMask(:, k)), length(xMono), ...
        100 * sum(activeMask(:, k)) / length(xMono));
end

% Try to find the highest RMS value that does not cause clipping
targetRMS = 0.2;         % initial high guess
minRMS = 0.01;           % do not go below this
step = 0.001;            % decrement step
found = false;

while ~found && targetRMS > minRMS
    clippingDetected = false;

    for k = 1:nFiles
        x = allSignalsPadded(:, k);
        mask = activeMask(:, k);
        activeSamples = x(mask);

        if isempty(activeSamples)
            continue;
        end

        rmsActive = sqrt(mean(activeSamples.^2));
        scale = targetRMS / rmsActive;
        x_scaled_active = activeSamples * scale;

        if any(abs(x_scaled_active) > 1)
            clippingDetected = true;
            break;  % stop checking if clipping is found in any file
        end
    end

    if clippingDetected
        targetRMS = targetRMS - step;  % decrease and retry
    else
        found = true;  % a safe RMS value was found
    end
end

if found
    fprintf('Target RMS found: %.4f\n', targetRMS);
else
    warning('No safe RMS value found that avoids clipping. Consider reducing source levels.');
end

% Apply normalization to each file using the selected target RMS
for k = 1:nFiles
    x = allSignalsPadded(:, k);
    mask = activeMask(:, k);
    activeSamples = x(mask);
    
    if isempty(activeSamples)
        warning('File %d is completely silent. Skipped.', k);
        continue;
    end

    rmsActiveOrig = sqrt(mean(activeSamples.^2));
    scale = targetRMS / rmsActiveOrig;

    x_scaled = x;  % copy of full signal
    x_scaled(mask) = x(mask) * scale;  % apply scaling only to active parts

    % Save to WAV file
    [~, name, ~] = fileparts(files(k).name);
    outputName = fullfile(outputFolder, [name '_norm.wav']);
    audiowrite(outputName, x_scaled, fs);

    % Print summary and plot comparison
    peak = max(abs(x_scaled));
    rmsActiveNorm = sqrt(mean(x_scaled(mask).^2));
    
    figure;
    plot(x, 'r', 'DisplayName', 'Original', 'LineWidth', 1);
    hold on;
    plot(x_scaled, 'b', 'DisplayName', 'Normalized', 'LineWidth', 1);
    title(sprintf('%s — RMS before: %.4f, after: %.4f. Peak: %.4f', name, rmsActiveOrig, rmsActiveNorm, peak));
    ylim([-1 1]);
    legend;
    grid on;
end
