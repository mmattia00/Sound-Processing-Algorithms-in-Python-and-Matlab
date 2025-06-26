clearvars
close all
clc

% === Define source and microphone positions (the same for all the recordings) ===
% Source coordinates in tracking reference frame

% OLD
% sourcePos = [-0.648, 1.505, 0.491]; % every recording is taken from the front
% micPos = [-1.228, 1.380, 0.469]; % Mic coordinates in tracking reference frame

% NEW
sourcePos = [0.4728, 1.5474, -0.0016]; % every recording is taken from the front
micPos = [-0.1057, 1.4253, -0.0242]; % Mic coordinates in tracking reference frame

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
mainFolder = "sounds/all_sources";
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

        % channel normalization
        % ch_1 = ch_1 / norm(ch_1);
        % ch_2 = ch_2 / norm(ch_2);
        % ch_3 = ch_3 / norm(ch_3);
        % ch_4 = ch_4 / norm(ch_4);
        % ch_1 = ch_1 / sqrt(mean(ch_1.^2));
        % ch_2 = ch_2 / sqrt(mean(ch_2.^2));
        % ch_3 = ch_3 / sqrt(mean(ch_3.^2));
        % ch_4 = ch_4 / sqrt(mean(ch_4.^2));
    
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

