using Plots
plotlyjs()

using Distributed
addprocs(Base.Sys.CPU_THREADS)

@everywhere begin
    include("src/firstfit.jl")
    include("src/fitness.jl")
end

args = Base.Sys.ARGS
include("src/genetic.jl")
include("src/ScheduleGA.jl")
include("src/Plotting/plotUtils.jl")
include("src/Viz/drawFuncs.jl")
include("src/Viz/viewSchedule.jl")

popSize = parse(Int64, args[1])
numGens = parse(Int64, args[2])
num_loops = parse(Int64, args[3])
dir_name = args[4]

runLoop("Input/Loose100Jobs.json", popSize, numGens, 50, num_loops, dir_name)
