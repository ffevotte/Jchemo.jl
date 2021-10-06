struct Plsrda
    fm  
    lev::AbstractVector
    ni::AbstractVector
end

"""
    Plsda(X, y, weights = ones(size(X, 1)); nlv)
Discrimination (DA) based on partial least squares regression (PLSR).
* `X` : X-data.
* `y` : Univariate class membership.
* `weights` : Weights of the observations.
* `nlv` : Nb. latent variables (LVs) to compute.

Discrimination (DA) based on PLS.

The training variable y (univariate class membership) is transformed
to a dummy table (Ydummy) containing nlev columns, where nlev is the number 
of classes present in `y`. Each column of Ydummy is a dummy variable (0/1). 
Then, a PLS2 is implemented on the X-data and Ydummy, 
returning `nlv` latent variables (LVs).
Then, a linear regression model (LMR) is run on the X-data and the LVs, 
returning predictions of the dummy variables. 
For a given observation, the final prediction is the class corresponding 
to the dummy variable for which the prediction is the highest.

By default, a softmax transformation is applied to the 
predicted Ydummy. This can be modified by argument `softmax`:
`predict(fm, Xtest; softmax = false)`.
""" 
function plsrda(X, y, weights = ones(size(X, 1)); nlv)
    z = dummy(y)
    fm = plskern(X, z.Y, weights; nlv = nlv)
    Plsrda(fm, z.lev, z.ni)
end

function predict(object::Plsrda, X; nlv = nothing, softmax = true)
    X = ensure_mat(X)
    m = size(X, 1)
    a = size(object.fm.T, 2)
    isnothing(nlv) ? nlv = a : nlv = (max(minimum(nlv), 0):min(maximum(nlv), a))
    le_nlv = length(nlv)
    pred = list(le_nlv)
    posterior = list(le_nlv)
    @inbounds for i = 1:le_nlv
        zpost = predict(object.fm, X; nlv = nlv[i]).pred
        if softmax
            @inbounds for j = 1:m
                zpost[j, :] .= mweights(exp.(zpost[j, :]))
            end
        end
        z =  mapslices(argmax, zpost; dims = 2) 
        pred[i] = reshape(replacebylev(z, object.lev), m, 1)
        posterior[i] = zpost
    end 
    if le_nlv == 1
        pred = pred[1]
        posterior = posterior[1]
    end
    (pred = pred, posterior = posterior)
end
    


