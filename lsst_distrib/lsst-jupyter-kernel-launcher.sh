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
# Save and consume all command line arguments: we don't want them to be passed
# to sourced scripts, such as 'loadLSST.bash'
#
allArgs="$@"
set --

#
# Helper functions
#

# getRelaseDir returns the absolute path of the directory where the given
# release is installed. It accepts an argument with the name of the release
# e.g. "w_2025_01" or "v28.0.1".
# getRelaseDir returns an empty string if the release could not be found
# installed.
function getRelaseDir() {
    local release=$1
    local declare -a distribDirs
    local arch=$(uname -m | tr [:upper:] [:lower:])
    case $(uname) in
        "Linux")
            distribDirs=(
            	# Prefer releases built on AlmaLinux, if available
                "/cvmfs/sw.lsst.eu/almalinux-${arch}/lsst_distrib"
                "/cvmfs/sw.lsst.eu/linux-${arch}/lsst_distrib"
            )
            ;;
        "Darwin")
            distribDirs=(
                "/cvmfs/sw.lsst.eu/darwin-${arch}/lsst_distrib"
            )
            ;;
        *)
            echo ""
            return
            ;;
    esac

    local releaseDir=""
    if [[ -z ${release} ]] || [[ ${release} == "latest" ]]; then
	    # Select the most recent release among the stables (v*) and weeklies (w_*), 
    	# but not development releases, that is not those ending by '-dev'
        releaseDir=$(ls -d ${distribDirs[0]}/v*[0-9] ${distribDirs[0]}/w_*[0-9] | tail -1)
        if [[ -n ${releaseDir} ]]; then
        	echo ${releaseDir}
        	return
        fi
    fi

    # Look for the specified release in the directories where the releases
    # are installed.
    for dir in ${distribDirs[@]}; do
        if [[ -d "${dir}/${release}" ]]; then
            echo "${dir}/${release}"
            return
        fi
    done
    echo ""
}

#
# Retrieve the absolute path of the requested release, if any, or of the
# latest available release.
# variable "LSST_DISTRIB_RELEASE" or the "latest" available
#
release=${LSST_DISTRIB_RELEASE:-'latest'}
releaseDir=$(getRelaseDir ${release})

#
# EUPS setup the requested release
#
if [[ -f ${releaseDir}/loadLSST.bash ]]; then
    #
    # Unset ANACONDA, MINICONDA and CONDA environment variables so that
    # the conda environment included in the Rubin's LSST science pipelines
    # takes precedence over the one potentially existing in the
    # Jupyter environment under which this kernel is being executed
    #
    for v in $(env | grep -e '^CONDA' -e '^ANACONDA' -e '^MINICONDA'); do 
        eval $(echo $v | awk -F '=' '{printf "unset %s", $1}')
    done

    #
    # Save the current PYTHONPATH
    #
    savedPythonPath=${PYTHONPATH}
    unset PYTHONPATH

    #
    # Activate the Rubin environment: if the value of the environment variable
    # 'LSST_USE_EXTENDED_CONDA_ENV' is "true", activate the extended conda 
    # environment by using the loader 'loadLSST-ext.bash' instead of 'loadLSST.bash'
    #
    export LSST_DISTRIB_RELEASE=$(basename ${releaseDir})
    loader=${releaseDir}/loadLSST.bash
    if [[ ${LSST_USE_EXTENDED_CONDA_ENV} == "true" ]] && [[ -f ${releaseDir}/loadLSST-ext.bash ]]; then
        loader=${releaseDir}/loadLSST-ext.bash
    fi
    unset LSST_USE_EXTENDED_CONDA_ENV

    #
    # Set up the LSST Science Pipelines environment
    #
    source ${loader}
    setup lsst_distrib

    #
    # Restore PYTHONPATH
    #
    if [[ -n ${savedPythonPath} ]]; then
        export PYTHONPATH="${PYTHONPATH}:${savedPythonPath}"
    fi
fi

#
# Source user-specific environment, to be compatible with behavior at the USDF's RSP.
# https://nb.lsst.io/science-pipelines/science-pipelines-in-notebooks.html
#
userSetups="${HOME}/notebooks/.user_setups"
if [[ -f ${userSetups} ]]; then
    source ${userSetups}
fi

#
# Launch the Jupyter kernel using the Python interpreter activated
# by the Rubin environment.
#
kernelDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [[ -f ${kernelDir}/kernel_launcher.py ]]; then
    exec python ${kernelDir}/kernel_launcher.py ${allArgs}
else
    exec python -m ipykernel_launcher ${allArgs}
fi
