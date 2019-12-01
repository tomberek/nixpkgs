{ stdenv, fetchgit
, runCommand
, pkgconfig, autoreconfHook
, autoconf
, automake
, libtool
, texinfo
, gettext
, gawk
, rapidjson
, gd
, shapelib
, libharu
, lmdb
, gmp
, mpfr
, postgresql
, hiredis
, expat
, tre
, makeWrapper
}:

let
extensions = stdenv.mkDerivation rec {
  name = "gawkextlib-unstable-2018-07-20";

  src = fetchgit {
    url = "git://git.code.sf.net/p/gawkextlib/code";
    rev = "f70f10da2804e4fd0a0bac57736e9c1cf21e345d";
    sha256 = "sha256-M3bBjOp8OrrOosEDScEgJUEFJPYApaC/do3QYRP6DmU=";
  };

  nativeBuildInputs = [
    autoconf automake libtool autoreconfHook pkgconfig
    texinfo gettext
  ];

  buildInputs = [
    gawk rapidjson gd shapelib libharu
    lmdb gmp mpfr postgresql hiredis expat tre ];

  postPatch = ''
    cd lib
  '';
  buildPhase = ''
    make
    mkdir -p $out/lib
    cp ./.libs/* $out/lib
    cp ../lib/gawkextlib.h $out/lib

    export LDFLAGS="$LDFLAGS -L$out/lib"
    declare -a list=("abort" "aregex" "csv" "errno" "gd" "haru" "json" "lmdb" "mbs" "mpfr" "nl_langinfo" "pgsql" "redis" "select" "xml" "timex" )
    for i in "''${list[@]}" ; do
      pushd ../$i
      ( autoreconf -i ; \
      ./configure --with-gawkextlib=$out/lib/ ; \
      make ; ) &
      popd
    done
    wait
    pushd ..
  '';
  installPhase = ''
    cp */.libs/* $out/lib
    ln -s ${gawk}/lib/gawk/* $out/lib/.
    popd
  '';

  doCheck = stdenv.isLinux;

  meta = with stdenv.lib; {
    homepage = https://sourceforge.net/projects/gawkextlib/;
    description = "Dynamically loaded extension libraries for GNU AWK";
    longDescription = ''
        The gawkextlib project provides several extension libraries for
        gawk (GNU AWK), as well as libgawkextlib containing some APIs that
        are useful for building gawk extension libraries. These libraries
        enable gawk to process XML data, interact with a PostgreSQL
        database, use the GD graphics library, and perform unlimited
        precision MPFR calculations.
    '';
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ tomberek ];
  };
};
in runCommand "gawk-with-gawkextlib" {
  nativeBuildInputs = [ makeWrapper ];
} ''
  mkdir -p $out/bin
  for i in ${gawk}/bin/*; do
    name="$(basename "$i")"
    makeWrapper $i $out/bin/$name \
      --set-default AWKLIBPATH ${extensions}/lib
  done
''


