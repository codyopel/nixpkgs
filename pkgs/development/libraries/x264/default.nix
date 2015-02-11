{ stdenv, fetchgit, yasm }:

with stdenv.lib;
stdenv.mkDerivation rec {
  name = "x264-${version}";
  version = "2014.12.12"; # Date of commit used Y.M.D

  src = fetchgit {
    url = "git://git.videolan.org/x264.git";
    # Use commits from the stable branch instead of master
    # http://git.videolan.org/?p=x264.git;a=shortlog;h=refs/heads/stable
    rev = "6a301b6ee0ae8c78fb704e1cd86f4e861070f641";
    sha256 = "1ynziyagkw9smjx8az4fwx8zf9bql36vjgzhdh876hz3yzilw993";
  };

  patchPhase = ''
    patchShebangs configure
    patchShebangs version.sh
  '';

  # --disable-static is not a configure option
  dontDisableStatic = true;

  configureFlags = [ "--enable-shared" ]
    ++ optional (!stdenv.isi686) "--enable-pic";

  nativeBuildInputs = [ yasm ];

  meta = {
    description = "Library and application for encoding H.264/MPEG-4 AVC video streams";
    homepage    = http://www.videolan.org/developers/x264.html;
    license     = licenses.gpl2;
    maintainers = with maintainers; [ codyopel ];
    platforms   = platforms.all;
  };
}
