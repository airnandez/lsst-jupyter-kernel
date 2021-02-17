#!/bin/bash

#
# Determine what platform we are running on
#
case $(uname) in
    "Linux")
        kernelSpecsDir="${HOME}/.local/share/jupyter/kernels";;
    "Darwin")
        kernelSpecsDir="${HOME}/Library/Jupyter/kernels";;
    *)
        echo "unsupported platform"
        exit 1
        ;;
esac

#
# Create the destination directory for the kernel
#
kernelName='lsst_distrib'
srcDir=./${kernelName}
dstDir=${kernelSpecsDir}/${kernelName}
mkdir -p ${dstDir}
rm -f ${dstDir}/*

#
# Copy the relevant files to the kernel directory
#
sed "s|{KERNEL_DIR}|${dstDir}|g" ${srcDir}/kernel.json > ${dstDir}/kernel.json
cp ${srcDir}/logo-64x64.png ${srcDir}/kernel_launcher.py ${srcDir}/lsst-jupyter-kernel-launcher.sh ${dstDir}
chmod u+x ${dstDir}/lsst-jupyter-kernel-launcher.sh
