xelor: xelor.ml dimacs.ml
	ocamlfind ocamlopt -o xelor -package str -linkpkg dimacs.ml xelor.ml

clean:
	rm -f *.cmi *.cmx *.o xelor
