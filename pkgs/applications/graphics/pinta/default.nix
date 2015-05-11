{ stdenv, fetchurl, intltool, pkgconfig
, mono, gtksharp
}:

stdenv.mkDerivation rec {
  name = "pinta-${version}";
  version = "1.6";

  src = fetchurl {
    url = "https://github.com/PintaProject/Pinta/releases/download/${version}/${name}.tar.gz";
    sha256 = "10fqk7mi1bls2zn3da35l5a65lkvnzgj5xmnv34946q5y6arxspi";
  };

  nativeBuildInputs = [ intltool pkgconfig ];

  buildInputs = [ mono gtksharp ];

  buildPhase = ''
    # xbuild understands pkgconfig, but gtksharp does not give .pc for gdk-sharp
    # So we have to go the GAC-way
    export MONO_GAC_PREFIX=${gtksharp}
    xbuild Pinta.sln
  '';

  # Very ugly - I don't know enough Mono to improve this. Isn't there any rpath in binaries?
  installPhase = ''
    mkdir -p $out/lib/pinta $out/bin
    cp bin/*.{dll,exe} $out/lib/pinta
    cat > $out/bin/pinta << EOF
    #!/bin/sh
    export MONO_GAC_PREFIX=${gtksharp}:\$MONO_GAC_PREFIX
    export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${gtksharp}/lib:${gtksharp.gtk}/lib:${mono}/lib
    exec ${mono}/bin/mono $out/lib/pinta/Pinta.exe
    EOF
    chmod +x $out/bin/pinta
  '';

  # Always needed on Mono, otherwise nothing runs
  dontStrip = true; 

  meta = with stdenv.lib; {
    description = "Drawing/editing program modeled after Paint.NET";
    homepage = http://www.pinta-project.com/;
    license = licenses.mit;
    maintainers = with maintainers; [ viric ];
    platforms = platforms.linux;
  };
}
