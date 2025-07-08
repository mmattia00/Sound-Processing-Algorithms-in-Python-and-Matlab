function azimuth_ang = extract_azimuth_angle(v)
% Extract azimuthal angle (in radians) of vector v projected onto XY plane

    vx = v(1);
    vy = v(2);
    azimuth_ang = atan2(vy, vx);
end
