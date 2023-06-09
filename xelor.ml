type literal = int
type clause = literal list
type formula = clause array

open Util

exception Unsat_causal of int * int list
exception Unsat

let check (f : formula) (modele : int array) =
  let check_xors literals =
    List.fold_left
      (fun acc l -> acc + if l > 0 then modele.(l) else 1 - modele.(-l))
      0 literals
    mod 2
    = 1
  in
  let rec aux f modele =
    match f with [] -> true | c :: f2 -> check_xors c && aux f2 modele
  in
  aux (Array.to_list f) modele

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
      if l > 0 then (abs rho.(l) + e) mod 2 else (1 - abs rho.(-l) + e) mod 2

(** Négation d'une clause de xor *)
let neg_xor c = match c with [] -> [ 0 ] | [ 0 ] -> [] | l :: c2 -> -l :: c2
(* On note [0] pour la clause vraie, tandis que [] est la clause vide qui est fausse *)

(* a l'indice i contient la liste des clauses qui influent sur la
   clause i avec des remplacements directs ou indirects.
   Utilisé pour print la trace en selectionnant l'ensemble des clauses
   qui font partie de la preuve de non satisfabilité *)
let causality : int list array ref = ref [||]
let add_causality i j = !causality.(j) <- i :: !causality.(i)

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
let simpl_clause ?(print_unsat_trace = 0) nb_vars ind c =
  let res = ref c in
  for i = 1 to nb_vars do
    let pos, neg = count !res i in
    if pos = 2 then res := remove i !res
    else if neg = 2 then res := remove (-i) !res
    else if pos = 1 && neg = 1 then res := neg_xor (remove_all [ i; -i ] !res)
  done;
  if !res = [] && print_unsat_trace = 0 then
    raise @@ Unsat_causal (1, ind :: !causality.(ind));
  !res

(** Remplace le littéral l (positif) par la clause g dans la formule f,
    et simplifie la formule *)
let replace_neg ?(print_unsat_trace = 0) start l g (f : formula) nb_vars : unit
    =
  let save = Array.copy f in
  if print_unsat_trace > 0 then
    Printf.printf "Replace %d by %s = ¬(%s) in %s:\n" l
      (clause_string @@ neg_xor g)
      (clause_string g)
      (form_string (Array.sub save start (Array.length save - start)));
  mapi_in_place start (replace_neg_clause l g (start - 1)) f;
  mapi_in_place start (simpl_clause ~print_unsat_trace nb_vars) f;
  if print_unsat_trace > 0 then (
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
    valuation rho, ou une exception si la formule n'est pas satisfiable 
    
    *)
let rec xelor ?(print_unsat_trace = 0) (f : formula) nb_vars : int array =
  (* print_unsat_trace vaut 0 si on ne doit pas afficher de trace d'insatisfiabilité,
     1 dans le cas où la méthode utilisée aboutit à une clause vide,
     et 2 dans le cas où une variable doit être à la faois vraie et fausse *)
  if print_unsat_trace > 0 then
    Printf.printf "The formula %s\nis not satisfiable.\n\nProof:\n\n"
    @@ form_string f;
  let rho = Array.make (nb_vars + 1) (-1) in
  causality := Array.make (Array.length f) [];
  (* causal_vars contient l'ensemble des clauses qui
     ont déterminé la valeur d'une variable. Utilisé pour la trace.
     causal_vats.(i) = causality.(j) avec j la clause qui a déterminé la valeur de i *)
  let causal_vars = Array.make (nb_vars + 1) [] in
  let f' = Array.copy f in
  (try
     let rec aux i =
       if i >= Array.length f' then ()
       else
         match f'.(i) with
         | [] ->
             if print_unsat_trace = 0 then raise @@ Unsat_causal (1, []) else ()
         | [ l ] ->
             if print_unsat_trace > 0 then
               Printf.printf "Processing clause: %d\n" l;
             (match (l, rho.(abs l)) with
             | 0, _ -> ()
             | l, -1 when l > 0 ->
                 rho.(l) <- 1;
                 causal_vars.(abs l) <- i :: !causality.(i);
                 if print_unsat_trace = 2 then
                   Printf.printf "The variable %d need to be true.\n" (abs l)
             | l, -1 ->
                 rho.(-l) <- 0;
                 causal_vars.(abs l) <- i :: !causality.(i);
                 if print_unsat_trace = 2 then
                   Printf.printf "The variable %d need to be false.\n" (abs l)
             | l, 1 when l > 0 -> ()
             | l, 0 when l < 0 -> ()
             | _ ->
                 if print_unsat_trace = 2 then
                   Printf.printf
                     "The variable %d need to be %s whereas it was needed to \
                      be %s.\n"
                     (abs l)
                     (if l > 0 then "true" else "false")
                     (if l > 0 then "false" else "true");
                 if print_unsat_trace = 0 then
                   raise
                     (Unsat_causal
                        (2, i :: (causal_vars.(abs l) @ !causality.(i)))));
             aux (i + 1)
         | l1 :: l2 :: c2 ->
             if print_unsat_trace > 0 then (
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
             let val_l = 1 - eval_xor g rho in
             if rho.(l) = 1 - val_l then (
               if print_unsat_trace = 2 then
                 Printf.printf
                   "The variable %d need to be %s whereas it was needed to be \
                    %s.\n"
                   l
                   (if val_l = 1 then "true" else "false")
                   (if val_l = 1 then "false" else "true");
               if print_unsat_trace = 0 then
                 raise
                   (Unsat_causal (2, i :: (causal_vars.(l) @ !causality.(i)))))
             else (
               rho.(l) <- val_l;
               causal_vars.(l) <- i :: !causality.(i);
               if print_unsat_trace = 2 then
                 Printf.printf "The variable %d need to be %s.\n" l
                   (if val_l = 1 then "true" else "false"))
     in
     aux 0
   with Unsat_causal (unsat_kind, clause_ids) when print_unsat_trace = 0 ->
     let clauses = List.map (fun i -> f.(i)) clause_ids in
     let f'' = Array.of_list clauses in
     xelor ~print_unsat_trace:unsat_kind f'' nb_vars |> ignore);
  if print_unsat_trace > 0 then (
    print_endline "Therefore there is no solution!\n";
    raise Unsat);
  (* Abs because variable with value -1 were assumed to be true
     during the proof *)
  Array.map abs rho

let print_result f nb_vars =
  print_newline ();
  try
    let modele = xelor f nb_vars in
    Printf.printf
      "SAT\n\nThe formula %s\nis satisfiable with the following model:\n"
      (form_string f);
    print_val modele;
    assert (check f modele);
    print_newline ()
  with Unsat -> print_string "UNSAT\n\n"

(* Exemples *)

let ex1 = [ [ 1; 3; 4 ]; [ 2; -3; 4 ]; [ 1; 2; -4 ]; [ 1; -2; -3 ] ]
let ex2 = [ [ 1; 2 ]; [ 1; -3 ]; [ -2; 3 ] ]

(* let () = print_result ex2 4 *)

let () =
  Printexc.record_backtrace true;
  let f, nb_vars = Dimacs.parse Sys.argv.(1) in
  print_result f nb_vars
