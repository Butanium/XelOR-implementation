type literal = int
type clause = literal list
type formula = clause array

open Util

exception Unsat of int list

(** Renvoie le nombre d'occurences de i et de ¬i *)
let rec count c i =
  match c with
  | [] -> (0, 0)
  | l :: c2 ->
      let pos, neg = count c2 i in
      if l = i then (pos + 1, neg)
      else if l = -i then (pos, neg + 1)
      else (pos, neg)

(** Evalue une clause de xor *)
let rec eval_xor f rho =
  match f with
  | [] -> 0
  | l :: f2 ->
      let e = eval_xor f2 rho in
      if l > 0 then (rho.(l) + e) mod 2 else (1 - rho.(-l) + e) mod 2

(** Négation d'une clause de xor *)
let neg_xor c = match c with [] -> [] | l :: c2 -> -l :: c2

let causality : int list array ref = ref [||]
let add_causality i j = !causality.(j) <- i :: !causality.(i)

(** Remplace le littéral l (positif) par la clause g dans la clause c *)
let replace_neg_clause l g g_ind c_ind c =
  let rec aux add_causal = function
    | [] -> []
    | l2 :: c2 when l2 = l ->
        if add_causal then add_causality g_ind c_ind;
        neg_xor g @ c2
    | l2 :: c2 when l2 = -l ->
        if add_causal then add_causality g_ind c_ind;
        g @ c2
    | l2 :: c2 -> l2 :: aux add_causal c2
  in
  aux true c

(** Simplifie une clause si une variable apparaît plusieurs fois *)
let simpl_clause nb_vars ind c =
  let res = ref c in
  for i = 1 to nb_vars do
    let pos, neg = count !res i in
    if pos = 2 then res := remove i !res
    else if neg = 2 then res := remove (-i) !res
    else if pos = 1 && neg = 1 then res := neg_xor (remove_all [ i; -i ] !res)
  done;
  if !res = [] then raise @@ Unsat !causality.(ind);
  !res

(** Remplace le littéral l (positif) par la clause g dans la formule f,
    et simplifie la formule *)
let replace_neg ?(print_trace = false) start l g (f : formula) nb_vars : unit =
  mapi_in_place start (replace_neg_clause l g start) f;
  mapi_in_place start (simpl_clause nb_vars) f

(** Renvoie une valuation satisfaisant la formule f en modifiant la
    valuation rho, ou une exception si la formule n'est pas satisfiable *)
let xelor ?(print_trace = false) (f : formula) rho nb_vars =
  causality := Array.make nb_vars [];
  let f' = Array.copy f in
  (* TODO: add try with here *)
  (* todo: use print_trace *)
  Array.iteri
    (fun start c ->
      match c with
      | [] -> raise @@ Unsat []
      | [ l ] when l > 0 -> rho.(l) <- 1
      | [ l ] -> ()
      | l1 :: l2 :: c2 ->
          let l, g =
            if l1 > 0 then (l1, l2 :: c2)
            else if l2 > 0 then (l2, l1 :: c2)
            else (-l1, -l2 :: c2)
          in
          replace_neg ~print_trace start l g f nb_vars;
          rho.(l) <- 1 - eval_xor g rho)
    f';
  rho

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
