using Plots
plotlyjs()

using Distributed
addprocs(Base.Sys.CPU_THREADS - 5)

@everywhere begin
    include("src/firstfit.jl")
    include("src/fitness.jl")
end

include("src/genetic.jl")
include("src/ScheduleGA.jl")
include("src/Plotting/plotUtils.jl")
include("src/Viz/drawFuncs.jl")
include("src/Viz/viewSchedule.jl")

popSize = 20000
numGens = 200
num_loops = 1
dir_name = "Accumulate_Test_MULT6"

@timev runLoop("Input/Loose100Jobs.json", popSize, numGens, 50, num_loops, dir_name, make_graphs=false, run_gams=false)
