%% ALTERNATIVE VERSION WITH FREQUENCY BANDS SEPARATION 
clearvars    % Clear all variables from the workspace
close all    % Close all figure windows
clc          % Clear the command window

% === Define source and microphone positions in the OptiTrack tracking space ===
sourcePos = [1.1994, 1.3936, -0.0016];  % Physical 3D coordinates of the sound source (assumed in front of the mic)
micPos = [-0.1045, 1.4151, -0.0099];    % Physical 3D coordinates of the microphone

% === Compute DOA (Direction of Arrival) in tracking reference frame ===
DOA_track_ref = compute_doa(sourcePos, micPos);  % Unit vector from mic to source

% === Convert DOA to microphone's coordinate system ===
% This matrix rotates coordinates from the OptiTrack reference frame to the microphone's reference frame.
M_rot = [1, 0, 0; 
         0, 0, -1; 
         0, 1, 0];
DOA = DOA_track_ref * M_rot;  % Apply rotation

% === Ambisonic projection matrix (from 4 cardioids to FOA XYZ) ===
% This is used to project audio signals onto three axes (X, Y, Z) using a tetrahedral mic layout
T = (1/2)*sqrt(3)*[1, 1, -1, -1;
                   1, -1, 1, -1;
                   1, -1, -1, 1];

% === Define geometric plane for rotation computations ===
P1 = [0, 0, 0];        % Origin point of rotation
P2 = DOA;              % DOA direction (unit vector)
P3 = choose_P3_based_on_plane_normal(plane_normal(P1, P2, [1, 0, 0]));  % A third point defining the rotation plane
t_origin = find_initial_vector(P1, P2, P3);  % Initial tangent vector for circular rotation

% === Generate rotated tangent vectors across 360° on the DOA plane ===
angles = 0:0.1:2*pi;  % Angles from 0 to 2π radians
t_rotated_mat = zeros(length(angles), 3);  % Preallocate matrix
for j = 1:length(angles)
    % Rotate the tangent vector around the DOA-defined plane
    t_rotated_mat(j,:) = rotation_over_a_plane(P1, P2, P3, t_origin, angles(j));
end

% === Load all subfolders containing Ambisonic recordings ===
mainFolder = "sounds/second_experiment/all_sources_norm";  % Parent folder of recordings
folders = dir(mainFolder);               % List all folders

% === Define 3 frequency bandpass filters ===
fs = 48000;  % Sampling rate (Hz) — adjust if needed

% Low band: 20–500 Hz
bp1 = designfilt('bandpassiir','FilterOrder',6, ...
                 'HalfPowerFrequency1', 20, 'HalfPowerFrequency2', 500, ...
                 'SampleRate', fs);

% Mid band: 500–2000 Hz
bp2 = designfilt('bandpassiir','FilterOrder',6, ...
                 'HalfPowerFrequency1', 500, 'HalfPowerFrequency2', 2000, ...
                 'SampleRate', fs);

% High band: 2000–8000 Hz
bp3 = designfilt('bandpassiir','FilterOrder',6, ...
                 'HalfPowerFrequency1', 2000, 'HalfPowerFrequency2', 8000, ...
                 'SampleRate', fs);

% Store all filters in a cell array for easy indexing
filters = {bp1, bp2, bp3};

% Titles for plots corresponding to the three bands
band_titles = {'Low Frequencies (0-500 Hz)', ...
               'Mid Frequencies (500-2000 Hz)', ...
               'High Frequencies (2-8 kHz)'};

% === Define plotting styles ===
lineStyles = {'-', '--', ':', '-.'};  % Different line styles to differentiate sources

% === Loop over frequency bands and generate one plot per band ===
for b = 1:3
    figure;  % Create a new figure for current band
    hold on;
    legend_entries = {};  % Initialize legend entries

    idx_plot = 0;  % Counter for sources plotted
    for i = 1:length(folders)
        % Skip non-folder entries and default '.' and '..'
        if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
            subfolderName = folders(i).name;
            fullSubfolderPath = fullfile(mainFolder, subfolderName);

            % === Load 4 cardioid microphone channels ===
            [ch_1, ~] = audioread(fullfile(fullSubfolderPath, "FLU.wav"));  % Front Left Up
            [ch_2, ~] = audioread(fullfile(fullSubfolderPath, "FRD.wav"));  % Front Right Down
            [ch_3, ~] = audioread(fullfile(fullSubfolderPath, "BLD.wav"));  % Back Left Down
            [ch_4, ~] = audioread(fullfile(fullSubfolderPath, "BRU.wav"));  % Back Right Up

            % === Apply bandpass filter to each channel for the current band ===
            ch_1_f = filtfilt(filters{b}, ch_1);
            ch_2_f = filtfilt(filters{b}, ch_2);
            ch_3_f = filtfilt(filters{b}, ch_3);
            ch_4_f = filtfilt(filters{b}, ch_4);

            % === Compute projection of FOA-encoded signals along rotated directions ===
            % Multiply in order: [angles × 3] · [3 × 4] · [4 × N] = [angles × N]
            ch_src_mat = t_rotated_mat * T * [ch_1_f'; ch_2_f'; ch_3_f'; ch_4_f'];

            % === Compute energy over time for each direction ===
            ch_pwr_vec = sum(ch_src_mat.^2, 2);  % Power for each angle

            % === Select appropriate line style (rotates if more sources than styles) ===
            idx_plot = idx_plot + 1;
            style = lineStyles{mod(idx_plot - 1, length(lineStyles)) + 1};

            % === Plot direction-dependent power ===
            plot(angles, ch_pwr_vec', style, 'LineWidth', 1.5);
            legend_entries{end+1} = subfolderName;  % Add entry to legend
        end
    end

    % === Format plot axes and legend ===
    xticks([pi/2, pi, 3*pi/2, 2*pi]);
    xticklabels({'\pi/2', '\pi', '3/2\pi', '2\pi'});
    xlabel('\angle (rad)');
    ylabel('Power');
    title(['Directional Power - ', band_titles{b}]);
    grid on;
    legend(legend_entries, 'Interpreter', 'none');  % Show subfolder names in legend
end
