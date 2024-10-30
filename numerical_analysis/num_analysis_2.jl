# Examples from/based on Fundamentals of Numerical Computation, Julia Edition. Tobin A. Driscoll and Richard J. Braun


using PrettyTables, Plots, LaTeXStrings

# let's count flops!

### matrix-vector multiplication
n = 1000:500:5000 #range of numbers
t = []
for n in n 
    A = randn(n,n)
    x = randn(n)
    time = @elapsed for j in 1:100 # do it many times to be able to measure time
        A*x
    end
    push!(t,time)
end

#t will be the time of operations (not visible yet)

data = hcat(n,t) #2 vectors stacked right to left; below: pretty table
header = (["size","time"],["n","seconds"]) #columns; subtitles
 pretty_table(data;
    header=header,
    header_crayon=crayon"yellow bold" ,
    formatters = ft_printf("%5.2f",2), #2 digits shown
    display_size =  (-1,-1)) #to get entire table

scatter(n,t,label="data",legend=false,
xaxis=(:log10,L"n"),yaxis = (:log10,"elapsed time (s)"),
title = "Time of matrix-vector multiplication",);

plot!(n,t[end]*(n/n[end]).^2,label=L"O(n^2)",lw=2,ls=:dash,lc=:red,legend = :topleft)

#(n_1/n_2)^2 = time_1/time_2 roughly as expected - see slides

### matrix-matrix multiplication
n = 100:100:1000
t = []
for n in n 
    A = randn(n,n)
    B = randn(n,n)
    time = @elapsed for j in 1:20 # do it many times to be able to measure time
        A*B
    end
    push!(t,time)
end

data = hcat(n,t)
header = (["size","time"],["n","seconds"])
pretty_table(data;
    header=header,
    header_crayon=crayon"yellow bold" ,
    formatters = ft_printf("%5.2f",2))

scatter(n,t,label="data",legend=false,
xaxis=(:log10,L"n"),yaxis = (:log10,"elapsed time (s)"),
title = "Time of matrix-matrix multiplication",);

plot!(n,t[end]*(n/n[end]).^3,label=L"O(n^3)",lw=2,ls=:dash,lc=:red,legend = :topleft)