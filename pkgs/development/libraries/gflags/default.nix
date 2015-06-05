{ stdenv, fetchurl, cmake }:

stdenv.mkDerivation rec {
  name = "gflags-${version}";
  version = "2.1.2";

  src = fetchurl {
    url = "https://github.com/gflags/gflags/archive/v${version}.tar.gz";
    sha256 = "0qi6bibybqffbzx7cwjbs87s0s38x62mwpybbzyqlz1nyz81ncyq";
  };

  cmakeFlags = [
    #"-DCMAKE_INSTALL_PREFIX=$(out)"
    #"-DBUILD_SHARED_LIBS=ON"
    #"-DBUILD_STATIC_LIBS=OFF"
    #"-DBUILD_gflags_LIB=ON"
    #"-DBUILD_gflags_nothreads_LIB=OFF"
    #"-DBUILD_PACKAGING=OFF"
    #"-DINSTALL_HEADERS=ON"
    #"-DGFLAGS_NAMESPACE=gflags"
  ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [ ];

  doCheck = true;

  meta = with stdenv.lib; {
    description = "A C++ library that implements commandline flags processing";
    homepage = https://github.com/gflags/gflags;
    license = licenses.bsd3;
    maintainers = with maintainers; [ linquize ];
    platforms = platforms.all;
  };
}
