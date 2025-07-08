clearvars
close all
clc

% Folder containing original Foley sounds
inputFolder = 'sounds/second_experiment/cropped_foley/';
outputFolder = 'sounds/second_experiment/cropped_normalized_foley/';
mkdir(outputFolder); % create the output folder if it doesn't exist

% Load a reference silence file to determine background noise threshold
[xSilence, fs] = audioread(fullfile("sounds/second_experiment/AmbisonicPr_silence.wav"));
winLength = round(0.05 * fs);  % 50 ms analysis window
pwrSilence = ShortTermPower(xSilence, winLength);
silenceThreshold = pwrSilence(1);  % constant power in the silence file

% List all WAV files in the input folder
files = dir(fullfile(inputFolder, '*.wav'));
nFiles = length(files);

% Find max length among files
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

% Load and pad
for k = 1:nFiles
    [x, ~] = audioread(fullfile(inputFolder, files(k).name));
    if size(x, 2) > 1
        x = mean(x, 2);
    end
    padded = [x; zeros(maxLength - length(x), 1)];
    allSignalsPadded(:, k) = padded;
    
    fprintf('File %d (%s): %d samples → padded to %d\n', ...
        k, files(k).name, length(x), maxLength);
end

% Binary mask for active samples
activeMask = false(size(allSignalsPadded));

% Compute active regions
for k = 1:nFiles
    xMono = allSignalsPadded(:, k);
    pwr = ShortTermPower(xMono, winLength);
    activeMask(:, k) = pwr > silenceThreshold;

    fprintf('Source %d: %d active out of %d (%.2f%%)\n', ...
        k, sum(activeMask(:, k)), length(xMono), ...
        100 * sum(activeMask(:, k)) / length(xMono));
end

% Target total power (energy) normalization
targetPower = 2100;  % Initial guess for total energy in active region
minPower = 0.0001;
step = 1;
found = false;

while ~found && targetPower > minPower
    clippingDetected = false;

    for k = 1:nFiles
        x = allSignalsPadded(:, k);
        mask = activeMask(:, k);
        activeSamples = x(mask);

        if isempty(activeSamples)
            continue;
        end

        totalEnergy = sum(activeSamples.^2);  % <-- POTENZA TOTALE QUI
        scale = sqrt(targetPower / totalEnergy);  % amplitude scaling

        x_scaled_active = activeSamples * scale;

        if any(abs(x_scaled_active) > 1)
            clippingDetected = true;
            break;
        end
    end

    if clippingDetected
        targetPower = targetPower - step;
    else
        found = true;
    end
end

if found
    fprintf('Target POWER found: %.5f\n', targetPower);
else
    warning('No safe power level found that avoids clipping.');
end

% Apply normalization
for k = 1:nFiles
    x = allSignalsPadded(:, k);
    mask = activeMask(:, k);
    activeSamples = x(mask);

    if isempty(activeSamples)
        warning('File %d is completely silent. Skipped.', k);
        continue;
    end

    totalPowerOrig = sum(activeSamples.^2);  % <-- POTENZA TOTALE ORIGINALE
    scale = sqrt(targetPower / totalPowerOrig);  % amplitude scaling factor

    x_scaled = x;
    x_scaled(mask) = x(mask) * scale;

    % Save
    [~, name, ~] = fileparts(files(k).name);
    outputName = fullfile(outputFolder, [name '_norm.wav']);
    audiowrite(outputName, x_scaled, fs);

    % Summary
    peak = max(abs(x_scaled));
    powerBefore = sum(x.^2);
    powerAfter = sum(x_scaled.^2);
    activePowerBefore = sum(x(mask).^2);
    activePowerAfter = sum(x_scaled(mask).^2);
    fprintf('%s -- POWER before: %.4f, after: %.4f. ACTIVE POWER before: %.4f, after: %.4f\n', ...
        name, powerBefore, powerAfter, activePowerBefore, activePowerAfter);
    
    % Plot
    figure;
    plot(x, 'r', 'DisplayName', 'Original', 'LineWidth', 1);
    hold on;
    plot(x_scaled, 'b', 'DisplayName', 'Normalized', 'LineWidth', 1);
    title(sprintf('%s — Total Active Power before: %.4f, after: %.4f. Peak: %.4f', ...
        name, totalPowerOrig, sum(x_scaled(mask).^2), peak));
    ylim([-1 1]);
    legend;
    grid on;
end
