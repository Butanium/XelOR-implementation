let map_in_place start f arr =
  for i = start to Array.length arr - 1 do
    arr.(i) <- f arr.(i)
  done

let mapi_in_place start f arr =
  for i = start to Array.length arr - 1 do
    arr.(i) <- f i arr.(i)
  done

(** Supprime toutes les occurences de el dans l *)
let rec remove el l = List.filter (( <> ) el) l

(** Supprime toutes les occurences des éléments de els dans l *)
let remove_all els l = List.fold_left (fun acc el -> remove el acc) l els

let clause_string c =
  match c with
  | [] -> "⊥"
  | [ 0 ] -> "⊤"
  | _ -> String.concat " ⊕ " (List.map string_of_int c)

let print_clause c = print_string (clause_string c)

let form_string f =
  if f = [||] then "⊤"
  else String.concat " /\\ " (List.map clause_string @@ Array.to_list f)

let print_form f = print_string (form_string f)

let print_val rho =
  Array.iteri (fun i x -> if i <> 0 then Printf.printf "%d: %d\n" i (abs x)) rho
