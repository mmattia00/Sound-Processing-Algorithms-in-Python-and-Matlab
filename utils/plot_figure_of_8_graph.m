function plot_figure_of_8_graph(theta0)
% Plot a figure-of-8 polar pattern rotated by azimuth angle theta0

    theta = linspace(0, 2*pi, 1000);
    n = 8;  % Sharpness parameter for lobes
    r = abs(cos(theta - theta0)).^n;

    mask = cos(theta - theta0) >= 0;  % Front lobe mask

    polarplot(theta(mask), r(mask), 'r', 'LineWidth', 2);
    hold on;
    polarplot(theta(~mask), r(~mask), 'b', 'LineWidth', 2);
    hold off;

    title('Polar representation');
end
