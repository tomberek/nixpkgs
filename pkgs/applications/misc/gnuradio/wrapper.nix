{ stdenv, buildEnv, pythonPackages, gnuradio, makeWrapper, python, extraPackages ? [] }:

with { inherit (stdenv.lib) appendToName makeSearchPath; };

stdenv.mkDerivation rec {
  name = (appendToName "with-packages" gnuradio).name;
  buildInputs = [ makeWrapper python ];
  env = buildEnv {
  inherit name;
  ignoreCollisions = true;
  paths = let
    path_1 = builtins.map ( drv : pythonPackages.toPythonModule drv ) (extraPackages ++ [gnuradio]);
    path_2 = gnuradio.propagatedBuildInputs;
    in path_1 ++ path_2;
  };

  buildCommand = ''
    mkdir -p $out/bin
    ln -s "${gnuradio}"/bin/* $out/bin/

    for file in $(find -L $out/bin -type f); do
        if test -x "$(readlink -f "$file")"; then
            wrapProgram "$file" \
                --suffix PYTHONPATH : "$PYTHONPATH":"$(toPythonPath ${env})" \
                --prefix GRC_BLOCKS_PATH : ${makeSearchPath "share/gnuradio/grc/blocks" extraPackages}
        fi
    done
  '';

  inherit (gnuradio) propagatedBuildInputs;
  inherit (gnuradio) meta;
}
