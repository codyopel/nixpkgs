# Generic builder for the NVIDIA drivers, supports versions 340+

# Notice:
# The generic builder does not use the exact version changes were made, so if
# choose to use a version not offically supported, it may require additional
# research into at which version certain changes were made.

. "${stdenv}/setup"

# Fail on any error
set -e

# PatchELF RPATH shrink removes libXv from the RPATH of `nvidia-settings', as a
# work around we run `patchelf' on everything except `nvidia-settings' (see
# `installNvidiaBin')
dontPatchELF=1

installNvidiaBin() {

  # Usage:
  # $1 - Min version ('-' = null, for no minimum)
  # $2 - Max version ('-' = null, for no maximum)
  # $3 - Executable name

  if ([ "${1}" == '-' ] || [ "${versionMajor}" -ge "${1}" ]) && \
     ([ "${2}" == '-' ] || [ "${2}" -le "${versionMajor}" ]) ; then
    # Create the executable directory if it doesn't exist
    if [ ! -d "${out}/bin" ] ; then
      mkdir -p "${out}/bin"
    fi

    # Install the executable
    cp -p "${3}" "${out}/bin"

    if [ ${versionMajor} -le 340 ] && [ "${3}" == 'nvidia-settings' ] ; then
      patchelf \
        --set-interpreter "$(cat ${NIX_CC}/nix-support/dynamic-linker)" \
        --set-rpath "${out}/lib:${glPath}:${gtkPath}:${programPath}" \
        "${out}/bin/${3}"
    else
      patchelf \
        --set-interpreter "$(cat ${NIX_CC}/nix-support/dynamic-linker)" \
        --set-rpath "${out}/lib:${glPath}:${programPath}" \
        "${out}/bin/${3}"
    fi

    # Shrink the RPATH for all executables except `nvidia-settings'
    # Using --shrink-rpath removes libXv from the RPATH of `nvidia-settings'
    if [ "${3}" != 'nvidia-settings' ] ; then
      patchelf --shrink-rpath "${out}/bin/${3}"
    fi
  fi

}

installNvidiaHeader() {

  # Usage:
  # $1 - Min version ('-' = null, for no minimum)
  # $2 - Max version ('-' = null, for no maximum)
  # $3 - Header name (w/o extension)
  # $4 - Include sub-directory (rel to $out/include/)

  if ([ "${1}" == '-' ] || [ "${versionMajor}" -ge "${1}" ]) && \
     ([ "${2}" == '-' ] || [ "${2}" -le "${versionMajor}" ]) ; then
    # Create the include directory if it doesn't exist
    if [ ! -d "${out}/include/${4}" ] ; then
      mkdir -p "${out}/include/${4}"
    fi

    # Install the header
    cp -p "${3}.h" "${out}/include/${4}"
  fi

}

installNvidiaLib() {

  # Usage:
  # $1 - Min version ('-' = null, for no minimum)
  # $2 - Max version ('-' = null, for no maximum)
  # $3 = Library name (w/o extension)
  # $4 = Custom so version (symlink to original) (1 is ignored since the symlink
  #      is always created, so it can be used in place of a null value)
  # $5 = File's so version
  # $6 = Lib sub-directory (rel to $out/lib/)

  local libFile
  local outDir
  local soVersion

  if ([ "${1}" == '-' ] || [ "${versionMajor}" -ge "${1}" ]) && \
     ([ "${2}" == '-' ] || [ "${2}" -le "${versionMajor}" ]) ; then

    # Create the lib directory if it doesn't exist
    if [ ! -z "${6}" ] && [ ! -d "${out}/lib/${6}" ] ; then
      mkdir -p "${out}/lib/${6}"
    fi

    # If the source *.so.<version> isn't set use *.so.$version
    if [ -z "${5}" ] ; then
      soVersion=".${version}"
    elif [ "${5}" == '-' ] ; then
      soVersion=
    else
      soVersion=".${5}"
    fi

    # If $outDir is set then we need to add a trailing `/'
    if [ -z "${6}" ] ; then
      outDir=
    else
      outDir="${6}/"
    fi

    # Handle cases where the file being installed is in a subdirectory within
    # the source directory
    libFile="$(basename "${3}")"

    # Install the library
    cp -pd "${3}.so${soVersion}" "${out}/lib/${6}"

    # Always create a symlink from the library to *.so & *.so.1
    if [ ! -z "${soVersion}" ] ; then 
      ln -snf \
        "${out}/lib/${outDir}${libFile}.so${soVersion}" \
        "${out}/lib/${outDir}${libFile}.so"
    fi
    if [ "${soVersion}" != '.1' ] ; then
      ln -snf \
        "${out}/lib/${outDir}${libFile}.so${soVersion}" \
        "${out}/lib/${outDir}${libFile}.so.1"
    fi

    # If $4 wasn't 1, then create a *.so.$4 symlink
    # Make sure that we don't set it if we haven't passed a value
    if [ ! -z "${4}" ] ; then
      if [ "${4}" != '-' ] && [ "${4}" != "${soVersion}" ] ; then
        ln -snf \
          "${out}/lib/${outDir}${libFile}.so${soVersion}" \
          "${out}/lib/${outDir}${libFile}.so.${4}"
      fi
    fi

    patchelf --set-rpath \
      "${out}/lib:${allLibPath}" \
      "${out}/lib/${outDir}${libFile}.so${soVersion}"

    patchelf --shrink-rpath "${out}/lib/${outDir}${libFile}.so${soVersion}"

  fi

}

