% loading the audio files (all mono)
path = "phone_ringing_test_3";
[ch_1, ~] = audioread(path + "/FLU.wav");
[ch_2, ~] = audioread(path + "/FRD.wav");
[ch_3, ~] = audioread(path + "/BLD.wav");
[ch_4, fs] = audioread(path + "/BRU.wav");


% defining Direction Of Arrival (DOA)
%sourcePos = [-0.567092, 1.540031, -0.777554]; %test 1
%sourcePos = [0.787807, 1.533283, -0.867458]; %test 2
%sourcePos = [0.785599, 1.548480, 0.933949]; %test 3
sourcePos = [1.156678, 1.547312, 1.188559]; %test 3'
%sourcePos = [-0.787221, 1.561335, 1.016164]; %test 4
%sourcePos = [1.330709, 1.535722, -0.044023]; %test 5
%sourcePos = [0.063359, 1.532059, -1.337881]; %test 6
micPos = [0.024946, 1.434991, 0.023666];
DOA_track_ref_system = compute_doa(sourcePos, micPos);

% transform the DOA in reference system of the mic
M_rot = [1, 0, 0; 0, 0, 1; 0, -1, 0];
DOA = DOA_track_ref_system * M_rot;


% compute rotation matrix
v = [0; 0; 1]; % reference vector
% check if the reference vector is parallel with the original source
tolerance = 1e-06;
cosTheta = dot(v, DOA) / (norm(v) * norm(DOA));
% when parallel cosTheta will be more or less 1 or -1 (something like
% 0.999999 or -1.0000001). We use a tolerance threshold to not depending on
% an exact match
if abs(cosTheta + 1) < tolerance || abs(cosTheta - 1) < tolerance 
    disp("The reference vector is parallel with respect to the source, changin reference vector...");
    v = [1; 0; 0];
else
    disp("Correct reference vector")
