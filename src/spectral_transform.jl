"""SpectralTransform struct that contains all parameters and preallocated arrays
for the spectral transform."""
struct SpectralTransform{NF<:AbstractFloat}

    # GRID
    grid::Type{<:AbstractGrid}  # grid type used
    nresolution::Int            # resolution parameter of grid

    # SPECTRAL RESOLUTION
    lmax::Int       # Maximum degree l=[0,lmax] of spherical harmonics
    mmax::Int       # Maximum order m=[0,l] of spherical harmonics
    nfreq::Int      # Number of fourier frequencies (real FFT)
    nfreq_max::Int

    # CORRESPONDING GRID SIZE
    nlon::Int               # Maximum number of longitude points (at Equator)
    # nlons::Vector{Int}      # Number of longitude points per latitude ring
    nlat::Int               # Number of latitude rings
    nlat_half::Int          # nlat on one hemisphere (incl equator if nlat odd)
    
    # CORRESPONDING GRID VECTORS
    colat::Vector{NF}       # Gaussian colatitudes (0,π) North to South Pole 
    cos_colat::Vector{NF}   # Cosine of colatitudes
    sin_colat::Vector{NF}   # Sine of colatitudes

    # Offset of first longitude from prime meridian (function of m and latitude)
    lon_offsets::Matrix{Complex{NF}}

    # NORMALIZATION
    norm_sphere::NF         # normalization of the l=0,m=0 mode
    norm_forward::NF        # normalization of the Legendre weights for forward transform (spectral)

    # FFT plans
    nlons::Vector{Int}                      # number of longitude points per ring
    rfft_plan::FFTW.rFFTWPlan{NF}           # FFT plan for grid to spectral transform
    brfft_plan::FFTW.rFFTWPlan{Complex{NF}} # spectral to grid transform (inverse)
    rfft_plans::Vector{FFTW.rFFTWPlan{NF}}  # one plan for each latitude ring for variable nlon
    brfft_plans::Vector{FFTW.rFFTWPlan{Complex{NF}}}

    # GRID INDICES
    ring_indices_1st::Vector{Int}           # for each latitude ring the first and last index in
    ring_indices_end::Vector{Int}           # grid.v data vector spanning all longitudes per ring

    # LEGENDRE POLYNOMIALS
    recompute_legendre::Bool                # Pre or recompute Legendre polynomials
    Λ::LowerTriangularMatrix{Float64}       # Legendre polynomials for one latitude (requires recomputing)
    Λs::Vector{LowerTriangularMatrix{NF}}   # Legendre polynomials for all latitudes (all precomputed)
    
    # QUADRATURE (integration for the Legendre polynomials, extra normalisation of π/nlat included)
    quadrature_weights::Vector{NF}

    # RECURSION FACTORS
    ϵlms::LowerTriangularMatrix{NF}         # precomputed for meridional gradients gradients grad_y1, grad_y2

    # GRADIENT MATRICES (on unit sphere, no 1/radius-scaling included)
    grad_x ::Vector{Complex{NF}}            # = i*m but precomputed
    grad_y1::LowerTriangularMatrix{NF}      # precomputed meridional gradient factors, term 1
    grad_y2::LowerTriangularMatrix{NF}      # term 2

    # GRADIENT MATRICES FOR U,V -> Vorticity,Divergence
    grad_y_vordiv1::LowerTriangularMatrix{NF}
    grad_y_vordiv2::LowerTriangularMatrix{NF}

    # GRADIENT MATRICES FOR Vorticity,Divergence -> U,V
    vordiv_to_uv_x::LowerTriangularMatrix{NF}
    vordiv_to_uv1::LowerTriangularMatrix{NF}
    vordiv_to_uv2::LowerTriangularMatrix{NF}

    # EIGENVALUES (on unit sphere, no 1/radius²-scaling included)
    eigenvalues  ::Vector{NF}               # = -l*(l+1), degree l of spherical harmonic
    eigenvalues⁻¹::Vector{NF}               # = -1/(l*(l+1))
end