installNvidiaMan() {

  # Usage:
  # $1 - Min version ('-' = null, for no minimum)
  # $2 - Max version ('-' = null, for no maximum)
  # $3 = Man page (w/o extension (.1.gz))

  if ([ "${1}" == '-' ] || [ "${versionMajor}" -ge "${1}" ]) && \
     ([ "${2}" == '-' ] || [ "${2}" -le "${versionMajor}" ]) ; then
    # Create the manpage directory if it doesn't exist
    if [ ! -d "${out}/share/man/man1" ] ; then
      mkdir -p "${out}/share/man/man1"
    fi

    # Install the manpage
    cp -p "${3}.1.gz" "${out}/share/man/man1"
  fi

}

unpackFile() {

  # This function prints the first 20 lines of the file, then awk's for the line
  # with `skip=' which contains the line number where the tarball begins, then
  # tails to that line and pipes the tarball to the required decompression
  # utility (gzip/lzma), which interprets the tarball, and finally pipes the
  # output to tar to extract the contents. This is exactly what the cli commands
  # in the `.run' file do, but there is an issue with some versions so it is
  # best to do it manually instead.

  local skip

  # The line you are looking for `skip=' is within the first 20 lines of the
  # file, make sure that you aren't grepping/awking/sedding the entire 60,000+
  # line file for 1 line (hense the use of `head').
  skip="$(head -n 20 "${src}" | awk -F= '/skip=/ { print $2 ; exit ; }')"

  # If the `skip=' value is null, more than likely the hash wasn't updated after
  # bumping the version.
  [ ! -z "${skip}" ]

  if [ ${versionMajor} -le 304 ] ; then
    tail -n +"${skip}" "${src}" | gzip -cd | tar xvf -
  else
    tail -n +"${skip}" "${src}" | xz -d | tar xvf -
  fi

  sourceRoot="$(pwd)"
  export sourceRoot

}

buildPhase() {

  local sysOut
  local sysSrc

  if test -n "${buildKernelspace}" ; then

    # Create the kernel module
    echo "Building the NVIDIA Linux kernel modules against: ${kernel}"

    cd "${sourceRoot}/kernel"

    kernelVersion="$(ls "${kernel}/lib/modules")"
    [ ! -z "${kernelVersion}" ]
    sysSrc="${kernel}/lib/modules/${kernelVersion}/source"
    sysOut="${kernel}/lib/modules/${kernelVersion}/build"

    # $src is also used by the nv makefile
    unset src

    make SYSSRC="${sysSrc}" SYSOUT="${sysOut}" module

    if [ ${versionMajor} -lt 355 ] && [ "${system}" == 'x86_64-linux' ] ; then
      cd "${sourceRoot}/kernel/uvm"
      make SYSSRC="${sysSrc}" SYSOUT="${sysOut}" module
    fi

    cd "${sourceRoot}"

  fi

}

