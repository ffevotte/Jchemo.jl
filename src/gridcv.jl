"""
    gridcv(X, Y; segm, score, fun, pars, verbose = false) 
Cross-validation (CV) over a grid of parameters.
* `X` : X-data (n, p).
* `Y` : Y-data (n, q).
* `segm` : Segments of the CV (output of functions
     [`segmts`](@ref), [`segmkf`](@ref) etc.).
* `score` : Function (e.g. `msep`) computing a prediction score.
* `fun` : Function computing the prediction model.
* `pars` : tuple of named vectors (arguments of `fun`) 
    defining the grid of parameters (e.g. output of function `mpar`).
* `verbose` : If true, fitting information are printed.

Compute a prediction score (= error rate) for a given model over a grid of parameters.

The score is computed over the training sets `X` and `Y` for each combination 
of the grid defined in `pars`. 

The vectors in `pars` must have same length.

The function returns two outputs: `res` (mean results) and `res_p` (results per replication).

## Examples
```julia
using JLD2, CairoMakie
mypath = dirname(dirname(pathof(Jchemo)))
db = joinpath(mypath, "data", "cassav.jld2") 
@load db dat
pnames(dat)

# Building Train (years <= 2012) and Test  (year = 2012)

X = dat.X 
y = dat.Y.y
year = dat.Y.year
tab(year)
s = year .<= 2012
Xtrain = X[s, :]
ytrain = y[s]
Xtest = rmrow(X, s)
ytest = rmrow(y, s)
ntrain = nro(Xtrain)

# KNNR models

K = 5 ; rep = 1
segm = segmkf(ntrain, K; rep = rep)

nlvdis = 15 ; metric = ["mahal" ;]
h = [1 ; 2.5] ; k = [5 ; 10 ; 20 ; 50] 
pars = mpar(nlvdis = nlvdis, metric = metric, h = h, k = k) 
length(pars[1]) 
res = gridcv(Xtrain, ytrain; segm = segm, 
    score = rmsep, fun = knnr, pars = pars, verbose = true).res ;
u = findall(res.y1 .== minimum(res.y1))[1] 
res[u, :]

fm = knnr(Xtrain, ytrain;
    nlvdis = res.nlvdis[u], metric = res.metric[u],
    h = res.h[u], k = res.k[u]) ;
pred = Jchemo.predict(fm, Xtest).pred 
rmsep(pred, ytest)

################# PLSR models

K = 5 ; rep = 1
segm = segmkf(ntrain, K; rep = rep)

nlv = 0:20
res = gridcvlv(Xtrain, ytrain; segm = segm, 
    score = rmsep, fun = plskern, nlv = nlv).res
u = findall(res.y1 .== minimum(res.y1))[1] 
res[u, :]

lines(res.nlv, res.y1,
    axis = (xlabel = "Nb. LVs", ylabel = "RMSEP"))

fm = plskern(Xtrain, ytrain; nlv = res.nlv[u]) ;
pred = Jchemo.predict(fm, Xtest).pred 
rmsep(pred, ytest)

# LWPLSR models

K = 5 ; rep = 1
segm = segmkf(ntrain, K; rep = rep)

nlvdis = 15 ; metric = ["mahal" ;]
h = [1 ; 2.5 ; 5] ; k = [50 ; 100] 
pars = mpar(nlvdis = nlvdis, metric = metric, h = h, k = k)
length(pars[1]) 
nlv = 0:20
res = gridcvlv(Xtrain, ytrain; segm = segm, 
    score = rmsep, fun = lwplsr, pars = pars, nlv = nlv, verbose = true).res
u = findall(res.y1 .== minimum(res.y1))[1] 
res[u, :]

lines(res.nlv, res.y1,
    axis = (xlabel = "Nb. LVs", ylabel = "RMSEP"))

fm = lwplsr(Xtrain, ytrain;
    nlvdis = res.nlvdis[u], metric = res.metric[u],
    h = res.h[u], k = res.k[u], nlv = res.nlv[u]) ;
pred = Jchemo.predict(fm, Xtest).pred 
rmsep(pred, ytest)

################# RR models

K = 5 ; rep = 1
segm = segmkf(ntrain, K; rep = rep)

lb = (10.).^collect(-5:1:-1)
res = gridcvlb(Xtrain, ytrain; segm = segm, 
    score = rmsep, fun = rr, lb = lb).res
u = findall(res.y1 .== minimum(res.y1))[1] 
res[u, :]

lines(log.(res.lb), res.y1,
    axis = (xlabel = "Nb. LVs", ylabel = "RMSEP"))

fm = rr(Xtrain, ytrain; lb = res.lb[u]) ;
pred = Jchemo.predict(fm, Xtest).pred 
rmsep(pred, ytest)

################# KRR models

K = 5 ; rep = 1
segm = segmkf(ntrain, K; rep = rep)

gamma = (10.).^collect(-4:1:4)
pars = mpar(gamma = gamma)
length(pars[1]) 
lb = (10.).^collect(-5:1:-1)
res = gridcvlb(Xtrain, ytrain; segm = segm, 
    score = rmsep, fun = krr, pars = pars, lb = lb).res
u = findall(res.y1 .== minimum(res.y1))[1] 
res[u, :]

lines(log.(res.lb), res.y1,
    axis = (xlabel = "Nb. LVs", ylabel = "RMSEP"))

fm = krr(Xtrain, ytrain; gamma = res.gamma[u], lb = res.lb[u]) ;
pred = Jchemo.predict(fm, Xtest).pred 
rmsep(pred, ytest)
```
"""
function gridcv(X, Y; segm, score, fun, pars, verbose = false)
    q = nco(Y)
    nrep = length(segm)
    res_rep = list(nrep)
    ncomb = length(pars[1]) # nb. combinations in pars
    @inbounds for i in 1:nrep
        verbose ? print("/ rept=", i, " ") : nothing
        listsegm = segm[i]       # segments in the repetition
        nsegm = length(listsegm) # segmts: 1; segmkf: K
        zres = list(nsegm)       # results for the repetition
        @inbounds for j = 1:nsegm
            verbose ? print("segm=", j, " ") : nothing
            s = listsegm[j]
            zres[j] = gridscore(
                rmrow(X, s), rmrow(Y, s),
                X[s, :], Y[s, :];
                score = score, fun = fun, pars = pars)
        end
        zres = reduce(vcat, zres)
        dat = DataFrame(rept = fill(i, nsegm * ncomb),
            segm = repeat(1:nsegm, inner = ncomb))
        zres = hcat(dat, zres)
        res_rep[i] = zres
    end
    verbose ? println("/ End.") : nothing
    res_rep = reduce(vcat, res_rep)
    gdf = groupby(res_rep, collect(keys(pars))) 
    namy = map(string, repeat(["y"], q), 1:q)
    res = combine(gdf, namy .=> mean, renamecols = false)
    (res = res, res_rep = res_rep, )
