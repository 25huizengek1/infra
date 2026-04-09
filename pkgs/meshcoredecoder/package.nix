{
  lib,
  python313Packages,
}:

python313Packages.buildPythonPackage (finalAttrs: {
  pname = "meshcoredecoder";
  version = "0.3.2";
  pyproject = true;

  src = python313Packages.fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-QF0FZzU5HZ62maUm1sQtT9QglNVUf94ivBLbXUVEqQQ=";
  };

  build-system = with python313Packages; [
    setuptools
    wheel
  ];

  dependencies = with python313Packages; [
    click
    cryptography
    pycryptodome
  ];

  optional-dependencies = with python313Packages; {
    dev = [
      black
      pylint
      pytest
      pytest-cov
    ];
  };

  pythonImportsCheck = [
    "meshcoredecoder"
  ];

  meta = {
    description = "Complete Python implementation of the MeshCore Packet Decoder";
    homepage = "https://pypi.org/project/meshcoredecoder/";
    license = lib.licenses.mit;
  };
})