"""
    S = SpectralTransform(NF,grid,trunc,recompute_legendre)

Generator function for a SpectralTransform struct. With `NF` the number format,
`grid` the grid type `<:AbstractGrid` and spectral truncation `trunc` this function sets up
necessary constants for the spetral transform. Also plans the Fourier transforms, retrieves the colatitudes,
and preallocates the Legendre polynomials (if recompute_legendre == false) and quadrature weights."""
function SpectralTransform( ::Type{NF},                     # Number format NF
                            grid::Type{<:AbstractGrid},     # type of spatial grid used
                            trunc::Int,                     # Spectral truncation
                            recompute_legendre::Bool) where NF

    # SPECTRAL RESOLUTION
    lmax = trunc                # Maximum degree l=[0,lmax] of spherical harmonics
    mmax = trunc                # Maximum order m=[0,l] of spherical harmonics

    # RESOLUTION PARAMETERS
    nresolution = get_resolution(grid,trunc)        # resolution parameter, nlat_half/nside for HEALPixGrid
    nlat_half = get_nlat_half(grid,nresolution)     # contains equator for HEALPix
    nlat = 2nlat_half - nlat_odd(grid)              # one less if grids have odd # of latitude rings
    nlon = get_nlon(grid,nresolution)               # number of longitudes around the equator
    nfreq     = nlon÷2 + 1                          # maximum number of fourier frequencies (real FFTs)
    nfreq_max = nlon÷2 + 1                          # maximum number of fourier frequencies (real FFTs)
    # nside = grid isa HEALPixGrid ? nresolution : 0  # nside is only defined for HEALPixGrid (npoints)
    # npoints = get_npoints(grid,nresolution)         # total number of grid points

    # LATITUDE VECTORS (based on Gaussian, equi-angle or HEALPix latitudes)
    colat = get_colat(grid,nresolution)             # colatitude in radians                             
    cos_colat = cos.(colat)
    sin_colat = sin.(colat)                             

    # NORMALIZATION
    norm_sphere = 2sqrt(π)      # norm_sphere at l=0,m=0 translates to 1s everywhere in grid space
    norm_forward = π/nlat       # normalization for forward transform to be baked into the quadrature weights

    # PLAN THE FFTs
    nlons = [get_nlon_per_ring(grid,nresolution,i) for i in 1:nlat_half]
    rfft_plan = FFTW.plan_rfft(zeros(NF,nlon))
    brfft_plan = FFTW.plan_brfft(zeros(Complex{NF},nlon÷2+1),nlon)
    rfft_plans = [FFTW.plan_rfft(zeros(NF,nlon)) for nlon in nlons]
    brfft_plans = [FFTW.plan_brfft(zeros(Complex{NF},nlon÷2+1),nlon) for nlon in nlons]

    # GRID INDICES PER RING
    ring_indices_1st = get_first_index_per_ring(grid,nresolution)
    ring_indices_end =  get_last_index_per_ring(grid,nresolution)

    # LONGITUDE OFFSETS OF FIRST GRID POINT PER RING (not for full and octahedral grids)
    _, lons = get_colatlons(grid,nresolution)
    lon0s = lons[ring_indices_1st[1:nlat_half]]
    lon_offsets = [cispi(m*lon0/π) for m in 0:mmax, lon0 in lon0s]

    # PREALLOCATE LEGENDRE POLYNOMIALS, lmax+2 for one more degree l for meridional gradient recursion
    Λ = zeros(LowerTriangularMatrix,lmax+2,mmax+1)  # Legendre polynomials for one latitude

    # allocate memory in Λs for polynomials at all latitudes or allocate dummy array if precomputed
    # Λs is of size (lmax+2) x (mmax+1) x nlat_half unless recomputed, one more degree l as before
    # for recomputed only Λ is used, not Λs, create dummy array of size 1x1x1 instead
    b = ~recompute_legendre                 # true for precomputed
    Λs = [zeros(LowerTriangularMatrix,b*(lmax+2),b*(mmax+1)) for _ in 1:b*nlat_half]

    if recompute_legendre == false          # then precompute all polynomials
        for ilat in 1:nlat_half             # only one hemisphere due to symmetry
            Legendre.λlm!(Λs[ilat], lmax+1, mmax, cos_colat[ilat])
            # underflow_small!(Λs[ilat],sqrt(floatmin(NF)))
        end
    end

    # QUADRATURE WEIGHTS (Gaussian, Clenshaw-Curtis, or Riemann depending on grid)
    quadrature_weights = get_quadrature_weights(grid,nresolution)
    quadrature_weights *= norm_forward

    # RECURSION FACTORS
    ϵlms = get_recursion_factors(lmax+1,mmax)

    # GRADIENTS (on unit sphere, hence 1/radius-scaling is omitted)
    grad_x = [im*m for m in 0:mmax+1]       # zonal gradient (precomputed currently not used)

    # meridional gradient for scalars (coslat scaling included)
    grad_y1 = zeros(LowerTriangularMatrix,lmax+2,mmax+1)          # term 1, mul with harmonic l-1,m
    grad_y2 = zeros(LowerTriangularMatrix,lmax+2,mmax+1)          # term 2, mul with harmonic l+1,m

    for m in 0:mmax                         # 0-based degree l, order m
        for l in m:lmax+1           
            grad_y1[l+1,m+1] = -(l-1)*ϵlms[l+1,m+1]
            grad_y2[l+1,m+1] = (l+2)*ϵlms[l+2,m+1]
        end
    end

    # meridional gradient used to get from u,v/coslat to vorticity and divergence
    grad_y_vordiv1 = zeros(LowerTriangularMatrix,lmax+2,mmax+1)   # term 1, mul with harmonic l-1,m
    grad_y_vordiv2 = zeros(LowerTriangularMatrix,lmax+2,mmax+1)   # term 2, mul with harmonic l+1,m

    for m in 0:mmax                         # 0-based degree l, order m
        for l in m:lmax+1           
            grad_y_vordiv1[l+1,m+1] = (l+1)*ϵlms[l+1,m+1]
            grad_y_vordiv2[l+1,m+1] = l*ϵlms[l+2,m+1]
        end
    end

    # zonal integration (sort of) to get from vorticity and divergence to u,v*coslat
    vordiv_to_uv_x = LowerTriangularMatrix([-m/(l*(l+1)) for l in 0:lmax+1, m in 0:mmax])
    vordiv_to_uv_x[1,1] = 0

    # meridional integration (sort of) to get from vorticity and divergence to u,v*coslat
    vordiv_to_uv1 = zeros(LowerTriangularMatrix,lmax+2,mmax+1)    # term 1, to be mul with harmonic l-1,m
    vordiv_to_uv2 = zeros(LowerTriangularMatrix,lmax+2,mmax+1)    # term 2, to be mul with harmonic l+1,m

    for m in 0:mmax                         # 0-based degree l, order m
        for l in m:lmax+1           
            vordiv_to_uv1[l+1,m+1] = ϵlms[l+1,m+1]/l
            vordiv_to_uv2[l+1,m+1] = ϵlms[l+2,m+1]/(l+1)
        end
    end

    vordiv_to_uv1[1,1] = 0                  # remove NaN from 0/0

    # EIGENVALUES (on unit sphere, hence 1/radius²-scaling is omitted)
    eigenvalues = [-l*(l+1) for l in 0:lmax+1]
    eigenvalues⁻¹ = inv.(eigenvalues)
    eigenvalues⁻¹[1] = 0                    # set the integration constant to 0
        
    # conversion to NF happens here
    SpectralTransform{NF}(  grid,nresolution,
                            lmax,mmax,nfreq,nfreq_max,
                            nlon,nlat,nlat_half,
                            colat,cos_colat,sin_colat,lon_offsets,
                            norm_sphere,norm_forward,
                            nlons,rfft_plan,brfft_plan,rfft_plans,brfft_plans,
                            ring_indices_1st,ring_indices_end,
                            recompute_legendre,Λ,Λs,quadrature_weights,
                            ϵlms,grad_x,grad_y1,grad_y2,
                            grad_y_vordiv1,grad_y_vordiv2,vordiv_to_uv_x,
                            vordiv_to_uv1,vordiv_to_uv2,
                            eigenvalues,eigenvalues⁻¹)
