{ lib, fetchurl, buildPythonPackage, pythonPackages }:

with lib;

buildPythonPackage rec {
  pname = "migra";
  version = "1.0.1554608452";

  src = fetchurl {
    url = "mirror://pypi/m/migra/migra-${version}.tar.gz";
    sha256 = "1i1i1cm10hzm64xmmmqn420qkbcdmw1yrh14gdz672xgll2jzsy0";
  };

  propagatedBuildInputs = with pythonPackages; [ setuptools six sqlbag schemainspect ];
  doCheck = false;

  meta = {
    description = "Command-line tool for querying PyPI and Python packages installed on your system";
    homepage = https://github.com/cakebread/yolk;
    maintainers = with maintainers; [];
    license = licenses.bsd3;
  };
}

