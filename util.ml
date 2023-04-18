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

let print_clause c =
  List.iter
    (fun l ->
      print_int l;
      print_char ' ')
    c

let print_form f =
  List.iter
    (fun c ->
      print_clause c;
      print_newline ())
    f

let print_val rho =
  Array.iter
    (fun x ->
      print_int x;
      print_char ' ')
    rho
