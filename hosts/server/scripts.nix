{
  config,
  pkgs,
  inputs,
}:
{
  stagitCreate =
    let
      destDir = "/var/tmp/stagit";
      reposDir = config.modules.git.directory;
      flags = builtins.concatStringsSep " " [
        "-u https://${config.networking.domain}/git/${name}/"
      ];

      indexScript = pkgs.writeShellScriptBin "index" ''
        ${pkgs.stagit}/bin/stagit-index ${reposDir}/*/ > ${destDir}/index.html

        # Symlink favicon.png, logo.png and stagit.css from site
        ${pkgs.sbase}/bin/ln -sf \
          ${inputs.site}/public/icon/256.png \
          ${destDir}/favicon.png

        ${pkgs.sbase}/bin/ln -sf \
          ${inputs.site}/public/icon/32.png \
          ${destDir}/logo.png

        ${pkgs.sbase}/bin/ln -sf \
          ${inputs.site}/public/stagit.css \
          ${destDir}/style.css
      '';

      repositoriesScript =
        config.modules.git.repositories
        |> builtins.attrNames
        |> builtins.map (name: ''
          ${pkgs.sbase}/bin/mkdir -p ${destDir}/${name}
          cd ${destDir}/${name}
          ${pkgs.stagit}/bin/stagit ${flags} ${reposDir}/${name}

          # Make the log.html file the index page
          ${pkgs.sbase}/bin/ln -sf \
            ${destDir}/${name}/log.html \
            ${destDir}/${name}/index.html

          # Symlink favicon.png, logo.png and style.css in repos from
          # index
          ${pkgs.sbase}/bin/ln -sf \
            ${destDir}/favicon.png \
            ${destDir}/${name}/favicon.png

          ${pkgs.sbase}/bin/ln -sf \
            ${destDir}/logo.png \
            ${destDir}/${name}/logo.png

          ${pkgs.sbase}/bin/ln -sf \
            ${destDir}/style.css \
            ${destDir}/${name}/style.css
        '')
        |> pkgs.writeShellScriptBin "repositories";

      script = pkgs.writeShellScriptBin "stagit-create" ''
        ${indexScript}
        ${repositoriesScript}
      '';
    in
    "${script}/bin/stagit-create";

  stagitPostReceive =
    { name }:
    let
      destDir = "/var/tmp/stagit";
      cacheFile = "${destDir}/.htmlcache";
      reposDir = config.modules.git.directory;
      flags = builtins.concatStringsSep " " [
        "-c ${cacheFile}"
        "-u https://${config.networking.domain}/git/${name}/"
      ];

      script = pkgs.writeShellScriptBin "stagit" ''
        # Define is_force=1 if 'git push -f' was used
        null_ref="0000000000000000000000000000000000000000"
        is_force=0
        while read -r old new ref; do
          ${pkgs.sbase}/bin/test "$old" = $null_ref && continue
          ${pkgs.sbase}/bin/test "$new" = $null_ref && continue

          has_revs=$(${pkgs.git}/bin/git rev-list "$old" "^$new" | \
            ${pkgs.sbase}/bin/sed 1q)

          if ${pkgs.sbase}/bin/test -n "$has_revs"; then
            is_force=1
            break
          fi
        done

        # If is_force = 1, remove commits and cache file
        if ${pkgs.sbase}/bin/test $is_force = "1"; then
          ${pkgs.sbase}/bin/rm -f ${cacheFile}
          ${pkgs.sbase}/bin/rm -rf ${reposDir}/${name}/commit
        fi

        ${pkgs.sbase}/bin/mkdir -p ${destDir}/${name}
        cd ${destDir}/${name}
        ${pkgs.stagit}/bin/stagit ${flags} ${reposDir}/${name}
        ${pkgs.stagit}/bin/stagit-index ${reposDir}/*/ \
          > ${destDir}/index.html

        # Make the log.html file the index page
        ${pkgs.sbase}/bin/ln -sf \
          ${destDir}/${name}/log.html \
          ${destDir}/${name}/index.html

        # Symlink favicon.png, logo.png and stagit.css from site
        ${pkgs.sbase}/bin/ln -sf \
          ${inputs.site}/public/icon/256.png \
          ${destDir}/favicon.png

        ${pkgs.sbase}/bin/ln -sf \
          ${inputs.site}/public/icon/32.png \
          ${destDir}/logo.png

        ${pkgs.sbase}/bin/ln -sf \
          ${inputs.site}/public/stagit.css \
          ${destDir}/style.css

        # Symlink favicon.png, logo.png and style.css in repos from
        # index
        ${pkgs.sbase}/bin/ln -sf \
          ${destDir}/favicon.png \
          ${destDir}/${name}/favicon.png

        ${pkgs.sbase}/bin/ln -sf \
          ${destDir}/logo.png \
          ${destDir}/${name}/logo.png

        ${pkgs.sbase}/bin/ln -sf \
          ${destDir}/style.css \
          ${destDir}/${name}/style.css
      '';
    in
    "${script}/bin/stagit";
}
