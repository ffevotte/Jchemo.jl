"""
    ensure_mat(X)
Reshape `X` to a matrix if necessary.
"""
ensure_mat(X::AbstractMatrix) = X
ensure_mat(X::AbstractVector) = reshape(X, :, 1)
ensure_mat(X::Number) = reshape([X], 1, 1)

"""
    iqr(x)
Compute the interquartile interval (IQR).
"""
iqr(x) = quantile(x, .75) - quantile(x, .25)


"""
    list(n::Integer)
Create a Vector{Any}(undef, n).
"""  
list(n::Integer) = Vector{Any}(undef, n) 

""" 
    mad(x)
Compute the median absolute deviation (MAD),
adjusted by a factor (1.4826) for asymptotically normal consistency. 
"""
mad(x) = 1.4826 * median(abs.(x .- median(x)))

""" 
    mweights(w)
Return a vector of weights that sums to 1.
"""
mweights(w) = w / sum(w)

"""
    rmrow(X, s)
Remove the rows of `X` having indexes `s`.
## Examples
```julia
X = rand(5, 2) ; 
rmrows(X, 2:3)
rmrows(X, [1, 4])
```
"""
rmrows(X::AbstractMatrix, s) = X[setdiff(1:end, s), :]
rmrows(X::AbstractVector, s) = X[setdiff(1:end, s)]

"""
    rmcols(X, s)
Remove the columns of `X` having indexes `s`.
## Examples
```julia
X = rand(5, 3) ; 
rmcols(X, 1:2)
rmcols(X, [1, 3])
```
"""
rmcols(X::AbstractMatrix, s) = X[:, setdiff(1:end, s)]

"""
    sourcedir(path)
Include all the files contained in a directory.
"""
function sourcedir(path)
    z = readdir(path)  ## List of files in path
    n = length(z)
    #sample(1:2, 1)
    for i in 1:n
        include(string(path, "/", z[i]))
    end
end

"""
    vrow(X, j)
    vcol(X, j)
View of the i-th row or j-th column of a matrix `X`.
""" 
vrow(X, i) = view(X, i, :)

vcol(X, j) = view(X, :, j)