end
    
"""
    gridcvlv(X, Y; segm, score, fun, nlv, pars, verbose = false)
* See `gridcv`.
* `nlv` : Nb., or collection of nb., of latent variables (LVs).

Same as [`gridcv`](@ref) but specific to (and much faster for) models 
using latent variables (e.g. PLSR).

Argument `pars` must not contain `nlv`.

See `?gridcv` for examples.
"""
function gridcvlv(X, Y; segm, score, fun, nlv, pars = nothing, 
        verbose = false)
    q = nco(Y)
    nrep = length(segm)
    res_rep = list(nrep)
    nlv = max(minimum(nlv), 0):maximum(nlv)
    le_nlv = length(nlv)
    @inbounds for i in 1:nrep
        verbose ? print("/ rept=", i, " ") : nothing
        listsegm = segm[i]       # segments in the repetition
        nsegm = length(listsegm) # segmts: 1; segmkf: K
        zres = list(nsegm)       # results for the repetition
        @inbounds for j = 1:nsegm
            verbose ? print("segm=", j, " ") : nothing
            s = listsegm[j]
            zres[j] = gridscorelv(
                rmrow(X, s), rmrow(Y, s),
                X[s, :], Y[s, :];
                score = score, fun = fun, nlv = nlv, pars = pars)
        end
        zres = reduce(vcat, zres)
        ## Case where pars is empty
        if isnothing(pars) 
            dat = DataFrame(rept = fill(i, nsegm * le_nlv),
                segm = repeat(1:nsegm, inner = le_nlv))
        else
            ncomb = length(pars[1]) # nb. combinations in pars
            dat = DataFrame(rept = fill(i, nsegm * le_nlv * ncomb),
                segm = repeat(1:nsegm, inner = le_nlv * ncomb))
        end
        zres = hcat(dat, zres)
        res_rep[i] = zres
    end
    verbose ? println("/ End.") : nothing
    res_rep = reduce(vcat, res_rep)
    isnothing(pars) ? namgroup = [:nlv] : namgroup =  [:nlv ; collect(keys(pars))]
    gdf = groupby(res_rep, namgroup) 
    namy = map(string, repeat(["y"], q), 1:q)
    res = combine(gdf, namy .=> mean, renamecols = false)
    (res = res, res_rep = res_rep, )
