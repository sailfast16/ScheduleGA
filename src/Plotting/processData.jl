using JLD
using Statistics

# Load all the Stats from a Run into Julia from a .jld file
function getRunStats(test_name, run_num)
    stats = load("Output/$(test_name)/run_$(run_num)/stats.jld")
    return stats["scores"], stats["lanes"], stats["times"]
end

# Get all runs
function getTestStats(test_name, num_runs)
    test_stats = []
    for i = 1:num_runs
        push!(test_stats, getRunStats(test_name, i))
    end
    return test_stats
end

# Seperate time values from the test_stats object
function procTimes(test_stats)
    gen_times = []
    for i = 1:length(test_stats)
        push!(gen_times, test_stats[i][3])
    end
    return gen_times
end

# Calculate ellapsed time
function getTotalTimes(gen_times)
    cum_run_times = []
    for run in gen_times
        cum_times = [0,run[1]]
        for i = 3:length(run)
            push!(cum_times, cum_times[i-1]+run[i])
        end
        push!(cum_run_times, cum_times)
    end
    return cum_run_times
end

# Calculate Avg and Std of all the run time data
function getTimeStats(gen_times)
    avg_gen_times = []
    std_gen_times = []
    for i = 1:length(gen_times[1])
        temp_times = []
        for j = 1:length(gen_times)
            push!(temp_times, gen_times[j][i])
        end
        push!(avg_gen_times, mean(temp_times))
        push!(std_gen_times, std(temp_times))
    end
    return avg_gen_times, std_gen_times
end

# Calculate Avg and Std of all the run fitness data
function getFitnessStats(test_stats)
    avg_gen_fits = []
    std_gen_fits = []

    all_fits = []
    for i = 1:length(test_stats)
        push!(all_fits, test_stats[i][1])
    end
    all_fits = vcat(all_fits...)

    for i = 1:size(all_fits,2)
        push!(avg_gen_fits, mean(all_fits[:,i]))
        push!(std_gen_fits, std(all_fits[:,i]))
    end

    return avg_gen_fits, std_gen_fits
end


# Create an array of all the top scores from each generation
# from each individual run
function getTopScores(test_stats)
    test_gen_scores = []
    for i = 1:length(test_stats)
        push!(test_gen_scores, test_stats[i][1][1,:])
    end
    return test_gen_scores
end

# Duh
function exponentialSmooth(y::Array{Any,1}, α)
    F = zeros(length(y)+1)
    F[1] = y[1]

    for t = 1:length(F)-1
        F[t+1] = α*y[t] + (1-α)*F[t]
    end
    return F
end

# Seperate the tuple of x and y values (required for graphing)
function sepXY(split_data)
    split_x_gens = []
    split_y_gens = []
    for gen in split_data
        gen_xs = []
        gen_ys = []
        for i = 1:length(gen)
            push!(gen_xs, gen[i][1])
            push!(gen_ys, gen[i][2])
        end
        push!(split_x_gens, gen_xs)
        push!(split_y_gens, gen_ys)
    end
    return vcat(split_x_gens...), vcat(split_y_gens...)
end

# Split the time data to better vizualize where the program
# taking a longer time to run
function seperateTimeData(time_stats, gen_times, α, bandwidth)
    smooth_avg = exponentialSmooth(time_stats[1], α)
    smooth_std = exponentialSmooth(time_stats[2], α)

    all_hi_vals = []
    all_avg_vals = []

    up_bound = smooth_avg + bandwidth*smooth_std
    lo_bound = smooth_avg - bandwidth*smooth_std

    for run in gen_times
        hi_vals = []
        avg_vals = []

        for i = 1:length(run)
            if run[i] > up_bound[i]
                push!(hi_vals, (i,run[i]))
            else
                push!(avg_vals, (i, run[i]))
            end
        end
        push!(all_hi_vals, hi_vals)
        push!(all_avg_vals, avg_vals)
    end

    hi_out = sepXY(all_hi_vals)
    avg_out = sepXY(all_avg_vals)

    return hi_out, avg_out
end
