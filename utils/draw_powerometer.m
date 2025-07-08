function draw_powerometer(power)
% Display power meter as a vertical bar with fixed scale

    bar(power, 'FaceColor', 'g');
    ylim([0 130]);
    title(sprintf('Power = %.2f', power));
    ylabel('Value');
    xticks([]);  % Remove x-axis labels
    grid on;
end
