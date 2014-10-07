lib: lib.composable [ "eval-support" "build-support" ] (

eval-support@{ calculate-id }:

build-support@{ compile-c, write-file }:

name: let
  self = args@{ filename, argv, envp ? null, settings ? {} }: let
    user = settings.user or null;

    group = settings.group or null;

    needs-envp = envp != null;

    exec-fun = if needs-envp
      then "execve(filename, argv, envp)"
      else "execv(filename, argv)";

    envp-def = if needs-envp then ''
      static char * envp[] = { ${lib.join ", " ((lib.map-attrs-to-list (name: value:
        ''"${name}=${value}"''
      ) envp) ++ [ "NULL" ])} };
    '' else "";

    setuid = if user == null
      then "0"
      else "setuid(${calculate-id user})";

    setgid = if group == null
      then "0"
      else "setgid(${calculate-id group})";
  in (compile-c [ "-Wl,-s" ] (write-file "${name}.c" ''
    #include <unistd.h>
    #include <err.h>

    static char * filename = "${filename}";

    /* TODO: Properly escape nix strings into C string literals */
    static char * argv[] = { ${lib.join ", " ((map (arg:
      ''"${arg}"''
    ) argv) ++ [ "NULL" ])} };

    ${envp-def}

    int main(int argc, char ** _argv) {
      if (${setgid} == -1)
        err(213, "Setting group id");
      if (${setuid} == -1)
        err(213, "Setting user id");
      ${exec-fun};
      err(212, "executing %s", filename);
    }
  '')) // {
    run-with-settings = new-settings: self (args // {
      settings = settings // new-settings;
    });

    inherit settings;
  };
in self)