end

"""
    S = SpectralTransform(P::Parameters)

Generator function for a SpectralTransform struct pulling in parameters from a Parameters struct."""
function SpectralTransform(P::Parameters)
    @unpack NF, grid, trunc, recompute_legendre = P
    return SpectralTransform(NF,grid,trunc,recompute_legendre)
end

"""
    ϵ = ϵ(NF,l,m) 

Recursion factors `ϵ` as a function of degree `l` and order `m` (0-based) of the spherical harmonics.
ϵ(l,m) = sqrt((l^2-m^2)/(4*l^2-1)) and then converted to number format NF."""
function ϵlm(::Type{NF},l::Int,m::Int) where NF
    return convert(NF,sqrt((l^2-m^2)/(4*l^2-1)))
end

"""
    ϵ = ϵ(l,m) 

Recursion factors `ϵ` as a function of degree `l` and order `m` (0-based) of the spherical harmonics.
ϵ(l,m) = sqrt((l^2-m^2)/(4*l^2-1)) with default number format Float64."""
ϵlm(l::Int,m::Int) = ϵlm(Float64,l,m)

"""
    get_recursion_factors(  ::Type{NF}, # number format NF
                            lmax::Int,  # max degree l of spherical harmonics (0-based here)
                            mmax::Int   # max order m of spherical harmonics
                            ) where {NF<:AbstractFloat}
        
Returns a matrix of recursion factors `ϵ` up to degree `lmax` and order `mmax` of number format `NF`."""
function get_recursion_factors( ::Type{NF}, # number format NF
                                lmax::Int,  # max degree l of spherical harmonics (0-based here)
                                mmax::Int   # max order m of spherical harmonics
                                ) where {NF<:AbstractFloat}

    # preallocate array with one more l for meridional gradients
    ϵlms = zeros(LowerTriangularMatrix{NF},lmax+2,mmax+1)      
    for m in 1:mmax+1                   # loop over 1-based l,m
        for l in m:lmax+2
            ϵlms[l,m] = ϵlm(NF,l-1,m-1) # convert to 0-based l,m for function call
        end
    end
    return ϵlms