end

"""
    gridcvlb(X, Y; segm, score, fun, lb, pars, verbose = false)
* See `gridcv`.
* `lb` : Value, or collection of values, of the ridge regularization parameter "lambda".

Same as [`gridcv`](@ref) but specific to (and much faster for) models 
using ridge regularization (e.g. RR).

Argument `pars` must not contain `lb`.

See `?gridcv` for examples.
"""
function gridcvlb(X, Y; segm, score, fun, lb, pars = nothing, 
        verbose = false)
    q = nco(Y)
    nrep = length(segm)
    res_rep = list(nrep)
    lb = sort(unique(lb))
    le_lb = length(lb)
    @inbounds for i in 1:nrep
        verbose ? print("/ rept=", i, " ") : nothing
        listsegm = segm[i]       # segments in the repetition
        nsegm = length(listsegm) # segmts: 1; segmkf: K
        zres = list(nsegm)       # results for the repetition
        @inbounds for j = 1:nsegm
            verbose ? print("segm=", j, " ") : nothing
            s = listsegm[j]
            zres[j] = gridscorelb(
                rmrow(X, s), rmrow(Y, s),
                X[s, :], Y[s, :];
                score = score, fun = fun, lb = lb, pars = pars)
        end
        zres = reduce(vcat, zres)
        ## Case where pars is empty
        if isnothing(pars) 
            dat = DataFrame(rept = fill(i, nsegm * le_lb),
                segm = repeat(1:nsegm, inner = le_lb))
        else
            ncomb = length(pars[1]) # nb. combinations in pars
            dat = DataFrame(rept = fill(i, nsegm * le_lb * ncomb),
                segm = repeat(1:nsegm, inner = le_lb * ncomb))
        end
        zres = hcat(dat, zres)
        res_rep[i] = zres
    end
    verbose ? println("/ End.") : nothing
    res_rep = reduce(vcat, res_rep)
    isnothing(pars) ? namgroup = [:lb] : namgroup =  [:lb ; collect(keys(pars))]
    gdf = groupby(res_rep, namgroup) 
    namy = map(string, repeat(["y"], q), 1:q)
    res = combine(gdf, namy .=> mean, renamecols = false)
    (res = res, res_rep = res_rep, )
end

####################### Multiblock

