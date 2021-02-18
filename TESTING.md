# Tardigrade-ci Testing Documentation

Testing tardigrade-ci implementation with various setup on local environment.

## Testing

This project can be utilized one of two ways, via docker or via a Makefile include.

### Test Setup

Configure or run the following script to setup a test project environment:

```bash
#!/bin/bash

TESTDIR=$(mktemp --tmpdir -d tardigrade-ci.XXXXXXXXXX)
cd $TESTDIR
git init
echo "FROM plus3it/tardigrade-ci:latest" > Dockerfile
echo "SHELL := /bin/bash" > Makefile
echo 'include $(shell test -f .tardigrade-ci || curl -sSL -o .tardigrade-ci "https://raw.githubusercontent.com/plus3it/tardigrade-ci/master/bootstrap/Makefile.bootstrap"; echo .tardigrade-ci)' >> Makefile
echo '# tardigrade-ci' > .gitignore
echo '.tardigrade-ci' >> .gitignore
echo 'tardigrade-ci/' >> .gitignore

docker pull python:3
docker pull plus3it/tardigrade-ci:latest
```

### Via Docker (non-tardigrade-ci image)

In a non-tardigrade-ci container, the first condition in `Makefile.bootstrap` ought to fail, resulting in the auto-init logic creating the `tardigrade-ci/` directory.

1. Environment setup should contain `"${TESTDIR:?}"` described in the [Test Setup](#test-setup) section.

2. Run the following Docker command in the `"${TESTDIR:?}"` directory:

```bash
docker run --rm -v $PWD:/workdir --workdir=/workdir --entrypoint make python:3 help
```

3. This should result in the creation of both `.tardigrade-ci` and `tardigrade-ci/`.

4. Run the following command to remove the `tardigrade-ci` subdirectory and bootstrap Makefile `.tardigrade-ci`:

```bash
docker run --rm -v $PWD:/workdir --workdir=/workdir --entrypoint make python:3 clean
```

5. Go to parent directory of `"${TESTDIR:?}"` and remove the directory to delete testing environment:

```bash
cd .. && rm -rf "${TESTDIR:?}"
```

### Via Docker (tardigrade-ci image)

Running a tardigrade-ci container will use the version of `tardigrade-ci` present in the container, and so will create only the `.tardigrade-ci` file in the `"${TESTDIR:?}"` directory.

1. Environment setup should contain `"${TESTDIR:?}"` described in the [Test Setup](#test-setup) section.

2. In the `"${TESTDIR:?}"` directory, run the following command:

```bash
docker run --rm -v $PWD:/workdir --workdir=/workdir --entrypoint make plus3it/tardigrade-ci:latest help
```

3. This should result in only the `.tardigrade-ci` file being created.

4. Run the following command to remove the `tardigrade-ci` subdirectory and bootstrap Makefile `.tardigrade-ci`:

```bash
docker run --rm -v $PWD:/workdir --workdir=/workdir --entrypoint make plus3it/tardigrade-ci:latest clean
```

5. Go to parent directory of `"${TESTDIR:?}"` and remove the directory to delete testing environment:

```bash
cd .. && rm -rf "${TESTDIR:?}"
```

### Via Makefile (`tardigrade-ci/` directory does not exist in root)

This option uses `make` to invoke the targets directly in your shell, instead of within the container environment. You may invoke any `make` target directly, e.g. `make ec/lint`, but be aware if you do so, the make target will attempt to install the tools it requires to your system.

1. Environment setup should contain `"${TESTDIR:?}"` described in the [Test Setup](#test-setup) section.

2. In the `"${TESTDIR:?}"` directory, run the following command:

```bash
make help
```

3. This should result in the creation of both `.tardigrade-ci` and `tardigrade-ci/`.

4. Run the following command to clean up the tardigrade-ci files:

```bash
make clean
```

5. Go to parent directory of `"${TESTDIR:?}"` and remove the directory to delete testing environment:

```bash
cd .. && rm -rf "${TESTDIR:?}"
```

### Via Makefile (`tardigrade-ci/` directory exists in root)
When the bootstrap Makefile detects the directory `tardigrade-ci/` in a parent of the current project directory, it will "include" that tardigrade-ci Makefile, instead of re-cloning `tardigrade-ci/`.

1. If the directory doesn't already exist, clone the `tardigrade-ci/` repo in the test project's parent directory:

```bash
cd "${TESTDIR:?}" && cd ..
git clone https://github.com/plus3it/tardigrade-ci.git
```

2. Environment setup should contain `"${TESTDIR:?}"` described in the [Test Setup](#test-setup) section.

3. In the `"${TESTDIR:?}"` directory, run the following command:

```bash
make help
```

4. This should result in the creation of only the `.tardigrade-ci` (bootstrap Makefile) file.

5. Run the following command to clean up the tardigrade-ci files:

```bash
make clean
```

6. Go to parent directory of `"${TESTDIR:?}"` and remove the directory to delete testing environment:

```bash
cd .. && rm -rf "${TESTDIR:?}" tardigrade-ci/
```
