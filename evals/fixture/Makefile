lint:
	shellcheck src/bad.sh

test:
	python3 -c 'import sys; sys.path.insert(0, "src"); from math_ops import add; assert add(2, 2) == 4'

build:
	bash -n src/build.sh
