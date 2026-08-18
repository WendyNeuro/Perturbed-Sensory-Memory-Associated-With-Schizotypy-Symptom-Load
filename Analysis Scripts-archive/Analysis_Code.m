% New analyses for second-round of revission to Schizophrenia Research
% Sep 29, 2025,
% Wendy A. Torrens

clc
clear

eeglab

path1 = '/Path/';

elec_locs = '/Path/Schizotypy32chan.elc';
bins_file = '/Path/MMN_BioSemiCodes.txt';

Ss_all = {'1CR' '3SF' '4LT' '5EP' '6LG' '10BP' '31' '32' '34' '35' '36' '37' '38' '40' '41'...
     '42' '43' '44' '45' '46' '60' '61' '62' '63' '65' '72' '73' '74' '75' '77' '78'...
     '80' '81' '83' '84' '85' '86' '7KL' '13' '15' '18' '19' '21' '24' '26' '30' '52'...
     '53' '54' '57' '59' '64' '68' '76' '79' '89' '90' '91' '92' '93' '94' '95' '96' '97' '98' '99'};


% --------------------------- Preprocess data ----------------------------

for j=1:length(Ss_all)
    EEG = pop_biosig([path1 Ss_all{j} '_MMN.bdf'], 'ref',[33 35] ,'refoptions',{'keepref' 'on'});
    
    EEG = pop_select( EEG, 'nochannel',{'Erg1'});
    EEG = pop_saveset( EEG, 'filename',[Ss_all{j} 'fixed_MMN.set'],'filepath',path1);

    EEG = pop_chanedit(EEG, 'lookup', elec_locs,'nosedir','+Y');
    if strcmp(Ss_all{j},'57''59''64')
        EEG.data(1,:) = EEG.data(34,:)
    end
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',50);
    EEG = pop_saveset( EEG, 'filename',[Ss_all{j} '_MMN_filtered.set'],'filepath',path1);
    pop_eegplot( EEG, 1, 1, 1);
    saveas(gcf, [Ss_all{j} '_MMN_plot','.fig']); % save plot
    
    close all
end

%% -------------------- Run ICA & Removed components ---------------------

for j=1:length(Ss_all)
    EEG = pop_loadset('filename',[Ss_all{j} '_filtered.set'],'filepath',path1);

    EEG = pop_runica(EEG,'icatype','runica','extended',1,'interrupt','on');
    EEG = pop_saveset( EEG, 'filename',[Ss_all{j} '_MMN_ICA.set'],'filepath',path1);
end

% ICA Removal
for j = 1:length(Ss_all)
    s = Ss_all{j};

        %load ICA
        EEG = pop_loadset([s,'_MMN_ICA.set'], path1);

        %plot for visual inspection
        pop_eegplot(EEG, 0,1,1);

        %make noise to alert
        t = 0:.0001:.100; x = sin(1*pi*1000.*(t));
        sound(x,10000);

        %hard code which components to remove
        removeComp = input('Enter components to remove []:');
        EEG = pop_subcomp(EEG,removeComp, 0);

        %close plot 
        close('Scroll component activities -- eegplot() -- BDF file')

        %save pruned data
        pop_saveset(EEG,[s,'_pruned'], path1)

        %save removal info
        data_name = sprintf('%s%s_data.mat', path1,s);
        ica_remove = length(removeComp);
        ica_comp = removeComp;
        save(data_name,'ica_remove','ica_comp');

end

%% ----------------- Processing and artifact rejection -------------------

