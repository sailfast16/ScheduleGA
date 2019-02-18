using JSON2
using JLD
using DelimitedFiles
using ProgressMeter

function evolve(jobs::Array{Job,1}, popSize::Int64, numGens::Int64, per_keep::Float64, per_swap::Float64, per_mut::Float64)
    numJobs = length(jobs)
    pop = makePop(popSize, jobs)
    gen_times = zeros(Float64, numGens)
    gen_scores = zeros(Int64, popSize, numGens)
    gen_lanes = zeros(Int64, popSize, numGens)
    total_time = 0
    prog = Progress(numGens; dt=0.1, desc="Evolution In Progress... ", color=:green, barlen=50)
    for i=1:numGens
        gen_scores[:,i] = pop.gen_scores
        gen_lanes[:,i] = pop.gen_lanes

        t0 = time_ns()
        breed!(pop, per_keep, per_swap, per_mut)
        ellapsed = (time_ns() - t0)/1e9
        total_time += ellapsed
        gen_times[i] = ellapsed
        ProgressMeter.next!(prog; showvalues=[(:Generation, "$i out of $numGens"),(:GenTime, ellapsed), (:Fitness, pop.gen_scores[1]),(:Lanes, pop.gen_lanes[1])])
        pop
    end
    print(pop.inds[1])
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
        dicttxt = String(Base.read(f))
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
end

function saveStats(stats, out_dir)
    gen_times = stats[1]
    gen_scores = stats[2]
    gen_lanes = stats[3]
    save(join([out_dir, "/stats.jld"]), "times", gen_times, "scores", gen_scores, "lanes", gen_lanes)
end

function makeSchedule(out_dir)
    out_path = join([out_dir,"/viz.png"])
    lanes, max_length = tasksToLanes(getSchedule(join([out_dir, "/schedule.json"])))
    drawSchedule(out_path, lanes, max_length)
end

function toGAMS(jobs, out_dir)
    ais = []
    bis = []
    pis = []

    for job in jobs
        push!(ais, job.least_start)
        push!(bis, job.max_end)
        push!(pis, job.length)
    end

    open(join([out_dir,"/gams_file.txt"]),"w") do f
        write(f, "aa(i) / \n")
        for i = 1:length(ais)
            write(f, "$i $(ais[i]), \n")
        end
        write(f, "/ \n \n")
        write(f, "b(i) / \n")
        for i = 1:length(bis)
            write(f, "$i $(bis[i]), \n")
        end
        write(f, "/ \n \n")
        write(f, "p(i) / \n")
        for i = 1:length(pis)
            write(f, "$i $(pis[i]), \n")
        end
        write(f, "/ \n")
    end
end


function runLoop(job_file::String, popSize::Int64, numGens::Int64, numJobs::Int64, numLoops::Int64, test_name::String)
    out_dir = join(["Output/",test_name])
    mkdir(out_dir)

    for i = 1:numLoops
        println("*********************************RUN NUMBER $(i) of $(numLoops)*********************************")
        run_dir = join([out_dir, "/run_$(i)"])
        mkdir(run_dir)
        jobs = shuffle(getJobs(job_file))[1:numJobs]
        pop, stats = evolve(jobs, popSize, numGens, .6, .2, .2)
        saveSchedule(pop, run_dir)
        saveStats(stats, run_dir)
        toGAMS(jobs, run_dir)
        makeSchedule(run_dir)
    end
end