end

# if number format not provided use Float64
get_recursion_factors(lmax::Int,mmax::Int) = get_recursion_factors(Float64,lmax,mmax)

"""
    gridded!(map,alms,S)

Backward or inverse spectral transform (spectral to grid space) from coefficients `alms` and SpectralTransform
struct `S` into the preallocated output `map`. Uses a planned inverse Fast Fourier Transform for efficiency in the
zonal direction and a Legendre Transform in the meridional direction exploiting symmetries for effciency.
Either recomputes the Legendre polynomials to save memory, or uses precomputed polynomials from `S` depending on
`S.recompute_legendre`."""
function gridded!(  map::AbstractMatrix{NF},                    # gridded output
                    alms::LowerTriangularMatrix{Complex{NF}},   # spectral coefficients input
                    S::SpectralTransform{NF}                    # precomputed parameters struct
                    ) where {NF<:AbstractFloat}                 # number format NF

    @unpack nlat, nlat_half, nfreq = S
    @unpack cos_colat = S
    @unpack recompute_legendre, Λ, Λs = S
    @unpack brfft_plan = S

    recompute_legendre && @boundscheck size(alms) == size(Λ) || throw(BoundsError)
    recompute_legendre || @boundscheck size(alms) == size(Λs[1]) || throw(BoundsError)
    lmax, mmax = size(alms) .- 1            # maximum degree l, order m of spherical harmonics

    @boundscheck mmax+1 <= nfreq || throw(BoundsError)
    @boundscheck nlat == length(cos_colat) || throw(BoundsError)

    # preallocate work arrays
    gn = zeros(Complex{NF}, nfreq)          # phase factors for northern latitudes
    gs = zeros(Complex{NF}, nfreq)          # phase factors for southern latitudes

    Λw = Legendre.Work(Legendre.λlm!, Λ, Legendre.Scalar(zero(NF)))

    @inbounds for ilat in 1:nlat_half       # symmetry: loop over northern latitudes (possibly incl Equator) only
        ilat_s = nlat - ilat + 1            # southern latitude index

        # Recalculate or use precomputed Legendre polynomials Λ
        Λ_ilat = recompute_legendre ? Legendre.unsafe_legendre!(Λw, Λ, lmax, mmax, cos_colat[ilat]) : Λs[ilat]

        # inverse Legendre transform by looping over wavenumbers l,m
        lm = 1                              # single index for non-zero l,m indices in LowerTriangularMatrix
        for m in 1:mmax+1                   # Σ_{m=0}^{mmax}, but 1-based index
            acc_odd  = zero(Complex{NF})    # accumulator for isodd(l+m)
            acc_even = zero(Complex{NF})    # accumulator for iseven(l+m)

            # integration over l = m:lmax+1
            lm_end = lm + lmax-m+1                  # first index lm plus lmax-m+1 (length of column minus 1)
            even_degrees = iseven(lm+lm_end)        # is there an even number of degrees in column m?

            # anti-symmetry: sign change of odd harmonics on southern hemisphere
            # but put both into one loop for contiguous memory access
            for lm_even in lm:2:lm_end-even_degrees     
                # split into even, i.e. iseven(l+m)
                # acc_even += alms[lm_even] * Λ_ilat[lm_even], but written with muladd
                acc_even = muladd(alms[lm_even],Λ_ilat[lm_even],acc_even)

                # and odd (isodd(l+m)) harmonics
                # acc_odd += alms[lm_odd] * Λ_ilat[lm_odd], but written with muladd
                acc_odd = muladd(alms[lm_even+1],Λ_ilat[lm_even+1],acc_odd)
            end

            # for even number of degrees, one acc_even iteration is skipped, do now
            acc_even = even_degrees ? muladd(alms[lm_end],Λ_ilat[lm_end],acc_even) : acc_even

            gn[m] += (acc_even + acc_odd)           # accumulators for northern
            gs[m] += (acc_even - acc_odd)           # and southern hemisphere

            lm = lm_end + 1                         # first index of next m column
        end

        # Inverse Fourier transform in zonal direction
        LinearAlgebra.mul!(@view(map[:,ilat]),  brfft_plan,gn)  # Northern latitude
        LinearAlgebra.mul!(@view(map[:,ilat_s]),brfft_plan,gs)  # Southern latitude

        fill!(gn, zero(Complex{NF}))        # set phase factors back to zero
        fill!(gs, zero(Complex{NF}))
    end

    return map
