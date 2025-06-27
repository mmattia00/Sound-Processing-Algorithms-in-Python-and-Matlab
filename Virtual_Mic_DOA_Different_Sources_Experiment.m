clearvars
close all
clc

% === Define source and microphone positions (the same for all the recordings) ===
% Source coordinates in tracking reference frame
sourcePos = [0.8870, 1.3893, 0.0786]; % every recording is taken from the front
micPos = [-0.0693, 1.4236, -0.0113]; % Mic coordinates in tracking reference frame

% Compute Direction of Arrival (DOA) vector in tracking system
DOA_track_ref = compute_doa(sourcePos, micPos);

% Transform DOA vector from tracking ref. system to mic ref. system
M_rot = [1, 0, 0;
         0, 0, -1;
         0, 1, 0];
DOA = DOA_track_ref * M_rot;
fprintf('DOA vector (mic reference system): [%.4f, %.4f, %.4f]\n', DOA);

% Transformation matrix for cardioid-to-native mic config (4 channels -> 3 virtual)
T = (1/2)*sqrt(3)*[1,  1, -1, -1;
                   1, -1,  1, -1;
                   1, -1, -1,  1];

% Calculate the plane for rotation based on DOA
P1 = [0, 0, 0];   % Origin
P2 = DOA;         % Vector pointing to source

% Compute initial P3 for plane definition (must not be collinear with P2)
P3_initial = [1, 0, 0];
% Compute normal to initial plane and choose appropriate P3 to avoid degeneracies
normal = plane_normal(P1, P2, P3_initial);
P3 = choose_P3_based_on_plane_normal(normal);

% Compute the vector from which we want to start the rotation, and so the
% one on the plane with azimuthal angle 0 (conventionally the one in the x axis) 
t_origin = find_initial_vector(P1, P2, P3);


% scorri tutte le sotto cartelle contenute in "all_sources"
mainFolder = "sounds/all_sources_norm";
% extract information about the main folder
folders = dir(mainFolder);

figure;
hold on;  % Keep all plots on same figure
legend_entries = {};  % Initialize empty cell array for legend names