"""
    gridcv_mb(X, Y; segm, score, fun, pars, verbose = false)
* See `gridcv`.

Same as [`gridcv`](@ref) but specific to multiblock regression.

See `?gridcv` for examples.
"""
function gridcv_mb(X, Y; segm, score, fun, pars, verbose = false)
    q = nco(Y)
    nrep = length(segm)
    res_rep = list(nrep)
    ncomb = length(pars[1]) # nb. combinations in pars
    nbl = length(X)
    @inbounds for i in 1:nrep
        verbose ? print("/ rept=", i, " ") : nothing
        listsegm = segm[i]       # segments in the repetition
        nsegm = length(listsegm) # segmts: 1; segmkf: K
        zres = list(nsegm)       # results for the repetition
        @inbounds for j = 1:nsegm
            verbose ? print("segm=", j, " ") : nothing
            s = listsegm[j]
            zX1 = list(nbl, Matrix{Float64})
            zX2 = list(nbl, Matrix{Float64})
            for k = 1:nbl
                zX1[k] = rmrow(X[k], s)
                zX2[k] = X[k][s, :]
            end
            zres[j] = gridscore(zX1, rmrow(Y, s), zX2, Y[s, :];
                score = score, fun = fun, pars = pars)
        end
        zres = reduce(vcat, zres)
        dat = DataFrame(rept = fill(i, nsegm * ncomb),
            segm = repeat(1:nsegm, inner = ncomb))
        zres = hcat(dat, zres)
        res_rep[i] = zres
    end
    verbose ? println("/ End.") : nothing
    res_rep = reduce(vcat, res_rep)
    gdf = groupby(res_rep, collect(keys(pars))) 
    namy = map(string, repeat(["y"], q), 1:q)
    res = combine(gdf, namy .=> mean, renamecols = false)
    (res = res, res_rep = res_rep, )
end

"""
    gridcvlv_mb(X, Y; segm, score, fun, nlv, pars, verbose = false)
* See `gridcv`.

Same as [`gridcv`](@ref) but specific to multiblock regression.

See `?gridcv` for examples.
"""
function gridcvlv_mb(X, Y; segm, score, fun, nlv, pars = nothing, 
        verbose = false)
    q = nco(Y)
    nrep = length(segm)
    res_rep = list(nrep)
    nlv = max(minimum(nlv), 0):maximum(nlv)
    le_nlv = length(nlv)
    nbl = length(X)
    @inbounds for i in 1:nrep
        verbose ? print("/ rept=", i, " ") : nothing
        listsegm = segm[i]       # segments in the repetition
        nsegm = length(listsegm) # segmts: 1; segmkf: K
        zres = list(nsegm)       # results for the repetition
        @inbounds for j = 1:nsegm
            verbose ? print("segm=", j, " ") : nothing
            s = listsegm[j]
            zX1 = list(nbl, Matrix{Float64})
            zX2 = list(nbl, Matrix{Float64})
            for k = 1:nbl
                zX1[k] = rmrow(X[k], s)
                zX2[k] = X[k][s, :]
            end
            zres[j] = gridscorelv(zX1, rmrow(Y, s), zX2, Y[s, :];
                score = score, fun = fun, nlv = nlv, pars = pars)
        end
        zres = reduce(vcat, zres)
        ## Case where pars is empty
        if isnothing(pars) 
            dat = DataFrame(rept = fill(i, nsegm * le_nlv),
                segm = repeat(1:nsegm, inner = le_nlv))
        else
            ncomb = length(pars[1]) # nb. combinations in pars
            dat = DataFrame(rept = fill(i, nsegm * le_nlv * ncomb),
                segm = repeat(1:nsegm, inner = le_nlv * ncomb))
        end
        zres = hcat(dat, zres)
        res_rep[i] = zres
    end
    verbose ? println("/ End.") : nothing
    res_rep = reduce(vcat, res_rep)
    isnothing(pars) ? namgroup = [:nlv] : namgroup =  [:nlv ; collect(keys(pars))]
    gdf = groupby(res_rep, namgroup) 
    namy = map(string, repeat(["y"], q), 1:q)
    res = combine(gdf, namy .=> mean, renamecols = false)
    (res = res, res_rep = res_rep, )
end


