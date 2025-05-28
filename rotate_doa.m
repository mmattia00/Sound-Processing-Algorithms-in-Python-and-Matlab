function[rotated_doa] = rotate_doa(original_doa, theta)
    M_rot = [cos(theta), -sin(theta), 0;
             sin(theta), cos(theta),  0;
             0,          0,           1];
    rotated_doa = M_rot * original_doa';
    rotated_doa = rotated_doa';
end