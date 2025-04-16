{
  config,
  pkgs,
  inputs,
}:
let
  stagit = {
    createIndex =
      { destDir, reposDir }:
      ''
        ${pkgs.sbase}/bin/mkdir -p ${destDir}

        ${pkgs.stagit}/bin/stagit-index ${reposDir}/*/ > ${destDir}/index.html

        # Copy favicon.png, logo.png and stagit.css from site
        ${pkgs.sbase}/bin/cp \
          ${inputs.site}/public/icon/256.png \
          ${destDir}/favicon.png

        ${pkgs.sbase}/bin/cp \
          ${inputs.site}/public/icon/32.png \
          ${destDir}/logo.png

        ${pkgs.sbase}/bin/cp \
          ${inputs.site}/public/stagit.css \
          ${destDir}/style.css

        ${pkgs.sbase}/bin/echo "Stagit index generated: ${destDir}/index.html".
      '';

    createRepository =
      {
        destDir,
        reposDir,
        name,
        httpBaseUrl,
      }:
      ''
        ${pkgs.sbase}/bin/mkdir -p ${destDir}/${name}
        cd ${destDir}/${name}
        ${pkgs.stagit}/bin/stagit \
          -l 100 \
          -u ${httpBaseUrl}/${name}/ \
          ${reposDir}/${name}

        # Make the log.html file the index page as well
        ${pkgs.sbase}/bin/cp \
          ${destDir}/${name}/log.html \
          ${destDir}/${name}/index.html

        # Symlink favicon.png, logo.png and style.css in repos from
        # index
        ${pkgs.sbase}/bin/cp \
          ${destDir}/favicon.png \
          ${destDir}/${name}/favicon.png

        ${pkgs.sbase}/bin/cp \
          ${destDir}/logo.png \
          ${destDir}/${name}/logo.png

        ${pkgs.sbase}/bin/cp \
          ${destDir}/style.css \
          ${destDir}/${name}/style.css

        ${pkgs.sbase}/bin/echo \
          "Stagit page generated for ${name}: ${destDir}/${name}".
      '';
  };
in
{
  stagitCreate =
    {
      destDir,
      reposDir,
      httpBaseUrl,
    }:
    let
      createIndex = stagit.createIndex {
        inherit destDir reposDir;
      };
      createRepositories =
        config.modules.git.repositories
        |> builtins.attrNames
        |> builtins.map (
          name:
          stagit.createRepository {
            inherit
              destDir
              reposDir
              name
              httpBaseUrl
              ;
          }
        )
        |> builtins.concatStringsSep "\n";

      script = pkgs.writeShellScriptBin "stagit-create" ''
        ${createIndex}
        ${createRepositories}
      '';
    in
    "${script}/bin/stagit-create";

  stagitPostReceive =
    {
      destDir,
      reposDir,
      name,
      httpBaseUrl,
    }:
    let
      createIndex = stagit.createIndex {
        inherit destDir reposDir;
      };
      createRepositories = stagit.createRepository {
        inherit
          destDir
          reposDir
          name
          httpBaseUrl
          ;
      };

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

        # If is_force = 1, delete commits
        if ${pkgs.sbase}/bin/test $is_force = "1"; then
          ${pkgs.sbase}/bin/rm -rf ${reposDir}/${name}/commit
        fi

        ${createIndex}
        ${createRepositories}
      '';
    in
    "${script}/bin/stagit";
}
