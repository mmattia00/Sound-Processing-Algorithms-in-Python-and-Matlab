function [t_origin] = find_initial_vector(P1, P2, P3)
% function to compute the vector on the plane corresponding to where we
% want to begin the rotation, and so where theta = 0 and so conventionally
% on the x axis

    % Due vettori nel piano
    v1 = P2 - P1;
    v2 = P3 - P1;
    
    % Calcola il vettore normale al piano
    n = cross(v1, v2);  % n = [a, b, c]
    
    % Coefficienti dell'equazione del piano: ax + by + cz + d = 0
    a = n(1);
    b = n(2);
    c = n(3);
    d = -dot(n, P1);

    % x = 1, y = 0; z = ??
    z = (-a*1-d)/c;

    % define vector
    orig_coord = [0,0,0];
    extremity_coord = [1, 0, z];
    t_origin = extremity_coord - orig_coord;
end