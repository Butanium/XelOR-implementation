exception Unsat

let rec remove a l =
  match l with [] -> [] | x :: q -> if x = a then q else x :: remove a q

let rec print_clause c =
  match c with
  | [] -> ()
  | l :: c2 ->
      print_int l;
      print_char ' ';
      print_clause c2

let rec print_form f =
  match f with
  | [] -> ()
  | c :: f2 ->
      print_clause c;
      print_string "\n";
      print_form f2

let print_val rho =
  let len = Array.length rho in
  for i = 1 to len - 1 do
    print_int rho.(i);
    print_char ' '
  done;
  print_string "\n"

let rec count c i =
  match c with
  | [] -> (0, 0)
  | l :: c2 ->
      let pos, neg = count c2 i in
      if l = i then (pos + 1, neg)
      else if l = -i then (pos, neg + 1)
      else (pos, neg)

(* Evalue une clause de xor *)
let rec eval_xor f rho =
  match f with
  | [] -> 0
  | l :: f2 ->
      let e = eval_xor f2 rho in
      if l > 0 then (rho.(l) + e) mod 2 else (1 - rho.(-l) + e) mod 2

(* Négation d'une clause de xor *)
let neg_xor c = match c with [] -> [] | l :: c2 -> -l :: c2

(* Remplace le littéral l (positif) par la clause g dans la clause c *)
let rec replace_neg_clause l g c =
  match c with
  | [] -> []
  | l2 :: c2 when l2 = l -> neg_xor g @ c2
  | l2 :: c2 when l2 = -l -> g @ c2
  | l2 :: c2 -> l2 :: replace_neg_clause l g c2

(* Simplifie une clause si une variable apparaît plusieurs fois *)
let simpl_clause nb_vars c =
  let res = ref c in
  for i = 1 to nb_vars do
    let pos, neg = count !res i in
    if pos = 2 then res := remove i (remove i !res)
    else if neg = 2 then res := remove (-i) (remove (-i) !res)
    else if pos = 1 && neg = 1 then res := neg_xor (remove i (remove (-i) !res))
  done;
  !res

(* Remplace le littéral l (positif) par la clause g dans la formule f,
   et simplifie la formule *)
let replace_neg l g f nb_vars =
  List.map (simpl_clause nb_vars) (List.map (replace_neg_clause l g) f)

(* Renvoie une valuation satisfaisant la formule f en modifiant la
   valuation rho, ou une exception si la formule n'est pas satisfiable *)
let rec xelor f rho nb_vars =
  match f with
  | [] -> rho
  | c :: f2 -> (
      match c with
      | [] -> raise Unsat
      | [ l ] when l > 0 ->
          rho.(l) <- 1;
          rho
      | [ l ] -> rho
      | l1 :: l2 :: c2 ->
          let l, g =
            if l1 > 0 then (l1, l2 :: c2)
            else if l2 > 0 then (l2, l1 :: c2)
            else (-l1, -l2 :: c2)
          in
          let rho2 = xelor (replace_neg l g f2 nb_vars) rho nb_vars in
          rho2.(l) <- 1 - eval_xor g rho;
          rho2)

let print_result f nb_vars =
  let rho = Array.make (nb_vars + 1) 0 in
  try
    let modele = xelor f rho nb_vars in
    print_string "SAT\n";
    print_val modele
  with Unsat -> print_string "UNSAT\n"

(* Exemples *)

let ex1 = [ [ 1; 3; 4 ]; [ 2; -3; 4 ]; [ 1; 2; -4 ]; [ 1; -2; -3 ] ]
let ex2 = [ [ 1; 2 ]; [ 1; -3 ]; [ -2; 3 ] ]

(* let () = print_result ex2 4 *)

let () =
  let f, nb_vars = Dimacs.parse Sys.argv.(1) in
  print_result f nb_vars
