function [main_lobe_width] = compute_main_lobe_width(ch_pwr_vec, angles)
    % --- Calculate main lobe width (3dB beamwidth) ---

    % Normalize power by max power to get relative power
    p_norm = ch_pwr_vec / max(ch_pwr_vec);
    
    % Threshold at 0.5 (half power, -3 dB point)
    threshold = 0.9;
    
    % Find indices where power crosses threshold on each side of the peak
    [~, peak_idx] = max(p_norm);
    
    % Search left side from peak_idx down to 1
    left_idx = find(p_norm(1:peak_idx) < threshold, 1, 'last');
    if isempty(left_idx)
        left_idx = 1;
    end
    
    % Search right side from peak_idx up to end
    right_idx_rel = find(p_norm(peak_idx:end) < threshold, 1, 'first');
    if isempty(right_idx_rel)
        right_idx = length(p_norm);
    else
        right_idx = peak_idx - 1 + right_idx_rel;
    end
    
    % Linear interpolate exact crossing angles for better accuracy
    theta_left = interp1(p_norm(left_idx:left_idx+1), angles(left_idx:left_idx+1), threshold);
    theta_right = interp1(p_norm(right_idx-1:right_idx), angles(right_idx-1:right_idx), threshold);
    
    % Compute main lobe width
    main_lobe_width = theta_right - theta_left; % in radians
end