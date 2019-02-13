using JSON2
using DataStructures

function getJobs(filename::String)
    temp_dict = Dict()
    open(filename, "r") do f
        dicttxt = String(Base.read(f))
        temp_dict = JSON2.read(dicttxt)
    end
    jobs = [Job(job[:name], job[:least_start], job[:max_end], job[:length]) for job in temp_dict]
    return jobs
end

function jobsToQueue(jobs::Vector{Job}, priorities::Vector{Int64})
    jobQueue = PriorityQueue()
    for i = 1:length(jobs)
        enqueue!(jobQueue, jobs[i], priorities[i])
    end
    jobQueue
end

function decodeNames!(schedule::Vector{scheduledJob})
    all_ids = [job.lane_id for job in schedule]
    unique_ids = unique(all_ids)

    for i = 1:length(unique_ids)
        for job in schedule
            if job.lane_id == unique_ids[i]
                job.lane_id = Int64(i)
            end
        end
    end
    schedule
    return
end

function getFittness(jobQueue::PriorityQueue, lane_lengths::Int64)
    lane_list = [Lane(hash(rand),0,0,0)]
    pop!(lane_list)
    schedule = [scheduledJob(Job(0,0,0,0),0,0,0)]
    pop!(schedule)

    not_done = true
    while not_done

        # if there are no lanes start the first one
        if length(lane_list)==0
            addNewLane(lane_list, hash(rand()), lane_lengths)
        end

        cur_job = peek(jobQueue).first
        schedule, lane_list = findFit(cur_job, lane_list, schedule, lane_lengths)
        dequeue!(jobQueue)

        sortLanes!(lane_list)

        if length(jobQueue)==0
            not_done = false
        end

    end

    num_lanes = length(unique(lane.id for lane in lane_list))
    decodeNames!(schedule)

    largest_slot = 0
    free_space = 0
    for slot in lane_list
        free_space += slot.length
        if slot.length > largest_slot
            largest_slot = slot.length
        end
    end

    fitness = (largest_slot*(num_lanes)^2)

    return fitness, num_lanes, schedule
end
