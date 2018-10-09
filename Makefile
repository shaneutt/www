HUGO := `which hugo`

all: clean build

clean:
	@mv docs/CNAME ./CNAME
	@rm -rf docs/*
	@mv CNAME docs/CNAME

build:
	@$(HUGO)

server: clean build
	@$(HUGO) server -w --disableFastRender

.PHONY: clean build server
