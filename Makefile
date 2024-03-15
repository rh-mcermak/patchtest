.DEFAULT_GOAL := run

export TZ=Europe/Prague

run:
	# For list of composes: https://docs.testing-farm.io/Testing%20Farm/0.1/test-environment.html#_composes
	time testing-farm request --compose RHEL-9.5.0-Nightly --git-url https://github.com/rh-mcermak/patchtest.git

lint:
	tmt plans lint
	tmt tests lint

ls:
	tmt -vv run discover