end

@inline function alias_index(   nlon::Int,  # number of longitude points
                                m::Int)     # order m of harmonics (=zonal wavenumber)
    
    # equatorial zone, zonal wavenumber m is smaller than Nyquist = no aliasing
    isconj, isnyq = false, false
    nyq = max(1, nlon ÷ 2)                  # Nyquist frequency
    m < nyq && return (m, isconj, isnyq)    # escape for equatorial zone
    
    # if zonal wavenumber m is >= Nyquist than alias, and indicate conjugate
    # or real doubling through isconj and isnyq
    m = mod(m, nlon)
    m, isconj = m > nyq ? (nlon-m, true) : (m,isconj)   # alias m and conjugate
    isnyq = m == 0 || (iseven(nlon) && m == nyq)        # is Nyquist frequency?
    return (m, isconj, isnyq)
end


@inline function alias_coeffs(  cn::Complex{<:AbstractFloat},
                                cs::Complex{<:AbstractFloat},
                                isconj::Bool,
                                isnyq::Bool)

    cn, cs = isnyq  ? (2*real(cn),2*real(cs)) : (cn, cs)    # real double for Nyquist freq
    cn, cs = isconj ? (conj(cn),conj(cs)) : (cn, cs)        # complex conjugate for m>Nyquist
    return acc_n
end

