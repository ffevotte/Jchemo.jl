struct PlsLda    # for plslda and plsqda 
    fm  
    lev::AbstractVector
    ni::AbstractVector
end

"""
    plslda(X, y, weights = ones(size(X, 1)); nlv, prior = "unif")
LDA on PLS latent variables (PLS-LDA).
* `X` : X-data.
* `y` : y-data (class membership).
* `weights` : Weights of the observations.
* `nlv` : Nb. latent variables (LVs) to compute.

The training variable `y` (univariate class membership) is transformed
to a dummy table (Ydummy) containing nlev columns, where nlev is the number 
of classes present in `y`. Each column of Ydummy is a dummy variable (0/1). 
Then, a PLS2 is implemented on `X` and Ydummy, 
returning `nlv` latent variables (LVs). Finally, a LDA is run on these LVs and `y`. 

## Examples
```julia
using JLD2
mypath = dirname(dirname(pathof(Jchemo)))
db = joinpath(mypath, "data", "forages.jld2") 
@load db dat
pnames(dat)

Xtrain = dat.Xtrain
ytrain = dat.Ytrain.y
Xtest = dat.Xtest
ytest = dat.Ytest.y

tab(ytrain)
tab(ytest)

nlv = 20      # nlv must be >=1 (conversely to plsrda for which nlv >= 0)
fm = plslda(Xtrain, ytrain; nlv = nlv) ;    
#fm = plsqda(Xtrain, ytrain; nlv = nlv) ;
pnames(fm)
pnames(fm.fm)

res = Jchemo.predict(fm, Xtest) ;
pnames(res)
res.pred
err(res.pred, ytest)

fm_pls = fm.fm.fm_pls ;
Jchemo.transform(fm_pls, Xtest)
Jchemo.transform(fm_pls, Xtest; nlv = 2)
Base.summary(fm_pls, Xtrain)
coef(fm_pls).B
coef(fm_pls, nlv = 1).B
coef(fm_pls, nlv = 2).B

fm_da = fm.fm.fm_da ;
T = transform(fm_pls, Xtest)
Jchemo.predict(fm_da[nlv], T).pred

Jchemo.predict(fm, Xtest; nlv = 1:2).pred
```
""" 
function plslda(X, y, weights = ones(size(X, 1)); nlv, prior = "unif")
    z = dummy(y)
    fm_pls = plskern(X, z.Y, weights; nlv = nlv)
    fm_da = list(nlv)
    @inbounds for i = 1:nlv
        fm_da[i] = lda(fm_pls.T[:, 1:i], y; prior = prior)
    end
    fm = (fm_pls = fm_pls, fm_da = fm_da)
    PlsLda(fm, z.lev, z.ni)
end

"""
    plsqda(X, y, weights = ones(size(X, 1)); nlv, prior = "unif")
QDA on PLS latent variables.
* `X` : X-data.
* `y` : y-data (class membership).
* `weights` : Weights of the observations.
* `nlv` : Nb. latent variables (LVs) to compute.

The training variable `y` (univariate class membership) is transformed
to a dummy table (Ydummy) containing nlev columns, where nlev is the number 
of classes present in `y`. Each column of Ydummy is a dummy variable (0/1). 
Then, a PLS2 is implemented on `X` and Ydummy, 
returning `nlv` latent variables (LVs). Finally, a QDA is run on these LVs and `y`.

See `?plslda` for examples.
""" 
function plsqda(X, y, weights = ones(size(X, 1)); nlv, prior = "unif")
    z = dummy(y)
    fm_pls = plskern(X, z.Y, weights; nlv = nlv)
    fm_da = list(nlv)
    for i = 1:nlv
        fm_da[i] = qda(vcol(fm_pls.T, 1:i), y; prior = prior)
    end
    fm = (fm_pls = fm_pls, fm_da = fm_da)
    PlsLda(fm, z.lev, z.ni)
end

function predict(object::PlsLda, X; nlv = nothing)
    X = ensure_mat(X)
    m = size(X, 1)
    a = size(object.fm.fm_pls.T, 2)
    isnothing(nlv) ? nlv = a : nlv = (max(minimum(nlv), 0):min(maximum(nlv), a))
    le_nlv = length(nlv)
    pred = list(le_nlv, Union{Matrix{Int64}, Matrix{Float64}, Matrix{String}})
    posterior = list(le_nlv, Matrix{Float64})
    @inbounds for i = 1:le_nlv
        znlv = nlv[i]
        T = transform(object.fm.fm_pls, X, nlv = znlv)
        zres = predict(object.fm.fm_da[znlv], T)
        z =  mapslices(argmax, zres.posterior; dims = 2) 
        pred[i] = reshape(replacebylev2(z, object.lev), m, 1)
        posterior[i] = zres.posterior
    end 
    if le_nlv == 1
        pred = pred[1]
        posterior = posterior[1]
    end
    (pred = pred, posterior = posterior)
end





