function n = plane_normal(P1, P2, P3)
% Calculate the normalized normal vector to the plane defined by points P1, P2, P3
    v1 = P2 - P1;
    v2 = P3 - P1;
    n = cross(v1, v2);
    n = n / norm(n);
end
