{ lib, fetchurl, buildPythonApplication, pythonPackages }:

with lib;

buildPythonApplication rec {
  pname = "schemainspect";
  version = "0.1.1571629429";

  src = fetchurl {
    url = "mirror://pypi/s/schemainspect/schemainspect-${version}.tar.gz";
    sha256 = "0plcl164fn42rv96klr1ahna985x8yxm4j82bj4rs7frshxwzg51";
  };

  propagatedBuildInputs = with pythonPackages; [ six sqlalchemy sqlbag psycopg2 ];
  doCheck = false;

  meta = {
    description = "Command-line tool for querying PyPI and Python packages installed on your system";
    homepage = https://github.com/cakebread/yolk;
    maintainers = with maintainers; [];
    license = licenses.bsd3;
  };
}

