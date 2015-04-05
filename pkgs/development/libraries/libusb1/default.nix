{ stdenv, fetchurl, fetchpatch, automake, pkgconfig
, udev ? null
}:

let
  inherit (stdenv) isLinux;
  inherit (stdenv.lib) optional;
in

stdenv.mkDerivation rec {
  name = "libusb-1.0.19";

  src = fetchurl {
    url = "mirror://sourceforge/libusb/${name}.tar.bz2";
    sha256 = "0h38p9rxfpg9vkrbyb120i1diq57qcln82h5fr7hvy82c20jql3c";
  };

  configureFlags = [ "--enable-udev" ];

  buildInputs = [ automake pkgconfig ];

  propagatedBuildInputs = optional isLinux udev;

  #NIX_LDFLAGS = stdenv.lib.optionalString stdenv.isLinux "-lgcc_s";

  meta = with stdenv.lib; {
    description = "User-space USB library";
    homepage = http://www.libusb.info;
    #license = licenses.;
    maintainers = with maintainers; [ urkud ];
    platforms = platforms.unix;
  };
}
