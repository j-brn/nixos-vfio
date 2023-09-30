{ pkgs, module, ... }:
let name = "staticfiles";
in pkgs.nixosTest ({
  inherit name;

  nodes = {
    machine = { config, ... }: {
      imports = [ module ];

      environment.staticFiles.files = {
        "/var/lib/foobar/somefile.txt" =
          pkgs.writeText "somefile" "some content";
        "/var/lib/barbar" = pkgs.runCommand "barbar" { } ''
          mkdir -p $out
          echo "foobar" > $out/file1.txt
          echo "baz" > $out/file2.txt
        '';
      };
    };
  };

  testScript = ''
    for path, expected in [
      ("/var/lib/foobar/somefile.txt", "some content"),
      ("/var/lib/barbar/file1.txt", "foobar"),
      ("/var/lib/barbar/file2.txt", "baz"),
    ]:
      exitcode, stdout = machine.execute(f"cat {path}");
      stdout = stdout.strip()

      assert exitcode == 0, f"{path} doesn't exist or isn't readable"
      assert stdout == expected, f"file at {path} has unexpected content: {stdout} != {expected}"
  '';
})
