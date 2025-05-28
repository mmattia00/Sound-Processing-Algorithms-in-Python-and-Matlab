function doa_vector = compute_doa(source_pos, mic_pos)
% Compute the unit Direction Of Arrival (DOA) vector from mic to source
    vec = source_pos - mic_pos;
    doa_vector = vec / norm(vec);
    fprintf('DOA vector (tracking reference system): [%.4f, %.4f, %.4f]\n', doa_vector);
end
