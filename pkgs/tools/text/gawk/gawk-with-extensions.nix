{ buildEnv, gawk, makeWrapper, extensions ? []}:
buildEnv rec {
    name = "${gawk.name}-with-extensions";
    paths = [ gawk ] ++ extensions;
    pathsToLink = [ "/bin" "/etc" "/include" "/lib" "/libexec" "/share" ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      ln -s $out/lib/gawk/* $out/lib/.
      wrapProgram $out/bin/gawk \
        --prefix AWKLIBPATH : $out/lib
    '';
}
