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

let add_causality i j =
  (* Printf.eprintf "add_causality %d %d\n%!" i j; *)
  (*todo remove*)
  !causality.(j) <- i :: !causality.(i)

(** Remplace le littéral l (positif) par la clause g dans la clause c *)
let replace_neg_clause l g g_ind c_ind c =
  let rec aux = function
    | [] -> []
    | l2 :: c2 when l2 = l ->
        add_causality g_ind c_ind;
        neg_xor g @ c2
    | l2 :: c2 when l2 = -l ->
        add_causality g_ind c_ind;
        g @ c2
    | l2 :: c2 -> l2 :: aux c2
  in
  aux c

(** Simplifie une clause si une variable apparaît plusieurs fois *)
let simpl_clause ?(print_unsat_trace = false) nb_vars ind c =
  let res = ref c in
  for i = 1 to nb_vars do
    let pos, neg = count !res i in
    if pos = 2 then res := remove i !res
    else if neg = 2 then res := remove (-i) !res
    else if pos = 1 && neg = 1 then res := neg_xor (remove_all [ i; -i ] !res)
  done;
  if !res = [] && not print_unsat_trace then
    (* Printf.eprintf "Unsat_causal: %d\n%!" ind; *)
    (*todo remove*)
    raise @@ Unsat_causal (ind :: !causality.(ind));
  !res

(** Remplace le littéral l (positif) par la clause g dans la formule f,
    et simplifie la formule *)
let replace_neg ?(print_unsat_trace = false) start l g (f : formula) nb_vars :
    unit =
  let save = Array.copy f in
  (*debug*)
  if print_unsat_trace then
    Printf.printf "Replace %d by %s = ¬(%s) in %s:\n" l
      (clause_string @@ neg_xor g)
      (clause_string g)
      (form_string (Array.sub save start (Array.length save - start)));
  mapi_in_place start (replace_neg_clause l g (start - 1)) f;
  mapi_in_place start (simpl_clause ~print_unsat_trace nb_vars) f;
  if print_unsat_trace then (
    Array.iter2
      (fun c c' ->
        if c <> c' then (
          print_clause c;
          print_string " -> ";
          if c' = [] then print_string "⊥" else print_clause c';
          print_newline ()))
      save f;
    let s = form_string (Array.sub f start (Array.length f - start)) in
    Printf.printf "Remaining: %s\n\n" (if s = "" then "⊥" else s))

(** Renvoie une valuation satisfaisant la formule f en modifiant la
    valuation rho, ou une exception si la formule n'est pas satisfiable *)
let rec xelor ?(print_unsat_trace = false) (f : formula) nb_vars : int array =
  if print_unsat_trace then
    Printf.printf "The formula %s\nis not satisfiable.\nProof:\n"
    @@ form_string f;
  let rho = Array.make (nb_vars + 1) 0 in
  causality := Array.make (Array.length f) [];
  let f' = Array.copy f in
  (try
     let rec aux i =
       if i >= Array.length f' then ()
       else
         match f'.(i) with
         | [] -> if not print_unsat_trace then raise @@ Unsat_causal [] else ()
         | [ l ] when l > 0 ->
             rho.(l) <- 1;
             aux (i + 1)
         | [ l ] -> aux (i + 1)
         | l1 :: l2 :: c2 ->
             if print_unsat_trace then (
               Printf.printf "Processing clause: ";
               print_clause f'.(i);
               print_newline ());
             let l, g =
               if l1 > 0 then (l1, l2 :: c2)
               else if l2 > 0 then (l2, l1 :: c2)
               else (-l1, -l2 :: c2)
             in
             replace_neg ~print_unsat_trace (i + 1) l g f' nb_vars;
             aux (i + 1);
             rho.(l) <- 1 - eval_xor g rho
     in
     aux 0
   with Unsat_causal clause_ids when not print_unsat_trace ->
     (* Printf.eprintf "Unsat_causal: %s\n%!"
        (String.concat ", " @@ List.map string_of_int clause_ids); *)
     (*todo remove*)
     let clauses = List.map (fun i -> f.(i)) clause_ids in
     let f'' = Array.of_list clauses in
     xelor ~print_unsat_trace:true f'' nb_vars |> ignore);
  if print_unsat_trace then (
    print_endline "Therefore there is no solution!\n";
    raise Unsat);
  rho

let print_result f nb_vars =
  print_newline ();
  try
    let modele = xelor f nb_vars in
    Printf.printf "The formula %s\nis satisfiable with the following model:\n"
      (form_string f);
    print_val modele;
    print_newline ()
  with Unsat -> ()

(* Exemples *)

let ex1 = [ [ 1; 3; 4 ]; [ 2; -3; 4 ]; [ 1; 2; -4 ]; [ 1; -2; -3 ] ]
let ex2 = [ [ 1; 2 ]; [ 1; -3 ]; [ -2; 3 ] ]

(* let () = print_result ex2 4 *)

let () =
  Printexc.record_backtrace true;
  let f, nb_vars = Dimacs.parse Sys.argv.(1) in
  print_result f nb_vars
