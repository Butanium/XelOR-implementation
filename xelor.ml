type literal = int
type clause = literal list
type formula = clause array

open Util

exception Unsat_causal of int list
exception Unsat

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
let simpl_clause ?(print_trace = false) nb_vars ind c =
  let res = ref c in
  for i = 1 to nb_vars do
    let pos, neg = count !res i in
    if pos = 2 then res := remove i !res
    else if neg = 2 then res := remove (-i) !res
    else if pos = 1 && neg = 1 then res := neg_xor (remove_all [ i; -i ] !res)
  done;
  if !res = [] && not print_trace then raise @@ Unsat_causal !causality.(ind);
  !res

(** Remplace le littéral l (positif) par la clause g dans la formule f,
    et simplifie la formule *)
let replace_neg ?(print_trace = false) start l g (f : formula) nb_vars : unit =
  let save = Array.copy f in
  if print_trace then (
    Printf.printf "Replace %d by " l;
    print_clause @@ neg_xor g;
    print_newline ());
  mapi_in_place start (replace_neg_clause l g start) f;
  mapi_in_place start (simpl_clause ~print_trace nb_vars) f;
  if print_trace then
    Array.iter2
      (fun c c' ->
        if c <> c' then print_clause c;
        print_string " -> ";
        print_clause c';
        print_newline ())
      save f

(** Renvoie une valuation satisfaisant la formule f en modifiant la
    valuation rho, ou une exception si la formule n'est pas satisfiable *)
let rec xelor ?(print_trace = false) (f : formula) nb_vars : int array =
  let rho = Array.make (nb_vars + 1) 0 in
  causality := Array.make nb_vars [];
  let f' = Array.copy f in
  (try
     Array.iteri
       (fun start c ->
         match c with
         | [] -> raise @@ Unsat_causal []
         | [ l ] when l > 0 -> rho.(l) <- 1
         | [ l ] -> ()
         | l1 :: l2 :: c2 ->
             let l, g =
               if l1 > 0 then (l1, l2 :: c2)
               else if l2 > 0 then (l2, l1 :: c2)
               else (-l1, -l2 :: c2)
             in
             replace_neg ~print_trace (start + 1) l g f' nb_vars;
             rho.(l) <- 1 - eval_xor g rho)
       f'
   with Unsat_causal clause_ids when not print_trace ->
     Printf.eprintf "Unsat_causal: %s\n"
       (String.concat ", " @@ List.map string_of_int clause_ids);
     let clauses = List.map (fun i -> f.(i)) clause_ids in
     let f'' = Array.of_list clauses in
     xelor ~print_trace:true f'' nb_vars |> ignore);
  if print_trace then (
    print_string "Therefore there is no solution";
    raise Unsat);
  rho

let print_result f nb_vars =
  try
    let modele = xelor f nb_vars in
    print_string "SAT\n";
    print_val modele
  with Unsat -> ()

(* Exemples *)

let ex1 = [ [ 1; 3; 4 ]; [ 2; -3; 4 ]; [ 1; 2; -4 ]; [ 1; -2; -3 ] ]
let ex2 = [ [ 1; 2 ]; [ 1; -3 ]; [ -2; 3 ] ]

(* let () = print_result ex2 4 *)

let () =
  Printexc.record_backtrace true;
  let f, nb_vars = Dimacs.parse Sys.argv.(1) in
  print_result f nb_vars
