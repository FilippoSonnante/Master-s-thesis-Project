%% ============================================================
%  Analysis of AMF memory usage with Memory Limit.
%  Each memory limit (80, 100, 250, 500) is expressed in MB
%  Each limit has 5 file that represent 5 different trials; when the AMF
%  exceeds the mem limit, the process is killed by oom.
% ============================================================

clear; clc; close all;

%% === Configuration ===
X_values = [80, 100, 250, 500];   % MemLimits in MB
Y_values = 1:5;                   % 5 files per limit

memory_column = 'mem_percent';
copies_column = 'copies';

%% === Summary table container ===
summaryTables = struct();

for X = X_values
    
    peakMatrix = [];   % 5 × Ncopies
    meanMatrix = [];   % 5 × Ncopies
    copiesRef  = [];   % reference copies list
    
    for Y = Y_values
        
        filename = sprintf('amf_cpu_log%dM_%d.csv', X, Y);
        
        if ~isfile(filename)
            fprintf('File not found: %s\n', filename);
            continue;
        end
        
        data = readtable(filename);
        
        copies_list = unique(data.(copies_column));
        copies_list = sort(copies_list);
        
        if isempty(copiesRef)
            copiesRef = copies_list;
        end
        
        % Preallocate
        means = zeros(size(copies_list));
        peaks = zeros(size(copies_list));
        
        % === Compute mean and peak grouped by copies ===
        for i = 1:length(copies_list)
            c = copies_list(i);
            subset = data(data.(copies_column) == c, :);
            mem_values = subset.(memory_column);
            
            means(i) = mean(mem_values);
            peaks(i) = max(mem_values);
        end
        
        % === Print table for this file ===
        summary_file = table(copies_list, means, peaks, ...
            'VariableNames', {'Copies', 'MeanMemoryPercent', 'PeakMemoryPercent'});
        
        fprintf('\n==============================================\n');
        fprintf(' RESULTS FOR FILE: %s\n', filename);
        fprintf('==============================================\n');
        disp(summary_file);
        
        % Store results
        meanMatrix = [meanMatrix; means(:)'];
        peakMatrix = [peakMatrix; peaks(:)'];
        
    end
    
    
    %% ============================================================
    %          PEAK FOR EACH MEM LIMIT
    %% ============================================================

    varNames = [{'File'}, cellstr("Copies_" + string(copiesRef)).'];
    fileIndex = (1:5)';    
    summaryTables.(sprintf('MemLimit_%d', X)) = ...
        array2table([fileIndex peakMatrix], 'VariableNames', varNames);

    fprintf('\n----------------------------------------------\n');
    fprintf(' CUMULATIVE TABLE FOR MEM LIMIT = %d MB\n', X);
    fprintf('----------------------------------------------\n');
    disp(summaryTables.(sprintf('MemLimit_%d', X)));
    
    
%% =======================================================
%                   GRAPH FOR EACH LIMIT
%% =======================================================

figGraph = figure('Name', sprintf('MemUsage with %dM Limit', X), 'NumberTitle','off');
hold on;

colors = lines(5);

% === Memory limit in percentage ===
if X == 80
    memLimitPercent = 2;   % approximated
else
    memLimitPercent = (X / 4096) * 100;
end

% === Plot mean and peak ===
for f = 1:5
    
    % Mean line
    plot(copiesRef, meanMatrix(f,:), 'LineWidth', 1.8, ...
        'Color', colors(f,:), ...
        'DisplayName', sprintf('File %d - Mean', f));
    
    % Peak points
    plot(copiesRef, peakMatrix(f,:), 'o', ...
        'Color', colors(f,:), ...
        'MarkerFaceColor', colors(f,:), ...
        'MarkerSize', 6, ...
        'DisplayName', sprintf('File %d - Peak', f));
    
    % Points above the limit
    exceed_idx = peakMatrix(f,:) > memLimitPercent;
    
    if any(exceed_idx)
        plot(copiesRef(exceed_idx), peakMatrix(f,exceed_idx),'rx', 'MarkerSize', 10, 'LineWidth', 2, 'HandleVisibility', 'off');
        
        for k = find(exceed_idx)
            text(copiesRef(k), peakMatrix(f,k), ...
                sprintf(' %.2f%%', peakMatrix(f,k)), ...
                'Color', 'r', 'FontSize', 10, ...
                'VerticalAlignment','bottom');
        end
    end
end

    % === Horizontal Limit Line (RED) ===
    yline(memLimitPercent, 'r--', 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Limit %.2f%% (%d MB)', memLimitPercent, X));
    text(copiesRef(end), memLimitPercent - (0.02 * memLimitPercent), ...
        sprintf('Limit %.2f%% (%d MB)', memLimitPercent, X), ...
        'Color', 'r', 'FontSize', 14, 'FontWeight','bold', ...
        'HorizontalAlignment','right', ...
        'VerticalAlignment','top');
    
    title(sprintf('MEM Usage - MemLimit %d MB', X));
    xlabel('Copies sent for each packet');
    ylabel('Memory Usage [%]');
    grid on;
    legend('show','Location','best');
    set(gca,'FontSize',12);
    hold off;
    
    % === SAVE GRAPH ===
    filename_mem = sprintf('Graph_MemLimit_%dMB.png', X);
    exportgraphics(figGraph, filename_mem, 'Resolution', 300);

    %% ============================================================
    %             TABLE FOR EACH MEMORY LIMIT
    %% ============================================================

    dataToShow = summaryTables.(sprintf('MemLimit_%d', X));
    dataMatrix = table2cell(dataToShow);

    figTable = figure('Name', sprintf('Cumulative Table %d MB', X), ...
                      'NumberTitle','off', ...
                      'Position',[200 200 900 300]);

    t = uitable(figTable, ...
        'Data', dataMatrix, ...
        'ColumnName', dataToShow.Properties.VariableNames, ...
        'Units','normalized', ...
        'Position',[0 0 1 1]);

    numericData = cell2mat(dataMatrix(:, 2:end));

    [rows, ~] = size(numericData);
    rowColors = zeros(rows,3);

    for i = 1:rows
        if any(numericData(i,:) > memLimitPercent)
            rowColors(i,:) = [1 0.6 0.6]; % red
        else
            rowColors(i,:) = [0.8 1 0.8]; % green
        end
    end

    t.BackgroundColor = rowColors;

    % === SAVE TABLE ===
    frame = getframe(figTable);
    imwrite(frame.cdata, sprintf('Table_MemLimit_%dMB.png', X));
    
end

fprintf('\n==== ALL TABLES AND GRAPHS GENERATED ====\n');

