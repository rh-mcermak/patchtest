.DEFAULT_GOAL := run

export TZ=Europe/Prague

run:
	testing-farm request --compose Fedora-Rawhide --git-url  https://gitlab.cee.redhat.com/mcermak/tmtupstreamstap.git

lint:
	tmt plans lint
	tmt tests lint

ls:
	tmt -vv run discover

