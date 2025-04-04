function [doa_vector] = compute_doa(source_pos, mic_pos)
    % Compute the vector from the microphone to the source
    v = source_pos - mic_pos;

    % Normalize the vector to obtain the unit DOA vector
    doa_vector = v / norm(v);

    % Optional: print the results
    fprintf('DOA vector: [%.4f, %.4f, %.4f]\n', doa_vector);
end
