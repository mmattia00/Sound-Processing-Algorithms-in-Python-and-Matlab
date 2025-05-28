function draw_plane(P1, P2, P3)
% Draw semi-transparent plane defined by points P1, P2, P3

    v1 = P2 - P1;
    v2 = P3 - P1;
    normal = cross(v1, v2);
    normal = normal / norm(normal);

    center = [0 0 0];
    v1 = v1 / norm(v1);
    v2 = cross(normal, v1);
    v2 = v2 / norm(v2);

    plane_size = 1.5;

    corners = [
        center + plane_size*( v1 + v2);
        center + plane_size*( v1 - v2);
        center + plane_size*(-v1 - v2);
        center + plane_size*(-v1 + v2);
    ];

    fill3(corners(:,1), corners(:,2), corners(:,3), [0.8 0.8 0.8], ...
        'FaceAlpha', 0.3, 'EdgeColor', 'none');
end
