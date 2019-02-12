using DelimitedFiles
using ProgressMeter

include("src/firstfit.jl")
include("src/fitness.jl")
include("src/genetic.jl")
include("src/Viz/drawFuncs.jl")
include("src/Viz/viewSchedule.jl")

function evolve(jobs::Array{Job,1}, popSize::Int64, numGens::Int64, per_keep::Float64, per_swap::Float64, per_mut::Float64)
    @everywhere begin
        include("src/firstfit.jl")
        include("src/fitness.jl")
        include("src/genetic.jl")
    end

    pop = makePop(popSize, jobs)
    gen_times = zeros(Float64, numGens)

    gen_scores = Array{Array{Int64,1},1}()
    gen_lanes = Array{Array{Int64,1},1}()
    total_time = 0
    prog = Progress(numGens; dt=0.1, desc="Evolution In Progress... ", color=:green, barlen=50)
    for i=1:numGens
        push!(gen_scores, pop.gen_scores)
        push!(gen_lanes, pop.gen_lanes)

        t0 = time_ns()
        breed!(pop, per_keep, per_swap, per_mut)
        ellapsed = (time_ns() - t0)/1e9
        total_time += ellapsed
        gen_times[i] = ellapsed
        ProgressMeter.next!(prog; showvalues=[(:Generation, "$i out of $numGens"),(:GenTime, ellapsed), (:Fitness, pop.gen_scores[1]),(:Lanes, pop.gen_lanes[1])])
        pop
    end
    pop, (gen_times, gen_scores, gen_lanes)
end

function getOptSchedule(pop::Population)
    jobQueue = jobsToQueue(pop.jobs, pop.inds[1][:])
    lane_lengths = maximum([x.max_end for x in pop.jobs])
    gen_score, num_lanes, schedule = getFittness(jobQueue, lane_lengths)
end

function getSchedule(filename)
    schedule_list = []
    open(filename, "r") do f
        global schedule
        dicttxt = String(read(f))
        schedule_list = JSON2.read(dicttxt)
    end
    schedule_list
end

function saveSchedule(pop::Population, out_dir)
    gen_score, num_lanes, new_schedule = getOptSchedule(pop)
    out_path = join([out_dir,"/schedule.json"])
    open(out_path, "w") do f
        JSON2.write(f,new_schedule)
    end
    writedlm( join([out_dir, "/inds.csv"]),  pop.inds, ',')
end

function saveStats(stats, out_dir)
    gen_times = stats[1]
    gen_scores = stats[2]
    gen_lanes = stats[3]
    writedlm( join([out_dir, "/times.csv"]),  gen_times, ',')
    writedlm( join([out_dir, "/scores.csv"]),  gen_scores, ',')
    writedlm( join([out_dir, "/lanes.csv"]),  gen_lanes, ',')
end

function makeSchedule(out_dir)
    out_path = join([out_dir,"/viz.png"])
    lanes, max_length = tasksToLanes(getSchedule(join([out_dir, "/schedule.json"])))
    drawSchedule(out_path, lanes, max_length)
end

function runLoop(job_file::String, popSize::Int64, numGens::Int64, numJobs::Int64, numLoops::Int64, test_name::String)
    out_dir = join(["Output/",test_name])
    mkdir(out_dir)

    for i = 1:numLoops
        println("*********************************RUN NUMBER $(i) of $(numLoops)*********************************")
        run_dir = join([out_dir, "/run_$(i)"])
        mkdir(run_dir)
        jobs = shuffle(getJobs(job_file))[1:numJobs]
        pop, stats = evolve(jobs, popSize, numGens, .2, .5, .2)
        saveSchedule(pop, run_dir)
        saveStats(stats, run_dir)
        makeSchedule(run_dir)
    end
end

popSize = 10000
numGens = 300
runLoop("Input/MS-20-78jobs.json", popSize, numGens, 78, 100, "10000PS-300Gens-{MS-20-78jobs}")
