include("processData.jl")
include("plotUtils.jl")

function createGraphs(test_name, num_runs, out_loc)
    println(out_loc)
    test_stats = getTestStats(test_name, num_runs)
    gen_times = procTimes(test_stats)
    cumulative_times = getTotalTimes(gen_times)
    test_gen_scores = getTopScores(test_stats)
    time_stats = getTimeStats(gen_times)
    fit_stats = getFitnessStats(test_stats)

    scatterTime(gen_times, time_stats, out_loc)
    outlierTime(gen_times, time_stats; α=0.1, bandwidth=1.5, out_loc)
    linearTime(cumulative_times, out_loc)
    scatterScores(test_gen_scores, out_loc)
    lineScores(test_gen_scores, out_loc)
end
