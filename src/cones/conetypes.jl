# -------------------------------------
# abstract type defs
# -------------------------------------
abstract type AbstractCone{T} end

function Base.deepcopy(m::Type{<: AbstractCone{T}}) where {T}
    typeof(m)(deepcopy(m.dim))
end

# -------------------------------------
# Zero Cone
# -------------------------------------

struct ZeroCone{T} <: AbstractCone{T}

    dim::DefaultInt

    function ZeroCone{T}(dim::Integer) where {T}
        dim >= 1 || throw(DomainError(dim, "dimension must be positive"))
        new(dim)
    end

end

ZeroCone(args...) = ZeroCone{DefaultFloat}(args...)


# ------------------------------------
# Nonnegative Cone
# -------------------------------------

struct NonnegativeCone{T} <: AbstractCone{T}

    dim::DefaultInt

    #internal working variables for W and λ
    w::Vector{T}
    λ::Vector{T}

    function NonnegativeCone{T}(dim) where {T}

        dim >= 1 || throw(DomainError(dim, "dimension must be positive"))
        w = zeros(T,dim)
        λ = zeros(T,dim)
        return new(dim,w,λ)

    end

end

NonnegativeCone(args...) = NonnegativeCone{DefaultFloat}(args...)

# ----------------------------------------------------
# Second Order Cone
# ----------------------------------------------------

mutable struct SecondOrderCone{T} <: AbstractCone{T}

    dim::DefaultInt

    #internal working variables for W and its products
    w::Vector{T}

    #scaled version of (s,z)
    λ::Vector{T}

    #vectors for rank 2 update representation of W^2
    u::Vector{T}
    v::Vector{T}

    #additional scalar terms for rank-2 rep
    d::T
    η::T

    function SecondOrderCone{T}(dim::Integer) where {T}
        dim >= 2 ? new(dim) : throw(DomainError(dim, "dimension must be >= 2"))
        w = zeros(T,dim)
        λ = zeros(T,dim)
        u = zeros(T,dim)
        v = zeros(T,dim)
        d = one(T)
        η = zero(T)
        return new(dim,w,λ,u,v,d,η)
    end

end

SecondOrderCone(args...) = SecondOrderCone{DefaultFloat}(args...)

# ------------------------------------
# Positive Semidefinite Cone
# ------------------------------------

mutable struct PSDConeWork{T}

    cholS
    cholZ
    SVD
    U
    V
    λ
    R
    Rinv
    L1
    L2

    function PSDConeWork{T}(n::Int) where {T}

        (cholS,cholZ,SVD,U,V,L1,L2) = ntuple(x->nothing, 7)
        λ    = zeros(T,n)
        R    = zeros(T,n,n)
        Rinv = zeros(T,n,n)

        return new(cholS,cholZ,SVD,U,V,λ,R,Rinv,L1,L2)
    end
end

#PJG: PSDConeWork(args...) = PSDConeWork{DefaultFloat}(args...)

struct PSDCone{T} <: AbstractCone{T}

      n::DefaultInt  #this is the matrix dimension, i.e. representing n /times n
  numel::DefaultInt  #this is the total number of elements in the matrix

    #PJG: need some further structure here to maintain
    #working memory for all of the steps in computing R
    work::PSDConeWork{T}   #PJG: kludgey AF for now

    function PSDCone{T}(n) where {T}

        n >= 1   || throw(DomainError(dim, "dimension must be positive"))
        numel = n*n

        work = PSDConeWork{T}(n)

        return new(n,numel,work)

    end

end

PSDCone(args...) = PSDCone{DefaultFloat}(args...)

struct PSDTriangleCone{T} <: AbstractCone{T}

        n::DefaultInt  #this is the matrix dimension, i.e. representing n /times n
    numel::DefaultInt  #this is the total number of elements in the matrix

    #PJG: need some further structure here to maintain
    #working memory for all of the steps in computing R
    work::PSDConeWork{T}   #PJG: kludgey AF for now

    function PSDTriangleCone{T}(n) where {T}

        n >= 1 || throw(DomainError(dim, "dimension must be positive"))
        numel = (n*(n+1))>>1
        work = PSDConeWork{T}(n)

        return new(n,numel,work)

    end

end

PSDTriangleCone(args...) = PSDTriangleCone{DefaultFloat}(args...)


# -------------------------------------
# Enum and dict for user interface
# -------------------------------------
"""
    SupportedCones
An Enum of supported cone type for passing to [`setup!`](@ref). The currently
supported types are:

* `ZeroConeT`       : The zero cone.  Used to define equalities.
* `NonnegativeConeT`: The nonnegative orthant.
* `SecondOrderConeT`: The second order / Lorentz / ice-cream cone.
# `PSDConeT`        : The positive semidefinite cone.
"""
@enum SupportedCones begin
    ZeroConeT
    NonnegativeConeT
    SecondOrderConeT
    PSDConeT
end

"""
    ConeDict
A Dict that maps the user-facing SupportedCones enum values to
the types used internally in the solver.   See [SupportedCones](@ref)
"""
const ConeDict = Dict(
           ZeroConeT => ZeroCone,
    NonnegativeConeT => NonnegativeCone,
    SecondOrderConeT => SecondOrderCone,
            PSDConeT => PSDCone,
)
