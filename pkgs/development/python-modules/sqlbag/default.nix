{ lib, fetchurl, buildPythonApplication, pythonPackages }:

with lib;

buildPythonApplication rec {
  pname = "sqlbag";
  version = "0.1.1548994599";

  src = fetchurl {
    url = "mirror://pypi/s/sqlbag/sqlbag-${version}.tar.gz";
    sha256 = "14mc2qbwn5y2qb8mkn4b8a0rfk7s3ydclyag100ampn1pi62ciq5";
  };

  propagatedBuildInputs = with pythonPackages; [ sqlalchemy pathlib six psycopg2 ];
  doCheck = false;

  meta = {
    description = "Command-line tool for querying PyPI and Python packages installed on your system";
    homepage = https://github.com/cakebread/yolk;
    maintainers = with maintainers; [];
    license = licenses.bsd3;
  };
}

