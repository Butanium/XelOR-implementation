# Equipe XelOR
## Question 2
$$(p\oplus r \oplus s) \land (q \oplus \neg r \oplus s) \land (p \oplus q \oplus \neg s) \land (p \oplus \neg q \oplus \neg r)$$
On utilise d'abord la propriété suivante :
$$(\neg p) \oplus (\neg q) \equiv p \oplus q$$

Puis, on ajoute deux variables $r'$ et $s'$ et on modifie la formule :
$$
(p\oplus r \oplus s) \land (q \oplus r' \oplus s) \land (p \oplus q \oplus s') \land (p \oplus q \oplus r) \land (r \oplus r') \land (s \oplus s')
$$

En effet $r \oplus r' \implies r' = \neg r$

Ainsi la nouvelle formule obtenue est équivalente à la première. 

## Question 3

Soit $I$ valuation telle que...