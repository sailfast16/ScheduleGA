using JSON2

mutable struct Job
    least_start::Int
    max_end::Int
    length::Int
    name::Int
end

function makeJobList(numjobs, min_len, max_len, loose, lane_lengths, out_path)
    jobs = []
    count = 1
    while length(jobs) < numjobs
        temp_len = rand(min_len:max_len)
        temp_space = rand(0:(temp_len*loose))
        temp_start = rand(0:lane_lengths-temp_len-temp_space)
        temp_end = temp_start+temp_len+temp_space
        push!(jobs, Job(0, lane_lengths, temp_len, count))
        count+=1
    end
    open(join(["Input/", out_path]), "w") do f
        JSON2.write(f,jobs)
    end
end

args = Base.Sys.ARGS

numJobs = parse(Int64, args[1])
min_len = parse(Int64, args[2])
max_len = parse(Int64, args[3])
loose = parse(Float64, args[4])
lane_lengths = parse(Int64, args[5])
out_path = args[6]

makeJobList(numJobs, min_len, max_len, loose, lane_lengths, out_path)
