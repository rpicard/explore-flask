.PHONY: build

ALL: init build

init:
	pip install -r requirements.txt

build:
	sphinx-build -b html source/ build/