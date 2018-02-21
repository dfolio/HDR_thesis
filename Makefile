#                                                         -*- Mode: Makefile -*-
################################################################################
## Copyright (c) 2018 David Folio
## All rights reserved.
################################################################################
##  License : under BSD license style...
################################################################################
## RCS info ####################################################################
## $Id:$
## $Author: dfolio $
## $Date: 2004/08/13 09:31:03 $
## $Revision: 1.1 $
#########################################################################


GTEX=$(wildcard *.tex)
DOCS=$(GTEX:%.tex=% )

FIGDIR=fig
STYDIR=sty
OUTDIR=out
#########################################################################
ECHO_E=echo -e
RM=rm -f
BIBTEX=bibtex  
INKSCAPE=/usr/bin/inkscape -z
LATEX=lualatex -synctex=1 -file-line-error 

ifneq ($(QUIET),)
LATEX	  += -interaction=batchmode
BIBTEX  += -terse
else
LATEX	+= -interaction=nonstopmode
endif

PANDOC=/usr/bin/pandoc
TEX2PDF=$(LATEX)
GLOSSAIRY=makeglossaries


TEX = $(DOCS:%=%.tex)
PDF = $(DOCS:%=%.pdf)

AUX = $(DOCS:%=%.aux)
BBL = $(DOCS:%=%.bbl)
IST = $(DOCS:%=%.ist)
LOG = $(DOCS:%=%.log)

EPUB = $(DOCS:%=%.epub)
HTML = $(DOCS:%=%.html)
MD   = $(DOCS:%=%.md)

