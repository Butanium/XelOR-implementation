# Xelor : un solveur de formules XOR-NF
Pour le rapport voir [Rapport.md](Rapport.md).

## Compilation et exécution
- Pour compiler le code : `make`
- Pour lancer les tests : `make test`
- Pour lancer le code sur un fichier DIMACS : `./xelor <fichier>`

## Structure du code
`util.ml` contient des fonctions utilitaires pour la manipulation de formules booléennes (`print`, `map_in_place`)

`dimacs.ml` contient des fonctions pour la lecture et l'écriture de formules au format DIMACS.

`xelor.ml` permet de lire une formule XOR-NF au format DIMACS et de vérifier si elle est satisfiable.

`test/` contient des formules DIMACS pour tester le code.