xelor: xelor.ml dimacs.ml
	ocamlfind ocamlopt -g -o xelor -package str -linkpkg dimacs.ml util.ml xelor.ml

clean:
	rm -f *.cmi *.cmx *.o xelor

test: # 1) call make xelor 2) run ./xelor on all files of directory tests in a row
	make xelor && for file in tests/*; do ./xelor $$file; done
