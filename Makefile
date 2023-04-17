xelor: xelor.ml dimacs.ml
	ocamlfind ocamlopt -o xelor -package str -linkpkg dimacs.ml util.ml xelor.ml

clean:
	rm -f *.cmi *.cmx *.o xelor
