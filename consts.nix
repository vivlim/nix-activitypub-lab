{
  addrs = {
    host = "10.200.200.1";
    inner = "10.200.200.2";
  };
  hostnames = {
    host = "ap-lab.localtest.me";
    inner = rec {
      host = "inner-gotosocial.localtest.me";
      account-domain = host;
    };
  };
  testcreds = {
    username = "test";
    password = "correct-horse-battery-staple"; # gts will reject a password that is too short.
    email = "test@localhost";
  };
}
