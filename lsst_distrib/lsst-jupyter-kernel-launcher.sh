#!/bin/bash

# ----------------------------------------------------------------------------#
# File:    lsst-jupyter-kernel-launcher.sh                                    #
#                                                                             #
# Purpose: launch a Python Jupyter kernel configured to use a given release   #
#          the LSST science pipelines (lsst_distrib) distributed via cvmfs    #
#          (see https://sw.lsst.eu)                                           #
#                                                                             #
# Usage:  this file and its companion configuration files must be located     #
#         at                                                                  #
#              ~/.local/share/jupyter/kernels   (Linux)                       #
#              ~/Library/Jupyter/kernels        (macOS)                       #
#                                                                             #
#          To specify the version of the LSST software that you want to use   #
#          in your Jupyter notebook, initialize the environment variable      #
#          LSST_DISTRIB_RELEASE to the value of a given release,              # 
#          e.g. w_2020_05.                                                    #
#                                                                             #
# Source:  https://www.github.com/airnandez/lsst-jupyter-kernel               #
#                                                                             #
# Author: fabio hernandez                                                     #
#         IN2P3/CNRS computing center (CC-IN2P3)                              #
#         https://cc.in2p3.fr                                                 #
# ----------------------------------------------------------------------------#

#
# Determine the lsst_distrib top level directory
#
case $(uname) in
	"Linux")
		distribDir='/cvmfs/sw.lsst.eu/linux-x86_64/lsst_distrib';;
    "Darwin")
		distribDir='/cvmfs/sw.lsst.eu/darwin-x86_64/lsst_distrib';;
esac

#
# Build the absolute path of the specified release via the environment
# variable "LSST_DISTRIB_RELEASE" or the "latest" available
#
release=${LSST_DISTRIB_RELEASE:-'latest'}
if [[ ${release} == 'latest' ]]; then
	release=$(ls ${distribDir} | tail -1)
fi
releaseDir=${distribDir}/${release}

#
# EUPS setup the requested release
#
if [[ -f ${releaseDir}/loadLSST.bash ]]; then
   export LSST_DISTRIB_RELEASE=$(basename ${releaseDir})
   source ${releaseDir}/loadLSST.bash
   setup lsst_distrib
fi


#
# Launch the Jupyter kernel using the python interpreter of the specified
# release 
#
# !!! WARNING: don't modify this line !!!
#
exec python -m ipykernel_launcher "$@"
