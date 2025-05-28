function draw_3D_representation(t_rotated, DOA, P1, P2, P3)
% Plot the 3D visualization including source DOA, rotated vectors, rotation plane, and coordinate axes

    axis equal;
    axis([-1.5 1.5 -1.5 1.5 -1.5 1.5]);
    hold on;

    % Plot source DOA vector as red point
    plot3(DOA(1), DOA(2), DOA(3), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

    % Plot rotated vector (red) and its opposite (blue)
    quiver3(0, 0, 0, t_rotated(1), t_rotated(2), t_rotated(3), 1, 'LineWidth', 2, 'Color', 'r');
    quiver3(0, 0, 0, -t_rotated(1), -t_rotated(2), -t_rotated(3), 1, 'LineWidth', 2, 'Color', 'b');

    % Draw rotation plane
    draw_plane(P1, P2, P3);

    % Draw coordinate axes in black
    line([-1.5 1.5], [0 0], [0 0], 'Color', 'k');
    line([0 0], [-1.5 1.5], [0 0], 'Color', 'k');
    line([0 0], [0 0], [-1.5 1.5], 'Color', 'k');

    % Set labels and title
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('3D representation');

    % Adjust view for better visualization
    view([0.2 -1 0.5]);
    grid on;
    hold off;
end
