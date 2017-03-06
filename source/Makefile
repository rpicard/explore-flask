BUILD = build
BOOKNAME = ExploreFlask
TITLE = title.txt
METADATA = metadata.xml
CHAPTERS = index.rst preface.rst conventions.rst environment.rst organizing.rst configuration.rst views.rst blueprints.rst templates.rst static.rst storing.rst forms.rst users.rst deployment.rst conclusion.rst
TOC = --toc --toc-depth=1
LATEX_CLASS = report
COVER_IMAGE = _static/images/cover.png

all: book

book: ebook html

clean:
	rm -r $(BUILD)

ebook: $(BUILD)/ebook/$(BOOKNAME).epub

html: $(BUILD)/html/$(BOOKNAME).html

$(BUILD)/ebook/$(BOOKNAME).epub: $(TITLE) $(CHAPTERS)
	mkdir -p $(BUILD)/ebook
	pandoc $(TOC) -S --epub-metadata=$(METADATA) --epub-cover-image=$(COVER_IMAGE) -o $@ $^

$(BUILD)/html/$(BOOKNAME).html: $(CHAPTERS)
	mkdir -p $(BUILD)/html
	pandoc $(TOC) --standalone --to=html5 -o $@ $^

.PHONY: all book clean ebook html