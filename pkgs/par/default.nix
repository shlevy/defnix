lib: lib.composable [ "build-support" "pkgs" ] (

build-support@{ compile-c }:

pkgs@{ execve }:

name: progs: execve name {
  filename = compile-c [ "-Wl,-s" ] ./par.c;

  argv = [ name ] ++ builtins.concatLists (map (prog: [ prog prog.name ]) progs);
})
