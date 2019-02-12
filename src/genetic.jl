using Distributed
using JSON2
import Random.shuffle

mutable struct Population
    jobs::Array{Job}
    inds::Array{Array{Int64,1},1}
    gen_scores::Array{Int64,1}
    gen_lanes::Array{Int64,1}
end

function Population(inds::Array{Array{Int64,1},1}, jobs::Vector{Job})
    gen_stats = pmap(scoreIndividual, inds, [jobs for i =1:length(inds)]; batch_size=nprocs())

    pop = Population(jobs, inds, [x[1] for x in gen_stats], [x[2] for x in gen_stats])
    sortPop!(pop)
    return pop
end

function scoreIndividual(individual::Array{Int64,1}, jobs::Vector{Job})
    jobQueue = jobsToQueue(jobs, individual)
    lane_lengths = maximum([x.max_end for x in jobs])
    gen_score, num_lanes, _ = getFittness(jobQueue, lane_lengths)
    return gen_score, num_lanes
end

function sortPop!(pop::Population)
    popSize = length(pop.inds)
    idxsort = sortperm(pop.gen_scores)
    indsnew = similar(pop.inds)
    scoresnew = zeros(Float64, length(pop.gen_scores))
    lanesnew = zeros(Float64, length(pop.gen_lanes))

    for i = 1:popSize
        indsnew[i] = pop.inds[idxsort[i]]
        scoresnew[i] = pop.gen_scores[idxsort[i]]
        lanesnew[i] = pop.gen_lanes[idxsort[i]]
    end

    pop.inds[:] = indsnew
    pop.gen_scores[:] = scoresnew
    pop.gen_lanes[:] = lanesnew
    return
end

function makePop(popSize::Int64, jobs::Vector{Job})
    numjobs = length(jobs)
    vals = collect(1:numjobs)
    inds = Array{Array{Int64,1},1}()
    for i = 1:popSize
        push!(inds, shuffle(vals))
    end

    Population(inds, jobs)
end

function getParents(pop::Population, per_keep::Float64)
    popSize = length(pop.inds)
    numJobs = length(pop.inds[1])

    num_keep = Int(floor(popSize*per_keep))
    popSize2 = Int(floor(popSize - num_keep))
    parents = similar(pop.inds)

    nparents = 0
    while nparents < popSize2
        test_lo = minimum(pop.gen_scores)
        test_hi = maximum(pop.gen_scores)
        jtest = rand(1:popSize)
        leveltest = rand(test_lo:test_hi)
        if pop.gen_scores[jtest] <= leveltest
            nparents = nparents + 1
            parents[nparents] = pop.inds[jtest]
        end
    end
    return parents, num_keep
end

function nPoint(p1::Array{Int64,1}, p2::Array{Int64,1}, per_swap::Float64)
    numJobs = length(p1)

    c1 = similar(p1)
    c2 = similar(p2)

    for i = 1:rand(collect(1:Int(ceil(numJobs*per_swap))))
        ind_mate = 1 + rand(1:(numJobs-1))

        c1[:] = p1
        k = findall(x->x==p2[ind_mate], c1)[1]
        c1[ind_mate] = p2[ind_mate]

        c1[k] =  p1[ind_mate]

        c2[:] = p2
        k = findall(x->x==p1[ind_mate], c2)[1]
        c2[ind_mate] = p1[ind_mate]

        c2[k] =  p2[ind_mate]
    end
    c1, c2
end

function mutate!(c1::Array{Int64,1}, c2::Array{Int64,1}, per_mut::Float64)
    numJobs = length(c1)
    nummut = rand(collect(1:Int(floor(numJobs*per_mut))))

    for l = 1:nummut
        mut_node = rand(1:numJobs-1)

        tmp1 = c1[mut_node]
        c1[mut_node] = c1[mut_node+1]
        c1[mut_node+1] = tmp1

        tmp2 = c2[mut_node]
        c2[mut_node] = c2[mut_node+1]
        c2[mut_node+1] = tmp2
    end
    return
end

function breed!(pop::Population, per_keep::Float64, per_swap::Float64, per_mut::Float64)
    popSize = length(pop.inds)
    numJobs = length(pop.inds[1])

    parents, num_keep = getParents(pop, per_keep)
    popSize2 = popSize - num_keep

    children = similar(pop.inds)

    for i = 1:floor(Int64, popSize2/2)
        p1 = parents[2*i-1]
        p2 = parents[2*i]

        c1, c2 = nPoint(p1, p2, per_swap)
        mutate!(c1, c2, per_mut)

        children[2*i-1] = c1
        children[2*i] = c2
    end

    new_pop = Population(children[1:popSize2], pop.jobs)
    pop.inds[num_keep+1:end] = new_pop.inds
    pop.gen_scores[num_keep+1:end] = new_pop.gen_scores
    pop.gen_lanes[num_keep+1:end] = new_pop.gen_lanes
    sortPop!(pop)
    return
end
