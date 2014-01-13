all:
	pandoc info.md {1,2,3,4,5,6,7,8}*.md -o build.pdf \
		--template latex/template.latex \
		--toc