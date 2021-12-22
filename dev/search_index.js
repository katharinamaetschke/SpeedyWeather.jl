var documenterSearchIndex = {"docs":
[{"location":"functions/#Function-and-type-index","page":"Function and type index","title":"Function and type index","text":"","category":"section"},{"location":"functions/#Parameters-and-constants","page":"Function and type index","title":"Parameters and constants","text":"","category":"section"},{"location":"functions/","page":"Function and type index","title":"Function and type index","text":"Params\nConstants","category":"page"},{"location":"functions/#SpeedyWeather.Params","page":"Function and type index","title":"SpeedyWeather.Params","text":"Parameter struct that holds all parameters that define the default model setup. With keywords such that default values can be changed at creation.\n\n\n\n\n\n","category":"type"},{"location":"functions/#SpeedyWeather.Constants","page":"Function and type index","title":"SpeedyWeather.Constants","text":"Struct holding the parameters needed at runtime in number format NF.\n\n\n\n\n\n","category":"type"},{"location":"functions/#Boundaries","page":"Function and type index","title":"Boundaries","text":"","category":"section"},{"location":"functions/","page":"Function and type index","title":"Function and type index","text":"Boundaries","category":"page"},{"location":"functions/#SpeedyWeather.Boundaries","page":"Function and type index","title":"SpeedyWeather.Boundaries","text":"Struct that holds the boundary arrays in grid-point space\n\nϕ0::Array{NF,2}              # surface geopotential [m^2/s^2]\nϕ0trunc::Array{NF,2}         # spectrally truncated surface geopotential [m^2/s^2]\nland_sea_mask::Array{NF,2}   # land-sea mask\nalbedo::Array{NF,2}          # annual mean surface albedo\n\n\n\n\n\n","category":"type"},{"location":"functions/#Spectral-transform","page":"Function and type index","title":"Spectral transform","text":"","category":"section"},{"location":"functions/","page":"Function and type index","title":"Function and type index","text":"Geometry\nfourier\nfourier_inverse\nlegendre\nlegendre_inverse\nspectral\ngridded","category":"page"},{"location":"functions/#SpeedyWeather.Geometry","page":"Function and type index","title":"SpeedyWeather.Geometry","text":"Geometry struct containing parameters and arrays describing the Gaussian grid and the vertical levels. NF is the number format used for the precomputed constants.\n\n\n\n\n\n","category":"type"},{"location":"functions/#SpeedyWeather.fourier","page":"Function and type index","title":"SpeedyWeather.fourier","text":"Fourier transform in the zonal direction.\n\n\n\n\n\n","category":"function"},{"location":"functions/#SpeedyWeather.fourier_inverse","page":"Function and type index","title":"SpeedyWeather.fourier_inverse","text":"Inverse Fourier transform in zonal direction.\n\n\n\n\n\n","category":"function"},{"location":"functions/#SpeedyWeather.legendre","page":"Function and type index","title":"SpeedyWeather.legendre","text":"Computes the Legendre transform\n\n\n\n\n\n","category":"function"},{"location":"functions/#SpeedyWeather.legendre_inverse","page":"Function and type index","title":"SpeedyWeather.legendre_inverse","text":"Computes the inverse Legendre transform.\n\n\n\n\n\n","category":"function"},{"location":"functions/#SpeedyWeather.spectral","page":"Function and type index","title":"SpeedyWeather.spectral","text":"Transform a gridded array into spectral space.\n\n\n\n\n\n","category":"function"},{"location":"functions/#SpeedyWeather.gridded","page":"Function and type index","title":"SpeedyWeather.gridded","text":"Transform a spectral array into grid-point space.\n\n\n\n\n\n","category":"function"},{"location":"dynamical_core/#Dynamical-core","page":"Dynamical core","title":"Dynamical core","text":"","category":"section"},{"location":"dynamical_core/","page":"Dynamical core","title":"Dynamical core","text":"A mathematical and implementation-specific description of the dynamical core used in SpeedyWeather.jl","category":"page"},{"location":"dynamical_core/#Mathematical-background","page":"Dynamical core","title":"Mathematical background","text":"","category":"section"},{"location":"dynamical_core/","page":"Dynamical core","title":"Dynamical core","text":"The primitive equations solved by SpeedyWeather.jl are","category":"page"},{"location":"dynamical_core/","page":"Dynamical core","title":"Dynamical core","text":"beginaligned\npartial_t u =  \npartial_t v =  \npartial_t T =   \npartial_t Q =  \nendaligned","category":"page"},{"location":"dynamical_core/","page":"Dynamical core","title":"Dynamical core","text":"more to come","category":"page"},{"location":"dynamical_core/#Implementation-details","page":"Dynamical core","title":"Implementation details","text":"","category":"section"},{"location":"dynamical_core/","page":"Dynamical core","title":"Dynamical core","text":"using SpeedyWeather\n\nP = Params(T=Float64)\nG = GeoSpectral{P.T}(P)\nB = Boundaries{P.T}(P,G)\n\nfourier(B.ϕ0trunc,G),G)","category":"page"},{"location":"dynamical_core/#Time-integration","page":"Dynamical core","title":"Time integration","text":"","category":"section"},{"location":"dynamical_core/","page":"Dynamical core","title":"Dynamical core","text":"SpeedyWeather.jl uses a leapfrog time scheme with a Robert's and William's filter to dampen the computational mode and achieve 3rd order accuracy.","category":"page"},{"location":"dynamical_core/#Oscillation-equation","page":"Dynamical core","title":"Oscillation equation","text":"","category":"section"},{"location":"dynamical_core/","page":"Dynamical core","title":"Dynamical core","text":"fracdFdt = iomega F","category":"page"},{"location":"how_to_run_speedy/#How-to-run-SpeedyWeather.jl","page":"How to run SpeedyWeather.jl","title":"How to run SpeedyWeather.jl","text":"","category":"section"},{"location":"how_to_run_speedy/","page":"How to run SpeedyWeather.jl","title":"How to run SpeedyWeather.jl","text":"The simplest way to run SpeedyWeather.jl with default parameters is","category":"page"},{"location":"how_to_run_speedy/","page":"How to run SpeedyWeather.jl","title":"How to run SpeedyWeather.jl","text":"using SpeedyWeather\nrun_speedy()","category":"page"},{"location":"how_to_run_speedy/#The-run_speedy-interface","page":"How to run SpeedyWeather.jl","title":"The run_speedy interface","text":"","category":"section"},{"location":"how_to_run_speedy/","page":"How to run SpeedyWeather.jl","title":"How to run SpeedyWeather.jl","text":"run_speedy","category":"page"},{"location":"how_to_run_speedy/#SpeedyWeather.run_speedy","page":"How to run SpeedyWeather.jl","title":"SpeedyWeather.run_speedy","text":"Prog = run_speedy(NF,kwargs...) Prog = run_speedy(kwargs...)\n\nRuns SpeedyWeather.jl with number format NF and any additional parameters in the keyword arguments kwargs.... Any unspeficied parameters will use the default values as defined in src/parameters.jl.\n\n\n\n\n\n","category":"function"},{"location":"parameterizations/#Parameterizations","page":"Parameterizations","title":"Parameterizations","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"This page describes the mathematical formulation of the parameterizations used in SpeedyWeather.jl to represent physical processes in the atmopshere. Every section is followed by a brief description of implementation details.","category":"page"},{"location":"parameterizations/#Convection","page":"Parameterizations","title":"Convection","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"more to come ...","category":"page"},{"location":"parameterizations/#Large-scale-condensation","page":"Parameterizations","title":"Large-scale condensation","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"more to come ...","category":"page"},{"location":"parameterizations/#Clouds","page":"Parameterizations","title":"Clouds","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"more to come ...","category":"page"},{"location":"parameterizations/#Short-wave-radiation","page":"Parameterizations","title":"Short-wave radiation","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"more to come ...","category":"page"},{"location":"parameterizations/#Long-wave-radiation","page":"Parameterizations","title":"Long-wave radiation","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"more to come ...","category":"page"},{"location":"parameterizations/#Surface-fluxes-of-momentum-and-energy","page":"Parameterizations","title":"Surface fluxes of momentum and energy","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"more to come ...","category":"page"},{"location":"parameterizations/#Vertical-diffusion","page":"Parameterizations","title":"Vertical diffusion","text":"","category":"section"},{"location":"parameterizations/","page":"Parameterizations","title":"Parameterizations","text":"more to come ...","category":"page"},{"location":"new_model_setups/#New-model-setups","page":"New model setups","title":"New model setups","text":"","category":"section"},{"location":"new_model_setups/","page":"New model setups","title":"New model setups","text":"more to come...","category":"page"},{"location":"#SpeedyWeather.jl-documentation","page":"Home","title":"SpeedyWeather.jl documentation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Welcome to the documentation for SpeedyWeather.jl a global atmospheric circulation model with simple parameterizations to represent physical processes such as clouds, precipitation and radiation.","category":"page"},{"location":"#Overview","page":"Home","title":"Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SpeedyWeather.jl is a spectral model that uses a Fourier and Legendre transform to calculcate tendencies of the prognostic variables vorticity, divergence, absolute temperature, logarithm of surface pressure and specific humidity. The time stepping uses a leapfrog scheme with additional filters and a semi-implicit formulation for gravity waves. The default resolution is T30 (96x48 grid points on a Gaussian grid, about 400km at the Equator) and 8 vertical levels.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Simple parameterizations are used to represent the physical processes convection, large-scale condensation, clouds, short-wave radiation, long-waves radiation, surface fluxes of momentum and energy, and vertical diffusion.","category":"page"},{"location":"#Manual-outline","page":"Home","title":"Manual outline","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"See the following pages of the documentation for more details","category":"page"},{"location":"","page":"Home","title":"Home","text":"How to run SpeedyWeather.jl\nDynamical core\nParameterizations\nNew model setups\nFunction and type index","category":"page"},{"location":"","page":"Home","title":"Home","text":"and the original documentation by Molteni and Kucharski.","category":"page"},{"location":"#Scope","page":"Home","title":"Scope","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The focus of SpeedyWeather.jl is to develop a global, yet simple, atmospheric model, that can run at various levels of precision (16, 32 and 64-bit) on different architectures (x86 and ARM, currently planned, GPUs probably in the future). Additionally, the model is written in an entirely number format-flexible way, such that any custom number format can be used and Julia will compile to the format automatically.","category":"page"},{"location":"#History","page":"Home","title":"History","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SpeedyWeather.jl is a Julia implementation of SPEEDY, which is written in Fortran 77. Sam Hatfield translated SPEEDY to Fortran 90 and started the project to port it to Julia in first translations to Julia.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SpeedyWeather.jl is not yet registered in the Julia Registry. So at the moment, open Julia's package manager from the REPL with ] and add the github repository to install SpeedyWeather.jl and all dependencies","category":"page"},{"location":"","page":"Home","title":"Home","text":"(@v1.6) pkg> add https://github.com/milankl/SpeedyWeather.jl","category":"page"},{"location":"","page":"Home","title":"Home","text":"other branches can be installed by adding #branch_name, e.g. add https://github.com/milankl/SpeedyWeather.jl#branch_name.","category":"page"},{"location":"#Developers","page":"Home","title":"Developers","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SpeedyWeather.jl is currently developed by Milan Klöwer and Tom Kipson, any contributions are always welcome.","category":"page"},{"location":"#Funding","page":"Home","title":"Funding","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This project is funded by the European Research Council under Horizon 2020 within the ITHACA project, grant agreement number 741112.","category":"page"},{"location":"boundary_conditions/#Boundary-conditions","page":"Boundary conditions","title":"Boundary conditions","text":"","category":"section"},{"location":"boundary_conditions/","page":"Boundary conditions","title":"Boundary conditions","text":"This page describes the formulation of boundary conditions and their implementation.","category":"page"},{"location":"time_integration/#Time-integration","page":"Time integration","title":"Time integration","text":"","category":"section"},{"location":"time_integration/","page":"Time integration","title":"Time integration","text":"SpeedyWeather.jl uses a leapfrog time scheme with a Robert's and William's filter to dampen the computational mode and achieve 3rd order accuracy.","category":"page"},{"location":"time_integration/#Oscillation-equation","page":"Time integration","title":"Oscillation equation","text":"","category":"section"},{"location":"time_integration/","page":"Time integration","title":"Time integration","text":"fracdFdt = iomega F","category":"page"},{"location":"time_integration/#Implementation-details","page":"Time integration","title":"Implementation details","text":"","category":"section"}]
}
