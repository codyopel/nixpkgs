{ stdenv, fetchurl, xdpyinfo }:

stdenv.mkDerivation rec {
  name = "screenFetch-${version}";
  version = "3.6.5";

  src = fetchurl {
    url = "https://github.com/KittyKatt/screenFetch/archive/v${version}.tar.gz";
    sha256 = "083gjqs7v98scxxifpacf3b3br13vwyw9p3q8zkaa84ppsa5lq5n";
  };

  patchPhase = ''
    substituteInPlace screenfetch-dev --replace xdpyinfo ${xdpyinfo}/bin/xdpyinfo
  '';

  installPhase = ''
    install -Dm 0755 screenfetch-dev $out/bin/screenfetch
    install -Dm 0644 screenfetch.1 $out/man/man1/screenfetch.1
  '';

  meta = with stdenv.lib; {
    description = "Fetches system/theme information in terminal for Linux desktop screenshots";
    longDescription = ''
      screenFetch is a "Bash Screenshot Information Tool". This handy Bash
      script can be used to generate one of those nifty terminal theme
      information + ASCII distribution logos you see in everyone's screenshots
      nowadays. It will auto-detect your distribution and display an ASCII
      version of that distribution's logo and some valuable information to the
      right. There are options to specify no ascii art, colors, taking a
      screenshot upon displaying info, and even customizing the screenshot
      command! This script is very easy to add to and can easily be extended.
    '';
    homepage = https://github.com/KittyKatt/screenFetch;
    license = licenses.gpl3;
    maintainers = with maintainers; [ relrod ];
    platforms = platforms.all;
  };
}
