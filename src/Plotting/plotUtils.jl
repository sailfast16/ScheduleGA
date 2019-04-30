include("processData.jl")

# Draws the band to show the outliers on the time scatter plot
function addStatsRibbon(time_stats, α, bandwidth)
    clibrary(:colorbrewer)
    smooth_avg = exponentialSmooth(time_stats[1], α)
    smooth_std = exponentialSmooth(time_stats[2], α)

    stats_ribbon = plot!(smooth_avg;
        ribbon = (bandwidth*smooth_std, bandwidth*smooth_std),
        lw=3,
        la=1,
        xlims=(-10,560),
        lab = "Avg. Time (Smoothed)",
        hover=smooth_avg,
        color=:orange)

    return stats_ribbon
end

# draw a scatter plot of all generation times for all runs
function scatterTime(gen_times, time_stats, loc)
    clibrary(:colorbrewer)
    time_plot_scatter = scatter(gen_times[1];
        xlabel="Generation",
        ylabel="Time [Seconds]",
        title="Time per Generation",
        lab="Run 1",
        xlims=(-10,560),
        palette=:RdYlBu,
        hover=gen_times[1])

    for i = 2:length(gen_times)
        scatter!(gen_times[i];
            lab="Run $i",
            palette=:RdYlBu,
            hover=gen_times[i])
    end

    addStatsRibbon(time_stats, .1, 1.5)
    savefig(time_plot_scatter, "$(loc)/scatter_time.svg")
    return time_plot_scatter
end

# same graph as above, but outliers are colored red, the rest are blue
function outlierTime(gen_times, time_stats, loc; α=0.1, bandwidth=1.5)
    clibrary(:colorbrewer)
    hi_gen_times, avg_gen_times = seperateTimeData(time_stats, gen_times, α, bandwidth)

    outlier_times = scatter(hi_gen_times[1], hi_gen_times[2];
        xlabel="Generation",
        ylabel="Average Computation Time",
        title="Computation Times Outliers",
        mc=:red,
        lab="High Vals.",
        hover=hi_gen_times[2])

    scatter!(avg_gen_times[1], avg_gen_times[2], mc=:blue, lab="Avg. Vals.", hover=avg_gen_times[2])

    addStatsRibbon(time_stats, α, bandwidth)

    savefig(outlier_times, "$(loc)/outlier_time.svg")
    return outlier_times
end


# Draw the cumulative time graph to show the program runs in linear time
function linearTime(cumulative_times, loc)
    time_plot = plot(cumulative_times[1];
        xlabel="Generation",
        ylabel="Time [Seconds]",
        title="Generation Run Time",
        lab="run_1",
        hover=cumulative_times[1])
    for i = 2:length(cumulative_times)
        plot!(cumulative_times[i]; lab="run_$(i)", hover=cumulative_times[i])
    end

    savefig(time_plot, "$(loc)/linear_time.svg")
    time_plot
end


# draw a scatter plot of all scores from all runs
function scatterScores(gen_scores, loc)
    clibrary(:colorbrewer)
    score_plot_scatter = scatter(gen_scores[1];
        xlabel="Generation",
        ylabel="Min. Generation Score",
        title="Generation Scores",
        lab="Run 1",
        xlims=(-10,560),
        palette=:RdYlBu,
        hover=gen_scores[1])

    for i = 2:length(gen_scores)
        scatter!(gen_scores[i];
            lab="Run $i",
            palette=:RdYlBu,
            hover=gen_scores[i])
    end

    savefig(score_plot_scatter, "$(loc)/scatter_score.svg")

    return score_plot_scatter
end


# Draw a line graph of all scores of all runs
function lineScores(gen_scores, loc)
    clibrary(:colorbrewer)
    score_plot_line = plot(gen_scores[1];
        xlabel="Generation",
        ylabel="Min. Generation Score",
        title="Generation Scores",
        lab="Run 1",
        xlims=(-10,560),
        lw=3,
        la=.5,
        palette=:RdYlBu,
        hover=gen_scores[1])

    for i = 2:length(gen_scores)
        plot!(gen_scores[i];
            lab="Run $i",
            lw=3,
            la=.5,
            palette=:RdYlBu,
            hover=gen_scores[i])
    end

    savefig(score_plot_line, "$(loc)/line_score.svg")

    return score_plot_line
end


function createGraphs(test_name, num_runs, out_loc)
    println(out_loc)
    test_stats = getTestStats(test_name, num_runs)
    gen_times = procTimes(test_stats)
    cumulative_times = getTotalTimes(gen_times)
    test_gen_scores = getTopScores(test_stats)
    time_stats = getTimeStats(gen_times)
    fit_stats = getFitnessStats(test_stats)

    scatterTime(gen_times, time_stats, out_loc)
    outlierTime(gen_times, time_stats, out_loc; α=0.1, bandwidth=1.5)
    linearTime(cumulative_times, out_loc)
    scatterScores(test_gen_scores, out_loc)
    lineScores(test_gen_scores, out_loc)
end
