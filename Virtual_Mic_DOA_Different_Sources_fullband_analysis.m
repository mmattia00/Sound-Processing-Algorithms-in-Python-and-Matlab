clearvars
close all
clc

%% === 1. Define Source and Microphone Positions ===
source_pos = [1.1994, 1.3936, -0.0016];   % Position of sound source
mic_pos    = [-0.1045, 1.4151, -0.0099];  % Microphone position in tracking system

%% === 2. Compute DOA and Transform to Mic Reference Frame ===
doa_tracking = compute_doa(source_pos, mic_pos);

M_tracking_to_mic = [1, 0, 0;
                     0, 0, -1;
                     0, 1, 0];
doa_mic = doa_tracking * M_tracking_to_mic;
fprintf('DOA vector (mic reference system): [%.4f, %.4f, %.4f]\n', doa_mic);

%% === 3. Define Transformation Matrix from Cardioid to Native Format ===
T = (1/2)*sqrt(3)*[ 1,  1, -1, -1;
                    1, -1,  1, -1;
                    1, -1, -1,  1 ];

%% === 4. Prepare Plane and Origin Vector for Rotation ===
P1 = [0, 0, 0];        % Origin
P2 = doa_mic;          % DOA vector
P3_guess = [1, 0, 0];  % Initial third point to define the plane
normal_vec = plane_normal(P1, P2, P3_guess);
P3 = choose_P3_based_on_plane_normal(normal_vec);

t0 = find_initial_vector(P1, P2, P3);  % Azimuth = 0 vector on the plane

%% === 5. Load Data from All Subfolders ===
main_folder = "sounds/second_experiment/all_sources_norm";
folders = dir(main_folder);

%% === 6. Plot Setup ===
figure;
hold on;
legend_entries = {};
line_styles = {'-', '--', ':', '-.'};
colors = lines(length(folders));
style_idx = 1;

%% === 7. Process Each Recording Folder ===
for i = 1:length(folders)
    folder = folders(i);
    if folder.isdir && ~ismember(folder.name, {'.', '..'})
        folder_name = folder.name;
        path = fullfile(main_folder, folder_name);

        % === Load Microphone Channels ===
        [FLU, ~] = audioread(fullfile(path, "FLU.wav"));
        [FRD, ~] = audioread(fullfile(path, "FRD.wav"));
        [BLD, ~] = audioread(fullfile(path, "BLD.wav"));
        [BRU, fs] = audioread(fullfile(path, "BRU.wav"));

        % === Generate Rotated Microphone Vectors ===
        angles = 0:0.1:2*pi;
        t_rot_mat = zeros(length(angles), 3);
        for j = 1:length(angles)
            t_rot_mat(j,:) = rotation_over_a_plane(P1, P2, P3, t0, angles(j));
        end

        % === Transform Channels and Compute Power ===
        mic_matrix = [FLU'; FRD'; BLD'; BRU'];
        ch_transformed = t_rot_mat * T * mic_matrix;
        power_vec = sum(ch_transformed.^2, 2);
        power_vec = power_vec / max(power_vec); % Normalize if needed

        % === Plot ===
        linestyle = line_styles{mod(style_idx - 1, length(line_styles)) + 1};
        color = colors(mod(style_idx - 1, size(colors,1)) + 1, :);
        style_idx = style_idx + 1;

        plot(angles, power_vec', 'LineStyle', linestyle, 'Color', color, 'LineWidth', 1.2);
        legend_entries{end+1} = folder_name;
    end
end

%% === 8. Final Plot Customization ===
xticks([pi/2, pi, 3*pi/2, 2*pi]);
xticklabels({'\pi/2', '\pi', '3/2\pi', '2\pi'});
xlabel('Angle (rad)');
ylabel('Power');
title('Directional Power across Subfolders');
grid on;
legend(legend_entries, 'Interpreter', 'none');