STYFILES  = $(wildcard $(STYDIR)/*.sty)
FIG_SVG	  =$(shell find $(FIGDIR) -type f -name '*.svg') 
#$(FIGDIR)/$(wildcard *.svg)
FIG_PDF	  =$(FIG_SVG:.svg=.pdf)
FIG_PNG	  =$(FIG_SVG:.svg=.png)
FIGFILES  =$(FIG_SVG) $(FIG_PDF) $(FIG_PNG)

## Add \input'ed or \include'd files to $(INCLUDES_TEX) dependencies; ignore
## .tex extensions.
INCLUDES_TEX += $(patsubst %,%.tex,\
		$(shell grep '^[^%]*\\\(input\|include\){' $(TEX) | \
			grep -o '\\\(input\|include\){[^}]\+}' | \
			sed -e 's/^.*{\([^}]*\)}.*/\1/' \
			    -e 's/\.tex$$//'))
INCLUDES_AUX=$(INCLUDES_TEX:.tex=.aux)

MDFILES = $(patsubst %.tex,%.md,$(INCLUDES_TEX))
MDOUT = $(patsubst ./tex/%,$(OUTDIR)/%,$(MDFILES))
#MDFILES  = $(patsubst ./tex/%,$(OUTDIR)/%,$(MD_FILES))
#$(OUTDIR)/
BIBFILES += $(patsubst %,%,\
		$(shell grep '^[^%]*\\bibliography{' $(TEX) | \
			grep -o '\\bibliography{[^}]\+}' | \
			sed -e 's/^[^%]*\\bibliography{\([^}]*\)}.*/\1/' \
			    -e 's/, */ /g'))
		    
BIB_DEPS+=$(BIBFILES) $(BIB_STYLE)  $(BBL)
STY_DEPS+=$(STYFILES)
TEX_DEPS+= $(TEX) $(INCLUDES_TEX) $(BIB_DEPS)  $(STY_DEPS) $(AUX) 


#pandoc global options
# --filter ${FILTER} +yaml_metadata_block+auto_identifiers+header_attributes+latex_macros 
PANDOC_GOPTS=  \
  --number-sections --smart --tab-stop=2 \
  --default-image-extension=png \
	-V lang=en -V otherlangs=en-US,fr,de\
	--toc -V toc-depth=3 
	
RERUN = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
RERUNBIB = "No file.*\.bbl|Citation.*undefined"
RERUNGLO = "(Package glosstex.*There were undefined terms|.*glosstex.*(\(re\))?run GlossTeX)"
BADBOX = "(([Uu]nder|[Oover])full|\\[hv]box)"

CLEAN_FILES= *~ *.log \
	*.blg *.brf *.cb *.ind *.idx *.ilg  \
  *.inx  *.toc *.lof *.out *.glx *.gxs *.gxg *.glo *.rel *.ptc *.upa *.upb *.xmpdata
DISTCLEAN_FILES=*.aux *.ind *.gls *.ps *.dvi *.bbl *.toc *.lof *.lot *.ist *.xmpi

.SUFFIXES:.sty .pdf .aux .tex \
	   .bbl \
	   .epub .html .md \
	   .png .tif .gif .jpg .pbm .pgm .ppm .dvi .fig \
     $(SUFFIXES)

.PHONY: all clean pdf view check clean distclean
#target command
all:pdf
	@$(ECHO_E) "\n***\n*** build $(TARGET) succeed\n"

view: $(PDF)
	@xdg-open  $(PDF)

#latex:$(AUX) $(TEX)   $(INCLUDES_TEX) $(STYLES)
check: $(PDF) $(AUX)
	@$(ECHO_E) "****************************************************\n"
	@egrep -i "(Reference|Citation).*undefined" $(LOG) && ( $(ECHO_E) "Info :Reference OK"; $(ECHO_E) " Warning: Check the reference"); true
	@egrep $(BADBOX) $(LOG)  && $(ECHO_E) " Warning: There were BAD BOX\n"; true
	@pdffonts $(PDF) | grep ".*Type 3.*" || $(ECHO_E) "Info : GOOD! no 'Type 3' font found in $(PDF)\n"


pdf: $(TEX_DEPS) $(TEX) $(FIG_PDF)
	@$(ECHO_E) "\n\n***\n*** [1] Running $(TEX2PDF) on $< ";
	$(RM) $@
	$(TEX2PDF) $(DOCS)
	@$(ECHO_E) "\n****************************************************\n"	
	@egrep -c $(RERUNBIB) $(LOG) >/dev/null && ( $(ECHO_E) "\n\n***\n*** Rebuild Bibliography...\n" &&$(MAKE) bib && $(TEX2PDF) $(DOCS)) ; true
	@egrep $(RERUN) $(LOG) >/dev/null && ($(TEX2PDF) $(DOCS)) ; true && $(ECHO_E) "There were NO undefined reference\n"

tex:$(TEX_DEPS) 
	@$(LATEX) $(DOCS)

bib:$(BIB_DEPS)

fig:$(FIG_SVG) $(FIG_PDF)


aux:$(TEX_DEPS) $(AUX)


md:$(TEX_DEPS) 
	@$(ECHO_E) "\n\n***\n*** [1] Running $(PANDOC) 'markdown' on $< ";
	pandoc $(TEX) -f latex \
	 $(PANDOC_GOPTS)\
	 -t markdown -o  "$(MD)"
	mv   $(MDFILES) $(OUTDIR)
epub:$(TEX_DEPS)
	@$(ECHO_E) "\n\n***\n*** [1] Running $(PANDOC) 'epub' on $< ";upb
	pandoc $(TEX) -f latex \
	 $(PANDOC_GOPTS)\
	 -t epub3 -o  "$(EPUB)" 

phtml:$(TEX_DEPS)
	@$(ECHO_E) "\n\n***\n*** [1] Running $(PANDOC) 'html' on $< ";
	pandoc $(TEX) -f latex \
	 $(PANDOC_GOPTS)\
	 -t html5 -o  "$(HTML)" 


###
.tex.aux:$(TEX_DEPS)
	@$(ECHO_E) "\n\n***\n*** [0] Missing $(AUX) ???  $* from $@ [$<] \n***\n"
	@$(LATEX) $<

.aux.bbl: $(TEX_DEPS) $(BIB_DEPS)
	@$(ECHO_E) "\n\n***\n*** [0] Running $(BIBTEX) on $* from $@ [$<]..."
	$(BIBTEX)   $<

.tex.pdf:$(TEX_DEPS)
	@$(ECHO_E) "\n\n***\n*** [0] Build $@ 'PDF' on $< ";
	$(MAKE) pdf

%.png: %.svg
	@$(INKSCAPE)	--export-area-page --export-png=$@ $<
%.pdf: %.svg
	@$(INKSCAPE)	--export-area-page --export-pdf=$@ $<
	
.tex.md:
	@$(ECHO_E) "\n\n***\n*** [0] Running $(PANDOC) to 'markdown' $@ from $< [$*] \n***\n"
	pandoc $<  -f latex \
	  $(PANDOC_GOPTS) \
	  -t markdown -o  "$@"

#.tex.md:
#	@$(ECHO_E) "\n\n***\n*** [0] Running $(PANDOC)  to 'tex' $* from $@ [$<]  \n***\n"
#	pandoc $@ \
#	  $(PANDOC_GOPTS) \
#	  -t markdown -o  "$*"
	  
#|gawk -v script=log -v full=$full -f vc-git.awk >
#git --no-pager log -1 HEAD --pretty=format:"Hash: %H%nAbr. Hash: %h%nParent Hashes: %P%nAbr. Parent Hashes: %p%nAuthor Name: %an%nAuthor Email: %ae%nAuthor Date: %ai%nCommitter Name: %cn%nCommitter Email: %ce%nCommitter Date: %ci%n"
info:
	@$(ECHO_E) -e " DOCS: $(DOCS) "
	@$(ECHO_E) -e "  TEX: $(TEX)"
	@$(ECHO_E) -e "  INCLUDES: $(INCLUDES_TEX)"
	@$(ECHO_E) -e "   MD: $(MDFILES)"
	@$(ECHO_E) -e "  STY: $(STYFILES)"
	@$(ECHO_E) -e "  FIG: $(FIGFILES)"
	@$(ECHO_E) -e "  BIBFILES: $(BIBFILES)"

clean:
	$(RM)  $(CLEAN_FILES)
	@$(ECHO_E) "\n\n***\n***  clean document\n"

distclean:clean
	$(RM)  $(DISTCLEAN_FILES)
	@$(ECHO_E) "\n\n***\n***  distclean document\n"

