# Examples from/based on Fundamentals of Numerical Computation, Julia Edition. Tobin A. Driscoll and Richard J. Braun

using PrettyTables, Plots, LaTeXStrings, LinearAlgebra

#A FILE I STARTED EDITING
### let's solve a simple system of equations 
A = [1.0 2.5; 3.25 4.125]
b = [5.5,6.75]

x_sol = A\b

# confirm the solution
A*x_sol - b #good

# let's solve the same system using the inverse
A_inv = inv(A)
x_sol2 = A_inv * b 

# confirm the solution
A*x_sol2 - b #almost 0: good

# are the solutions the same?
x_sol == x_sol2 #very small difference -> false
x_sol ≈ x_sol2 #approximately equal

#using A\b better than inverted matrix to get solutions of linear equations

### let's count flops!

# solve system using A\b, NEVER USE  INV TO CALCULATE solutions
n = 50:50:500
t_operator = []
t_inv = []

for n in n 
    A = randn(n,n)
    b = randn(n)
    time = @elapsed for j in 1:100 # do it many times to be able to measure time
        A\b
    end
    push!(t_operator,time)
end

for n in n 
    A = randn(n,n)
    b = randn(n)
    time = @elapsed for j in 1:100 # do it many times to be able to measure time
        inv(A)*b
    end
    push!(t_inv,time)
end

data = hcat(n,t_operator,t_inv)
header = (["size","time operator","time inv"],["n","seconds","seconds"])
pretty_table(data;
    header=header,
    header_crayon=crayon"yellow bold" ,
    formatters = ft_printf("%5.2f",2))
#operator / much quicker than inv too

plt = plot(n,t_operator,label="operator",seriestype=:scatter)
plot!(plt,n,t_inv,label="inv(A)*b",seriestype=:scatter,
xaxis=(:log10,L"n"),yaxis = (:log10,"elapsed time (s)"),
title = "Time of matrix-matrix multiplication",)



function forwardsub(L,b)

    n = size(L,1)
    x = zeros(n)
    x[1] = b[1]/L[1,1]
    for i in 2:n
        s = sum( L[i,j]*x[j] for j in 1:i-1 )
        x[i] = ( b[i] - s ) / L[i,i]
    end
    return x
end

function backsub(U,b)

    n = size(U,1)
    x = zeros(n)
    x[n] = b[n]/U[n,n]
    for i in n-1:-1:1
        s = sum( U[i,j]*x[j] for j in i+1:n )
        x[i] = ( b[i] - s ) / U[i,i]
    end
    return x
end


# let's test our functions 
A = rand(1.:9.,5,5)
L = tril(A) #to extract lower elements
U = triu(A) #to extract upper elements
b = rand(1.:9.,5)


x_L = forwardsub(L,b)
x_U = backsub(U,b)

resid_L = L*x_L - b
resid_U = U*x_U - b


# let's count flops!
n = 500:500:10000
t_1 = []
t_2 = []
for n in n 
    A = randn(n,n)
    L = tril(A)
    b = randn(n)
    time_1 = @elapsed for j in 1:10 # do it many times to be able to measure time
        forwardsub(L,b)
    end
    time_2 = @elapsed for j in 1:10 
        L\b
    end
    push!(t_1,time_1)
    push!(t_2,time_2)
end


plt = scatter(n,t_1,label="forwardsub",legend=false,
xaxis=(:log10,L"n"),yaxis = (:log10,"elapsed time (s)"),
title = "Time of forward elimination",);
plot!(plt,n,t_2,label="operator",seriestype=:scatter)

plot!(n,t[end]*(n/n[end]).^2,label=L"O(n^2)",lw=2,ls=:dash,lc=:red,legend = :topleft)

#operator A\b still quicker

### ----------------
### LU factorization - BEGINNING OF LESS IMPORTANT  #################################

A₁ = [
     2    0    4     3 
    -4    5   -7   -10 
     1   15    2   -4.5
    -2    0    2   -13
    ];
