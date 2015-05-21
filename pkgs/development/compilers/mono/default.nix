{ stdenv, callPackage, fetchurl, pkgconfig
, bison, glib, gettext, perl, libgdiplus, libX11, ncurses, zlib
, withLLVM ? false # Enable mono-llvm JIT compiler for supported methods
}:

let
  inherit (stdenv.lib) optionals optionalString;

  mono-llvm = callPackage ./mono-llvm.nix { };
in

stdenv.mkDerivation rec {
  name = "mono-${version}";
  version = "4.0.1.43";

  src = fetchurl {
    url = "http://download.mono-project.com/sources/mono/${name}.tar.bz2";
    sha256 = "03rfn2dm3x787wy7fjpvv3rrbql2h7as71hr01vj10lw53f23kkf";
  };

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ bison glib gettext perl libgdiplus libX11 ncurses zlib ];

  propagatedBuildInputs = [ glib ];

  NIX_LDFLAGS = "-lgcc_s";

  configureFlags = [
    #"--with-tls=pthread"
    #"--with-static_mono=no"
    #"--with-shared_mono=yes"
    #"--enable-libraries"
    #"--enable-executables"
    "--x-includes=${libX11}/include"
    "--x-libraries=${libX11}/lib"
    "--with-libgdiplus=${libgdiplus}/lib/libgdiplus.so"
  ] ++ optionals withLLVM [
    "--enable-llvm"
    "--enable-llvmloaded"
    "--with-llvm=${mono-llvm}"
  ];

  # Patch all the necessary scripts. Also, if we're using LLVM, we fix the default
  # LLVM path to point into the Mono LLVM build, since it's private anyway.
  preBuild = ''
    makeFlagsArray=(INSTALL=`type -tp install`)
    patchShebangs ./
  '' + optionalString withLLVM ''
    substituteInPlace mono/mini/aot-compiler.c --replace "llvm_path = g_strdup (\"\")" "llvm_path = g_strdup (\"${mono-llvm}/bin/\")"
  '';

  # Fix mono DLLMap so it can find libX11 and gdiplus to run winforms apps
  # Other items in the DLLMap may need to be pointed to their store locations, I don't think this is exhaustive
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
    homepage = http://mono-project.com/;
    description = "Cross platform, open source .NET development framework";
    license = licenses.free; # Combination of LGPL/X11/GPL ?
    maintainers = with maintainers; [ obadz thoughtpolice viric ];
    platforms = platforms.linux;
  };
}
