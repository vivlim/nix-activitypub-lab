{
  addrs = {
    host = "10.200.200.1";
    inner = "10.200.200.2";
    boundary = "10.200.200.3";
    outer = "10.200.200.4";
    akkoma = "10.200.200.5";
  };
  hostnames = {
    host = "ap-lab.localtest.me";
    inner = rec {
      host = "inner-gotosocial.localtest.me";
      account-domain = host;
    };
    boundary = rec {
      host = "boundary-gotosocial.localtest.me";
      account-domain = host;
    };
    outer = rec {
      host = "outer-gotosocial.localtest.me";
      account-domain = host;
    };
    akkoma = rec {
      host = "akkoma.localtest.me";
      account-domain = host;
    };
  };
  testcreds = {
    username = "test";
    password = "correct-horse-battery-staple"; # gts will reject a password that is too short.
    email = "test@localhost";
  };
}