nvidiaKernelspace() {

  # Install the kernel module
    mkdir -p "${out}/lib/modules/${kernelVersion}/misc"
    
    cp -p \
      'kernel/nvidia.ko' \
      "${out}/lib/modules/${kernelVersion}/misc"

    if [ "${system}" == 'x86_64-linux' ] ; then
      if [ ${versionMajor} -ge 355 ] ; then
        cp -p \
          'kernel/nvidia-uvm.ko' \
          "${out}/lib/modules/${kernelVersion}/misc"
      else
        cp -p \
          'kernel/uvm/nvidia-uvm.ko' \
          "${out}/lib/modules/${kernelVersion}/misc"
      fi
    fi

}

nvidiaUserspace() {

  #
  ## Libraries
  #

    # Graphics libraries
      # OpenGL API entry point
      installNvidiaLib '-' '-' 'libGL'
      # OpenGL ES API entry point
      installNvidiaLib '-' '-' 'libGLESv1_CM'
      installNvidiaLib '-' '-' 'libGLESv2' '2'
      # EGL API entry point
      installNvidiaLib '355' '-' 'libEGL' '-' '1'
      installNvidiaLib '355' '-' 'libEGL_nvidia' '-' '0'

    # Vendor neutral graphics libraries
      installNvidiaLib '355' '-' 'libOpenGL' '-' '0'
      installNvidiaLib '355' '-' 'libGLdispatch' '-' '0'

    # Driver components ???
      installNvidiaLib '-' '-' 'libnvidia-eglcore'
      installNvidiaLib '-' '-' 'libnvidia-glcore'
      installNvidiaLib '-' '-' 'libnvidia-glsi'

    # NVIDIA OpenGL-based inband frame readback
      installNvidiaLib '-' '-' 'libnvidia-ifr'

    # Thread local storage libraries for NVIDIA OpenGL libraries
      installNvidiaLib '-' '-' 'libnvidia-tls'
      installNvidiaLib '-' '-' 'tls/libnvidia-tls' '1' "${version}" 'tls'
      installNvidiaLib '-' '-' 'tls_test_dso' '1' '-'

    # X.Org DDX driver
      installNvidiaLib '-' '-' 'nvidia_drv' '1' '-' 'xorg/modules/drivers'

    # X.Org GLX extension module
      installNvidiaLib '-' '-' 'libglx' '1' "${version}" 'xorg/modules/extensions'

    # VDPAU libraries
      # Top-level wrapper
      installNvidiaLib '-' '-' 'libvdpau'
      # Debug trace library
      installNvidiaLib '-' '-' 'libvdpau_trace'
      # NVIDIA VDPAU implementation
      installNvidiaLib '-' '-' 'libvdpau_nvidia'

    # Managment & Monitoring library
      installNvidiaLib '-' '-' 'libnvidia-ml'

    # CUDA libraries
      installNvidiaLib '-' '-' 'libcuda'
      installNvidiaLib '-' '-' 'libnvidia-compiler'
      # CUDA video decoder library
      installNvidiaLib '-' '-' 'libnvcuvid'

    # OpenCL libraries
      # Vendor independent ICD loader
      installNvidiaLib '-' '-' 'libOpenCL' '1' '1.0.0'
      # NVIDIA ICD
      installNvidiaLib '-' '-' 'libnvidia-opencl'

    # Linux kernel userspace driver config library
      installNvidiaLib '-' '-' 'libnvidia-cfg'

    # Wrapped software rendering library
      installNvidiaLib '-' '-' 'libnvidia-wfb' '1' "${version}" 'xorg/modules'

    # Framebuffer capture library
      installNvidiaLib '-' '-' 'libnvidia-fbc'

    # NVENC video encoding library
      installNvidiaLib '-' '-' 'libnvidia-encode'

    # NVIDIA GTK+ 2/3 libraries
      if test -n "${nvidiasettingsSupport}" && test -z "${libsOnly}" && [ ${versionMajor} -ge 346 ] ; then
        if test -n "${gtk3Support}" ; then
          installNvidiaLib '-' '-' 'libnvidia-gtk3'
          patchelf --set-rpath \
            "${out}/lib:${glPath}:${gtkPath}" \
            "${out}/lib/libnvidia-gtk3.so.${version}"
        else
          installNvidiaLib '-' '-' 'libnvidia-gtk2'
          patchelf --set-rpath \
            "${out}/lib:${glPath}:${gtkPath}" \
            "${out}/lib/libnvidia-gtk2.so.${version}"
        fi
      fi

  #
  ## Headers
  #

    # OpenGL headers
      installNvidiaHeader '-' '-' 'gl' 'GL'
      installNvidiaHeader '-' '-' 'glext' 'GL'
      installNvidiaHeader '-' '-' 'glx' 'GL'
      installNvidiaHeader '-' '-' 'glxext' 'GL'

  #
  ## Executables (support programs)
  #

    if test -z "${libsOnly}" ; then
      # System Management Interface
      installNvidiaBin '-' '-' 'nvidia-smi'
      installNvidiaBin '-' '-' 'nvidia-debugdump'
      installNvidiaBin '-' '-' 'nvidia-cuda-mps-control'
      installNvidiaBin '-' '-' 'nvidia-cuda-mps-server'
      ###installNvidiaBin '-' '-' 'nvidia-cuda-proxy-control'
      installNvidiaBin '-' '-' 'nvidia-persistenced'
      ###installNvidiaBin '-' '-' 'mkprecompiled'
      ###installNvidiaBin '-' '-' 'nvidia-bug-report.sh'
      ###installNvidiaBin '-' '-' 'nvidia-installer'
      ###installNvidiaBin '-' '-' 'nvidia-modprobe'
      ###installNvidiaBin '-' '-' 'nvidia-xconfig'
      ###installNvidiaBin '-' '-' 'tls_test' (also tls_test.so)
      if test -n "${nvidiasettingsSupport}" ; then
        installNvidiaBin '-' '-' 'nvidia-settings'
      fi
    fi

  #
  ## Manpages
  #

    if test -z "${libsOnly}" ; then
      installNvidiaMan '-' '-' 'nvidia-smi'
      installNvidiaMan '-' '-' 'nvidia-cuda-mps-control'
      installNvidiaMan '-' '-' 'nvidia-persistenced'
      ###installNvidiaMan '-' '-' 'nvidia-installer'
      ###installNvidiaMan '-' '-' 'nvidia-modprobe'
      ###installNvidiaMan '-' '-' 'nvidia-xconfig'
      if test -n "${nvidiasettingsSupport}" ; then
        installNvidiaMan '-' '-' 'nvidia-settings'
      fi
    fi

  #
  ## Configs
  #

    if test -z "${libsOnly}" ; then
      # NVIDIA application profiles
        mkdir -p "${out}/share/doc"
        cp -p \
          "nvidia-application-profiles-${version}-key-documentation" \
          "${out}/share/doc"
        cp -p \
          "nvidia-application-profiles-${version}-rc" \
          "${out}/share/doc"

      # OpenCL ICD config
        mkdir -p "${out}/lib/vendors"
        cp -p 'nvidia.icd' "${out}/lib/vendors"
    fi

  #
  ## Desktop Entries
  #

    if test -z "${libsOnly}" ; then
      if test -n "${nvidiasettingsSupport}" ; then
        # NVIDIA Settings .desktop entry
          mkdir -p "${out}/share/applications"
          cp -p 'nvidia-settings.desktop' "${out}/share/applications"
          substituteInPlace \
            "${out}/share/applications/nvidia-settings.desktop" \
            --replace '__UTILS_PATH__' "${out}/bin" \
            --replace '__PIXMAP_PATH__' "${out}/share/pixmaps"
      fi
    fi

  #
  ## Icons
  #

    if test -z "${libsOnly}" ; then
      if test -n "${nvidiasettingsSupport}" ; then
        # NVIDIA Settings icon
          mkdir -p "${out}/share/pixmaps"
          cp -p \
            'nvidia-settings.png' \
            "${out}/share/pixmaps"
      fi
    fi

  #
  ## Tests
  #

  if test -z "${libsOnly}" && test -n "${nvidiasettingsSupport}" ; then
    # Simple test
    ${out}/bin/nvidia-settings --version
  fi

}

installPhase() {

  # Kernelspace
  if test -n "${buildKernelspace}" ; then
    nvidiaKernelspace
  fi

  # Userspace
  if test -n "${buildUserspace}" ; then
    nvidiaUserspace
  fi

}

genericBuild

set +e
