# Equipe XelOR

## Question 2

$$(p\oplus r \oplus s) \land (q \oplus \neg r \oplus s) \land (p \oplus q \oplus \neg s) \land (p \oplus \neg q \oplus \neg r)$$

On utilise d'abord la propriété suivante :

$$(\neg p) \oplus (\neg q) \equiv p \oplus q$$

Puis on ajoute deux variables $r'$ et $s'$ et on modifie la formule :

$$
(p\oplus r \oplus s) \land (q \oplus r' \oplus s) \land (p \oplus q \oplus s') \land (p \oplus q \oplus r) \land (r \oplus r') \land (s \oplus s')
$$

En effet $r \oplus r' \equiv r' = \neg r$.

Ainsi la nouvelle formule obtenue est équivalente à la première. 

## Question 3

Remarque : La propriété donnée est fausse : $(p \oplus p) \land x$ n'est pas satisfiable, mais $x[ \neg p / p ] = x$ l'est. Pour que la propriété soit vraie, il faut que $p$ ne soit pas utilisée dans $G$.

Soit $\rho$ valuation telle que $\rho$ satisfait la formule $(p \oplus G) \land F$. Alors en particulier $\rho$ satisfait la formule $p \oplus G$.
On doit donc avoir $\rho(G) = 1 - \rho(p)$, et par suite $\rho(\neg G) = \rho(p)$. On en déduit $\rho(F) = \rho(F[ \neg G /p ]) = 1$. Ainsi $F[ \neg G /p ]$ est satisfiable.

Réciproquement, supposons que $\rho$ satisfait $F[ \neg G / p ]$. On définit $\rho' := \rho [ p \mapsto 1-\rho(G) ]$.
Ainsi $\rho'(p \oplus G) = 1$, et $\rho'(\neg G) = \rho'(p)$ car $p$ n'est pas utilisée dans $G$. D'où $\rho'(F) = \rho'(F [ \neg G / p ]) = 1$, et donc $(p \oplus G) \land F$ est satisfaite par $\rho'$.

Donc $(p \oplus G) \land F$ et $F[ \neg G / p ]$ sont bien équisatisfiable (à condition que $p$ ne soit pas utilisée dans $G$).

## Question 4

La formule est de la forme $(p \oplus G) \land F$ avec $G = r \oplus s$, donc d'après la question 3, elle est équisatisfiable à $F [ \neg G / p ]$.
Or $\neg G = \neg (r \oplus s) \equiv \neg r \oplus s$, donc la formule initiale est équisatisfiable à :

$$
(q \oplus \neg r \oplus s) \land (\neg r \oplus s \oplus q \oplus \neg s) \land (\neg r \oplus s \oplus \neg q \oplus \neg r)
$$

De plus $(s \oplus \neg s) \equiv \top$ donc $\neg r \oplus s \oplus q \oplus \neg s \equiv \neg (\neg r \oplus q) \equiv r \oplus q$, et $\neg r \oplus \neg r \equiv \bot$ donc $\neg r \oplus s \oplus \neg q \oplus \neg r \equiv s \oplus \neg q$.
Ainsi la formule est équisatisfiable à :

$$
(q \oplus \neg r \oplus s) \land (r \oplus q) \land (s \oplus \neg q)
$$

Cette formule est de la forme $(r \oplus G') \land F'$ avec $G' = q$, donc d'après la question 3 elle est équisatisfiable à :

$$
(q \oplus q \oplus s) \land (s \oplus \neg q)
\equiv s \land (s \oplus \neg q)
$$

qui est équisatisfiable à $q$ en utilisant encore la question 3.

Ainsi la formule est satisfiable par la valuation $\rho$ telle que

$$
\begin{array}{l}
\rho(q) = 1 \\
\rho(s) = 1 - \rho(\neg q) = 1 \\
\rho(r) = 1 - \rho(G') = 1 - \rho(q) = 0 \\
\rho(p) = 1 - \rho(G) = 1 - \rho(r \oplus s) = 0
\end{array}
$$

## Question 5

L'algorithme considère la première clause de la formule.
- Si elle est vide, la formule n'est pas satisfiable. 
- Si elle ne contient qu'un littéral, on modifie la valuation courante puis on calcule la satisfiabilité du reste de la formule.
- Sinon, l'algorithme modifie si besoin la clause en une clause équisatisfiable avec un littéral positif. Ainsi, la nouvelle formule est de la forme $(p \oplus G) \land F$. On calcule ensuite récursivement la satisfiabilité de $F [ \neg G / p ]$, qui donne exactement la satisfiabilité de la formule initiale.

L'algorithme termine puisque le nombre de clauses décroit à chaque appel récursif. La question 3 assure sa correction.

## Question 6
On garde en mémoire quelle clause modifie quelle clause et quelle clause impose telle valuation à tel littéral. On peut alors extraire la sous formule insatisfiable de $F$. On tente ensuite de prouver cetter formule en printant chaque étape jusqu'à :
- Devoir satisfaire une clause vide = $\bot$
- Devoir changer la valuation d'un littéral déjà fixé

Ce qui prouve que la formule est insatisfiable.

## Extensions
Nous avons fait deux extensions :
- Evaluation d'une formule xelor en fonction d'un modèle. Il suffit de vérifier qu'il y a un nombre impair de 1 dans chaque clause.
- Preuve que $a\lor b$ ne peut pas être mis sous forme XOR-NF.
### Preuve de la deuxième extension
On se ramène au cas où les clauses sont de longeurs au plus 2 car pour $l_1 \oplus\ldots\oplus l_n$ quand $l_i\in\{a, \neg a, b\}$ on utilise la commutativité et l'associativité pour réduire les $l\oplus \neg l$ en 1 et les $l\oplus l$ en 0 pour $l\in\{a, b\}$.

Supposons que F sous forme XOR-NF est équivalente $a\lor b$. Si $a\oplus b$ est dans F. Alors $F(a \leftarrow \top, b \leftarrow \top) = \bot \land \ldots=\bot \not = \top \lor \top = \top$.

De même si $a\oplus \neg b$ est dans F. Alors $F(a \leftarrow \top, b \leftarrow \bot) = \bot \land \ldots=\bot \not = \top \lor \bot = \top$.

Donc $a\oplus b$ et $a\oplus \neg b$ ne sont pas dans F et, par symétrie, $b\oplus \neg a$ et $\neg a\oplus \neg b\Leftrightarrow a\oplus b$ non plus. 

De plus, si $a \in F$, alors $F(a \leftarrow \bot, b\leftarrow\top) = \bot \land \ldots=\bot \not = \bot \lor \top = \top$ donc $a$ n'est pas dans F. De même, $b$ n'est pas dans F.

Enfin, si $\neg a \in F$, alors $F(a \leftarrow \top) = \bot \land \ldots=\bot \not = \top \lor b = \top$ donc $\neg a$ n'est pas dans F. De même, $\neg b$ n'est pas dans F.

Ainsi $F$ est forcément vide ce qui est absurde car $\bot\lor\bot = \bot$.