L = diagm(ones(4))
U = zeros(4,4);

# first step 
U[1,:] = A₁[1,:]
U

L[:,1] = A₁[:,1]/U[1,1]
L

# second step 
A₂ = A₁ - L[:,1]*U[1,:]'
U[2,:] = A₂[2,:]
L[:,2] = A₂[:,2]/U[2,2]
L

# third step
A₃ = A₂ - L[:,2]*U[2,:]'
U[3,:] = A₃[3,:]
L[:,3] = A₃[:,3]/U[3,3]
L

# fourth step
A₄ = A₃ - L[:,3]*U[3,:]'
U[4,:] = A₄[4,:]
L[:,4] = A₄[:,4]/U[4,4]
L

#END OF LESS IMPORTANT ###############################################

# let's check if the factorization is correct
L*U - A₁

# write it as a function (here we write it with loops)
function my_lu_fact(A)
    n = size(A,1)
    A_ret = float(copy(A))
    for j in 1:n 
        for i in j+1:n
            A_ret[i,j] = A_ret[i,j]/A_ret[j,j]
            for k in j+1:n
                A_ret[i,k] = A_ret[i,k] - A_ret[i,j]*A_ret[j,k]
            end
        end
    end

    return A_ret
end

A = rand(1.:9.,5,5)

A_ret = my_lu_fact(A)
L = tril(A_ret,-1) + I #takes lower triangular of any matrix
#I is identity matrix, here it knows what dimension is; thx to LinearAlgebra package
tril(A_ret,-1)
tril(A_ret,-2)
U = triu(A_ret) #takes upper  triangular of any matrix

# let's check if the factorization is correct
L*U - A

# let's compare (our code) with Julia's (LinearAlgebra) LU factorization
L_1,U_1,P = lu(A) #LinearAlgebra function
L_1 - L #not 0
U_1 - U #not 0

L_1 * U_1 - A # is Julia wrong???
P #4th, 5th, 2nd, 1st, 3rd row - it was permutated

#Julia returns decomposition A~ (with permutation), not A

#we can turn off pivoting

L_2,U_2,P = lu(A,NoPivot())
L_2 - L #0 as expected
U_2 - U #0 as expected

L_2 * U_2 - A #0 as expected
P #1 2 3 4 5

#? lu -> more info; check documentation of functions you don't know


### ----------------
### LU solve 

# combine forward and backward substitution and LU factorization

function my_lu_solve(A,b)
    A_ret = my_lu_fact(A)
    L = tril(A_ret,-1) + I
    U = triu(A_ret)
    y = forwardsub(L,b) #function above
    x = backsub(U,y) #function above
    return x
end

# let's test our function
A = rand(1.:9.,5,5)
b = rand(1.:9.,5)
x = my_lu_solve(A,b)
resid = A*x - b


# another example... 
ϵ = 1e-15; A = [1 1 2;2 2+ϵ 0; 4 14 4]; b = [-5;10;0.0]
x = my_lu_solve(A,b) #1 set of numbers
resid = A*x - b
x = A\b #2nd set of numbers 
#different numbers -> because we divided by very small number (epsilon) - pivoting -> problems
resid = A*x - b

L,U   = my_lu_fact(A) #very big number e16
L,U,P = lu(A)

##### TAKEAWAY - USE FUNCTION, PREFERABLY WITH PIVOTING



# let's count flops!

n = 100:100:1500
t_1 = []
t_2 = []
for n in n 
    A = randn(n,n)
    b = randn(n)
    time_1 = @elapsed for j in 1:10 # do it many times to be able to measure time
        my_lu_solve(A,b)
    end
    time_2 = @elapsed for j in 1:10 
        A\b
    end
    push!(t_1,time_1)
    push!(t_2,time_2)
end

plt = plot(n,t_1,label="my LU",seriestype=:scatter)
plot!(plt,n,t_2,label="operator",seriestype=:scatter,
xaxis=(:log10,L"n"),yaxis = (:log10,"elapsed time (s)"),title = "Time",)
