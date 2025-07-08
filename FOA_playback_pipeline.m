clearvars  % Remove all variables from the workspace
close all  % Close all figure windows
clc        % Clear the command window

%% === Configuration Parameters ===
test_number = 1;  % Index to select the test (used to choose audio and label)
test_string_positions = ["back-left", "front-left", "front-right", "back-right", "front", "right"];
% Descriptive positions associated with different tests

%% === Loudspeaker Marker Positions (z-axis sign is flipped) ===
% These are 3D coordinates of markers used to locate the loudspeakers
% Each loudspeaker is defined by 2 OptiTrack markers placed on it
P1 = [-1.2590, 0.4258, 0.9908]; P2 = [-1.2287, 0.5271, 1.2168];   % Loudspeaker 1
P3 = [1.0422, 0.5036, 1.2931];  P4 = [1.1115, 0.6506, 1.0976];    % Loudspeaker 2
P5 = [1.2900, 0.5070, -1.1268]; P6 = [1.0973, 0.6557, -1.2089];   % Loudspeaker 3
P7 = [-1.1184, 0.4381, -1.3248]; P8 = [-1.2103, 0.5532, -1.1232]; % Loudspeaker 4

%% === Load Mono Audio Signals from Cardioid Capsules ===
basePath = sprintf("sounds/playback_experiment/speech/test_%d", test_number);
% Read the mono recordings captured by each capsule
[ch_FLU, ~] = audioread(fullfile(basePath, "FLU.wav"));  % Front Left Up
[ch_FRD, ~] = audioread(fullfile(basePath, "FRD.wav"));  % Front Right Down
[ch_BLD, ~] = audioread(fullfile(basePath, "BLD.wav"));  % Back Left Down
[ch_BRU, fs]  = audioread(fullfile(basePath, "BRU.wav")); % Back Right Up

%% === FOA Encoding: Cardioids → Ambisonic Channels (W, X, Y, Z) ===
% Transformation matrix to convert cardioid signals into Ambisonic format
T_encode = (1/2)*sqrt(3)*[1,  1,  1,  1;
                          1,  1, -1, -1;
                          1, -1,  1, -1;
                          1, -1, -1,  1];
input_signals = [ch_FLU'; ch_FRD'; ch_BLD'; ch_BRU'];  % Matrix [4 x N], each row is a cardioid channel

ch_native = (T_encode * input_signals).';  % Matrix [N x 4], columns are W, X, Y, Z

% Apply gains to Ambisonic channels: enhance spatial components, reduce omnidirectional component
augmenting_gain = 1.5;
diminishing_gain = 0.5;
ch_native(:, 1) = ch_native(:, 1) * diminishing_gain;   % W channel
ch_native(:, 2) = ch_native(:, 2) * augmenting_gain;    % X channel
ch_native(:, 3) = ch_native(:, 3) * augmenting_gain;    % Y channel
ch_native(:, 4) = ch_native(:, 4) * augmenting_gain;    % Z channel

%% === Compute Normalized Coordinates of Each Loudspeaker ===
% Compute loudspeaker center as the midpoint of its two markers
L1 = compute_center_of_paralelepiped(P1, P2);  % Loudspeaker 1
L2 = compute_center_of_paralelepiped(P3, P4);  % Loudspeaker 2
L3 = compute_center_of_paralelepiped(P5, P6);  % Loudspeaker 3
L4 = compute_center_of_paralelepiped(P7, P8);  % Loudspeaker 4

% The loudspeakers are already placed symmetrically around the origin,
% so no translation (centering) is needed.

% Rotate coordinates from OptiTrack's frame to the microphone's reference frame
M_rot = [1, 0, 0;
         0, 0, 1;
         0, -1, 0];  % Swaps and inverts Y/Z to match mic frame

% Apply rotation
L1 = L1 * M_rot;
L2 = L2 * M_rot;
L3 = L3 * M_rot;
L4 = L4 * M_rot;

% Normalize the vectors: we only need the direction, not distance
L1 = L1 / norm(L1);
L2 = L2 / norm(L2);
L3 = L3 / norm(L3);
L4 = L4 / norm(L4);

%% === FOA Decoding: Ambisonic WXYZ → 4 Loudspeaker Signals ===
% Build the decoding matrix using each loudspeaker's direction vector
% Each row: [1, x_l, y_l, z_l] — i.e., scalar gain for W plus direction for XYZ
T_decode = [1, L1;
            1, L2;
            1, L3;
            1, L4];  % Matrix [4 x 4]

% Decode the Ambisonic signals by applying the decoding matrix
% Multiply: decoding matrix × [WXYZ]^T → loudspeaker signals
S = 0.5 * T_decode * ch_native';  % Matrix [4 x N]

% (Optional) Normalize to avoid clipping if amplitude exceeds [-1, 1]
max_val = max(abs(S), [], 'all');
if max_val > 1
    S = S / max_val;
end

%% === Save Decoded Signals as WAV Files + README ===
outputFolder = 'C:\Users\ACE71542GR175\Desktop\Musica digitale\playback_template_for_ambisonic_project Project';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);  % Create output folder if it doesn't exist
else
    % Clean up previous output: remove all .txt and .wav files
    delete(fullfile(outputFolder, '*.txt'));
    delete(fullfile(outputFolder, '*.wav'));
    delete(fullfile(outputFolder, '*.wav.asd'));  % Optional metadata files
end

% Save one WAV file per loudspeaker channel
for i = 1:4
    audiowrite(fullfile(outputFolder, sprintf('S%d.wav', i)), S(i, :), fs);
end

% Write a README to indicate the test and target source direction
readmePath = fullfile(outputFolder, 'README.txt');
fid = fopen(readmePath, 'w');
fprintf(fid, 'The virtual source should be perceived in the position: %s\n', ...
        test_string_positions(test_number));
fclose(fid);

disp('Decoding and file saving completed successfully.');

%% === Visualization: Power per Loudspeaker Channel ===
% Compute RMS power of each loudspeaker signal
rms_power = rms(S, 2).^2;  % Vector [4 x 1]: one value per loudspeaker

% Plot bar graph of the loudspeaker powers
figure;
bar(rms_power, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');  % Light blue bars with black borders
xticks(1:4);
xticklabels({'LS1', 'LS2', 'LS3', 'LS4'});  % Label each speaker
ylabel('Power (RMS^2)');
title(sprintf('Speaker Power Distribution - Test %d (%s)', ...
    test_number, test_string_positions(test_number)));
grid on;  % Add grid to the plot