function gridded!(  map::AbstractGrid{NF},                      # gridded output
                    alms::LowerTriangularMatrix{Complex{NF}},   # spectral coefficients input
                    S::SpectralTransform{NF}                    # precomputed parameters struct
                    ) where {NF<:AbstractFloat}                 # number format NF

    @unpack nlat, nlons, nlat_half, nfreq_max = S
    @unpack cos_colat, lon_offsets = S
    @unpack recompute_legendre, Λ, Λs = S
    @unpack brfft_plans = S
    @unpack ring_indices_1st, ring_indices_end = S

    recompute_legendre && @boundscheck size(alms) == size(Λ) || throw(BoundsError)
    recompute_legendre || @boundscheck size(alms) == size(Λs[1]) || throw(BoundsError)
    lmax, mmax = size(alms) .- 1            # maximum degree l, order m of spherical harmonics

    @boundscheck mmax+1 <= nfreq_max || throw(BoundsError)
    @boundscheck nlat == length(cos_colat) || throw(BoundsError)
    @boundscheck typeof(map) <: S.grid || throw(BoundsError)
    @boundscheck get_nresolution(map) == S.nresolution || throw(BoundsError)

    # preallocate work arrays
    gn = zeros(Complex{NF}, nfreq_max)      # phase factors for northern latitudes
    gs = zeros(Complex{NF}, nfreq_max)      # phase factors for southern latitudes

    Λw = Legendre.Work(Legendre.λlm!, Λ, Legendre.Scalar(zero(NF)))

    @inbounds for ilat_n in 1:nlat_half     # symmetry: loop over northern latitudes only
        ilat_s = nlat - ilat_n + 1          # southern latitude index
        nlon = nlons[ilat_n]                # number of longitudes on this ring
        nfreq = nlon÷2 + 1                  # max Fourier frequency wrt to nlon

        # Recalculate or use precomputed Legendre polynomials Λ
        Λ_ilat = recompute_legendre ? 
            Legendre.unsafe_legendre!(Λw, Λ, lmax, mmax, cos_colat[ilat]) : Λs[ilat_n]

        # inverse Legendre transform by looping over wavenumbers l,m
        lm = 1                              # single index for non-zero l,m indices
        for m in 1:mmax+1                   # Σ_{m=0}^{mmax}, but 1-based index
            acc_odd  = zero(Complex{NF})    # accumulator for isodd(l+m)
            acc_even = zero(Complex{NF})    # accumulator for iseven(l+m)

            # integration over l = m:lmax+1
            lm_end = lm + lmax-m+1              # first index lm plus lmax-m+1 (length of column -1)
            even_degrees = iseven(lm+lm_end)    # is there an even number of degrees in column m?

            # anti-symmetry: sign change of odd harmonics on southern hemisphere
            # but put both into one loop for contiguous memory access
            for lm_even in lm:2:lm_end-even_degrees     
                # split into even, i.e. iseven(l+m)
                # acc_even += alms[lm_even] * Λ_ilat[lm_even], but written with muladd
                acc_even = muladd(alms[lm_even],Λ_ilat[lm_even],acc_even)

                # and odd (isodd(l+m)) harmonics
                # acc_odd += alms[lm_odd] * Λ_ilat[lm_odd], but written with muladd
                acc_odd = muladd(alms[lm_even+1],Λ_ilat[lm_even+1],acc_odd)
            end

            # for even number of degrees, one acc_even iteration is skipped, do now
            acc_even = even_degrees ? muladd(alms[lm_end],Λ_ilat[lm_end],acc_even) : acc_even

            # CORRECT FOR LONGITUDE OFFSETTS
            w = lon_offsets[m,ilat_n]           # longitude offset rotation
            acc_n = (acc_even + acc_odd)*w      # accumulators for northern
            acc_s = (acc_even - acc_odd)*w      # and southern hemisphere
            
            # ALIAS ZONAL WAVENUMBERS
            m_alias, isconj, isnyq = alias_index(nlon, m)   # polar zones, alias m if > Nyquist
            acc_n, acc_s = alias_coeffs(acc_n, acc_s, isconj, isnyq)

            gn[m_alias] += acc_n                # accumulate in phase factors for northern
            gs[m_alias] += acc_s                # and southern hemisphere

            lm = lm_end + 1                     # first index of next m column
        end

        # Inverse Fourier transform in zonal direction
        brfft_plan = brfft_plans[ilat_n]        # FFT planned wrt nlon on ring
        js = each_index_in_ring(map,ilat_n)     # in-ring indices northern ring
        LinearAlgebra.mul!(view(map.v,js),brfft_plan,view(gn,1:nfreq))  # perform FFT

        js = each_index_in_ring(map,ilat_s)     # in-ring indices southern ring
        LinearAlgebra.mul!(view(map.v,js),brfft_plan,view(gs,1:nfreq))  # perform FFT

        fill!(gn, zero(Complex{NF}))                        # set phase factors back to zero
        fill!(gs, zero(Complex{NF}))
    end

    return map
