module PSDModels

using LinearAlgebra, SparseArrays
using KernelFunctions: Kernel
using ProximalOperators: IndPSD, prox, prox!
using ProximalAlgorithms: FastForwardBackward
import Base

export PSDModel

struct PSDModel{T<:Number}
    B::Hermitian{T, Matrix{T}}  # A is the PSD so that f(x) = ∑_ij k(x, x_i) * A * k(x, x_j)
    k::Kernel                   # k(x, y) is the kernel function
    X::Vector{T}                # X is the set of points for the feature map
end


function PSDModel(
                X::Vector{T}, 
                Y::Vector{T}, 
                k::Kernel;
                solver=:direct,
                kwargs...
            ) where {T<:Number}
    if solver == :direct
        return PSDModel_direct(X, Y, k; kwargs...)
    if solver == :gradient_descent
        @error "Solver not implemented"
        return nothing
    else
        @error "Solver not implemented"
        return nothing
    end
end

function PSDModel_gradient_descent(
                        X::Vector{T},
                        Y::Vector{T},
                        k::Kernel;
                    ) where {T<:Number}
    K = T[k(x, y) for x in X, y in X]
    K = Hermitian(K)
    
    f_A(A) = @error("TODO")
    grad(A) = @error("TODO")

    psd_constraint = IndPSD()

    solver = ProximalAlgorithms.FastForwardBackward(maxit=1000, tol=1e-5, verbose=true)
    solution, iterations = solver(x0=nothing, f=f_A, g=psd_constraint)

end

function PSDModel_direct(
                X::Vector{T}, 
                Y::Vector{T}, 
                k::Kernel;
                regularize_kernel=true,
                cond_thresh=1e10,
                λ_1=1e-8,
                trace=false,
            ) where {T<:Number}
    K = T[k(x, y) for x in X, y in X]
    K = Hermitian(K)

    trace && @show cond(K)

    if regularize_kernel && (cond(K) > cond_thresh)
        K += λ_1 * I
        if trace
            @show "Kernel has been regularized"
            @show λ_1
            @show cond(K)
        end
    end
    
    @assert isposdef(K)
    
    V = cholesky(K)
    V_inv = inv(V)

    A = Hermitian(spdiagm(Y))
    B = Hermitian((V_inv' * A * V_inv))

    # project B onto the PSD cone, just in case
    B, _ = prox(IndPSD(), B)

    return PSDModel{T}(B, k, X)
end


function (a::PSDModel)(x::T) where {T<:Number}
    v = a.k.(Ref(x), a.X)
    return v' * a.B * v
end

function Base.:+(a::PSDModel, 
                b::PSDModel)
    @error "Not implemented"
    return nothing
end

function Base.:-(
    a::PSDModel,
    b::PSDModel
)
    @error "Not implemented"
    return nothing
end

Base.:*(a::PSDModel, b::Number) = b * a
function Base.:*(a::Number, b::PSDModel)
    return PSDModel(
        a * b.B,
        b.k,
        b.X
    )
end

function Base.:*(
    a::PSDModel,
    b::PSDModel
)
    @error "Not implemented"
    return nothing
end

end # module PositiveSemidefiniteModels
