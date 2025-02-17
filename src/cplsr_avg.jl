struct CplsrAvg
    fm
    fm_da::PlsLda
    lev
    ni
end

"""
    cplsr_avg(X, Y, cla = nothing; ncla = nothing, nlv_da, nlv)
Clusterwise PLSR.
* `X` : X-data (n, p).
* `Y` : Y-data (n, q).
* `cla` : A vector (n) defining the class membership (clusters). If `cla = nothing`, 
    a k-means clustering is done internally and returns `ncla` clusters.
* `ncla` : Only used if `cla = nothing`. 
    Number of clusters that has to be returned by the k-means clustering.
* `nlv` : A character string such as "5:20" defining the range of the numbers of LVs 
    to consider in the pLSR-AVG models ("5:20": the predictions of models with nb LVS = 5, 6, ..., 20 
    are averaged). Syntax such as "10" is also allowed ("10": correponds to
    the single model with 10 LVs).

A PLSR-AVG model (see `?plsr_avg`) is fitted to predict Y for each of the clusters, 
and a PLS-LDA is fitted to predict, for each cluster, the probability to belong to this cluster.
The final prediction is the weighted average of the PLSR-AVG predictions, where the 
weights are the probabilities predicted by the PLS-LDA model. 

## References
Preda, C., Saporta, G., 2005. Clusterwise PLS regression on a stochastic process. 
Computational Statistics & Data Analysis 49, 99–108. https://doi.org/10.1016/j.csda.2004.05.002

## Examples
```julia
using JLD2, CairoMakie
mypath = dirname(dirname(pathof(Jchemo)))
db = joinpath(mypath, "data", "cassav.jld2") 
@load db dat
pnames(dat)

X = dat.X 
y = dat.Y.y
year = dat.Y.year
tab(year)
s = year .<= 2012
Xtrain = X[s, :]
ytrain = y[s]
Xtest = rmrow(X, s)
ytest = rmrow(y, s)

ncla = 5 ; nlv_da = 15 ; nlv = "10:12"
fm = cplsr_avg(Xtrain, ytrain; 
    ncla = ncla, nlv_da = nlv_da, nlv = nlv) ;
pnames(fm)
fm.lev
fm.ni

res = predict(fm, Xtest) 
res.posterior
rmsep(res.pred, ytest)
f, ax = scatter(vec(res.pred), ytest)
abline!(ax, 0, 1)
f
```
"""
function cplsr_avg(X, Y, cla = nothing; ncla = nothing, nlv_da, nlv)
    X = ensure_mat(X) 
    Y = ensure_mat(Y)
    if isnothing(cla)
        zfm = Clustering.kmeans(X', ncla; maxiter = 500, display = :none)
        cla = zfm.assignments
    end
    z = tab(cla)
    lev = z.keys
    nlev = length(lev)
    ni = collect(values(z))
    #fm_da = plsrda(X, cla; nlv = nlv_da)
    fm_da = plslda(X, cla; nlv = nlv_da, prior = "prop")
    #fm_da = plsqda(X, cla; nlv = nlv_da, prior = "prop")
    fm = list(nlev)
    @inbounds for i = 1:nlev
        z = eval(Meta.parse(nlv))
        zmin = minimum(z)
        zmax = maximum(z)
        ni[i] <= zmin ? zmin = ni[i] - 1 : nothing
        ni[i] <= zmax ? zmax = ni[i] - 1 : nothing
        znlv = string(zmin:zmax)
        s = cla .== lev[i]
        fm[i] = plsr_avg(X[s, :], Y[s, :]; nlv = znlv)
    end
    CplsrAvg(fm, fm_da, lev, ni)
end

function predict(object::CplsrAvg, X)
    X = ensure_mat(X)
    m = size(X, 1)
    nlev = length(object.lev)
    post = predict(object.fm_da, X).posterior
    #post .= (mapreduce(i -> Float64.(post[i, :] .== maximum(post[i, :])), hcat, 1:m)')
    #post = (mapreduce(i -> mweight(exp.(post[i, :])), hcat, 1:m))'
    #post .= (mapreduce(i -> 1 ./ (1 .+ exp.(-post[i, :])), hcat, 1:m)')
    #post .= (mapreduce(i -> post[i, :] / sum(post[i, :]), hcat, 1:m))'
    acc = post[:, 1] .* predict(object.fm[1], X).pred
    @inbounds for i = 2:nlev
        if object.ni[i] >= 30
            acc .+= post[:, i] .* predict(object.fm[i], X).pred
        end
    end
    (pred = acc, posterior = post)
end