end

"""
    spectral!(alms,map,S)

Forward spectral transform (grid to spectral space) from the gridded field `map` on a regular Gaussian
grid (with Gaussian latitudes). Uses a planned real-valued Fast Fourier Transform in the zonal direction,
and a Legendre Transform in the meridional direction exploiting symmetries.Either recomputes the Legendre
polynomials `Λ` for each latitude on one hemisphere or uses precomputed polynomials from `S.Λs`, depending
on `S.recompute_legendre`. Further uses Legendre weights on Gaussian latitudes for a leakage-free
transform."""
function spectral!( alms::LowerTriangularMatrix{Complex{NF}},   # output: spectral coefficients
                    map::AbstractMatrix{NF},                    # input: gridded values
                    S::SpectralTransform{NF}
                    ) where {NF<:AbstractFloat}
    
    @unpack nlat, nlat_half, nfreq = S
    @unpack cos_colat, sin_colat = S
    @unpack recompute_legendre, Λ, Λs, quadrature_weights = S
    @unpack rfft_plan = S
    
    recompute_legendre && @boundscheck size(alms) == size(Λ) || throw(BoundsError)
    recompute_legendre || @boundscheck size(alms) == size(Λs[1]) || throw(BoundsError)

    lmax, mmax = size(alms) .- 1            # maximum degree l, order m of spherical harmonics
    nlon, nlat = size(map)                  # number of longitudes, latitudes in grid space
    nlat_half = (nlat+1) ÷ 2                # half the number of longitudes
    nfreq = nlon÷2 + 1                      # Number of fourier frequencies (real FFTs)
    @boundscheck mmax+1 <= nfreq || throw(BoundsError)

    # preallocate work warrays
    fn = zeros(Complex{NF},nfreq)   # Fourier-transformed northern latitude
    fs = zeros(Complex{NF},nfreq)   # Fourier-transformed southern latitude

    # partial sums are accumulated in alms, force zeros initially.
    fill!(alms,0)

    Λw = Legendre.Work(Legendre.λlm!, Λ, Legendre.Scalar(zero(NF)))

    @inbounds for ilat in 1:nlat_half   # symmetry: loop over northern latitudes only
        ilat_s = nlat - ilat + 1        # corresponding southern latitude index

        # Fourier transform in zonal direction
        LinearAlgebra.mul!(fn, rfft_plan, @view(map[:,ilat]))       # Northern latitude
        LinearAlgebra.mul!(fs, rfft_plan, @view(map[:,ilat_s]))     # Southern latitude

        # Legendre transform in meridional direction
        # Recalculate or use precomputed Legendre polynomials Λ
        Λ_ilat = recompute_legendre ?
            Legendre.unsafe_legendre!(Λw, Λ, lmax, mmax, cos_colat[ilat]) : Λs[ilat]
        quadrature_weight = quadrature_weights[ilat]                # weights normalised with π/nlat

        lm = 1                                          # single index for spherical harmonics
        for m in 1:mmax+1                               # Σ_{m=0}^{mmax}, but 1-based index
            an = fn[m] * quadrature_weight              # weighted northern latitude
            as = fs[m] * quadrature_weight              # weighted southern latitude
            a_even = an + as                            # sign flip due to anti-symmetry with
            a_odd = an - as                             # odd polynomials 

            # integration over l = m:lmax+1
            lm_end = lm + lmax-m+1                      # first index lm plus lmax-m+1 (length of column -1)
            even_degrees = iseven(lm+lm_end)            # is there an even number of degrees in column m?
            
            # anti-symmetry: sign change of odd harmonics on southern hemisphere
            # but put both into one loop for contiguous memory access
            for lm_even in lm:2:lm_end-even_degrees
                # split into even, i.e. iseven(l+m)
                # alms[lm_even] += a_even * Λ_ilat[lm_even], but written with muladd
                alms[lm_even] = muladd(a_even,Λ_ilat[lm_even],alms[lm_even])
                
                # and odd (isodd(l+m)) haxwxwrmonics
                # alms[lm_odd] += a_odd * Λ_ilat[lm_odd], but written with muladd
                alms[lm_even+1] = muladd(a_odd,Λ_ilat[lm_even+1],alms[lm_even+1])
            end

            # for even number of degrees, one even iteration is skipped, do now
            alms[lm_end] = even_degrees ? muladd(a_even,Λ_ilat[lm_end],alms[lm_end]) : alms[lm_end]

            lm = lm_end + 1                             # first index of next m column
        end
    end

    return alms
