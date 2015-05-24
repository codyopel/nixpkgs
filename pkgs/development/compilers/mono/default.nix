{ stdenv, callPackage, fetchurl, coreutils, pkgconfig
, bison, glib, gettext, perl, python, libgdiplus, libX11, ncurses, zlib
, withLLVM ? false # Enable mono-llvm JIT compiler for supported methods
}:

let
  inherit (stdenv.lib) enableFeature optional optionals optionalString;
  mono-llvm = callPackage ./mono-llvm.nix { };
  outDir = "$out";
in

stdenv.mkDerivation rec {
  name = "mono-${version}";
  version = "4.0.1.43";

  src = fetchurl {
    url = "http://download.mono-project.com/sources/mono/${name}.tar.bz2";
    sha256 = "03rfn2dm3x787wy7fjpvv3rrbql2h7as71hr01vj10lw53f23kkf";
  };

  patchPhase = ''
    patchShebangs .

    # Fix pkgconfig files (not seting variables during build)
    ls
    for file in data/* ; do
      if [ -f "$1" ] ; then
        sed -e 's,''\${prefix},${outDir},' -i $file
        sed -e 's,''\${pcfiledir},${outDir},' -i $file
        sed -e 's,''\${assemblies_dir},${outDir}/lib/mono,' -i $file
        sed -e 's,''\${libdir},${outDir}/lib,' -i $file
      fi
    done
  '' + optionalString withLLVM ''
    # Fix mono-llvm reference
    substituteInPlace mono/mini/aot-compiler.c \
      --replace "llvm_path = g_strdup (\"\")" "llvm_path = g_strdup (\"${mono-llvm}/bin/\")"
  '';

  NIX_LDFLAGS = "-lgcc_s";

  configureFlags = [
    #"--with-tls=pthread"
    #"--with-static_mono=no"
    #"--with-shared_mono=yes"
    #"--enable-libraries"
    #"--enable-executables"
    "--with-jit"
    "--with-crosspkgdir=$(out)/lib/pkgconfig"
    "--enable-nls"
    "--x-includes=${libX11}/include"
    "--x-libraries=${libX11}/lib"
    "--with-libgdiplus=${libgdiplus}/lib/libgdiplus.so"
    (enableFeature withLLVM "llvm")
    (enableFeature withLLVM "llvmloaded")
  ] ++ optionals withLLVM [
    "--with-llvm=${mono-llvm}"
  ];

  makeFlags = [
    "INSTALL=${coreutils}/bin/install"
  ];

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ bison gettext perl python libgdiplus libX11 ncurses zlib ]
    ++ optional withLLVM mono-llvm;

  propagatedBuildInputs = [ glib ];

  # Fix mono DLLMap so it can find libX11 and gdiplus to run winforms apps
  # Other items in the DLLMap may need to be pointed to their store locations
  # http://www.mono-project.com/Config_DllMap
  postBuild = ''
    find . -name 'config' -type f | while read i; do
        sed -i "s@libX11.so.6@${libX11}/lib/libX11.so.6@g" $i
        sed -i "s@/.*libgdiplus.so@${libgdiplus}/lib/libgdiplus.so@g" $i
    done
  '';

  dontDisableStatic = true; # https://bugzilla.novell.com/show_bug.cgi?id=644723

  dontStrip = true;

  enableParallelBuilding = false;

  meta = with stdenv.lib; {
    description = "Cross platform, open source .NET development framework";
    homepage = http://mono-project.com/;
    license = licenses.gpl1; # Combination of LGPL1/X11/GPL1/MPL
    maintainers = with maintainers; [ codyopel obadz thoughtpolice viric ];
    platforms = platforms.linux;
  };
}
