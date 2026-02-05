{
  lib,
  python313Packages,
}:

python313Packages.buildPythonPackage (finalAttrs: {
  pname = "meshcoredecoder";
  version = "0.2.3";
  pyproject = true;

  src = python313Packages.fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-je+J6JluMDRevrsgv/miUGoVUM1wGQiZJl+aq6KXvw8=";
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
