struct Lane
    id
    start::Int64
    fin::Int64
    length::Int64
end

struct Job
    name::Int64
    least_start::Int64
    max_end::Int64
    length::Int64
end

mutable struct scheduledJob
    job::Job
    lane_id
    start::Int64
    fin::Int64
end

function addNewLane(lane_list::Vector{Lane}, lane_id::UInt, laneLength::Int64)
    new_lane = Lane(lane_id, 0, laneLength, laneLength)
    push!(lane_list, new_lane)
end

function splitLane!(lane_list::Vector{Lane}, lane::Lane, start_split::Int, end_split::Int)
    temp1 = Lane(lane.id, lane.start, start_split, start_split-lane.start)
    temp2 = Lane(lane.id, end_split, lane.fin, lane.fin-end_split)

    push!(lane_list, temp1)
    push!(lane_list, temp2)
    deleteat!(lane_list, findall(x->x==lane, lane_list)[1])
end

function sortLanes!(lanes::Vector{Lane})
    lengths = [lanes[i].length for i =1:length(lanes)]
    indsort = sortperm(lengths, rev=true)

    lanes[:] = [lanes[i] for i in indsort]
end

function findFit(job::Job, lane_list::Vector{Lane}, schedule::Vector{scheduledJob}, lane_lengths::Int64)
    # decrease number of slots to check by only checking the ones that are long enough
    find_length = filter(x->x.length>=job.length, lane_list)
    not_done = true

    for cur_slot in find_length
        if cur_slot.start>=job.least_start
            if cur_slot.fin >= cur_slot.start+job.length & cur_slot.start+job.length <= job.max_end
                job_loc = [cur_slot.start, cur_slot.start+job.length]
                not_done = false
                splitLane!(lane_list, cur_slot, job_loc[1], job_loc[2])
                tempJob = scheduledJob(job, cur_slot.id, job_loc[1], job_loc[2])
                push!(schedule, tempJob)
                return schedule, lane_list
                break
            end

        elseif cur_slot.start<=job.least_start
            if job.least_start+job.length <= cur_slot.fin
                job_loc = [job.least_start, job.least_start+job.length]
                not_done = false
                splitLane!(lane_list, cur_slot, job_loc[1], job_loc[2])
                tempJob = scheduledJob(job, cur_slot.id, job_loc[1], job_loc[2])
                push!(schedule, tempJob)
                return schedule, lane_list
                break
            end
        end
    end

    if not_done
        temp_id = hash(rand())
        addNewLane(lane_list, temp_id, lane_lengths)
        sortLanes!(lane_list)

        temp_start = job.least_start
        temp_end = temp_start + job.length
        job_loc = [temp_start, temp_end]
        splitLane!(lane_list, lane_list[1], job_loc[1], job_loc[2])
        tempJob = scheduledJob(job, temp_id, job_loc[1], job_loc[2])
        push!(schedule, tempJob)
        return schedule, lane_list
    end
end
