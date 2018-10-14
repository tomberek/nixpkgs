{ lib, fetchFromGitHub, buildPythonPackage, fetchPypi, requests }:

buildPythonPackage rec {
  version = "1.9.1";
  pname = "python-yubico-client";

  src = fetchFromGitHub {
    owner = "Kami";
    repo = pname;
    rev = "v1.9.1";
    sha256 = "0kzqrbylxslya5g89grrpj34fa4aqrixchzgx9cvksjh42hzwz9n";
  };

  postPatch = ''
    sed -i "s#'requests>.*#'requests'#" setup.py
  '';
  #buildInputs = [ test-utils ];
  propagatedBuildInputs = [ requests ];
  doCheck = false;

  meta = with lib; {
    description = "Python library for validating Yubico Yubikey One Time Passwords (OTPs) based on the validation protocol version 2.0.";
    homepage = https://yubico-client.readthedocs.org/en/latest/;
    license = licenses.bsd3;
  };
}
