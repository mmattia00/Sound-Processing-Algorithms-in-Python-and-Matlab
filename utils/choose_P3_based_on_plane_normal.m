function P3 = choose_P3_based_on_plane_normal(n)
% Choose P3 point to define plane, avoiding parallelism of normal vector to Y-axis

    y_axis = [0 1 0];
    tolerance = 0.05;
    if abs(dot(n, y_axis)) > 1 - tolerance
        % Normal is (anti-)parallel to Y-axis, choose P3 = X-axis to avoid degeneracy
        P3 = [1 0 0];
    else
        % Otherwise choose P3 as Y-axis
        P3 = [0 1 0];
    end
end
