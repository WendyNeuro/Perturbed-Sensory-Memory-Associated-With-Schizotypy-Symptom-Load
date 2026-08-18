% W E N D Y  A.  T O R R E N S
% 1 0 / 1 6 / 2 0 2 5
% R E - S U B M I S S I O N  # 2

% Plotting both ERPs togther

eeglab

path1 = '/Path/';

% - T O P O - P L O T S - - - - - - - - - - - - - - - - - - - - - - - - - -

close all
% Get times
times = ERP.times;  % in ms

% Define time windows
win1 = [80 170];
win2 = [80 170];
win3 = [150 250];

% Convert time windows to indices
[~, ix1] = min(abs(times - win1(1)));
[~, ix2] = min(abs(times - win1(2)));
[~, jx1] = min(abs(times - win2(1)));
[~, jx2] = min(abs(times - win2(2)));
[~, kx1] = min(abs(times - win3(1)));
[~, kx2] = min(abs(times - win3(2)));

% Average the data in those time windows (channels x timepoints x bins)
data1 = mean(ERP.bindata(:, ix1:ix2, 1), 2);  % 1st bin
data2 = mean(ERP.bindata(:, jx1:jx2, 2), 2);  % 2nd bin
data3 = mean(ERP.bindata(:, kx1:kx2, 4), 2);  % 4th bin


figure('Position', [100 100 1600 500]);  % Large wide figure

% Format
Font_Size = 20;
FontName = 'Calibri';  % Set font here

% 1st scalp map — Standard N100
subplot(1,3,1);
topoplot(data1, ERP.chanlocs, ...
    'maplimits', [-1.0 1.0], ...
    'electrodes', 'on', ...
    'emarker2', {[], '.', 'k', 15, 1}, ...
    'plotrad', 0.6);
title('Standard N100 (80–170 ms)', 'FontSize', Font_Size, 'FontName', FontName);
cbar('vert', 0, [-1.0 1.0]);
set(gca, 'FontSize', Font_Size, 'FontName', FontName);

% 2nd scalp map — Deviant N100
subplot(1,3,2);
topoplot(data2, ERP.chanlocs, ...
    'maplimits', [-1.5 1.5], ...
    'electrodes', 'on', ...
    'emarker2', {[], '.', 'k', 15, 1}, ...
    'plotrad', 0.6);
title('Deviant N100 (80–170 ms)', 'FontSize', Font_Size, 'FontName', FontName);
cbar('vert', 0, [-1.5 1.5]);
set(gca, 'FontSize', Font_Size, 'FontName', FontName);

% 3rd scalp map — MMN
subplot(1,3,3);
topoplot(data3, ERP.chanlocs, ...
    'maplimits', [-2.0 2.0], ...
    'electrodes', 'on', ...
    'emarker2', {[], '.', 'k', 15, 1}, ...
    'plotrad', 0.6);
title('MMN (150–210 ms)', 'FontSize', Font_Size, 'FontName', FontName);
cbar('vert', 0, [-2.0 2.0]);
set(gca, 'FontSize', Font_Size, 'FontName', FontName);

colormap('turbo');


% - P L O T S - F O R - O R I G I N A L - E R P s - - - - - - - - - - - - -

groups = {'High', 'Control'};

% Create electrode 41 (the average of Fz and Cz)

for j = 1:length(groups)

    filename = fullfile(path1, [groups{j} '_grand.erp']);

    [ERP, ~] = pop_loaderp('filename', filename);

    ERP = pop_erpchanoperator( ERP, {  'ch41=ch31+ch32/2'} , 'ErrorMsg', 'popup', 'KeepLocations',  1, 'Warning', 'on' );

    ERP = pop_savemyerp(ERP, ...
        'erpname', [groups{j} '_grand_filtered'], ...
        'filename', [groups{j} '_grand_filtered.erp'], ...
        'filepath', path1, ...
        'Warning', 'off');
end

%close all

groups = {'High', 'Control'};

% Average of Fz and Cz

colors = {'k', [0.6 0.6 0.6],};
lineStyles = {'-', '-'};  % -- makes dashed

bins = {1, 'standard'; 2, 'deviant'; 4, 'MMN'};
channel = 41;

for i = 1:size(bins, 1)
    binNum = bins{i, 1};
    figure; hold on;
    title(['ERP for Average of Fz and Cz - ' bins{i, 2}], 'FontSize', 20);

    for j = 1:length(groups)
        filename = fullfile(path1, [groups{j} '_grand.erp']);
        
        [ERP, ~] = pop_loaderp('filename', filename);

        data = ERP.bindata(channel, :, binNum);
        times = ERP.times;

        % Plot ERP waveform
        plot(times, data, 'Color', colors{j}, 'LineStyle', lineStyles{j}, 'LineWidth', 2);
    end

    % Solid lines at 0
    yline(0, 'k-', 'LineWidth', 1); % 0 µV line
    xline(0, 'k-', 'LineWidth', 1); % 0 ms line

    % Our epoch
    xlim([-100 350]);

    if binNum == 1 || binNum == 2
        ylim([-6 4]);  % We want these to have the same ylim
    else binNum == 4
        ylim([-6 4]);
    end

    % Highlight latencies for bin 1 (80 ms to 170 ms)
    if binNum == 1
        % highlightIdx = times >= 80 & times <= 170;
        highlightIdx = times >= 80 & times <= 170;
        xHighlight = times(highlightIdx);
        yLimits = ylim;


        yHighlightTop = repmat(yLimits(2), size(xHighlight));  % Top limit (max)
        yHighlightBottom = repmat(yLimits(1), size(xHighlight));  % Bottom limit (min)

        % Fill the highlighted region
        fill([xHighlight, fliplr(xHighlight)], [yHighlightBottom, fliplr(yHighlightTop)], ...
            'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end

    % Highlight latencies for bin 2 (80 ms to 170 ms)
    if binNum == 2
        highlightIdx = times >= 80 & times <= 170;
        xHighlight = times(highlightIdx);
        yLimits = ylim;
        yHighlightTop = repmat(yLimits(2), size(xHighlight));
        yHighlightBottom = repmat(yLimits(1), size(xHighlight));

        % Fill the highlighted region
        fill([xHighlight, fliplr(xHighlight)], [yHighlightBottom, fliplr(yHighlightTop)], ...
            'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end

    % Highlight latencies for bin 4 (150 ms to 250 ms)
    if binNum == 4
        highlightIdx = times >= 150 & times <= 250;
        xHighlight = times(highlightIdx);
        yLimits = ylim;

        yHighlightTop = repmat(yLimits(2), size(xHighlight));
        yHighlightBottom = repmat(yLimits(1), size(xHighlight));

        fill([xHighlight, fliplr(xHighlight)], [yHighlightBottom, fliplr(yHighlightTop)], ...
            'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end

    xlabel('Time (ms)', 'FontSize', 25, 'FontName', 'Calibri');
    ylabel('Amplitude (µV)', 'FontSize', 25, 'FontName', 'Calibri');

    set(gca, 'FontSize', 25, 'FontName', 'Calibri');

    legend(groups, 'Location', 'best', 'FontSize', 25, 'FontName', 'Calibri');
    box on;
end

