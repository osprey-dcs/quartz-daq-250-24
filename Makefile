KICAD_CLI=kicad-cli

all: chassis-wiring-rev2.pdf

clean:
	rm -f chassis-wiring-rev2.pdf

.PHONY: all clean


%.pdf: %.kicad_sch
	$(KICAD_CLI) sch export pdf -o $@ $<
