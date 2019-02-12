using Gadfly
import Cairo, Fontconfig
using DelimitedFiles

times = readdlm("Output/Times/time1.csv")
times = reshape(times,(1,2000))

fig1 = plot(x=1:length(times), y=times, Guide.Title("Time over Generations"), Guide.XLabel("Generation"), Guide.YLabel("Generation Time [Seconds]"))

scores = readdlm("Output/Scores/score1.csv")
scores = reshape(scores, (1,2000))

fig2 = plot(x=1:length(scores), y=scores, Geom.line,Guide.Title("Fitness over Generations"), Guide.XLabel("Generation"), Guide.YLabel("Fitness Value"))

hstack(fig1, fig2)

draw(PNG("times.png", 8inch, 5inch), fig1)
draw(PNG("scores.png", 8inch, 5inch), fig2)
draw(PNG("ellapsed.png", 8inch, 5inch), fig3)

total_time = 0
total_times = []
for i = 1:length(times)
    global total_time
    total_time+=times[i]
    push!(total_times, total_time)
end

fig3 = plot(x=1:length(total_times), y=total_times, Geom.line,Guide.Title("Ellapsed Time over Generation"), Guide.XLabel("Generation"), Guide.YLabel("Ellapsed Time [Seconds]"))