for j=1:length(Ss_all)
    EEG = pop_loadset('filename',[Ss_all{j} '_pruned.set'],'filepath',path1);
    for n = 1:length(EEG.event)
        EEG.event(n).latency = EEG.event(n).latency+(200/2);
    end
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric',...
        { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist', [path1 Ss_all{j} '.txt'] );

    EEG  = pop_binlister( EEG , 'BDF', bins_file, 'ExportEL', [path1 Ss_all{j} '_conds.txt'],...
        'IndexEL',  1, 'SendEL2', 'EEG&Text', 'Voutput', 'EEG' );
    EEG = pop_saveset( EEG, 'filename',[Ss_all{j} '_MMN_bins.set'],'filepath',path1);

    EEG = pop_epochbin( EEG , [-100.0  330.0],  'pre');% changed from -50 to -100
    EEG = pop_saveset( EEG, 'filename',[Ss_all{j} '_MMN_epoched.set'],'filepath',path1);


    % Run artifact detection
    EEG = pop_artextval(EEG, 'Channel', 1:32, ...
        'Flag', 1, ...
        'Threshold', [-100 100], ...
        'Twindow', [-100.8 328.1]);

    % Summarize
    [EEG, tprej, acce, rej, histoflags] = pop_summary_AR_eeg_detection(EEG, 'none');
    EEG = pop_summary_AR_eeg_detection(EEG, [path1 Ss_all{j} '_MMN_AR.txt']); 
    EEG = pop_saveset(EEG, 'filename', [Ss_all{j} '_MMN_AR.set'], 'filepath', path1); 

end

% Get AR Data

s = {};
percentAcceptedList = [];
percentRejectedList = [];


for j = 1:length(Ss_all)
    txtFile = fullfile(path1, [Ss_all{j} '_MMN_AR.txt']);
    
    if exist(txtFile, 'file')
        fid = fopen(txtFile);
        lines = textscan(fid, '%s', 'Delimiter', '\n');
        fclose(fid);
        lines = lines{1};
        
        % Find the 'Total' line
        for i = 1:length(lines)
            if contains(lines{i}, 'Total')
                % Extract accepted percentage
                tokens = regexp(lines{i}, 'Total\s+\d+\(\s*(\d+\.\d+)\)\s+\d+\(\s*(\d+\.\d+)\)', 'tokens');
                if ~isempty(tokens)
                    percentAccepted = str2double(tokens{1}{1});
                    percentRejected = str2double(tokens{1}{2});
                    
                    % Store results
                    s{end+1} = Ss_all{j};
                    percentAcceptedList(end+1) = percentAccepted;
                    percentRejectedList(end+1) = percentRejected;
                end
                break;
            end
        end
    else
        warning('File not found: %s', txtFile);
    end
end

% Save to CSV
T = table(s', percentAcceptedList', percentRejectedList', ...
    'VariableNames', {'Subject', 'PercentAccepted', 'PercentRejected'});

AR_file = fullfile(path1, 'MMN_AR_Summary.csv'); 
writetable(T, AR_file);

fprintf('Saved summary to %s\n', AR_file);

%% ---------------- Create Filtered and unfiltered ERPs ------------------

% Subjects have been removed if epochs kept <75%
% Ss is with removed files.
Ss = {'1CR' '3SF' '4LT' '5EP' '6LG' '10BP' '31' '32' '34' '35' '36' '37' '38' '40' '41'...
     '43' '44' '45' '46' '60' '61' '63' '65' '72' '73' '74' '75' '77' '78'...
     '80' '84' '85' '7KL' '13' '15' '18' '19' '21' '24' '26' '30' '52'...
     '53' '54' '57' '59' '68' '76' '79' '90' '91' '93' '94' '95' '96' '98' '99'};

% Saving unfiltered vs. filtered

for j=1:length(Ss)
    EEG = pop_loadset('filename',[Ss{j} '_MMN_AR.set'],'filepath',path1);
  
    EEG = pop_eegfiltnew(EEG, [], 20); 

    ERP = pop_averager( EEG , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on');
    ERP = pop_binoperator( ERP, { 'bin4=b2-b1'});
    % ERP = pop_erplindetrend( ERP, 'all' ); % for supplemental materials
    ERP = pop_savemyerp(ERP, 'erpname', [Ss{j}], 'filename', [Ss{j} '_filtered.erp'],...
         'filepath', path1, 'Warning', 'off');
    % ERP = pop_ploterps( ERP, [ 1:4],  1:32 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08],...
    %     'BinNum', 'on', 'Blc', 'pre', 'Box', [ 6 6], 'ChLabel', 'on', 'FontSizeChan',...
    %     10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec',...
    %     {'k-' , 'r-' }, 'LineWidth',  1, 'Maximize','on', 'Position', ...
    %     [ 93.7143 15.0714 106.857 31.9286], 'Style', 'Classic', 'Tag', 'ERP_figure', ...
    %     'Transparency',  0, 'xscale',[ -100.0 330.0   -50 0:100:500 ], 'YDir', 'normal' );
    % 
    % saveas(gcf, [Ss{j} '_ERP_plot','.fig']); 
    % close all
end

% ----------- Average ERPs for each group and all participants -----------

groups = {'High', 'Control', 'Both'};
groups = {'High', 'Control'};

for j = 1:length(groups)
    listfile = [path1 groups{j} '_list.txt'];

    % Grand average
    ERP = pop_gaverager(listfile, 'ExcludeNullBin', 'on');

    % Save 
    ERP = pop_savemyerp(ERP, ...
        'erpname', [groups{j} '_grand'], ...
        'filename', [groups{j} '_grand.erp'], ...
        'filepath', path1, ...
        'Warning', 'off');
end
  
%% --------------------------- Data Extraction ---------------------------

clear
clc


% Individual peak selection 
% =========================================================
% Peak Extraction Script for ERP Data (Save as .fig)
% =========================================================

% Subjects
Ss = {'1CR','3SF','4LT','5EP','6LG','10BP','31','32','34','35','36','37','38','40','41', ...
      '43','44','45','46','60','61','63','65','72','73','74','75','77','78', ...
      '80','84','85','7KL','13','15','18','19','21','24','26','30','52', ...
      '53','54','57','59','68','76','79','90','91','93','94','95','96','98','99'};

% Electrodes & Conditions
electrodes = [31 32];
conds = {
    'Standard', 1;
    'Deviant', 2;
};
latWindow = [80 170];  % N100 window in ms based on prior lit

% Initialize results table
summary = table('Size',[0 5], ...
    'VariableTypes',{'string','string','double','double','double'}, ...
    'VariableNames',{'Subject','Condition','Electrode','Latency','Amplitude'});

% Loop through subjects
for s = 1:length(Ss)
    subj = Ss{s};
    fprintf('Processing subject: %s\n', subj);

    % Load ERP file
    erpfile = fullfile(path1, [subj '.erp']);
    if ~exist(erpfile, 'file')
        warning('ERP file not found: %s', erpfile);
        continue;
    end

    [ERP, ~] = pop_loaderp('filename', [subj '.erp'], 'filepath', path1);

    times = ERP.times;

    % Loop through conditions
    for i = 1:size(conds,1)
        prefix = conds{i,1};
        binNum = conds{i,2};

        % Loop through electrodes
        for e = 1:length(electrodes)
            elec = electrodes(e);
            data = squeeze(ERP.bindata(elec,:,binNum));

            % Within Standardized time window
            mask = times >= latWindow(1) & times <= latWindow(2);
            dataWin = data(mask);
            timeWin = times(mask);

            % Start with NaNs
            N1 = [NaN NaN];  % [latency amplitude]

            if ~isempty(dataWin)
                [minVal, idx] = min(dataWin);
                Time = timeWin(idx);
                N1 = [Time minVal];
            end

            % Place into summary table
            summary = [summary; {subj, prefix, elec, N1(1), N1(2)}];

            % QC plot
            fig = figure;
            plot(times, data, 'k', 'LineWidth',2); hold on;
            yline(0,'k-'); xline(0,'k-');
            xlim([-100 380]);
            ylim([-10 5]);
            title(sprintf('%s - %s - Elec %d', subj, prefix, elec));
            xlabel('Time (ms)'); ylabel('Amplitude (µV)');

            % Mark N1
            if ~isnan(N1(1))
                plot(N1(1), N1(2), 'bo', 'MarkerSize',8, 'LineWidth',2);
                text(N1(1), N1(2)-0.4, 'N1', 'Color','b','FontSize',10,'HorizontalAlignment','center');
            end

            % Save figure for quality control
            saveas(fig, fullfile(path1, sprintf('%s_%s_E%d_QC.fig', subj, prefix, elec)));
            close(fig);
        end
    end
end
close all
% Save results table
writetable(summary, fullfile(path1,'N1_results.csv'));

fprintf('All done! Results saved to N1_results.csv\n');

%% -------- MMN

clear
clc

% Electrodes & Conditions
electrodes = [31 32];
conds = {
    'MMN',4;
};

latWindow = [150 250];  % MMN window in ms

% Initialize results table
summary = table('Size',[0 5], ...
    'VariableTypes',{'string','string','double','double','double'}, ...
    'VariableNames',{'Subject','Condition','Electrode','Latency','Amplitude'});

% Loop through subjects
for s = 1:length(Ss)
    subj = Ss{s};
    fprintf('Processing subject: %s\n', subj);

    % Load ERP file
    erpfile = fullfile(path1, [subj '.erp']);
    if ~exist(erpfile, 'file')
        warning('ERP file not found: %s', erpfile);
        continue;
    end

    [ERP, ~] = pop_loaderp('filename', [subj '.erp'], 'filepath', path1);

    times = ERP.times;

    % Loop through conditions
    for i = 1:size(conds,1)
        prefix = conds{i,1};
        binNum = conds{i,2};

        % Loop through electrodes
        for e = 1:length(electrodes)
            elec = electrodes(e);
            data = squeeze(ERP.bindata(elec,:,binNum));

            % Within Standardized time window
            mask = times >= latWindow(1) & times <= latWindow(2);
            dataWin = data(mask);
            timeWin = times(mask);

            % Start with NaNs
            MMN = [NaN NaN];  % [latency amplitude]

            if ~isempty(dataWin)
                [minVal, idx] = min(dataWin);
                Time = timeWin(idx);
                MMN = [Time minVal];
            end

            % Place into summary table
            summary = [summary; {subj, prefix, elec, MMN(1), MMN(2)}];

            % QC plot
            fig = figure;
            plot(times, data, 'k', 'LineWidth',2); hold on;
            yline(0,'k-'); xline(0,'k-');
            xlim([-100 380]);
            ylim([-14 2]);
            title(sprintf('%s - %s - Elec %d', subj, prefix, elec));
            xlabel('Time (ms)'); ylabel('Amplitude (µV)');

            % Mark MMN
            if ~isnan(MMN(1))
                plot(MMN(1), MMN(2), 'bo', 'MarkerSize',8, 'LineWidth',2);
                text(MMN(1), MMN(2)-0.4, 'MMN', 'Color','b','FontSize',10,'HorizontalAlignment','center');
            end

            % Save QC figure
            saveas(fig, fullfile(path1, sprintf('%s_%s_E%d_QC.fig', subj, prefix, elec)));
            close(fig);
        end
    end
end
close all
% Save results table
writetable(summary, fullfile(path1,'MMN_results.csv'));
fprintf('Done! Saved to MMN_results.csv\n');

