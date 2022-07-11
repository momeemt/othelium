# Package

version       = "0.1.0"
author        = "momeemt"
description   = "The othello application and API"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["othelium"]
binDir        = "bin"

# Dependencies

requires "nim >= 1.6.6"
requires "nimx == 0.1"