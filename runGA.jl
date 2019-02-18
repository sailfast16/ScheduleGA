using Distributed
addprocs(Base.Sys.CPU_THREADS)

@everywhere begin
    include("src/firstfit.jl")
    include("src/fitness.jl")
end

include("src/Viz/drawFuncs.jl")
include("src/Viz/viewSchedule.jl")
include("src/genetic.jl")
include("src/ScheduleGA.jl")

args = Base.Sys.ARGS

popSize = parse(Int64, args[1])
numGens = parse(Int64, args[2])
num_loops = parse(Int64, args[3])
dir_name = args[4]


runLoop("Input/MS-20-78jobs.json", popSize, numGens, 30, num_loops, dir_name)
