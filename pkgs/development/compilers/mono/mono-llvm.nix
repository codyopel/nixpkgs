{ stdenv, fetchFromGitHub, cmake
, perl
, groff
, python
, libffi
, binutils
, libxml2
, valgrind
, ncurses
, zlib
}:

let
  inherit (stdenv) isDarwin isLinux;
  inherit (stdenv.lib) optional;
in

stdenv.mkDerivation rec {
  name = "mono-llvm-${version}";
  version = "2015-03-26";

  src = fetchFromGitHub {
    owner = "mono";
    repo = "llvm";
    rev = "ce4fcecb92436ef560ff70b34b546e027ccf8d1a";
    sha256 = "1fldqs2865r6k03hr83z2yi7zrg7ynsz4wf009kfg98wvs9kic4p";
  };

  #unpackPhase = ''
  #  unpackFile ${src}
  #  mv llvm-* llvm
  #  sourceRoot=$PWD/llvm
  #'';

  #patches = [ ./build-fix-llvm.patch ];

  patchPhase = ''
    rm -f ./configure
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_ENABLE_FFI=ON"
    "-DLLVM_BINUTILS_INCDIR=${binutils}/include"
    "-DCMAKE_CXX_FLAGS=-std=c++11"
  ] ++ optional (!isDarwin) "-DBUILD_SHARED_LIBS=ON";

  nativeBuildInputs = [ cmake ];

  buildInputs = [ perl groff libxml2 python libffi ]
    ++ optional isLinux valgrind;

  propagatedBuildInputs = [ ncurses zlib ];

  # hacky fix: created binaries need to be run before installation
  preBuild = ''
    mkdir -p $out/
    ln -sv $PWD/lib $out
  '';

  postBuild = "rm -fR $out";

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Collection of modular and reusable compiler and toolchain technologies - Mono build";
    homepage = http://llvm.org/;
    license = licenses.bsd3;
    maintainers = with maintainers; [ codyopel thoughtpolice ];
    platforms = platforms.all;
  };
}