end

"""
    map = gridded(alms)

Backward or inverse spectral transform (spectral to grid space) from coefficients `alms`. Based on the size
of `alms` the corresponding grid space resolution is retrieved based on triangular truncation and a 
SpectralTransform struct `S` is allocated to execute `gridded(alms,S)`."""
function gridded(   alms::AbstractMatrix{Complex{NF}};  # spectral coefficients
                    recompute_legendre::Bool=true,      # saves memory
                    grid::Type{<:AbstractGrid}=FullGaussianGrid,
                    ) where NF                          # number format NF

    _, mmax = size(alms) .- 1                           # -1 for 0-based degree l, order m
    S = SpectralTransform(NF,grid,mmax,recompute_legendre)
    return gridded(alms,S)
end

"""
    map = gridded(alms,S)

Backward or inverse spectral transform (spectral to grid space) from coefficients `alms` and the 
SpectralTransform struct `S`. Allocates the output `map` with Gaussian latitudes and executes
`gridded!(map,alms,S)`."""
function gridded(   alms::AbstractMatrix{Complex{NF}},  # spectral coefficients
                    S::SpectralTransform{NF}            # struct for spectral transform parameters
                    ) where NF                          # number format NF

    output = Matrix{NF}(undef,S.nlon,S.nlat)    # preallocate output
    input = LowerTriangularMatrix(alms)         # drop the upper triangle entries
    gridded!(output,input,S)                    # now execute the in-place version
    return output
end

"""
    alms = spectral(map)

Forward spectral transform (grid to spectral space) from the gridded field `map` on a regular Gaussian
grid (with Gaussian latitudes) into the spectral coefficients of the Legendre polynomials `alms`. Based
on the size of `map` this function retrieves the corresponding spectral resolution via triangular
truncation and sets up a SpectralTransform struct `S` to execute `spectral(map,S)`."""
function spectral(  map::AbstractMatrix{NF};        # gridded field nlon x nlat
                    recompute_legendre::Bool=true,  # saves memory
                    grid::Type{<:AbstractGrid}=FullGaussianGrid
                    ) where NF                      # number format NF

    # check grid is compatible with triangular spectral truncation
    nlon, nlat = size(map)
    @boundscheck nlon == 2nlat || throw(BoundsError)
    @boundscheck iseven(nlat) || throw(BoundsError)
    nlat_half = nlat÷2
    trunc = get_truncation(grid,nlat_half)

    S = SpectralTransform(NF,grid,trunc,recompute_legendre)
    return spectral(map,S)
end

"""
    alms = spectral(map,S)

Forward spectral transform (grid to spectral space) from the gridded field `map` on a regular Gaussian
grid (with Gaussian latitudes) and the SpectralTransform struct `S` into the spectral coefficients of
the Legendre polynomials `alms`. This function allocates `alms` and executes `spectral!(alms,map,S)`."""
function spectral(  map::AbstractMatrix{NF},    # gridded field nlon x nlat
                    S::SpectralTransform{NF},   # spectral transform struct
                    ) where NF                  # number format NF

    # check grid is compatible with triangular spectral truncation
    nlon, nlat = size(map)
    @boundscheck nlon == 2nlat || throw(BoundsError)
    @boundscheck nlon == S.nlon || throw(BoundsError)

    # always use one more l for consistency with vector quantities and 
    alms = LowerTriangularMatrix{Complex{NF}}(undef,S.lmax+2,S.mmax+1)
    return spectral!(alms,map,S)                # in-place version
end