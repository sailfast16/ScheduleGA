using JSON2

function parse_lines(gams_out, out_dir)
    json_out = []

    f = open(gams_out)
    lines = readlines(f)

    for line in lines
        split_line = split(line, " ", keepempty=false)

        if parse(Float64, split_line[3]) == 1
            task = Dict()
            task["job"] = Dict()
            task["job"]["name"] = parse(Int, split_line[1])
            task["job"]["length"] = Int(parse(Float64, split_line[5]))
            task["lane_id"] = parse(Int, split_line[2])
            task["start"] = Int(parse(Float64, split_line[4]))
            task["fin"] = task["start"] + task["job"]["length"]

            push!(json_out, task)
        end
        json_out
    end

    out_path = join([out_dir,"/schedule_gams.json"])
    open(out_path, "w") do f
        JSON2.write(f, json_out)
    end
end



js = parse_lines("gams_out.csv", pwd())
