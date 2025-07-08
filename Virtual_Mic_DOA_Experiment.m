clearvars
close all
clc

% === Load mono audio channels ===
basePath = "sounds/first_experiment/phone_ringing_test_1";
[ch_1, ~] = audioread(fullfile(basePath, "FLU.wav"));
[ch_2, ~] = audioread(fullfile(basePath, "FRD.wav"));
[ch_3, ~] = audioread(fullfile(basePath, "BLD.wav"));
[ch_4, fs]  = audioread(fullfile(basePath, "BRU.wav"));

% === Define source and microphone positions (example test case) ===
% Source coordinates in tracking reference frame
sourcePos = [-2.114, 1.454, 0.538]; %test 1: back-left 
% sourcePos = [-0.123, 1.528, 0.478]; %test 2: front-left
% sourcePos = [-0.195, 1.523, -1.523]; %test 3: front-right
% sourcePos = [-2.159, 1.447, -1.415]; %test 4: back-right
% sourcePos = [-0.136, 1.525, -0.526]; %test 5: front
% sourcePos = [-1.174, 1.4801, -1.496]; %test 6: right
micPos = [-1.228, 1.380, -0.469]; % Mic coordinates in tracking reference frame

% Compute Direction of Arrival (DOA) vector in tracking system
DOA_track_ref = compute_doa(sourcePos, micPos);

% Transform DOA vector from tracking ref. system to mic ref. system
M_rot = [1, 0, 0;
         0, 0, 1;
         0, 1, 0];
DOA = DOA_track_ref * M_rot;
fprintf('DOA vector (mic reference system): [%.4f, %.4f, %.4f]\n', DOA);

% Transformation matrix for cardioid-to-native mic config (4 channels -> 3 virtual)
T = (1/2)*sqrt(3)*[1,  1, -1, -1;
                   1, -1,  1, -1;
                   1, -1, -1,  1];

% Initial vector representing source direction in mic ref system
t_orig = DOA;

% Calculate the plane for rotation based on DOA
P1 = [0, 0, 0];   % Origin
P2 = DOA;         % Vector pointing to source

% Compute initial P3 for plane definition (must not be collinear with P2)
P3_initial = [1, 0, 0];
% Compute normal to initial plane and choose appropriate P3 to avoid degeneracies
normal = plane_normal(P1, P2, P3_initial);
P3 = choose_P3_based_on_plane_normal(normal);

% Number of animation frames and angular step size
N_frames = 100;
theta_stepsize = 2*pi / N_frames;

% Setup figure window full screen
figure;
set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

% === Main animation loop ===
for i = 0:N_frames
    clf;  % Clear current figure
    
    % Calculate rotated vector on the plane
    t_rotated = rotation_over_a_plane(P1, P2, P3, t_orig, theta_stepsize * i);
    
    % === Subplot 1: 3D Visualization ===
    h1 = subplot(1,3,1);
    draw_3D_representation(t_rotated, DOA, P1, P2, P3);
    set(h1, 'Position', [0.05 0.1 0.36 0.8]);
    
    % === Subplot 2: Power Meter ===
    % Calculate power for virtual mic aligned with rotated direction
    ch_src = t_rotated * T * [ch_1'; ch_2'; ch_3'; ch_4'];
    ch_src_pwr = sum(ch_src.^2);
    
    h2 = subplot(1,3,2);
    draw_powerometer(ch_src_pwr);
    set(h2, 'Position', [0.5 0.1 0.10 0.8]);
    
    % === Subplot 3: 2D Polar Pattern ===
    subplot(1,3,3);
    azimuth_angle = extract_azimuth_angle(t_rotated);
    plot_figure_of_8_graph(azimuth_angle);
    
    pause(0.5);
end
