clearvars
close all
clc

%% === Parametri di configurazione ===
test_number = 1;
test_string_positions = ["back-left", "front-left", "front-right", "back-right", "front", "right"];

% === Marker dei 4 loudspeaker === (cambiando il segno alla z)
P1 = [-1.2590, 0.4258, 0.9908]; P2 = [-1.2287, 0.5271, 1.2168];
P3 = [1.0422, 0.5036, 1.2931];  P4 = [1.1115, 0.6506, 1.0976];
P5 = [1.2900, 0.5070, -1.1268];  P6 = [1.0973, 0.6557, -1.2089];
P7 = [-1.1184, 0.4381, -1.3248]; P8 = [-1.2103, 0.5532, -1.1232];

% === Caricamento segnali audio mono da capsule cardioidi ===
basePath = sprintf("sounds/playback_experiment/speech/test_%d", test_number);
[ch_FLU, ~] = audioread(fullfile(basePath, "FLU.wav"));  % Front Left Up
[ch_FRD, ~] = audioread(fullfile(basePath, "FRD.wav"));  % Front Right Down
[ch_BLD, ~] = audioread(fullfile(basePath, "BLD.wav"));  % Back Left Down
[ch_BRU, fs]  = audioread(fullfile(basePath, "BRU.wav")); % Back Right Up

%% === Encoding FOA: da cardioidi → WXYZ (standard) ===
T_encode = (1/2)*sqrt(3)*[1,  1,  1,  1;
                          1,  1, -1, -1;
                          1, -1,  1, -1;
                          1, -1, -1,  1];
input_signals = [ch_FLU'; ch_FRD'; ch_BLD'; ch_BRU']; % [4 x N] una riga per ogni canale
ch_native = (T_encode * input_signals).';  % [N x 4] una colonna per W una colonna per X ecc..
augmenting_gain = 1.5;
diminishing_gain = 0.5;
ch_native(:, 1) = ch_native(:, 1) * diminishing_gain;    % W
ch_native(:, 2) = ch_native(:, 2) * augmenting_gain;    % X
ch_native(:, 3) = ch_native(:, 3) * augmenting_gain;    % Y
ch_native(:, 4) = ch_native(:, 4) * augmenting_gain;    % Z


%% === Calcolo delle coordinate normalizzate dei loudspeaker ===
% Calcolo centro dei marker
L1 = compute_center_of_paralelepiped(P1, P2);
L2 = compute_center_of_paralelepiped(P3, P4);
L3 = compute_center_of_paralelepiped(P5, P6);
L4 = compute_center_of_paralelepiped(P7, P8);

% no need to do any translation becaude the loudspeaker are already around
% the origin
% center = [(L1(1)+L2(1)+L3(1)+L4(1))/4, (L1(2)+L2(2)+L3(2)+L4(2))/4, (L1(3)+L2(3)+L3(3)+L4(3))/4];
% L1 = L1 - center;
% L2 = L2 - center;
% L3 = L3 - center;
% L4 = L4 - center;

% Rotazione coordinate da OptiTrack → Mic
M_rot = [1, 0, 0;
         0, 0, 1;
         0, -1, 0];
L1 = L1 * M_rot;
L2 = L2 * M_rot;
L3 = L3 * M_rot;
L4 = L4 * M_rot;

% Normalizza perchè siamo interessati alla direzione su cui proiettare il
% segnale 
L1 = L1 / norm(L1);
L2 = L2 / norm(L2);
L3 = L3 / norm(L3);
L4 = L4 / norm(L4);



%% === Decoding FOA: WXYZ → 4 Loudspeaker ===
T_decode = [1, L1;
            1, L2;
            1, L3;
            1, L4];  % [4 x 4]

% Calcolo segnali finali per ciascun loudspeaker
% S = 0.5 * (ch_native * T_decode.');  % [N x 4]
S = 0.5 * T_decode * ch_native';  %
% (Opzionale) Normalizzazione output per evitare clipping
max_val = max(abs(S), [], 'all');
if max_val > 1
    S = S / max_val;
end

%% === Salvataggio WAV + README ===
outputFolder = 'C:\Users\ACE71542GR175\Desktop\Musica digitale\playback_template_for_ambisonic_project Project';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
else
    % Elimina file .txt, .wav e .wav.asd nella cartella
    delete(fullfile(outputFolder, '*.txt'));
    delete(fullfile(outputFolder, '*.wav'));
    delete(fullfile(outputFolder, '*.wav.asd'));
end

for i = 1:4
    audiowrite(fullfile(outputFolder, sprintf('S%d.wav', i)), S(i, :), fs);
end

% README.txt (fuori dal ciclo)
readmePath = fullfile(outputFolder, 'README.txt');
fid = fopen(readmePath, 'w');
fprintf(fid, 'The virtual source should be perceived in the position: %s\n', test_string_positions(test_number));
fclose(fid);

disp('Decoding e salvataggio completati con successo.');

%% === Visualizzazione: potenza di ciascun loudspeaker ===
% Calcola la potenza RMS di ciascun canale
rms_power = rms(S, 2).^2;  % vettore [4 x 1] = potenza per LS1, LS2, LS3, LS4

% Crea un bar plot
figure;
bar(rms_power, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');
xticks(1:4);
xticklabels({'LS1', 'LS2', 'LS3', 'LS4'});
ylabel('Power (RMS^2)');
title(sprintf('Speaker Power Distribution - Test %d (%s)', ...
    test_number, test_string_positions(test_number)));
grid on;


