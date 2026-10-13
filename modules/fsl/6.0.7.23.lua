-- Lmod modulefile for the CINN FSL install on RACC2.
-- Installed on RACC2 as /software/modules/CINN/fsl/6.0.7.23.lua
-- Load with:  module load fsl/6.0.7.23
help([[FSL 6.0.7.23 with fsl_sub configured for Slurm on RACC2]])
whatis("Name: FSL")
whatis("Version: 6.0.7.23")

local base = "/software/CINN/fsl/6.0.7.23"

setenv("FSLDIR", base)
setenv("FSLOUTPUTTYPE", "NIFTI_GZ")
setenv("FSLMULTIFILEQUIT", "TRUE")
setenv("FSLTCLSH", pathJoin(base, "bin", "fsltclsh"))
setenv("FSLWISH",  pathJoin(base, "bin", "fslwish"))
setenv("FSLGECUDAQ", "")
prepend_path("PATH", pathJoin(base, "share", "fsl", "bin"))
