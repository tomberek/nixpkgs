{stdenv, fetchFromGitHub, python, pythonPackages, iptables, ... }:
let
  inherit (python.pkgs) buildPythonApplication;
in
buildPythonApplication rec {
  version = "1.29.1827.6";
  name="pritunl-v${version}";
  src = fetchFromGitHub {
    owner = "pritunl";
    repo = "pritunl";
    rev = "${version}";
    sha256 = "1jf3bba89wz4hkmlx73wamyzlahhy3lavlqnb5rhin92mczyhdvq";
  };

  propagatedBuildInputs = with python.pkgs;
  [ flask cheroot jinja2 pymongo netifaces boto boto3 requests redis dateutil psutil pyroute2 google_api_python_client twisted pyopenssl cryptography certifi yubico-client

    iptables
];
  postPatch = ''
    sed -i "s#'requests>.*#'requests'#" setup.py
  '';

  meta = {
    homepage = https://pritunl.com;
    description = "Enterprise VPN server";
    maintainers = with stdenv.lib.maintainers; [ tomberek ];
  };
}