for i = 1:length(folders)
    if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
        subfolderName = folders(i).name;
        fullSubfolderPath = fullfile(mainFolder, subfolderName);
        % fprintf('Folder name: %s\n', fullSubfolderPath);

        % === Load mono audio channels ===
        [ch_1, ~] = audioread(fullfile(fullSubfolderPath, "FLU.wav"));
        [ch_2, ~] = audioread(fullfile(fullSubfolderPath, "FRD.wav"));
        [ch_3, ~] = audioread(fullfile(fullSubfolderPath, "BLD.wav"));
        [ch_4, fs] = audioread(fullfile(fullSubfolderPath, "BRU.wav"));

        angles = 0:0.1:2*pi;
        t_rotated_mat = zeros(length(angles), 3);

        for j = 1:length(angles)
            t_rotated_mat(j,:) = rotation_over_a_plane(P1, P2, P3, t_origin, angles(j));
        end

        % PROBLEM: signals now normalized but with different lenghts and
        % maybe different silent areas (does it affect the final overall
        % comparation?)
        ch_src_mat = t_rotated_mat * T * [ch_1'; ch_2'; ch_3'; ch_4'];
        ch_pwr_vec = sum(ch_src_mat.^2, 2);
        % main_lobe_width = compute_main_lobe_width(ch_pwr_vec, angles);
        % fprintf('Main lobe width (3dB beamwidth) for %s: %.3f radians (%.1f degrees)\n', subfolderName, main_lobe_width, rad2deg(main_lobe_width));


        % Plot the curve and store the label
        plot(angles, ch_pwr_vec');
        legend_entries{end+1} = subfolderName;  % Add to legend labels
    end
end

% Customize axes
xticks([pi/2, pi, 3*pi/2, 2*pi]);
xticklabels({'\pi/2', '\pi', '3/2\pi', '2\pi'});
xlabel('\angles (rad)');
ylabel('Power');
title('Directional Power across subfolders');
grid on;

% Add legend
legend(legend_entries, 'Interpreter', 'none');  % Use 'none' to avoid interpreting underscores


%% ALTERNATIVE VERSION WITH FREQUENCY BANDS SEPARATION 
% clearvars
% close all
% clc
% 
% % === Define source and microphone positions ===
% sourcePos = [0.8870, 1.3893, 0.0786]; 
% micPos = [-0.0693, 1.4236, -0.0113]; 
% 
% DOA_track_ref = compute_doa(sourcePos, micPos);
% M_rot = [1, 0, 0; 0, 0, -1; 0, 1, 0];
% DOA = DOA_track_ref * M_rot;
% 
% T = (1/2)*sqrt(3)*[1, 1, -1, -1; 1, -1, 1, -1; 1, -1, -1, 1];
% 
% P1 = [0, 0, 0];
% P2 = DOA;
% P3 = choose_P3_based_on_plane_normal(plane_normal(P1, P2, [1, 0, 0]));
% t_origin = find_initial_vector(P1, P2, P3);
% 
% angles = 0:0.1:2*pi;
% t_rotated_mat = zeros(length(angles), 3);
% for j = 1:length(angles)
%     t_rotated_mat(j,:) = rotation_over_a_plane(P1, P2, P3, t_origin, angles(j));
% end
% 
% mainFolder = "sounds/all_sources_norm";
% folders = dir(mainFolder);
% 
% % === Define filters for 3 bands ===
% fs = 48000; % Change this to the actual fs if needed
% bp1 = designfilt('bandpassiir','FilterOrder',6, ...
%                  'HalfPowerFrequency1', 20, 'HalfPowerFrequency2', 500, ...
%                  'SampleRate', fs);
% bp2 = designfilt('bandpassiir','FilterOrder',6, ...
%                  'HalfPowerFrequency1', 500, 'HalfPowerFrequency2', 2000, ...
%                  'SampleRate', fs);
% bp3 = designfilt('bandpassiir','FilterOrder',6, ...
%                  'HalfPowerFrequency1', 2000, 'HalfPowerFrequency2', 8000, ...
%                  'SampleRate', fs);
% 
% % Store band filters in cell array
% filters = {bp1, bp2, bp3};
% band_titles = {'Low Frequencies (0-500 Hz)', ...
%                'Mid Frequencies (500-2000 Hz)', ...
%                'High Frequencies (2-8 kHz)'};
% 
% % === Create one figure per band ===
% for b = 1:3
%     figure;
%     hold on;
%     legend_entries = {};
% 
%     for i = 1:length(folders)
%         if folders(i).isdir && ~strcmp(folders(i).name, '.') && ~strcmp(folders(i).name, '..')
%             subfolderName = folders(i).name;
%             fullSubfolderPath = fullfile(mainFolder, subfolderName);
% 
%             [ch_1, ~] = audioread(fullfile(fullSubfolderPath, "FLU.wav"));
%             [ch_2, ~] = audioread(fullfile(fullSubfolderPath, "FRD.wav"));
%             [ch_3, ~] = audioread(fullfile(fullSubfolderPath, "BLD.wav"));
%             [ch_4, ~] = audioread(fullfile(fullSubfolderPath, "BRU.wav"));
% 
%             % Filtra tutti i canali nella banda corrente
%             ch_1_f = filtfilt(filters{b}, ch_1);
%             ch_2_f = filtfilt(filters{b}, ch_2);
%             ch_3_f = filtfilt(filters{b}, ch_3);
%             ch_4_f = filtfilt(filters{b}, ch_4);
% 
%             % Trasformazione e potenza
%             ch_src_mat = t_rotated_mat * T * [ch_1_f'; ch_2_f'; ch_3_f'; ch_4_f'];
%             ch_pwr_vec = sum(ch_src_mat.^2, 2);
%             % ch_pwr_vec = ch_pwr_vec / max(ch_pwr_vec);  % Normalizza per forma
% 
%             plot(angles, ch_pwr_vec');
%             legend_entries{end+1} = subfolderName;
%         end
%     end
% 
%     xticks([pi/2, pi, 3*pi/2, 2*pi]);
%     xticklabels({'\pi/2', '\pi', '3/2\pi', '2\pi'});
%     xlabel('\angles (rad)');
%     ylabel('Power');
%     title(['Directional Power - ', band_titles{b}]);
%     grid on;
%     legend(legend_entries, 'Interpreter', 'none');
% end
