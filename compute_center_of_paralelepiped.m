function[center] = compute_center_of_paralelepiped(P1, P2)
% function that given the coordinates of the the opposite vertices of the
% entire parallelepiped (i.e. those furthest diagonally), return the
% coordinates of the center of the parallelepiped
center = (P1 + P2) / 2;
end