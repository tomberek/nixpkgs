{ stdenv, fetchgit
, pkgconfig, autoreconfHook
, autoconf
, automake
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
}:

stdenv.mkDerivation rec {
  name = "gawkextlib-unstable-2018-07-20";

  src = fetchgit {
    url = "git://git.code.sf.net/p/gawkextlib/code";
    rev = "9a8454c2d10cc97b529620f19cb696d48a6254fe";
    sha256 = "04sp1xdwfi2rjxzm1f1sivm0b6sg7l06wc9q9flixfy5qyc7j82q";
  };

  nativeBuildInputs = [ autoconf automake autoreconfHook pkgconfig texinfo gettext
  ];

  buildInputs = [ gawk rapidjson gd shapelib libharu lmdb gmp mpfr postgresql hiredis expat ];

  dontConfigure = true;
  postPatch = ''
    cd lib
  '';
  buildPhase = ''
    make
    mkdir -p $out/lib
    cp ./.libs/* $out/lib
    cp ../lib/gawkextlib.h $out/lib

    export LDFLAGS="$LDFLAGS -L$out/lib"
    declare -a list=("abort" "csv" "errno" "gd" "haru" "json" "lmdb" "mbs" "mpfr" "pgsql" "redis" "select" "xml")
    for i in "''${list[@]}" ; do
      pushd ../$i
      autoreconf -i
      ./configure --with-gawkextlib=$out/lib/
      make
      popd
    done
    pushd ..
    cp */.libs/* $out/lib
  '';
  installPhase = ''
    mkdir -p $out/lib
    cp */.libs/* $out/lib
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
}

