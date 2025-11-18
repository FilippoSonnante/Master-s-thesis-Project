%% ============================================================
%  CPU and MEMORY usage of the Open5Gs AMF during Fuzzing activities
%  In this case the first file is related to wrong values in NGAP
%  packets while the second one is related to completely wrong NGAP packets
% ============================================================

clear; clc; close all;

%% === Configuration ===

Fuzzing_wrong_values = 'amf_cpu_log.csv';
Fuzzing_wrong_packets = 'amf_cpu_log2.csv';

data1 = readtable(Fuzzing_wrong_values);
data2 = readtable(Fuzzing_wrong_packets);

%% === Data analysis ===

function summary_table = analyze_amf_data(data, file_label)

    copies_list = unique(data.copies);
    cpu_mean = zeros(size(copies_list));
    cpu_max  = zeros(size(copies_list));
    mem_mean = zeros(size(copies_list));
    mem_max  = zeros(size(copies_list));

    % === Confidence intervals (95%) ===
    cpu_ci_low = zeros(size(copies_list));
    cpu_ci_high = zeros(size(copies_list));
    mem_ci_low = zeros(size(copies_list));
    mem_ci_high = zeros(size(copies_list));

    % === Statistics for each number of copies sent ===
    for i = 1:length(copies_list)
        c = copies_list(i);
        subset = data(data.copies == c, :);

        % CPU
        cpu_mean(i) = mean(subset.cpu_percent);
        cpu_max(i)  = max(subset.cpu_percent);
        cpu_std = std(subset.cpu_percent);
        n = height(subset);
        sem = cpu_std / sqrt(n);
        ci = 1.96 * sem;
        cpu_ci_low(i)  = cpu_mean(i) - ci;
        cpu_ci_high(i) = cpu_mean(i) + ci;

        % MEM
        mem_mean(i) = mean(subset.mem_percent);
        mem_max(i)  = max(subset.mem_percent);
        mem_std = std(subset.mem_percent);
        sem = mem_std / sqrt(n);
        ci = 1.96 * sem;
        mem_ci_low(i)  = mem_mean(i) - ci;
        mem_ci_high(i) = mem_mean(i) + ci;
    end

    % === Summary table ===
    summary_table = table(copies_list, cpu_mean, cpu_max, mem_mean, mem_max, ...
        'VariableNames', {'Copies forwarded for each packet','CPU Usage Mean (%)','Max CPU Usage (%)','MEM Usage Mean (%)','Max Memory Usage (%)'});

    disp(['=== CPU and MEMORY USAGE for  ', file_label, ' ===']);
    disp(summary_table);

    %% === CPU Usage mean vs max ===
    fig_cpu = figure('Name',['CPU Usage - ', file_label],'NumberTitle','off');
    hold on;

    x = copies_list(:);
    y_low = cpu_ci_low(:);
    y_high = cpu_ci_high(:);

    fill([x; flipud(x)], [y_low; flipud(y_high)], ...
         [0.7 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName', '95% CI');

    plot(x, cpu_mean, '-o', 'LineWidth', 1.8, 'DisplayName', 'CPU Usage Mean');
    plot(x, cpu_max, '--s', 'LineWidth', 1.8, 'DisplayName', 'Max CPU Usage');

    xlabel('Forwarded Copies for each packet');
    ylabel('CPU Usage [%]');
    title(['AMF CPU USAGE - ', file_label]);
    legend('show', 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 12);
    hold off;

    % === Save CPU graph ===
    filename_cpu = sprintf('CPU_Usage_%s.png', strrep(file_label, ' ', '_'));
    exportgraphics(fig_cpu, filename_cpu, 'Resolution', 300);

    %% === Memory Usage mean vs max ===
    fig_mem = figure('Name',['Memory Usage - ', file_label],'NumberTitle','off');
    hold on;

    x = copies_list(:);
    y_low = mem_ci_low(:);
    y_high = mem_ci_high(:);

    fill([x; flipud(x)], [y_low; flipud(y_high)], ...
         [0.7 1 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName', '95% CI');

    plot(x, mem_mean, '-o', 'LineWidth', 1.8, 'DisplayName', 'MEM Usage Mean');
    plot(x, mem_max, '--s', 'LineWidth', 1.8, 'DisplayName', 'Max MEM Usage');

    xlabel('Forwarded Copies for each packet');
    ylabel('MEM Usage [%]');
    title(['AMF MEM USAGE - ', file_label]);
    legend('show', 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 12);
    hold off;

    % === Save Memory graph ===
    filename_mem = sprintf('Memory_Usage_%s.png', strrep(file_label, ' ', '_'));
    exportgraphics(fig_mem, filename_mem, 'Resolution', 300);

end

%% === Separate analysis for each file ===

summary1 = analyze_amf_data(data1, 'Wrong NGAP Field Values');
summary2 = analyze_amf_data(data2, 'Wrong NGAP Packets');

%% === Save summary tables ===

writetable(summary1, 'amf_summary_file1.xlsx');
writetable(summary2, 'amf_summary_file2.xlsx');
disp('Summary tables saved: amf_summary_file1.xlsx and amf_summary_file2.xlsx');
disp('Graphs saved as PNG files in the current folder.');