struct Svmda
    fm
    lev::AbstractVector
    ni::AbstractVector
end

"""
    svmda(X, y; kern = "rbf", 
        gamma = 1. / size(X, 2), degree = 3, coef0 = 0., cost = 1.
        epsilon = .1)
Support vector machine for discrimination "C-SVC" (SVM-DA).
* `X` : X-data.
* `y : y-data (univariate).
* 'kern' : Type of kernel used to compute the Gram matrices.
    Possible values are "krbf", "kpol", "klin" or "ktanh". 
* 'gamma' : See below.
* 'degree' : See below.
* 'coef0' : See below.
* 'cost' : Cost of constraints violation C parameter.
* 'epsilon' : Epsilon parameter in the loss function. 

Kernel types : 
* "krbf" -- radial basis function: exp(-gamma * |x - y|^2)
* "kpol" -- polynomial: (gamma * x' * y + coef0)^degree
* "klin* -- linear: x' * y
* "ktan" -- sigmoid: tanh(gamma * x' * y + coef0)

The function uses package LIBSVM.jl (https://github.com/JuliaML/LIBSVM.jl) 
that is an interface to library LIBSVM (Chang & Li 2001).

## References 

Package LIBSVM.jl: https://github.com/JuliaML/LIBSVM.jl

Chang, C.-C. & Lin, C.-J. (2001). LIBSVM: a library for support vector machines. 
Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm. 
Detailed documentation (algorithms, formulae, ...) can be found in
http://www.csie.ntu.edu.tw/~cjlin/papers/libsvm.ps.gz

Chih-Chung Chang and Chih-Jen Lin, LIBSVM: a library for support vector machines. 
ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27, 2011. 
Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm

Schölkopf, B., Smola, A.J., 2002. Learning with kernels: 
support vector machines, regularization, optimization, and beyond.
Adaptive computation and machine learning. MIT Press, Cambridge, Mass.

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

gamma = .01 ; cost = 1000 ; epsilon = 1
fm = svmda(Xtrain, ytrain; 
    gamma = gamma, cost = cost, epsilon = epsilon) ;
pnames(fm)

res = Jchemo.predict(fm, Xtest) ;
pnames(res)
res.pred
err(res.pred, ytest)
```
""" 
function svmda(X, y; kern = "krbf", 
        gamma = 1. / size(X, 2), degree = 3, coef0 = 0., cost = 1.,
        epsilon = .1)
    gamma = Float64(gamma) ; degree = Int64(degree) ; coef0  = Float64(coef0) ; 
    cost  = Float64(cost)
    epsilon = Float64(epsilon)
    X = ensure_mat(X)
    y = vec(y)
    ztab = tab(y)
    if kern == "krbf"
        fkern = LIBSVM.Kernel.RadialBasis
    elseif kern == "kpol"
        fkern = LIBSVM.Kernel.Polynomial
    elseif kern == "klin"
        fkern = LIBSVM.Kernel.Linear
    elseif kern == "ktanh"
        fkern = LIBSVM.Kernel.Sigmoid
    end
    nt = 0 
    fm = svmtrain(X', y;
        svmtype = SVC, 
        kernel = fkern,
        gamma =  gamma,
        coef0 = coef0,
        degree = degree,
        cost = cost, epsilon = epsilon,
        nt = nt) 
    Svmda(fm, ztab.keys, ztab.vals)
end


"""
    predict(object::Svmda, X)
Compute y-predictions from a fitted model.
* `object` : The fitted model.
* `X` : X-data for which predictions are computed.
""" 
function predict(object::Svmda, X)
    X = ensure_mat(X)
    pred = svmpredict(object.fm, X')[1]
    n = length(pred)
    pred = reshape(pred, n, 1)
    (pred = pred,)
end
