"""
    rmgap(X; indexcol, k = 5)
    rmgap!(X; indexcol, k = 5)
Remove vertical gaps in spectra , e.g. for ASD.  
* `X` : X-data.
* `indexcol` : The indexes of the columns where are located the gaps. 
* `k` : The number of columns used on the left side 
        of the gaps for fitting the linear regressions.

For each observation (row of matrix `X`),
the corrections are done by extrapolation from simple linear regressions 
computed on the left side of the defined gaps. 

For instance, If two gaps are observed between indexes 651-652 and 
between indexes 1425-1426, respectively, then the syntax should 
be `indexcol = [651 ; 1425]`.

```julia
using JLD2, CairoMakie
mypath = dirname(dirname(pathof(Jchemo)))
db = joinpath(mypath, "data", "asdgap.jld2") 
@load db dat
pnames(dat)

X = dat.X
wl = names(dat.X)
wl_num = parse.(Float64, wl)

z = [1000 ; 1800] 
u = findall(in(z).(wl_num))
f, ax = plotsp(X, wl_num)
vlines!(ax, z; linestyle = :dash, color = (:grey, .8))
f

# Corrected data

u = findall(in(z).(wl_num))
zX = rmgap(X; indexcol = u, k = 5)  
f, ax = plotsp(zX, wl_num)
vlines!(ax, z; linestyle = :dash, color = (:grey, .8))
f
```
""" 
function rmgap(X; indexcol, k = 5)
    rmgap!(copy(X); indexcol, k)
end

function rmgap!(X; indexcol, k = 5)
    X = ensure_mat(X)
    size(X, 2) == 1 ? X = reshape(X, 1, :) : nothing
    p = size(X, 2)
    k = max(k, 2)
    ngap = length(indexcol)
    @inbounds for i = 1:ngap
        ind = indexcol[i]
        wl = max(ind - k + 1, 1):ind
        fm = mlr(Float64.(wl), X[:, wl]')
        pred = predict(fm, ind + 1).pred
        bias = X[:, ind + 1] .- pred'
        X[:, (ind + 1):p] .= X[:, (ind + 1):p] .- bias
    end
    X
end
