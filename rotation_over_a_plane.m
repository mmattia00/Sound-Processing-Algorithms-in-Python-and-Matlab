function vec_rot = rotation_over_a_plane(P1, P2, P3, vec_orig, theta)
% Rotate vector vec_orig around normal axis defined by plane P1,P2,P3 by angle theta
% Rotation follows Rodrigues' rotation formula

    v1 = P2 - P1;
    v2 = P3 - P1;
    normal = cross(v1, v2);
    normal = normal / norm(normal);

    K = [0, -normal(3), normal(2);
         normal(3), 0, -normal(1);
         -normal(2), normal(1), 0];

    R = eye(3) + sin(theta)*K + (1 - cos(theta))*(K*K);
    vec_rot = (R * vec_orig')';
end
