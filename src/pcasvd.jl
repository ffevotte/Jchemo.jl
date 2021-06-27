struct Pca
    T::Array{Float64}
    P::Array{Float64}
    sv::Vector{Float64}
    xmeans::Vector{Float64}
    weights::Vector{Float64}
    ## For consistency with PCA Nipals
    niter::Union{Int64, Nothing}
    conv::Union{Bool, Nothing}
end

"""
    pcasvd(X, weights = ones(size(X, 1)); nlv)
PCA by SVD decomposition.
* `X` : matrix (n, p).
* `weights` : vector (n,).
* `nlv` : Nb. principal components (PCs).

Noting D a (n, n) diagonal matrix of weights for the observations (rows of X),
the function does a SVD factorization of D^(1/2) * X, using LinearAlgebra.svd.

`X` is internally centered. 

The in-place version modifies externally `X`. 
""" 
function pcasvd(X, weights = ones(size(X, 1)); nlv)
    pcasvd!(copy(X), weights; nlv = nlv)
end

function pcasvd!(X, weights = ones(size(X, 1)); nlv)
    X = ensure_mat(X)
    n, p = size(X)
    nlv = min(nlv, n, p)
    weights = mweights(weights)
    sqrtw = sqrt.(weights)
    xmeans = colmeans(X, weights) 
    center!(X, xmeans)
    res = LinearAlgebra.svd!(Diagonal(sqrtw) * X)
    P = res.V[:, 1:nlv]
    ## by default in LinearAlgebra.svd
    ## "full = false" ==> [1:min(n, p)]
    sv = res.S   
    sv[sv .< 0] .= 0
    ## eig = sv.^2
    ## = Eigenvalues of X'DX = Cov(X) in metric D
    ## where D = Diagonal(weights) 
    ## = variances of scores T in metric D
    ## = TT = colSums(weights * T .* T)  
    ## = norms^2 of the scores T in metric D
    ## = colnorms(T, weights = weights)^2   
    ## -------- Strictly, T should be generated by transform(object, X)
    ## But T is returned below to keep consistency with PLS,
    ## where T is a direct output of the algorithm
    ## T = D^(-1/2) * U * S
    ## Faster but requires weights > 0 (or mananage NA vales for weights = 0)
    ## Alternative: T = X * P  
    T = Diagonal(1 ./ sqrtw) * @view(res.U[:, 1:nlv]) * (Diagonal(@view(sv[1:nlv])))
    Pca(T, P, sv, xmeans, weights, nothing, nothing)
end

"""
    summary(object::Pca, X)
Summarize the maximal (i.e. with maximal nb. PCs) fitted model.
* `object` : The fitted model.
* `X` : The X-data that was used to fit the model.
""" 
function Base.summary(object::Pca, X)
    nlv = size(object.T, 2)
    X = center(X, object.xmeans)
    sstot = sum(object.weights' * (X.^2))
    D = Diagonal(object.weights)
    TT = D * object.T.^2
    tt = vec(sum(TT, dims = 1))
    pvar = tt / sstot
    cumpvar = cumsum(pvar)
    explvar = DataFrame(pc = 1:nlv, var = tt, pvar = pvar, cumpvar = cumpvar)
    contr_ind = DataFrame(scale(TT, tt), :auto)
    xvars = colvars(X, object.weights)
    zX = scale(X, sqrt.(xvars))
    zT = D * scale(object.T, sqrt.(tt))
    cor_circle = DataFrame(zX' * zT, :auto)
    z = X' * zT
    coord_var = DataFrame(z, :auto)
    z = z .* z
    contr_var = DataFrame(scale(z, sum(z, dims = 1)), :auto)
    nam = map(string, repeat(["pc"], nlv), 1:nlv)
    rename!(contr_ind, nam)
    rename!(cor_circle, nam)
    rename!(coord_var, nam)
    rename!(contr_var, nam)
    (explvar = explvar, contr_ind = contr_ind,
        contr_var = contr_var, coord_var = coord_var, cor_circle = cor_circle)
end

""" 
    transform(object::Pca, X; nlv = nothing)
Compute PCs ("scores" T) from a fitted model and a matrix X.
* `object` : The maximal fitted model.
* `X` : Matrix (m, p) for which PCs are computed.
* `nlv` : Nb. PCs to consider. If nothing, it is the maximum nb. PCs.
""" 
function transform(object::Pca, X; nlv = nothing)
    a = size(object.T, 2)
    isnothing(nlv) ? nlv = a : nlv = min(nlv, a)
    center(X, object.xmeans) * @view(object.P[:, 1:nlv])
end



