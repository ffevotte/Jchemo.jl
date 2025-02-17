module Jchemo  # Start-Module

using CairoMakie
using Clustering
using DataInterpolations
using Distributions
using DataFrames
using Distances
using HypothesisTests
using ImageFiltering
using Interpolations
using LIBSVM
using LinearAlgebra
using NearestNeighbors
using Random
using SparseArrays 
using Statistics
using StatsBase    # sample
using XGBoost

include("utility.jl") 
include("aov1.jl")
include("fweight.jl") 
include("matW.jl")
include("nipals.jl")
include("plots.jl")
include("preprocessing.jl") 
include("rmgap.jl")

include("fda.jl")
include("pcasvd.jl")
include("pcaeigen.jl")
include("kpca.jl")
include("rp.jl")

# Multiblock PCA
include("mbpca_cons.jl")
include("mbpca_comdim_s.jl")

# Regression 
include("mlr.jl")
include("rr.jl")
include("plskern.jl") ; include("plsrosa.jl")
include("plsnipals.jl") ; include("plssimp.jl") 
include("plsr_avg.jl")
include("plsr_avg_aic.jl")
include("plsr_avg_cv.jl")
include("plsr_avg_unif.jl")
include("plsr_avg_shenk.jl")
include("plsr_stack.jl")
include("cglsr.jl")
include("pcr.jl")
include("krr.jl") ; include("kplsr.jl") ; include("dkplsr.jl")
include("aicplsr.jl")
include("wshenk.jl")  

# SVM
include("svmr.jl")

# Bagging
include("baggr.jl") ; include("baggr_util.jl")

# Trees
include("treer_xgb.jl")
include("treeda_xgb.jl")

include("xfit.jl")
include("scordis.jl")

# Discrimination 
include("dmnorm.jl")
include("rrda.jl")
include("lda.jl") ; include("qda.jl")
include("mlrda.jl")
include("plsrda.jl")
include("plslda.jl")
include("plsrda_avg.jl") 

# SVM
include("svmda.jl")

# Local regression
include("locw.jl")
include("knnr.jl")
include("lwplsr.jl")
include("lwplsr_avg.jl")
include("lwplsr_s.jl")
include("cplsr_avg.jl")  # Use structure PlsrDa

# Multiblock regresssion
include("angles.jl")
include("blockscal.jl")
include("mbplsr.jl") 
include("mbplsr_rosa.jl") 
include("mbplsr_so.jl") 

# Local discrimination
include("lwplsrda.jl") ; include("lwplslda.jl") ; include("lwplsqda.jl")
include("lwplsrda_avg.jl") ; include("lwplslda_avg.jl") ; include("lwplsqda_avg.jl")
include("knnda.jl")

# Variable selection/importance (direct methods) 
include("covsel.jl")
include("iplsr.jl")

# Validation
include("mpar.jl")
include("scores.jl")
include("gridscore.jl")
include("segm.jl") ; include("gridcv.jl")

# Transfer
include("caltransf_ds.jl")
include("caltransf_pds.jl")

# Sampling
include("sampling.jl")

include("distances.jl")
include("getknn.jl")
include("wdist.jl")
include("kernels.jl")

export 
    # Utilities
    aggstat,
    checkdupl, checkmiss,
    center, center!, 
    colmean, colnorm2, colstd, colsum, colvar,
    corm, covm, 
    datasets,
    dummy,
    ensure_df, ensure_mat,
    findmax_cla, 
    fweight,
    list, 
    matB, matW, 
    mblock,
    mweight, mweight!,
    nco,
    norm2,
    nro,
    pnames, psize,
    recodcat2int, replacebylev2, recodnum2cla,
    replacebylev,
    rmcol, rmrow, 
    rowmean, rowstd, rowsum,   
    scale, scale!,
    sourcedir,
    ssq,
    summ,
    tab, tabnum,
    vcol, vrow, 
   # Pre-processing
    caltransf_ds, caltransf_pds,
    eposvd,
    interpl, interpl_mon, 
    linear_int, quadratic_int, quadratic_spline, cubic_spline,
    mavg, mavg!, mavg_runmean, mavg_runmean!,
    rmgap, rmgap!,
    savgk, savgol, savgol!,
    snv, snv!, detrend, detrend!, fdif, fdif!,
    # Pca
    kpca,
    nipals,
    pcasvd, pcasvd!, pcaeigen, pcaeigen!, pcaeigenk, pcaeigenk!,
    rpmat_gauss, rpmat_li, rp,
    scordis, odis,
    # Multiblock Pca
    blockscal, blockscal_frob, blockscal_mfa,
    blockscal_ncol, blockscal_sd,
    lg,
    mbpca_comdim_s, mbpca_cons,
    rv,
    # Regression
    aov1,
    mlr, mlr!, mlrchol, mlrchol!, mlrpinv, mlrpinv!, mlrpinv_n, mlrpinv_n!,
    mlrvec!, mlrvec,
    plskern, plskern!, plsnipals, plsnipals!, 
    plsrosa, plsrosa!, plssimp, plssimp!,
    cglsr, cglsr!,
    pcr, 
    rr, rr!, rrchol, rrchol!,   
    krr, kplsr, kplsr!, dkplsr, dkplsr!,
    plsr_avg, plsr_avg!,
    dfplsr_cg, aicplsr,
    wshenk,
    svmr,   
    treer_xgb, rfr_xgb, xgboostr, vimp_xgb,
    baggr, baggr_vi, baggr_oob,
    # Multi-block
    mbplsr,
    mbplsr_rosa, mbplsr_rosa!,
    mbplsr_so,
    # Variable selection/importance (direct methods) 
    covsel,
    iplsr,
    #
    xfit, xfit!, xresid, xresid!,
    # Local regression
    locw, locwlv,
    knnr,
    lwplsr, lwplsr_avg, lwplsr_s,  
    cplsr_avg,
    # Discrimination
    dmnorm, dmnorm!,
    fda, fda!, fdasvd, fdasvd!,
    mlrda,
    rrda, krrda,
    lda, qda, 
    plsrda, kplsrda,
    plslda, plsqda,
    plsrda_avg, plslda_avg, plsqda_avg,
    svmda,
    treeda_xgb, rfda_xgb, xgboostda,
    # Local Discrimination
    lwplsrda, lwplslda, lwplsqda,
    lwplsrda_avg, lwplslda_avg, lwplsqda_avg,
    knnda,
    #
    transform, coef, predict,
    # Validation
    residreg, residcla, 
    ssr, msep, rmsep, bias, sep, cor2, r2, rpd, rpdr, mse, err,
    mpar,
    gridscore, gridscorelv, gridscorelb,
    segmts, segmkf,
    gridcv, gridcvlv, gridcvlb, 
    gridcv_mb, gridcvlv_mb,
    # Sampling
    sampks, sampdp, sampsys, sampclas,
    # Distances
    getknn, wdist, wdist!,
    euclsq, mahsq, mahsqchol,
    krbf, kpol,
    # Graphics
    plotsp
    # Not exported since surcharge:
    # - summary => Base.summary

end # End-Module