end
% notice that e1 coincide with the DOA because we want to rotate the
% reference system toward the source
e1 = DOA;  % keep as column
v_proj = dot(e1, v) * e1;
e2 = v' - v_proj;
e2 = e2 / norm(e2);
e3 = cross(e1, e2);
R = [e1', e2', e3'];

disp(R);

% extend to 4x4 matrix
R_ext = eye(4);
R_ext(2:4, 2:4) = R;
% disp(R_ext);

% original T matrix
T = (1/2) * sqrt(3) * [1, 1, 1, 1; 1, 1, -1, -1; 1, -1, 1, -1; 1, -1, -1, 1];

% apply transformation
T_prime = R_ext * T; % '*' as matrix product

% Apply the transformation to each channel
% Applying original transfomation matrix
ch_1_native = T(1,1) * ch_1 + T(1,2) * ch_2 + T(1,3) * ch_3 + T(1,4) * ch_4;
ch_2_native = T(2,1) * ch_1 + T(2,2) * ch_2 + T(2,3) * ch_3 + T(2,4) * ch_4;
ch_3_native = T(3,1) * ch_1 + T(3,2) * ch_2 + T(3,3) * ch_3 + T(3,4) * ch_4;
ch_4_native = T(4,1) * ch_1 + T(4,2) * ch_2 + T(4,3) * ch_3 + T(4,4) * ch_4;
% Applying modified transformation matrix
ch_1_rotated = T_prime(1,1) * ch_1 + T_prime(1,2) * ch_2 + T_prime(1,3) * ch_3 + T_prime(1,4) * ch_4;
ch_2_rotated = T_prime(2,1) * ch_1 + T_prime(2,2) * ch_2 + T_prime(2,3) * ch_3 + T_prime(2,4) * ch_4;
ch_3_rotated = T_prime(3,1) * ch_1 + T_prime(3,2) * ch_2 + T_prime(3,3) * ch_3 + T_prime(3,4) * ch_4;
ch_4_rotated = T_prime(4,1) * ch_1 + T_prime(4,2) * ch_2 + T_prime(4,3) * ch_3 + T_prime(4,4) * ch_4;


% Power analysis
% Calculate the total power of the original channels
power_ch1 = sum(ch_1.^2);
power_ch2 = sum(ch_2.^2);
power_ch3 = sum(ch_3.^2);
power_ch4 = sum(ch_4.^2);

% Calculate the total power of the transformed channels (captured using the
% virtual native configuration)
power_ch1_native = sum(ch_1_native.^2);
power_ch2_native = sum(ch_2_native.^2);
power_ch3_native = sum(ch_3_native.^2);
power_ch4_native = sum(ch_4_native.^2);

% Calculate the total power of the transformed channels (captured using the
% virtual rotated native configuration)
power_ch1_rotated = sum(ch_1_rotated.^2);
power_ch2_rotated = sum(ch_2_rotated.^2);
power_ch3_rotated = sum(ch_3_rotated.^2);
power_ch4_rotated = sum(ch_4_rotated.^2);


% Display results
disp("Power of original channels:");
disp(["ch_1: ", num2str(power_ch1)]);
disp(["ch_2: ", num2str(power_ch2)]);
disp(["ch_3: ", num2str(power_ch3)]);
disp(["ch_4: ", num2str(power_ch4)]);

disp("Power of transformed channels (captured with a virtual native configuration):");
disp(["ch_1: ", num2str(power_ch1_native)]);
disp(["ch_2: ", num2str(power_ch2_native)]);
disp(["ch_3: ", num2str(power_ch3_native)]);
disp(["ch_4: ", num2str(power_ch4_native)]);

disp("Power of transformed channels (captured with a virtual native configuration rotated toward the source):");
disp(["ch_1: ", num2str(power_ch1_rotated)]);
disp(["ch_2: ", num2str(power_ch2_rotated)]);
disp(["ch_3: ", num2str(power_ch3_rotated)]);
disp(["ch_4: ", num2str(power_ch4_rotated)]);


% plots and conclusions
% Power data for each configuration
power_data = [power_ch1, power_ch2, power_ch3, power_ch4; 
              power_ch1_native, power_ch2_native, power_ch3_native, power_ch4_native; 
              power_ch1_rotated, power_ch2_rotated, power_ch3_rotated, power_ch4_rotated];

% Transpose the power data so that rows correspond to channels and columns to configurations
power_data = power_data';

% Channel names
channel_names = {'ch_1', 'ch_2', 'ch_3', 'ch_4'};

% Configuration names
config_names = {'Original', 'Native', 'Rotated'};

% Heatmap plot
figure;
heatmap(config_names, channel_names, power_data);
xlabel('Configurations');
ylabel('Channels');
title('Heatmap of Power Across Configurations and Channels');
% Time-domain power for each channel
time = (0:length(ch_1)-1) / fs;  % time vector based on sampling frequency

% Calculate the power for each channel in the time domain (squared signal)
power_ch1_time = ch_1.^2;
power_ch2_time = ch_2.^2;
power_ch3_time = ch_3.^2;
power_ch4_time = ch_4.^2;

% Plot time-domain power for each channel
figure;

subplot(2, 2, 1); % Create a subplot for each channel
plot(time, power_ch1_time);
title('Time-Domain Power of ch_1');
xlabel('Time (s)');
ylabel('Power');

subplot(2, 2, 2);
plot(time, power_ch2_time);
title('Time-Domain Power of ch_2');
xlabel('Time (s)');
ylabel('Power');

subplot(2, 2, 3);
plot(time, power_ch3_time);
title('Time-Domain Power of ch_3');
xlabel('Time (s)');
ylabel('Power');

subplot(2, 2, 4);
plot(time, power_ch4_time);
title('Time-Domain Power of ch_4');
xlabel('Time (s)');
ylabel('Power');

sgtitle('Time-Domain Power of Each Channel'); % Title for the entire figure

