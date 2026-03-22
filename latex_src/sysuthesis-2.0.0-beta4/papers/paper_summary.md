# **_mathematics_**

_Article_
## **Generalized Shortest Path Problem: An Innovative Approach for** **Non-Additive Problems in Conditional Weighted Graphs**


**Adrien Durand** _**[∗]**_ **, Timothé Watteau** **, Georges Ghazi** _**[∗]**_ **and Ruxandra Mihaela Botez** _**[∗]**_


Laboratory of Applied Research in Active Control, Avionics and AeroServoElasticity (LARCASE), École de
Technologie Supérieure (ÉTS), Université de Québec, Montréal, QC H3C 1K3, Canada; timothe.wt@gmail.com
***** Correspondence: adrien.durand1709@gmail.com (A.D.); georges.ghazi@etsmtl.ca (G.G.);
ruxandra.botez@etsmtl.ca (R.M.B)


**Abstract:** The shortest path problem is fundamental in graph theory and has been studied extensively
due to its practical importance. Despite this aspect, finding the shortest path between two nodes
remains a significant challenge in many applications, as it often becomes complex and time consuming.
This complexity becomes even more challenging when constraints make the problem non-additive,
thereby increasing the difficulty of finding the optimal path. The objective of this paper is to
present a broad perspective on the conventional shortest path problem. It introduces a new method
to classify cost functions associated with graphs by defining distinct sets of cost functions. This
classification facilitates the exploration of line graphs and an understanding of the upper bounds on
the transformation sizes for these types of graphs. Based on these foundations, the paper proposes
a practical methodology for solving non-additive shortest path problems. It also provides a proof
of optimality and establishes an upper bound on the algorithmic cost of the proposed methodology.
This study not only expands the scope of traditional shortest path problems but also highlights their
computational complexity and potential solutions.


**Keywords:** universal shortest path problem; line graphs; graph cost functions; optimization techniques


**MSC:** 68R10


**Citation:** Durand, A.; Watteau, T.;


Ghazi, G.; Botez, R.M. Generalized



Shortest Path Problem: An Innovative


Approach for Non-Additive Problems


in Conditional Weighted Graphs.


_Mathematics_ **2024**, _12_ [, 2995. https://](https://doi.org/10.3390/math12192995)


[doi.org/10.3390/math12192995](https://doi.org/10.3390/math12192995)


Academic Editor: Andrea Scozzari


Received: 26 July 2024


Revised: 14 September 2024


Accepted: 21 September 2024


Published: 26 September 2024


**Copyright:** © 2024 by the authors.


Licensee MDPI, Basel, Switzerland.


This article is an open access article


distributed under the terms and


conditions of the Creative Commons


[Attribution (CC BY) license (https://](https://creativecommons.org/licenses/by/4.0/)


[creativecommons.org/licenses/by/](https://creativecommons.org/licenses/by/4.0/)


4.0/).



**1. Introduction**


Among the wide range of challenges addressed in graph theory, the problem of finding
the shortest path between two nodes (or vertices), commonly known as the shortest path
problem (SPP), is one of the most fundamental and most widely studied. Indeed, a variety
of real-world problems, ranging from network routing in communication systems [ 1 ],
robotics [ 2 ], transportation logistics [ 3, 4 ] and trajectories optimization [ 5 – 9 ], depend on the
efficient resolution of the SPP. In fact, regardless of the application context, the problem can
always be formulated to determine a path between two vertices of the graph that minimizes
the sum of the weights of the edges that compose it. Although this is a universal problem,
solving the shortest path remains a topic of interest for many researchers.
Over several decades, Dijkstra’s algorithm, introduced by Edsger W. Dijkstra in
1956 [ 10 ], and the A* algorithm, developed by Peter Hart, Nils Nilsson, and Bertram
Raphael in 1968 [ 11 ], have been used as fundamental methods for solving the SPP. Basically,
Dijkstra’s algorithm finds the shortest path from a starting node to all other nodes in a
weighted graph by iteratively selecting the node giving the smallest known distance and
by updating the distances to its neighboring nodes. The A* algorithm, on the other hand,
can be seen as an improvement of Dijkstra’s algorithm, as it uses heuristics to prioritize
paths that appear to be the smallest, thus often finding the shortest path more efficiently.
While practical in many problems, these algorithms can unfortunately be computationally
expensive and slow for very large graphs, particularly when there are complex constraints



_Mathematics_ **2024**, _12_ [, 2995. https://doi.org/10.3390/math12192995](https://doi.org/10.3390/math12192995) [https://www.mdpi.com/journal/mathematics](https://www.mdpi.com/journal/mathematics)


_Mathematics_ **2024**, _12_, 2995 2 of 24


between nodes and segments. These algorithms can also be inefficient, or even fail to find a
solution, when the cost function to be minimized is non-additive.
The difficulty of solving the SSP is not always due to the choice of the optimization
algorithm, but rather to the way in which the problem is defined. Loui [ 12 ] highlighted
this issue by criticizing the rigidity of classical SPP models and pointed out the relevance
of incorporating probabilistic weights in these methods under certain circumstances. To
address this problem, two solutions were proposed: (1) minimizing the expected values of
the weights, and (2) setting bounds for each weight and minimizing a combined function.
Another solution proposed by Loui was the use of dynamic programming, which consists
of solving a problem by dividing it into sub-problems, then solving these sub-problems
incrementally from the simplest to the most complex, storing their intermediate results.
The use of weighted graphs with random variables, instead of predetermined fixed
variables, is a common approach in the literature. This approach was used by Raj et al.
in [ 13 ] to improve the safety of hazardous goods transport routes. Their objective was to
identify the safest path in a graph, while imposing a variance constraint to mitigate paths
with excessive uncertainties. In fact, the modeling of the variance is particularly interesting
from an optimization point of view, as it does not reduce the cost function to a simple sum
of weights. Indeed, the variance, which is quadratic by nature, requires a more complex
calculation and can be determined for each path _p_ using a binary vector _x_ _∈_ [ 0, 1 ] _[|]_ _[E]_ _[|]_, such
that _x_ _α_ = 1 if _α_ _∈_ _p_, or _x_ _α_ = 0 otherwise. Starting from this definition, the variance of a path
can be computed using the covariance matrix _Q_ = [ _q_ _α_, _β_ ] _∈_ R _[|]_ _[E]_ _[|×|]_ _[E]_ _[|]_, which is symmetric
and positive definite, with rows and columns indexed by the segments of the graph. The
interaction cost between two arcs _α_ and _β_ is reflected by the sum of the off-diagonal entries
_q_ _α_, _β_ + _q_ _β_, _α_, while the linear cost of an arc _γ_ is represented by the diagonal element _q_ _γ_, _γ_ . The
variance of a path _p_ is then obtained by using the formula: Var ( _p_ ) = _x_ _[T]_ _Qx_ .
While Raj et al. [ 13 ] treated the variance as a constraint, Sen et al. [ 14 ] considered it as a
component of the cost function (or as the cost function itself). In their study, which focused
on the application of a shortest path algorithm for road traffic, they implemented a multiobjective optimization to balance the expected travel time and its variance. The concept
of considering a cost function of the form _f_ ( _p_ ) = _x_ _[T]_ _Qx_ is referred to as the quadratic
shortest path problem (QSPP). Hu and Sotirov in [ 15 ] proposed a solution to this problem
using semi-definite programming relaxation methods for directed graphs. They used the
alternating direction method of multipliers to find solutions and demonstrated that their
bounds were the strongest for this problem at that time. Many methods have also been
effective in addressing the QSPP, such as proposed by Rostami et al. [ 16, 17 ] and by Hu [ 18 ].
In several studies, the weighting of segments in shortest path calculations has been
treated using random variables. This technique is typically used when it is difficult to
predetermine the weights of segments in a graph. Weiss and Kaminka [ 19 ] proposed a
slightly different modeling approach by exploring shortest path computation techniques
when obtaining the exact segment weights is algorithmically expensive. To deal with this
complexity, they approximated the weights with a certain level of confidence using a cost
estimation function that provides bounds on the actual value of the weights. However,
this approach, while practical, requires the development of a shortest path algorithm that
works with these estimated weights, which may affect the optimality of the solution.
Turner and Hamacher in [ 20 ] introduced the concept of the universal shortest path
problem (USPP). This concept consists of incorporating and then extending previously
known variants, such as the largest edge cost (bottleneck SSP) and the difference between
the largest and smallest edge cost (balanced SPP). In a subsequent study [ 21 ], Turner
developed strongly polynomial-time algorithms to solve the USPP with equality constraints.
These efforts highlight the continuous evolution and diversification of methodologies to
address the complex challenges posed by shortest path problems.
An alternative modeling approach for addressing the SPP involves considering graph
weights not as real scalar values but as vectors. This vector-based method, adopted by
Jiang et al. [ 22 ], assigns distinct physical meanings to each vector component. For instance,


_Mathematics_ **2024**, _12_, 2995 3 of 24


in the context of a road network, vector weights might represent the length of a road
segment, the degree of congestion, and the probability of delays. The SPP can then be
solved by using a cost function that mathematically combines the vector components,
reducing it to a traditional cost function. However, this approach does not offer any
significant improvements; it simply organizes the data differently while solving the SPP
using Dijkstra’s or A* algorithms. It is therefore more adapted for multi-objective problems,
where the objective is to optimize multiple criteria as considered by Salzman et al. in [ 23 ]
to solve the SPP with two objective functions using heuristic methods. The vector-based
approach may seem trivial, because once the problem is modeled as a weighted graph with
associated quantities, engineers can easily apply standard physical formulas to derive a
relevant cost. However, the real challenge often lies in the initial modeling of the problem
as a weighted graph, for which this approach does not provides solutions.
Vidhya and Saraswathi [ 24 ] addressed the SPP under fuzzy conditions using trapezoidal intuitionistic fuzzy numbers (TrIFNs). These TrIFNs were used to model the uncertainties and inaccuracies associated with the arcs in a graph. The problem was formulated
as a bi-objective problem: minimizing costs and travel time. Each arc of the graph was
associated with a fuzzy cost ˜ _c_ _ij_ and a fuzzy time _t_ [˜] _ij_ .
The literature review clearly shows that in the majority of studies (if not all), a rigid
representation of the shortest path problem has always been considered. No current
approach envisages a weighting system that considers the position of a segment in the
graph, such as adapting the weights depending on the previous nodes (or segments) on
the path. It has also been observed that the shortest path problem and its variants offer
numerous opportunities for research and application. However, despite the popularity
of the problem, the costs associated with a path are typically computed in only three
ways: through (1) additive scalar cost functions of the form _f_ ( _p_ ) = ∑ _α_ _∈_ _p_ _c_ _α_, (2) quadratic
scalar cost functions _f_ ( _p_ ) = _x_ _[T]_ _Qx_, or (3) cost functions that incorporate vector weights.
Consequently, it seems both interesting and necessary to generalize the cost functions or
the methods of weighting the graphs to a wider range of problems.
This paper proposes to extend the concept of cost functions in traditional SPPs by
including non-additive functions. It provides a classification of these functions and introduces a method for solving the SPP using a non-additive cost function with conditional
weighting. Driven by practical engineering needs, the method is applied to a specific case
within the aeronautical sector. In this case study, the integration of geometric constraints
requires the use of non-additive cost functions, illustrating the practical application and
relevance of the proposed method.
The remainder of this paper is organized as follows: In Section 2, the notations used
throughout the paper are clarified. In Section 3, different types of cost functions are
classified by introducing new elements of analysis for finite graphs. The application of
the line graph and the estimation of the graph size following a sequence of iterated line
graphs are explored in Section 4. Insights from the previous sections are then combined in
Section 5 to optimally solve the shortest path problem using a _k_ -additive cost function. An
application example highlighting the relevance of this method is presented in Section 6.
The paper concludes with final remarks and conclusions in the last section.


**2. Notations for Graphs**


Two types of graphs are considered in this study: undirected graphs and directed
graphs (or digraphs). These sets will be denoted as _G_ and _G_ _d_, respectively. Basically, a
graph _G_ _∈G_ can be defined as a set of vertices (or nodes) _V_ connected by a set of edges
(or segments) _E_, and is mathematically denoted as _G_ = ( _V_, _E_ ) . A digraph is a type of
graph where the edges have a direction associated with them. This aspect means that the
connections between vertices are not bidirectional, as in a undirected graph, but follow a
specific direction from one vertex to another.
To distinguish edges from vertices, the following notations are used: vertices are
represented by lowercase Latin letters (e.g., _u_, _v_, etc.), while edges are represented by


_Mathematics_ **2024**, _12_, 2995 4 of 24


lowercase Greek letters (e.g., _α_, _β_, etc.). Based on these notations, the following properties
can be established:


           - If _G_ _∈G_ is an undirected graph, the vertices that constitute an edge are interchangeable.
Thus, any edge _α_ _∈_ _E_ defined as a set of nodes such as _α_ = _{_ _u_, _v_ _}_ with _u_, _v_ _∈_ _V_,
can be equivalently expressed as _α_ = _{_ _v_, _u_ _}_ . Consequently, an edge is a subset of _V_
composed of two elements.

           - If _G_ _[′]_ _∈G_ _d_ is a digraph, an edge can be seen as an ordered pair of two elements that are
obviously not interchangeable. Consequently, for any edge _α_ _∈_ _E_ defined as _α_ = ( _u_, _v_ )
with _u_, _v_ _∈_ _V_, a direction must be specified. For this purpose, the first element of the
directed edge, _α_ 1 = _u_, is referred to as the tail of the edge _α_, while the second element,
_α_ 2 = _v_, is referred to as the head of the edge _α_ .


Both directed and undirected graphs can be weighted. A weighted graph is defined as
_G_ = ( _V_, _E_, _w_ ) where _w_ : _E_ _→_ R is a function that assigns a real weight to each edge.
Finally, the set of neighbors of a vertex is denoted as _N_ ( _v_ ), and is defined as follows:
_N_ ( _v_ ) = _{_ _u_ _∈_ _V_ _|_ ( _v_, _u_ ) _∈_ _E_ _}_ . This set includes all vertices _u_ that are directly connected to
the vertex (or node) _v_ by an edge in the graph.


**3. Classification of Graph Cost Functions**


As discussed in Section 1, the effectiveness of solving the SPP depends not only on the
definition of the graph, but also on the nature of the cost function. This function is essential
for mathematically evaluating the efficiency of a path in terms of metrics to be minimized.
The objective of this section is to define three categories of cost functions applicable to any
SPP: (1) additive, (2) non-additive, and (3) _k_ -additive. In addition, this section provides
mathematical definitions to characterise these categories using techniques of differential
analysis on finite graphs.


_3.1. Elements of Differential Analysis on a Finite Graph_


Calculus on finite weighted graphs is a well-studied field. Dodziuk [ 25 ] initiated
the study of the Laplacian operator in the discrete domain, highlighting several properties of the continuous operator that transfer well to discrete representation. Subsequent
work by Woess [ 26 ] and McDonald and Meyers [ 27 ] further developed this framework by
considering the spaces of vertex or edge functions as a Hilbert space _H_ . This approach
involves defining an inner product in _H_ ( _V_ ) and _H_ ( _E_ ), which facilitates the application of
calculus concepts. The mathematical tools developed in these studies also allow the use
of differential operators, such as the weighted graph derivative _∂_ _x_ _i_ _f_ ( _x_ _j_ ), or the weighted
gradient ( _∇_ _w_ ) and divergence ( _∇_ _[∗]_ _w_ [), respectively, defined as] _[ ∇]_ _[w]_ _[f]_ [ (] _[x]_ _i_ [,] _[ x]_ _j_ [) =] _[ ∂]_ _[x]_ _i_ _[f]_ [ (] _[x]_ _j_ [)] [ with]
_f_ _∈H_ ( _V_ ) and _⟨_ _f_, _∇_ _[∗]_ _w_ _[F]_ _[⟩]_ _H_ ( _V_ ) [=] _[ ⟨∇]_ _[w]_ _[f]_ [,] _[ F]_ _[⟩]_ _H_ ( _E_ ) [with] _[ F]_ _[ ∈H]_ [(] _[E]_ [)] [.]
In this study, various concepts from differential calculus are applied to graphs in
order to characterize both the structure of the graph and its associated cost function. For
further information on this subject, readers are referred to the studies of Friedman and
Tillich [28–30]. These studies introduce a specialized form of “calculus” for graphs, allowing graph theory to make new connections with functional analysis. Such an innovative
approach has been applied effectively in various domains, including image processing,
machine learning, and network analysis [31–34].
Let _f_ : _P →_ R [+] be a cost function associated with a graph _G_, where _P_ denotes
the set of all paths in _G_ = ( _V_, _E_ ) . A path _p_ _∈P_ is an ordered list of nodes (or vertices)
without repetition, such that any two consecutive nodes in the list are connected by an edge.
Consequently, it can be written that _E_ _⊂P_ . Also, given the absence of node repetition in
any path, the number of possible paths is finite, i.e., _|P| <_ ∞.
We can introduce the _space of real path functions_ _H_ ( _P_ ), which is a _|P|_ -dimensional
Hilbert space such as:


_H_ ( _P_ ) = _{_ _f_ : _P →_ R _}_ (1)


_Mathematics_ **2024**, _12_, 2995 5 of 24


The variations of _f_ _∈H_ ( _P_ ) can be analysed by examining the function _∂_ _f_ (i.e., the
differential of _f_ ) which can be defined as follows:


_∂_ _f_ : _E_ _× P →_ R
(2)
( _α_, _p_ ) _�→_ _∂_ _f_ ( _α_ _|_ _α_ ˜ _∈_ _p_ ) = _f_ ( _α_ ˜ _∈_ _p_ ) _−_ _f_ ( _p_ _\_ _α_ )


where _α_ ˜ _∈_ _p_ means that the edge _α_ is included in the path _p_, and _f_ ( _p_ _\_ _α_ ) refers to the
evaluation of the cost function on the edges of _p_ excluding the edge _α_ .
Equation (2) can be re-written as:


_∂_ _f_ ( _α_ _|_ _p_ 1 _αp_ 2 ) = _f_ ( _p_ 1 _αp_ 2 ) _−_ ( _f_ ( _p_ 1 _u_ 1 ) + _f_ ( _u_ 2 _p_ 2 )), _α_ = ( _u_ 1, _u_ 2 ) (3)


to express the variation of _f_ with respect to an edge _α_ ˜ _∈_ _p_ that connects two paths _p_ 1 and _p_ 2
within _P_, such that _p_ = _p_ 1 _αp_ 2 . This equation is useful to describe the effect of including
the edge _α_ in a given path _p_ .
Similarly, Equation (4):


∆ _i_ = 1,2 _∂_ _f_ ( _α_ _|_ _p_ _i_ _α_ ) = _|_ _∂_ _f_ ( _α_ _|_ _p_ 1 _α_ ) _−_ _∂_ _f_ ( _α_ _|_ _p_ 2 _α_ ) _|_ (4)


can be used to quantify the difference in _∂_ _f_ between two paths _p_ 1 _α_ and _p_ 2 _α_ sharing the
same “terminal” edge _α_ . This equation is useful to compare the effect of connecting the
edge _α_ to two given paths, _p_ 1 and _p_ 2 .
Finally, using the mathematical definitions introduced in this section, we can establish
the following property for a generalized cost function _f_ .


**Property 1.** _The cost function_ _f_ _can be expressed as the sum of its local differentials by considering_
_the complete path p, such that:_
### f ( p ) = ∑ ∂ f ( α | p ) (5)

_α_ ˜ _∈_ _p_


_This representation of f is referred to as the “differential form of f”._


_3.2. Additive and Non-Additive Cost Functions_


In graph theory, an additive cost function is a function where the total cost is “simply”
the sum of individual costs associated with each edge that compose a path. This type of
function is commonly used in problems where the cost can be incrementally accumulated
without considering the interaction between edges or nodes.
Mathematically, an additive cost function can be defined on the graph set _P_ as follows:


_f_ _∈_ F _G_ ( 0 ) with F _G_ ( 0 ) = _{_ _f_ _∈H_ ( _P_ ) _|∀_ _p_, _α_ _∈P ×_ _E_, ∆ _i_ _∂_ _f_ ( _α_ _|_ _p_ _i_ ) = 0 _}_ (6)


F _G_ ( 0 ) is then the set of additive cost function. Based on this definition, a non-additive cost
function is any cost function associated with graph _G_ that does not belong to the set F _G_ ( 0 ),
such that:
_f_ / _∈_ F _G_ ( 0 ) _⇒_ _f_ _∈_ F _G_ ( 0 ) (7)


_3.3. k-Additive Cost Function_


A _k_ -additive cost function generalizes additive cost functions and refines the concept
of non-additive cost functions by incorporating interactions among up to _k_ components of
a path. In other words, a _k_ -additive cost function is a function for which the value of the
cost is influenced by interactions among up to _k_ components. Interactions beyond the _k_ [th]

component are assumed to be negligible or zero. This type of cost function is particularly
useful in problems where the cost associated with an edge in a graph is primarily influenced
by the properties of adjacent edges.
In addition, the _k_ -additivity nature of a cost function can be oriented. Therefore, we
can categorize the following three sets according to their orientation:


_Mathematics_ **2024**, _12_, 2995 6 of 24


**Definition 1.** _The k-additive on the left cost function set:_


F _G_ _[L]_ [(] _[k]_ [)] [ :] [=] _[ {]_ _[ f]_ _[ ∈H]_ [(] _[P]_ [)] _[|∀]_ _[p]_ [,] _[ α]_ _[ ∈P ×]_ _[ E]_ _[|]_ _[ l]_ [(] _[p]_ [)] _[ ≥]_ _[k]_ _[ ⇒]_ [∆] _[i]_ _[∂]_ _[f]_ [ (] _[α]_ _[|]_ _[q]_ _[i]_ _[p][α]_ [) =] [ 0] _[}]_ (8)


**Definition 2.** _The k-additive on the right cost function set:_


F _G_ _[R]_ [(] _[k]_ [)] [ :] [=] _[ {]_ _[ f]_ _[ ∈H]_ [(] _[P]_ [)] _[|∀]_ _[p]_ [,] _[ α]_ _[ ∈P ×]_ _[ E]_ _[|]_ _[ l]_ [(] _[p]_ [)] _[ ≥]_ _[k]_ _[ ⇒]_ [∆] _[i]_ _[∂]_ _[f]_ [ (] _[α]_ _[|]_ _[α][pq]_ _[i]_ [) =] [ 0] _[}]_ (9)


**Definition 3.** _The k-additive on the left and right cost function set:_



�



F _G_ _[LR]_ [(] _[k]_ [)] [ :] [=]



�



_f_ _∈H_ ( _P_ ) _|∀_ _p_ 1, _p_ 2, _α_ _∈P_ [2] _×_ _E_ _|_



_l_ ( _p_ 1 ) _≥_ _k_
� _l_ ( _p_ 2 ) _≥_ _k_ _[⇒]_ [∆] _[i]_ _[∂]_ _[f]_ [ (] _[α]_ _[|]_ _[q]_ _[i]_ _[p]_ [1] _[α][p]_ [2] _[q]_ _i_ _[′]_ [) =] [ 0]



(10)



We now understand that an additive cost function F _G_ ( 0 ) is a 0-additive cost function.
Specifically, if in the definition it is found that _l_ ( _p_ ) = 0, this indicates that _p_ is an empty
path, which is in line with the definition given in Equation (6)
The main concepts presented in this section are illustrated in Figure 1, which represents
a section of a graph _G_ .


( **a** ) ( **b** )
**Figure 1.** Representation of differential analysis tools on finite graph. ( **a** ) Representation of ∆ _∂_ _f_ ( _α_ _|_ _p_ ) .
( **b** ) Representation of the condition that _f_ _∈_ F _[L]_ ( _k_ ) .


Figure 1a illustrates the difference in _∂_ _f_ along the edge _α_ between two paths _q_ 1 and
_q_ 2 . Figure 1b, on the other hand, shows that if _∂_ _f_ on edge _α_ remains constant when
coming from two distinct paths _q_ 1 and _q_ 2, both distant by _k_ nodes, then the cost function
is _k_ -additive. Specifically, the equality between _f_ ( _q_ 1 _pα_ ) _−_ _f_ ( _q_ 1 _p_ ) and _f_ ( _q_ 2 _pα_ ) _−_ _f_ ( _q_ 2 _p_ ),
representing the differential of _f_ on the edge _α_ from paths _q_ 1 _p_ and _q_ 2 _p_ (i.e., _∂_ _f_ ( _α_ _|_ _q_ 1 _p_ ) and
_∂_ _f_ ( _α_ _|_ _q_ 2 _p_ ), respectively), confirms these _k_ -additive characteristics.


**Property 2.** _Let us consider the three sets_ F _G_ _[L]_ [(] _[k]_ [)] _[,]_ [ F] _G_ _[R]_ [(] _[k]_ [)] _[ and]_ [ F] _G_ _[LR]_ [(] _[k]_ [)] _[, as defined in]_ _[ Equations (][8][)–(][10][)]_ _[.]_
_Thus, we can write:_



_∀_ _k_ _∈_ N :







F _G_ _[L]_ [(] _[k]_ [)] _[⊆]_ [F] _G_ _[L]_ [(] _[k]_ [ +] [ 1] [)] [,]

F _G_ _[R]_ [(] _[k]_ [)] _[⊆]_ [F] _G_ _[R]_ [(] _[k]_ [ +] [ 1] [)] [,]

F _G_ _[LR]_ [(] _[k]_ [)] _[⊆]_ [F] _G_ _[LR]_ [(] _[k]_ [ +] [ 1] [)]



(11)



**Proof of Property 2.** Let _f_ _∈_ F _G_ _[L]_ [(] _[k]_ [)] [. By Definition][ 1][ of] [ F] _G_ _[L]_ [(] _[k]_ [)] [ given in Equation (][8][),] [ we have] [:]


_∀_ _p_, _e_ _|_ _l_ ( _p_ ) _≥_ _k_, ∆ _i_ _∂_ _f_ ( _q_ _i_ _pe_ ) = 0 (12)


This expression states that for any path _p_ and node _e_ where the length of _p_ (i.e.,
_l_ ( _p_ ) ) is at least _k_, the variation ∆ _i_ in the partial derivative _∂_ _f_ of the function _f_ along the
concatenated path _q_ _i_ _pe_ equals zero.


_Mathematics_ **2024**, _12_, 2995 7 of 24


We define _p_ _[′]_ = _vp_ with _p_ = _p_ [1] . . . _p_ _[k]_, and _p_ [1] _∈N_ ( _v_ ), which implies _p_ _[′]_ _∈P_ and
_l_ ( _p_ _[′]_ ) = _k_ + 1. Therefore, we have:


∆ _i_ _∂_ _f_ ( _q_ _i_ _[′]_ _[p]_ _[′]_ _[e]_ [) =] [ ∆] _[i]_ _[∂]_ _[f]_ [ (] _[q]_ _i_ _[′]_ _[vpe]_ [)] (13)


Given that _q_ _i_ _[′′]_ [=] _[ q]_ _i_ _[′]_ _[v]_ [,] _[ ∀]_ _[i]_ [, it follows that:]


∆ _i_ _∂_ _f_ ( _q_ _i_ _[′]_ _[p]_ _[′]_ _[e]_ [) =] [ ∆] _[i]_ _[∂]_ _[f]_ [ (] _[q]_ _i_ _[′′]_ _[pe]_ [)] (14)


Or, ∆ _i_ _∂_ _f_ ( _q_ _i_ _[′′]_ _[pe]_ [) =] [ 0, which implies that] _[ f]_ _[ ∈]_ [F] _G_ _[L]_ [(] _[k]_ [ +] [ 1] [)] [. This sequence of equalities]
demonstrates that the function _f_, which shows no change in differential after extending the
path beyond _k_ nodes, belongs to F _G_ _[L]_ [(] _[k]_ [ +] [ 1] [)] [.]
For F _G_ _[R]_ [(] _[k]_ [)] _[ ⊆]_ [F] _G_ _[R]_ [(] _[k]_ [ +] [ 1] [)] [, and] [ F] _G_ _[LR]_ [(] _[k]_ [)] _[ ⊆]_ [F] _G_ _[LR]_ [(] _[k]_ [ +] [ 1] [)] [ the proof is conducted with the]
same methodology and inverting path order.


Using the mathematical expressions and properties defined above, we can now represent a cost function as the sum of its local variations, as detailed in Property 3.


**Property 3.** _f_ _∈_ F _G_ ( _k_ ) _is_ _k_ _-additive because we can reduce its differential form (c.f. Equation (5))_
_to a sum of terms with the path considered being only k nodes long :_



_f_ ( _p_ ) = _f_ ( _p_ [1] . . . _p_ _[k]_ ) +



_l_ ( _p_ ) _−_ 1
### ∑ ∂ f ( p [i], p [i] [+] [1] | p [i] [+] [1] [−] [k] . . . p [i] [+] [1] ) (15)

_i_ = _k_



_This formulation is particularly useful for shortest path problems when the cost functions are non-_
_additive. By using the local variations, we can better understand how the costs accumulate along_
_the different segments of a path, even when the overall cost function is not simply the sum of the_
_costs of each segment._


There are certain cases where the form of the cost function adds complexity to solving
the shortest path problem. This complexity arises when the variations in the cost function
depend on paths of arbitrary lengths. Such a situation occurs with _k_ -additive functions
when _k_ _→_ ∞ . This set of functions, which includes all other sets of functions, represents the
most challenging category to analyze within this context.


**Definition 4.** _The general cost function set on G can be defined as:_



F _G_ _[X]_ [(] [∞] [)] [ :] [=][ F] _G_ _[X]_ [(] _[k]_ [)] �



F _G_ _[X]_ [(] _[k]_ [)] [,] _[ ∀]_ _[k]_ _[ ∈]_ [N] [,] _[ X]_ _[ ∈{]_ _[L]_ [,] _[ R]_ [,] _[ LR]_ _[}]_ (16)



Using Definition 4, we can conclude that if a function belongs exclusively to F _G_ _[X]_ [(] [∞] [)]
and to no other defined set of functions, it cannot be solved using the methods presented
in this paper for the shortest path problem.


_3.4. Examples of Classification_


Here, we provide two examples of cost functions which can be classified based on the
definitions proposed in the previous sub-sections.


3.4.1. A Classical F _G_ ( 0 ) Function


Let us consider that each edge _α_ _∈_ _E_ of a graph _G_ is associated with a weight _w_ _α_ . A
classical and trivial cost function would be to compute the cost of a path by summing the
weights of its constituent edges. This cost function is commonly used in many shortest
path problems. Although it is a simple model, it is often sufficient to solve the problem
under consideration. It can be defined as follows:


_Mathematics_ **2024**, _12_, 2995 8 of 24

### f ( p ) = ∑ w α (17)

_α_ ˜ _∈_ _p_


Given the structure of the cost function, it can be easily demonstrated that _f_ _∈_ F _G_ ( 0 ),
meaning that _f_ is additive.


3.4.2. A Simple General F _G_ _[L]_ [(] _[k]_ [)] [ Function]

Let us consider the sliding product window function _f_ _n_, defined such that:



_f_ _n_ ( _p_ ) =



_l_ ( _p_ ) _−_ _n_ _i_ + _n_
### ∑ ∏ p [k]
_i_ = 1 � _k_ = _i_ �



(18)



where _p_ _[k]_ _∈_ R .


**Property 4.** _Using the definition proposed in Section 3.3, it can be shown that:_


_f_ _n_ ( _p_ ) _∈_ F _G_ _[L]_ [(] _[n]_ [)] _[ ∩]_ [F] _G_ _[L]_ [(] _[n]_ _[ −]_ [1] [)] [.] (19)


**Proof of Property 4.** Let _α_ = ( _u_ 1, _u_ 2 ) _∈_ _E_, and _p_ = _p_ [1] . . . _p_ _[l]_ [(] _[p]_ [)] : _p_ _[i]_ _∈_ _V_ . Using the
definition of _f_ _n_ ( _p_ ) in Equation (18), _f_ _n_ ( _pα_ ) can be developed as follows:



(20)









_l_ ( _p_ )


### ∏ p [k]

 _k_ = _l_ ( _p_ ) _−_ _n_ + 2



 + _u_ 1 _u_ 2



_i_ + _n_
### ∏ p [k]
� _k_ = _i_ �



_f_ _n_ ( _pα_ ) =



_l_ ( _p_ ) _−_ _n_
### ∑

_i_ = 1



+ _u_ 1



_l_ ( _p_ )


### ∏ p [k]

 _k_ = _l_ ( _p_ ) _−_ _n_ + 1



 + _u_ 2























_l_ ( _p_ )


### ∏ p [k]

 _k_ = _l_ ( _p_ ) _−_ _n_ + 2











= _f_ _n_ ( _p_ ) + _u_ 1









_l_ ( _p_ )


### ∏ p [k]

 _k_ = _l_ ( _p_ ) _−_ _n_ + 1







Then, by using the definition of _∂_ _f_ given in Equation (2), we can write:


_∂_ _f_ _n_ ( _α_ _|_ _pα_ ) = _f_ _n_ ( _pα_ ) _−_ _f_ _n_ ( _p_ )



(21)













_l_ ( _p_ )


### ∏ p [k]

 _k_ = _l_ ( _p_ ) _−_ _n_ + 2

















 + _u_ 2







= _u_ 1



_l_ ( _p_ )


### ∏ p [k]

 _k_ = _l_ ( _p_ ) _−_ _n_ + 1







By assuming that _p_ _[′]_ = _v_ _i_ _pα_ where _v_ _i_ _∈_ _V_ can vary, we can study if the variation of _v_ _i_
modifies the cost _f_ ( _α_ _|_ _p_ _[′]_ ) :

- _l_ ( _p_ ) _≥_ _n_ _⇒_ ∆ _i_ _∂_ _f_ _n_ ( _α_ _|_ _v_ _i_ _pα_ ) = 0, thus _f_ _n_ _∈_ F _G_ _[L]_ [(] _[n]_ [)]

- _l_ ( _p_ ) = _n_ _−_ 1 _⇒_ ∆ _i_ _∂_ _f_ _n_ ( _α_ _|_ _v_ _i_ _pα_ ) = _∂_ _f_ _n_ ( _α_ _|_ _pα_ ) ∆ _v_ _i_ _̸_ = 0, thus _f_ _n_ _∈_ F _G_ _[L]_ [(] _[n]_ _[ −]_ [1] [)]

This result demonstrates that based on _l_ ( _p_ ), the cost function _f_ _n_ may either belong to
the set F _[L]_ _[f]_ _[n]_ [ is a member of the intersection of]
_G_ [(] _[n]_ [)] [ or to the set] [ F] _G_ _[L]_ [(] _[n]_ _[ −]_ [1] [)] [. Consequentl][y][,]

these two sets, implying that _f_ _n_ ( _p_ ) _∈_ F _G_ _[L]_ [(] _[n]_ [)] _[ ∩]_ [F] _G_ _[L]_ [(] _[n]_ _[ −]_ [1] [)] [.]


**4. Line Graph Application for k-Additive Functions**


In 1932, Whitney [ 35 ] introduced a new construction for undirected graphs, called _line_
_graphs_ . This concept was further extended to directed graphs ( _line digraph_ ) with the study
proposed by Harary and Norman [ 36 ]. Line digraphs are particularly useful in applications
where the relationships between the edges of a graph are as important as the relationships
between the vertices themselves. Consequently, they can be used to account for constraints
in a graph by converting problems stated in terms of edge connectivity into equivalent
problems stated in terms of vertex connectivity, which are often easier to analyze and solve
using existing graph algorithms.


_Mathematics_ **2024**, _12_, 2995 9 of 24


_4.1. Introduction to Line Graphs_

Basically, a line digraph _H_ = ( _V_ _H_, _E_ _H_ ) _∈G_ _d_ of a given digraph _G_ = ( _V_ _G_, _E_ _G_ ) _∈G_ _d_ is
a graph that represents the adjacencies between the edges of _G_ = ( _V_ _G_, _E_ _G_ ) . The line graph
is constructed using a transformation denoted as _H_ = _L_ _d_ ( _G_ ), and based on the following
conditions:


_V_ _H_ = _{_ _u_ _|_ _u_ = _α_ _∈_ _E_ _G_ _}_

(22)
_E_ _H_ = _{_ ( _α_, _β_ ) _|_ _α_, _β_ _∈_ _V_ _H_ _|_ _α_ 2 = _β_ 1 _}_


In Equation (22), the first condition means that each vertex of _H_ = ( _V_ _H_, _E_ _H_ ) corresponds to an edge of the original graph _G_ = ( _V_ _G_, _E_ _G_ ), while the second condition
implies that two vertices in _H_ = ( _V_ _H_, _E_ _H_ ) are connected by an edge if and only if their
corresponding edges in _G_ = ( _V_ _G_, _E_ _G_ ) share a common vertex.
The transformation _H_ = _L_ _d_ ( _G_ ) can be seen as a mapping application from the set of
digraphs to itself, denoted as: _L_ _d_ : _G_ _d_ _→G_ _d_ . It is important to note that there is a similar
mapping application _L_ : _G →G_ for undirected graphs; however, here, we only focus on
directed graphs. Indeed, any undirected graph _G_ can be converted into a directed graph
_G_ _[′]_ by transforming each undirected edge _{_ _u_, _v_ _} ∈_ _E_ _G_ into two directed edges ( _u_, _v_ ) _∈_ _E_ _G_ _′_
and ( _v_, _u_ ) _∈_ _E_ _G_ _′_ . Therefore, without loss of generality, the discussion in the remainder of
this paper will focus exclusively on directed graphs. Consequently, the notation _L_ _d_ ( _·_ ) will
be simplified to the more general notation _L_ ( _·_ ) .
Figure 2 illustrates a example of the process of generating a line digraph _G_ [1] = _L_ ( _G_ [0] )
from the original digraph _G_ [0] . As shown in this figure, the first step of the transformation
involves replacing each edge of the original digraph _G_ [0] with a vertex in _G_ [1] . The new
vertices in _G_ [1] are labeled to indicate the direction of the original edge in _G_ [0] they represent.
For example, the edge from vertex 1 to 4 in _G_ [0] becomes a vertex in _G_ [1] labeled as “14” (i.e.,
1 to 4). Subsequently, all vertices created in _G_ [1] are connected with directed edges based on
a specific rule: if two edges in _G_ [0] share a common vertex, and one edge’s arrival vertex is
the other edge’s departure vertex, then the corresponding vertices in _G_ [1] are connected by a
directed edge. For example, since _G_ [0] has edges from 1 to 4 and from 4 to 2, then in _G_ [1], the
vertex representing “14” will have a directed edge to the vertex representing “42”.



























**Figure 2.** Illustration of line graph transformation.


In this paper, we will use several iterations of _L_ ( _·_ ) . The sequence of graphs _G_ built by
the iteration of _L_ ( _·_ ) can be noted as:


_G_ [0], _G_ [1] = _L_ ( _G_ [0] ), _G_ [2] = _L_ ( _L_ ( _G_ [0] )) = _L_ [2] ( _G_ [0] ), . . ., _G_ _[m]_ = _L_ _[m]_ ( _G_ [0] ) (23)


This sequence was studied by van Rooij et al. [37], who demonstrated that if a graph
contains a cycle, the sequence will never end with an empty graph. They also found that
the size of graphs could increase without bounds. This aspect can cause problems if _L_ ( _·_ )
must be numerically iterated a significant number of times.
Figure 3 illustrates a more general procedure for generating the transformation
_L_ ( _G_ _[n]_ _[−]_ [1] ) from the graph _G_ _[n]_ .


_Mathematics_ **2024**, _12_, 2995 10 of 24















**Figure 3.** General transformation from _G_ _[n]_ _[−]_ [1] = _L_ _[n]_ _[−]_ [1] ( _G_ ) to _G_ _[n]_ = _L_ _[n]_ ( _G_ ) .


_4.2. Algebraic Formulation of the Adjacency Matrix of a Line Graph Sequence_


One of the fundamental tools in graph analysis is the adjacency matrix. This binary matrix captures all connections between the vertices of a graph, thereby defining its structure.
However, graph transformations completely redefine these connections. Consequently, it
becomes necessary to determine the equivalent adjacency matrix for a line graph _G_ [(] _[n]_ [)] that
results from applying the transformation _L_ _[n]_ ( _G_ ) multiple times.
For this purpose, we introduce the application _E_ ( _·_ ), which is a matrix transformation
that squares the size of the matrix. This transformation is defined as follows:


_E_ : _M_ _n_ _→M_ _n_ 2 (24)
A _�→E_ (A) = (A _⊗_ A) _⊙_ ∆ _n_


where _⊙_ represents the Hadamard product, or element-wise product, and ∆ _n_ _∈M_ _n_ 2 ( _{_ 0, 1 _}_ )
is built such that:



_D_ 1 _[n]_ . . . _D_ _n_ _[n]_

... ...
_D_ 1 _[n]_ . . . _D_ _n_ _[n]_



, with [ _D_ _kn_ []] _i_, _j_ [=] _[ δ]_ _[i]_ [,] _[k]_ (25)





∆ _[n]_ =









and _D_ _k_ _[n]_ [is filled with zeros, except on the] _[ k]_ [th] [ row filled with ones.]


**Theorem 1.** _Let_ A _∈M_ _n_ ( _{_ 0, 1 _}_ ) _be the adjacency binary matrix associated with the digraph_
_G_ _∈G_ _d_ _. The matrix composed of non-zeros rows and columns from_ _E_ (A) _is the adjacency matrix_
_of L_ ( _G_ ) _._


**Proof of Theorem 1.** Let _G_, _H_ _∈G_ _d_, such that _L_ ( _G_ ) = _H_, and let A _G_ be the adjacency matrix associated with _G_ . In this proof, we will construct the adjacency matrix A _H_ associated
with _H_ .

Let us assume that we do not know if an edge exists; we will then consider all
possibilities. Each node _u_ in _V_ _G_ can potentially be connected to any other node _v_ in _V_ _G_,
including itself (if we allow self-loops ( _u_, _u_ ) ). This results in _|_ _V_ _G_ _|_ [2] possible connections. If
we denote _|_ _V_ _G_ _|_ = _n_, therefore, the size of the matrix A _H_ will be _n_ [2] _×_ _n_ [2] .
Let us keep the order of the nodes used in the adjacency matrix A _G_ as follows:


_u_ 1, _u_ 2, _· · ·_, _u_ _n_


We choose the order of the nodes for A _H_ as follows:


_Mathematics_ **2024**, _12_, 2995 11 of 24


( _u_ 1, _u_ 1 ), ( _u_ 1, _u_ 2 ), _· · ·_, ( _u_ 1, _u_ _n_ ), ( _u_ 2, _u_ 1 ), _· · ·_ ( _u_ 2, _u_ _n_ ), _· · ·_, ( _u_ _n_, _u_ _n_ )


Thus, we can say that:

           - There could be a one in the line _k_ = _in_ + _v_, corresponding to _α_ _k_ = ( _u_ _i_, _u_ _v_ ) in A _H_ only
if [A _G_ ] _i_, _v_ = 1; meaning that _α_ _k_ = ( _u_ _i_, _u_ _v_ ) _∈_ _E_ _G_ .

           - There could be a one in the _k_ [th] line, with _k_ = _in_ + _v_, and the _l_ [th] row, with _l_ = _jn_ + _w_,
corresponding to the connection ( _α_ _k_, _α_ _l_ ) only if _v_ = _j_ ; meaning that ( _α_ _k_ ) 2 = ( _α_ _l_ ) 1 (i.e.,
the second node of _α_ _k_ is equal to the first node of _α_ _k_ ).


Using Properties 1–3, we can deduce that:


[A _H_ ] _k_, _l_ = [A _G_ ] _i_, _v_ _×_ [A _G_ ] _j_, _w_ _×_ _δ_ _v_, _j_ (26)


where _k_ = _in_ + _v_ and _l_ = _jn_ + _w_ .
By definition of the Kronecker product ( _⊗_ ) and using the definition of _E_ ( _·_ ) and ∆ _[n]_ in
Equations (24) and (25), respectively, we can write:


_A_ _H_ = (A _G_ _⊗_ A _G_ ) _⊙_ ∆ _n_ = _E_ (A _G_ ) (27)


This last result thus demonstrates that _E_ (A _G_ ) is the adjacency matrix of _A_ _H_ .


The result of Theorem 1 can be generalized to a line digraph _G_ _[m]_ resulting from
_m_ -transformations, using the following theorem:


**Theorem 2.** _Let_ A _∈M_ _n_ ( _{_ 0, 1 _}_ ) _be the adjacency binary matrix associated with the digraph_
_G_ _∈G_ _d_ _. The matrix defined by:_



�



_E_ _[m]_ (A) =



2 _m_
� A
� _i_ = 1



_⊙_ _K_ _m_ : _K_ 1 = ∆ _n_ ; _K_ _m_ + 1 = ( _K_ _m_ _⊗_ _K_ _m_ ) _⊙_ ∆ _n_ 2 _m_ + 1 (28)



_is the adjacency matrix of G_ _[m]_ = _L_ _[m]_ ( _G_ )


**Proof of Theorem 2.** Let A _G_ _m_ _∈M_ _n_ . We can demonstrate the result shown in Theorem 2
using a proof by induction. For this purpose, let us denote ( _∗_ ) as the property we want to
demonstrate.


- For _m_ = 1: the proof of Theorem 1 demonstrates that the property ( _∗_ ) is true.

- For _m_ + 1: we assume that the property ( _∗_ ) is true for a given _m_, meaning that:



�



A _G_ _m_ =



2 _m_
� A
� _i_ = 1



_⊙_ _K_ _m_ (29)



is the adjacency matrix of _G_ _[m]_ = _L_ _[m]_ ( _G_ ) .

Using the result of the proof of Theorem 1, we can say that A _G_ _m_ + 1 = _E_ (A _G_ _m_ ) is the
adjacency matrix of _L_ ( _G_ _[m]_ ) = _G_ _[m]_ [+] [1], and we can write:


_E_ (A _G_ _m_ ) = (A _G_ _m_ _⊗_ A _G_ _m_ ) _⊙_ ∆ _X_ (30)


To determine the value of _X_, we need the size of A _G_ _m_ . If A G is a _n_ _×_ _n_ matrix, then
A _G_ 1 is a _n_ [2] _×_ _n_ [2] matrix. By induction: A _G_ _m_ is a _n_ [2] _[m]_ _×_ _n_ [2] _[m]_ so _X_ = _n_ [2] _[m]_ [+] [1], since:


_E_ (A _G_ _m_ ) = (A _G_ _m_ _⊗_ A _G_ _m_ ) _⊙_ ∆ _n_ 2 _m_ + 1



�



2 _m_
� A
�� _i_ = 1



�



_⊗_

�



_⊙_ _K_ _m_



��



(31)
_⊙_ ∆ _n_ 2 _m_ + 1



=



2 _m_
� A
��� _i_ = 1



_⊙_ _K_ _m_


_Mathematics_ **2024**, _12_, 2995 12 of 24


Using the direct product and Kronecker product rules, and arranging the terms of the
equations, we obtain :



_E_ (A _G_ _m_ ) =



2 _×_ 2 _m_
� A
� _i_ = 1 �



_⊙_ ( _K_ _m_ _⊗_ _K_ _m_ ) _⊙_ ∆ _n_ 2 _m_ + 1 (32)



Based on the definition of _K_ _m_ + 1, we can write:



� A

_i_ = 1



_E_ (A _G_ _m_ ) =







 2 _[m]_ [+] [1]

�

_i_ = 1





 _⊙_ _K_ _m_ + 1 (33)



This last result implies that � 2 _i_ = _m_ 1 + 1 [A] _⊙_ _K_ _m_ + 1 is the adjacency matrix of _L_ _[m]_ [+] [1] ( _G_ ) .
� �

Thus, the property ( _∗_ ) is true for _m_ + 1.
In conclusion, the property ( _∗_ ) is true for all _m_ _∈_ N _[∗]_


Finally, Theorem 3 can be used to quantify the upper bound of the complexity of the
iterated line graphs in terms of the number of edges, considering that while the structure
becomes increasingly interconnected, it is still finite and bounded as a function of the
number of vertices _n_ and the number of iterations _m_ .


**Theorem 3.** _For any graph_ _G_ _, the number of edges of its associated_ _m_ _[th]_ _line graph_ _L_ _[m]_ ( _G_ ) _is_
_bounded. This aspect implies:_ _∀_ _G_ _∈G_, _|_ _V_ _G_ _|_ = _n_ _⇒|_ _E_ _L_ _m_ ( _G_ ) _| ≤_ _n_ _[m]_ [+] [2]


**Proof of Theorem 3.** Let us define the application _S_ ( _·_ ) as the sum of all terms of a matrix,
such as:


_S_ : _M →_ R



_n_
### A �→S (A) = ∑

_i_ = 1



_n_ (34)
_a_
### ∑ ij

_j_ = 1



The application _S_ ( _·_ ) can be used to count the number of edges in a graph given its
adjacency matrix. Specifically, for a graph _G_ _∈G_ with its associated adjacency matrix A _G_,
applying _S_ (A _G_ ) yields the number of edges, represented as _|_ _E_ _G_ _|_ .
Considering that A and _K_ _m_ are binary matrices, we can write :


_S_ ( _E_ _[m]_ (A)) _≤S_ ( _K_ _m_ ) (35)


We need to know the value of _S_ ( _K_ _m_ ) depending on _m_ . Let _K_ _m_ _∈M_ _n_ and _K_ _m_ + 1 =
( _K_ _m_ _⊗_ _K_ _m_ ) _⊙_ ∆ _n_ . Thus, [ _K_ _m_ + 1 ] _n_ ( _i_ _−_ 1 )+ _v_, _n_ ( _j_ _−_ 1 )+ _w_ = [ _K_ _m_ ] _iv_ _×_ [ _K_ _m_ ] _jw_ _×_ _δ_ _jv_, and:



_n_ [2]
### S ( K m + 1 ) = ∑

_k_ = 1



_n_ [2]
### ∑ [ K m + 1 ] kl (36)

_l_ = 1



Let _k_ = _n_ ( _i_ _−_ 1 ) + _v_ and _l_ = _n_ ( _j_ _−_ 1 ) + _w_ with _i_, _j_, _v_, _w_ _∈_ � 1, _n_ � . We can therefore
rewrite the previous equation as follows:


_Mathematics_ **2024**, _12_, 2995 13 of 24



_n_
### S ( K m + 1 ) = ∑

_i_ = 1


_n_

=
### ∑

_i_ = 1


_n_

=
### ∑

_i_ = 1


_n_

=
### ∑

_i_ = 1



_n_
### ∑

_j_ = 1


_n_
### ∑

_j_ = 1



_n_
### ∑

_v_ = 1



_n_
### ∑ [ K m ] iv × [ K m ] jw × δ jv

_w_ = 1



_n_
### ∑ [ K m ] ij × [ K m ] jw

_w_ = 1



�



_n_
### ∑

_w_ = 1



_n_
### ∑ [ K m ] ij × [ K m ] jw
� _j_ = 1



(37)



� �� �

[ _K_ _m_ [2] ] _iw_


_n_
### ∑ [ K m [2] []] iw [=] [ S] [(] [K] m [2] [)]

_w_ = 1



which means that _∀_ _m_ _∈_ N _[∗]_, _S_ ( _K_ _m_ + 1 ) = _S_ ( _K_ _m_ [2] [)] [.]
Moreover, if a graph has _n_ nodes, it implies that _K_ 1 _∈M_ _n_ 2 . We find that _S_ ( _K_ 1 ) = _n_ [3] .
Additionally, _∀_ _m_ _∈_ N _[∗]_, the relationships _S_ ( _K_ _m_ [2] [) =] _[ n]_ _[ · S]_ [(] _[K]_ _[m]_ [)] [ holds.]
By integrating all this information, we deduce that _S_ ( _K_ _m_ ) = _n_ _[m]_ _[−]_ [1] _· S_ ( _K_ 1 ) = _n_ _[m]_ [+] [2] .
Finally, we can conclude that _|_ _E_ _L_ _m_ ( _G_ ) _| ≤_ _n_ _[m]_ [+] [2] .


As shown in Figure 4, the size of the iterated line graph could increase exponentially
with the number of transformations _m_ . For instance, by considering a digraph _G_ with
_n_ = 10 nodes, the associated 6 [th] line digraph, i.e., _L_ [6] ( _G_ ), will have a maximum of 10 [7] nodes.
This aspect represents one of the main drawbacks of using multiple transformations, as it
could become too time-consuming to generate the _m_ [th] line digraph.



10 [9]


10 [8]


10 [7]


10 [6]





10 [5]


10 [4]


10 [3]


10 [2]


10 [1]

|Col1|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|
|---|---|---|---|---|---|---|---|---|---|
||~~_n_~~<br>_n_|~~= 2~~<br> = 4||||||||
||_n_<br>~~_n_~~|= 6<br>~~= 8~~||||||||
||_n_|= 10||||||||
|||||||||||
|||||||||||
|||||||||||
|||||||||||
|||||||||||



0 1 2 3 4 5 6 7

_m_


**Figure 4.** Evolution of the maximal size of the digraph.


**5. Application of Line Graph Sequences for Non-Additive Shortest Path Problems**


This section provides a comprehensive procedure for solving the shortest path problem
using non-additive cost functions. Several algorithms are proposed to be used for (1)
constructing the line digraph, (2) adding conditional weights to the generated line digraph
to include constraints, and (3) adapting Dijkstra’s algorithm to the line digraph. In addition,
a proof of the optimality of the proposed methodology is also provided.


_5.1. Problem Definition_


Let consider the following optimization problem associated with a digraph _G_ =
( _V_ _G_, _E_ _G_ ) _∈G_ _d_ :


_Mathematics_ **2024**, _12_, 2995 14 of 24


min _f_ ( _p_ ) _|_ _f_ _∈_ F _G_ ( _k_ )
_p_ _∈P_ _G_



(38)



_s_ . _t_ .







_p_ 1 = _s_

_p_ _n_ = _t_, with _n_ = _l_ ( _p_ )
_∀_ _i_ _∈_ �1, _n_ � _|_ ( _p_ _i_, _p_ _i_ + 1 ) _∈_ _E_ _G_



This problem is similar to the shortest path problem, except that the cost function is a
_k_ -additive cost function. The only constraints are that the first and the last vertices of the
path are imposed: _s_ for the source, and _t_ for the target, and that the path can only follow
the edges of the graph.


_5.2. Proposed Methodology—Conditional Weighting Shortest Path (CWSP)_


To solve the optimization problem presented in Equation (38), it is first necessary to
construct a substitute graph, and then to use the properties of the _k_ -additive cost functions
established in Section 3 to add weights to this substitute graph. Extra weighted edges
can be introduced to connect the original graph _G_ with the substitute graph _H_ . Finally,
Dijkstra’s algorithm can be adapted and applied to the weighted substitute graph to solve
the optimization problem in Equation (38). Algorithms 1–3 can be applied for that purpose.


**Algorithm 1:** Construction of a line graph _L_ ( _G_ )

**Input:** Graph _G_ = ( _V_ _G_, _E_ _G_ ) .
**Result:** _L_ ( _G_ ) .
_V_ _L_ ( _G_ ) _←{_ ( _α_ ) : _α_ _∈_ _E_ _G_ _}_
_E_ _L_ ( _G_ ) _←_ ∅
**for** _α_ _∈_ _E_ _G_ **do**

**for** _β_ _∈_ _E_ _G_ **do**

**if** _α_ 2 = _β_ 1 **then**

_E_ _L_ ( _G_ ) _←_ _E_ _L_ ( _G_ ) _∪{_ ( _α_, _β_ ) _}_
**end**

**end**
_L_ ( _G_ ) _←_ ( _V_ _L_ ( _G_ ), _E_ _L_ ( _G_ ) )
**end**


Algorithm 1 is proposed for constructing the line digraph _L_ ( _G_ ) associated with the
digraph _G_ . This transformation converts the original problem, which is stated in terms of
edge connectivity, into a substitute (or equivalent) problem expressed in terms of vertex
connectivity. Figures 5 and 6 illustrate an example of the application of Algorithm 1.
Figure 5a shows the original digraph _G_, while Figure 5b shows the resulting line digraph
_L_ ( _G_ ) = _H_ . The line digraph in Figure 5b is then completed to include all entering nodes,
as shown in Figure 6. These nodes represent the entry nodes into the original graph, i.e., all
nodes that have only one connection with another node in the original digraph _G_ .
Once the line digraph _L_ ( _G_ ) is constructed, it serves as the substitute graph. The edges
of this new graph must be weighted based on the static weights present in the original
digraph _G_, as well as on various constraints typically captured by the _k_ -non-additive
cost function _f_ ( _p_ ) . This process is performed with Algorithm 2. For instance, using the
the sliding product window _f_ _swp_ ( _p_ ) as defined in Equation (18), and considering the
line digraph in Figure 6, we can determine the weight for the edge (( 2, 6 ), ( 6, 8 )) to be
_∂_ _f_ 2 ( 6, 8 _|_ 2, 6, 8 ) = 96. Similarly, for an entering edge such as ( 3, ( 3, 4 )), the weight would be
_f_ _swp_ ( 3, 4 ) = 12.


_Mathematics_ **2024**, _12_, 2995 15 of 24


**Algorithm 2:** Conditional weighting of a substitute graph

**Input:** Graph: _G_ = ( _V_ _G_, _E_ _G_ ) .
Cost function : _f_ .
_k_ order of additivity of _f_
**Result:** _H_ = ( _V_ _H_, _E_ _H_, _W_ _H_ ) .
_H_ _←_ _L_ _[k]_ ( _G_ ) _▷_ Using Algorithm 1
**for** ( _p_, _q_ ) _∈_ _E_ _H_ **do**

_▷_ _l_ ( _p_ ) = _l_ ( _q_ ) = _k_ + 1
( _u_ 1 . . . _u_ _k_ + 1 ) _←_ _p_
( _v_ 1 . . . _v_ _k_ + 1 ) _←_ _q_
_β_ _←_ ( _u_ _k_ + 1, _v_ _k_ + 1 ) _▷_ _β_ _∈_ _E_ _G_
_w_ _α_ _←_ _∂_ _f_ ( _β_ _|_ _α_ )
**end**

_V_ _H_ _←_ _V_ _H_ � _V_ _G_
**for** _p_ _∈_ _V_ _H_ **do**

_p_ 1 _←_ _u_
_γ_ _←_ ( _u_, _p_ ) _▷_ _γ_ is an enter edge from _G_ to _H_
_E_ _H_ _←_ _E_ _H_ � _{_ _γ_ _}_
_w_ _γ_ _←_ _f_ ( _p_ . . . _p_ _k_ )
**end**
_W_ _H_ _←{_ _w_ _α_ : _α_ _∈_ _E_ _H_ _}_


**Algorithm 3:** Dijkstra for a substitute graph

**Input:** Graph _H_ = ( _V_ _H_, _E_ _H_ ), source node _s_, and target node _t_ .
**Result:** _p_ _[∗]_

**for** _v_ _∈_ _V_ _H_ **do**

cost[ _v_ ] _←_ ∞
predecessor[ _v_ ] _←_ ∅
**end**

cost[ _s_ ] _←_ 0
_Q_ _←_ _V_ _H_
**while** _Q_ _̸_ = ∅ **do**

_u_ _←_ extract-min ( _Q_ )
**for** _α_ = ( _u_, _v_ ) **do**

**if** _cost_ [ _v_ ] _>_ _cost_ [ _u_ ] + _w_ _α_ **then**

cost [ _v_ ] _←_ cost [ _u_ ] + _w_ _α_ predecessor [ _v_ ] _←_ _u_
**end**

**if** _v_ _k_ + 1 = _t_ **then**

_u_ _last_ = _v_
**break**
**end**

**end**

**end**
_p_ _[∗]_ = ( _t_ )

_u_ = _u_ _last_
**while** _l_ ( _u_ ) = _k_ + 1 **do**

_v_ = _u_
_u_ _←_ predecessor [ _v_ ]
_p_ _[∗]_ _←_ ( _u_ _k_ + 1, _p_ _[∗]_ )
**end**
_p_ _[∗]_ _←_ ( _v_ 1 . . . _v_ _k_, _p_ _[∗]_ )


_Mathematics_ **2024**, _12_, 2995 16 of 24



































( **a** ) ( **b** )

**Figure 5.** Illustration of a digraph _G_ and its transformation _H_ = _L_ ( _G_ ) . ( **a** ) Original digraph _G_ .
( **b** ) Resulting line digraph _H_ = _L_ ( _G_ ) .































**Figure 6.** Line graph with entering nodes.


Finally, using the conditional weighted line digraph _H_ = ( _V_ _H_, _E_ _H_, _W_ _H_ ) obtained with
Algorithm 2, the shortest path from the source node _s_ to the target node _t_ in _H_ can be
determined using Dijkstra’s algorithm (see Algorithm 3). It is important to consider that
a node _v_ in _H_ represents a series of node in _G_ . This configuration implies that the target
node _t_ _∈_ _V_ _G_ is reached when the last element of _v_ _∈_ _V_ _H_ is _t_, and the length of _v_ is _k_ + 1.
The stop criterion in Dijkstra’s algorithm will be achieved when _v_ _k_ + 1 = _t_ .
The set of the three Algorithms 1–3 constitutes the conditional weighting shortest path
(CWSP) method for solving a shortest path problem when the cost function is _k_ -left-additive
F _[L]_ ( _k_ ) or _k_ -right-additive F _[R]_ ( _k_ ) .


_5.3. Proof of Optimality and Algorithmic Cost_


The optimal path _p_ _[∗]_ returned by Algorithm 3 represents the shortest path between the
source node _s_ and the target node _t_ within the substitute graph _H_ . This optimal path can be
transferred to the original graph _G_, and the next Property 5 guarantees that the transferred
path is indeed the optimal path that minimizes the cost function described in Equation (38).


**Property 5.** _The path returned by Algorithm 3 is a path that minimizes the cost function_ _f_ ( _p_ ) _,_
_such that:_
_p_ _[∗]_ _∈_ argmin _{_ _f_ ( _p_ ) _|_ _p_ _∈P_, _p_ 1 = _s_, _p_ _n_ = _t_ _}_ (39)


_Mathematics_ **2024**, _12_, 2995 17 of 24


**Proof of Property 5.** First of all, because _f_ _∈_ F _G_ ( _k_ ), we can break it into the sum of local
differentials using Property 1:
### f ( p ) = ∑ ∂ f ( α | p ) (40)

_α_ ˜ _∈_ _p_


Let us define _q_ _∈P_ _H_, such that:


_q_ 1 = _p_ 1 _[∗]_
(41)
_q_ _i_ = _p_ _i_ _[∗]_ [. . .] _[ p]_ _[∗]_ _k_ + _i_ [for] _[ i]_ [ =] [ 1 . . .] _[ n]_ _[ −]_ _[k]_


and let us define _T_ _H_ = _{_ _v_ _∈_ _V_ _H_ _|_ _v_ _k_ + 1 = _t_ _}_ .
Dijkstra’s algorithm ensures that:



_q_ _∈_ argmin


### ∑ w α | q 1 = s, q n ∈ T H

� _α_ ˜ _∈_ _q_



�



and:
### ∑ w α = f ( p 1 [∗] [. . .] [ p] [∗] k [) +] ∑ ∂ f ( β | α ) with β = ( α k + 1 α k + 2 ) (42)

_α_ ˜ _∈_ _q_ _α_ ˜ _∈_ _q_ _\_ _q_ 1


Since _l_ ( _α_ _\_ _β_ ) = _k_ and _f_ _∈_ F _G_ ( _k_ ), we find that ∆ _r_ _∂_ _f_ ( _β_ _|_ _rα_ ) = 0. In addition, _∀_ _α_ ˜ _∈_ _q_, it
follows that _α_ ˜ _∈_ _p_ _[∗]_ . Therefore, we can substitute _∂_ _f_ ( _β_ _|_ _α_ ) = _∂_ _f_ ( _β_ _|_ _p_ _[∗]_ ) .
We can also change the sum of variables as follows:


_α_ ˜ _∈_ _q_ _\_ _q_ 1 _→_ _β_ ˜ _∈_ _p_ _[∗]_ _\_ ( _p_ 1 _[∗]_ [. . .] _[ p]_ _[∗]_ _k_ [)] [ :] [=] _[ p]_ _[′]_ (43)


which leads to:

### ∑ w α = f ( p 1 [∗] [. . .] [ p] [∗] k [) +] ∑ f ( β | p [∗] ) = f ( p [∗] ) (44)

_α_ ˜ _∈_ _q_ _β_ _∈_ _p_ _[′]_


In conclusion, _p_ _[∗]_ is indeed the minimum solution of the k-additive cost function
problem.


In addition to assessing optimality, it might also be interesting to determine the
algorithmic cost of the proposed CWSP method. This cost can be evaluated in terms of the
maximum number of iterations required to solve the optimization problem. This parameter
depends on two aspects: the size of the initial graph _|_ _V_ _G_ _|_, and the order of the cost function
_k_ . Property 6 can be used to determine this cost.


**Property 6.** _Consider a graph_ _G_ = ( _V_ _G_, _E_ _G_ ) _such as_ _|_ _V_ _G_ _|_ = _n_ _, and an associated cost function_
_f_ _∈_ F _[X]_ ( _k_ ) _, where X_ = _{_ _R or L_ _}_ _. Thus:_

_1._ _The algorithmic cost of computing L_ _[k]_ ( _G_ ) _is at highest order_ _O_ _m_ + _n_ _[k]_ [+] [2] [�] _._
�

_2._ _The algorithmic cost of the CWSP algorithm is, at highest order,_ _O_ ( _n_ _[k]_ [+] [1] ( _n_ + ( _k_ + 1 ) log ( _n_ ))) _._


**Proof of Property 6.**
**1. The algorithm cost of computing** _L_ ( _G_ ) **is** _O_ ( _|_ _E_ _G_ _|_ ) **:**
Theorem 1 establishes that at a given iteration _i_, the number of edges is bounded by
_|_ _E_ _L_ _i_ ( _G_ ) _| ≤_ _n_ _[i]_ [+] [2] . Summing all the costs, we obtain the following result:



_m_
### cost = ∑ | E L i ( G ) |

_i_ = 0

cost = _m_ + _n_ [3] + _n_ [4] + . . . + _n_ _[m]_ [+] [2]


cost ∝ _m_ + _n_ _[m]_ [+] [2]



(45)


_Mathematics_ **2024**, _12_, 2995 18 of 24


**2. The algorithmic cost of the CWSP with a Fibonacci heap [38]:**
Since _|_ _E_ _L_ _k_ ( _G_ ) _| ≤_ _n_ _[k]_ [+] [2], and using the definition of _L_ ( _·_ ), we can write :


_|_ _V_ _L_ _k_ ( _G_ ) _|_ = _|_ _E_ _L_ _k_ _−_ 1 ( _G_ ) _|_ (46)


which implies:
_|_ _V_ _L_ _k_ ( _G_ ) _| ≤_ _n_ _[k]_ [+] [1] (47)


The computational cost of Dijkstra’s algorithm is _O|_ _E_ _|_ + _|_ _V_ _|_ log ( _|_ _V_ _|_ ), and it is used
in the last step with Algorithm 3. By substitution we can upper-bound the number of
iterations, _n_ _it_ :
_n_ _it_ = _|_ _E_ _L_ _k_ ( _G_ ) _|_ + _|_ _V_ _L_ _k_ ( _G_ ) _| ·_ log ( _|_ _V_ _L_ _k_ ( _G_ ) _|_ )



_≤_ _n_ _[k]_ [+] [2] + _n_ _[k]_ [+] [1] log ( _n_ _[k]_ [+] [1] )



(48)



_≤_ _n_ _[k]_ [+] [1] ( _n_ + ( _k_ + 1 ) log ( _n_ ))


Therefore, the computational cost is at most _O_ ( _n_ _[k]_ [+] [1] ( _n_ + ( _k_ + 1 ) log ( _n_ ))) .


**6. Application: Case Study in Airport Trajectory Optimization**


One of the main motivations for the development of the shortest path technique with
conditional weighting is to address problems where constraints, which can be geometric or
physical, can lead to the generation of paths that are infeasible in practice.
A typical example is the management of aircraft ground trajectories at airports. Indeed,
airports impose various types of restrictions and rules that pilots must comply with, such
as directional taxiways and prohibited turns to avoid sharp maneuvers or to account for the
size (or weight) of the aircraft. In addition, aircraft can accelerate or decelerate as they enter
or exit turns. Consequently, their ground speeds are influenced by their current trajectory
and the segment they will taxiing next. As illustrated in Figure 7a, these factors create areas
within the airport where the ground speed of an aircraft cannot be predetermined. In the
segments in the circled area in Figure 7a, the aircraft ground speed can vary according to
three scenarios: the aircraft can (1) maintain its ground speed if it continues on the straight
segment; (2) decelerate if it enters a turn; or (3) accelerate if it exits a turn. Additionally,
certain trajectories are prohibited due to restrictions on maneuvers, such as sharp turns.
For instance, as shown in Figure 7a, the aircraft is not authorized to perform a left turn to
enter the turn segment, or a right turn to exit the turn segment.
Due to these constraints, optimizing the ground trajectory of an aircraft within a graph that





|Col1|Col2|Col3|Col4|Col5|Col6|
|---|---|---|---|---|---|
|||||||
|||||||
|||||||
||||**Lege**|**nd:**<br>|**nd:**<br>|
||||**Lege**|**nd:**<br>|**nd:**<br>|
|||||~~Taxiways~~<br>Runways<br>Map nodes<br>||
|||||~~Gate Positions~~<br>Parking Positions||


−73.76 −73.75 −73.74 −73.73 −73.72


Longitude - [deg]







**Figure 7.** Illustration of a graph for an airport and constraint during ground operations. ( **a** ) Example
of restrictions along the path of an aircraft during taxi operation. ( **b** ) Example of a graph for Montreal
Trudeau International Airport (CYUL).


_Mathematics_ **2024**, _12_, 2995 19 of 24


_6.1. Model_


In this section, we evaluate the effectiveness of the conditional weighting shortest path
method proposed in this paper for solving the shortest path problem in an airport, taking
into account constraints on sharp turns.
The cost function for this application is based on the total distance traveled by the
aircraft, while avoiding sharp turns. All sharp turns are determined _a priori_ on the original
graph using a classification method that considers four nodes (or three edges) to verify if
the middle segment is allowed. Turn constraints are included in the cost function with a
barrier function _b_ ( _·_ ), defined as:


_b_ : _V_ [4] _→{_ 1, + ∞ _}_



_b_ ( _v_ _i_ _−_ 1, . . ., _v_ _i_ + 2 ) =



1, if the turn is authorized

+ ∞, if the turn is not authorized
�



(49)



By considering the function:
_d_ : _V_ [2] _→_ R [+] (50)


which returns the distance between two points of the airport, the cost function can be
expressed as follows:



_f_ ( _p_ ) = _d_ ( _v_ 1, _v_ 2 ) +



_l_ ( _p_ ) _−_ 2
### ∑ d ( v i, v i + i ) · b ( v i − 1, . . ., v i + 2 ) + d ( v n − 1, v n ) · c ( v n − 3, . . ., v n ) (51)

_i_ = 2



Using the definitions and properties introduced in Section 3.3, we can confirm that
_f_ ( _p_ ) belongs to F _G_ _[LR]_ [(] [2] [)] [ (see Equation (][10][)). Indeed, the left–right] _[ k]_ [-additivity nature of the]
cost function comes from the need to consider information about the edges preceding and
succeeding a given edge to accurately classify sharp turns.


_6.2. Methodology and Results_


To compare and validate the CWSP method, the optimization problem described
in Equation (38) was applied to Miami International Airport. In addition, 50 different
scenarios were considered to find the shortest path between two randomly selected points
on the airport graph, each separated by at least 20 nodes. For each scenario, the CWSP
method using the non-additive cost function specified in Equation (51) was applied. At
the same time, Dijkstra’s algorithm was also applied; however, since it cannot handle
non-additive cost functions, the cost function for this algorithm was limited to the total
distance traveled by the aircraft:



_f_ _[∗]_ ( _p_ ) =



_l_ ( _p_ ) _−_ 1
### ∑ d ( v i, v i + 1 ) (52)

_i_ = 1



which is additive by nature.
It should be noted that the optimal solution found by Dijkstra’s algorithm was further
evaluated using the cost function described in Equation (51). This evaluation determined
whether the solution provided by Dijkstra’s algorithm was reliable (i.e., feasible) or not. If
the value of the cost function was finite, this indicated that Dijkstra’s algorithm had found a
viable solution. Conversely, if the value of the cost function was infinite, this suggested that
the solution was not feasible in practice, as it included at least one prohibited sharp turn.
Figure 8 shows examples of results comparisons for four different problems. In
this figure, the trajectory found by Dijkstra’s algorithm is highlighted in green, while
the trajectory found by the CWSP method is highlighted in blue. At a first glance, both
strategies were able to find a trajectory between the source and destination nodes. However,
when the trajectory found by Dijkstra’s algorithm was evaluated using the cost function in
Equation (51), an infinite cost value was observed. This result can be attributed to the fact


_Mathematics_ **2024**, _12_, 2995 20 of 24


that the solution provided by Dijkstra’s algorithm contains sharp turns that are forbidden.
These turns are marked with red circles for each problem. In contrast, the CWSP method
successfully found a better and feasible solution without any forbidden turns.







( **a** )



( **b** )







( **c** ) ( **d** )

**Figure 8.** Examples of results; comparison between a trajectory found by the CWSP method and
a trajectory found using Dijkstra’s algorithm. ( **a** ) Problem #4. ( **b** ) Problem #40. ( **c** ) Problem #47.
( **d** ) Problem #49.


This analysis was repeated for all 50 problems. A table summarizing the results
for each problem is included in the Appendix A. By analyzing the results, it was found
that the CWSP method successfully solved all problems, consistently finding the shortest
feasible trajectory while avoiding sharp turns. Dijkstra’s algorithm was also able to find a
solution, but only 28% of these solutions were reliable (i.e., feasible without forbidden turns).
Interestingly, as shown in the table in the Appendix A, whenever Dijkstra’s algorithm found
an acceptable solution, it was identical to the solution found by the CWSP method. This
analysis is significant because it shows that the CWSP method is not only capable of finding
the shortest path in the sense of Dijkstra’s algorithm, it is also well-suited to handle complex
graphs with constraints or to deal with non-additive cost functions.


**7. Conclusions**


In this paper, we presented a generalization of classical cost functions on graphs,
traditionally called “additive” functions, which are part of the space of real edge functions.
This generalization leads to the development of real path functions, a category known as
non-additive or _k_ -additive. While these functions are applicable to various shortest path
problems, their complexity makes traditional shortest path algorithms designed to optimize
real edge functions unsuitable.


_Mathematics_ **2024**, _12_, 2995 21 of 24


To address a shortest path problem, our first step was to develop tools for characterizing and analyzing path functions. By studying the variations of these functions, we were
able to classify them into distinct sets.
Then, for a subset of these non-additive function sets, we proposed a technique for
solving the shortest path problem. This technique relies on the weighting of a substitute
graph, which is determined by successive iterations of transforming a graph into its
associated line graph. The proposed method has proven effective on a simple problem that
could not have been solved using Dijkstra’s algorithm alone, demonstrating its potential for
application to numerous physical and engineering problems requiring complex modeling.
This article establishes an initial framework and provides an exact solution that represents
a significant advance in the field of complex shortest path problems.
However, the computational cost of such a method is difficult to bound because it
strongly depends on the topology of the initial graph. Furthermore, the complexity of the
cost function rapidly increases with the size of the replacement graph used to accurately
solve the problem. Finally, this method, with its solid proof of convergence, can be used
to validate the efficiency of faster heuristic methods for solving the shortest path problem
with non-additive path functions.
The research initiated in this paper can be extended in several directions. Firstly, the
upper bound provided for the size of the linear graph sequence is highly dependent on the
structure of the initial graph. A tighter limit could potentially be obtained by examining
how the sequence of linear graphs evolves as a function of the topology of the initial
graph. Furthermore, it has been observed that when _k_ is large, the cost of constructing
and weighting the line graph becomes significant. It would be useful to study and limit
the error introduced when approximating a _k_ -additive cost function by a ( _k_ _−_ _n_ ) -additive
cost function, where _n_ _<_ _k_ . This approach could lead to faster solutions to the problem
while quantifying the associated error. Finally, the general concept of non-additive cost
functions encompasses different types of functions. The methodology proposed in this
paper is suitable for functions in F( _k_ ) . However, we believe that exact methods applicable
to functions in F( ∞ ) which are similar to quadratic forms such as _f_ ( _p_ ) = _x_ _[T]_ _Qx_ ”, are also
worth exploring.


**Author Contributions:** Conceptualization, A.D.; funding acquisition, G.G. and R.M.B.; methodology,
A.D. and T.W.; project administration, G.G.; supervision, G.G. and R.M.B.; validation, A.D. and T.W.;
writing—original draft, A.D.; writing—review and editing, G.G. and R.M.B. All authors have read
and agreed to the published version of the manuscript.


**Funding:** This research was funded by the Natural Sciences and Engineering Research Council of
Canada (NSERC: RGPIN-2022-03864), and by the Fonds de Recherche ÉTS sur les Changements
Climatiques (FRECC).


**Data Availability Statement:** Dataset available on request from the authors.


**Acknowledgments:** This research was performed at the Laboratory of Applied Research in Active
Controls, Avionics and AeroServoElasticity research (LARCASE). The authors would like to thank the
Fond de Recherche ÉTS sur les Changements Climatiques (FRECC) for their support of this project.


**Conflicts of Interest:** The authors declare no conflicts of interest.


**Abbreviations**


The following abbreviations are used in this manuscript:


SPP Shortest Path Problem

USPP Universal Shortest Path Problem

QSPP Quadratic Shortest Path Problem
CWSP Conditional Weighting Shortest Path
LARCASE Laboratory of Applied Research in Active Control, Avionics and AeroServoElasticity


_Mathematics_ **2024**, _12_, 2995 22 of 24


_G_ Set of graphs
_P_ Set of paths in a graph
_H_ ( _P_ ) Space of real path functions
_G_ = ( _V_, _E_ ) General graph
_f_ ( _·_ ) General cost function
_∂_ _f_ ( _·|·_ ) differential of _f_
∆ _i_ = 1,2 _X_ _i_ Variation on any quantity _X_ _i_
_p_ _\_ _α_ Path _p_ deprived of edge _α_
F _[X]_ Set of _k_            - additive cost function in direction _X_
_G_ [(] _[k]_ [)]
A Adjacency matrix
∆ _[n]_ Binary matrix define in Equation (25)
_L_ ( _G_ ) Line graph of _G_


**Appendix A. Results for All 50 Problems**


**N** _**[◦]**_ **Problem** **Dijkstra’s Algorithm** **Dijkstra’s Algorithm** **Conditional Weighting**
**Solution Cost** **Solution Cost** **Method Considering**
**Ignoring Constraints** **Considering Constraints** **Constraints**


1 1959.5 + ∞ 2017.1


2 3945.8 + ∞ 3983.9


3 768.1 768.1 768.1


4 2327.3 + ∞ 2655.8


5 1128.2 1128.2 1128.2


6 308.8 + ∞ 836.8


7 1014.6 1014.6 1014.6


8 2061.4 + ∞ 2094.6


9 2297.5 + ∞ 3940.0


10 1434.3 1434.3 1434.3


11 1720.5 + ∞ 1889.7


12 2567.8 + ∞ 4500.3


13 946.7 + ∞ 1047.1


14 593.0 + ∞ 648.0


15 607.2 + ∞ 690.3


16 1389.8 + ∞ 1828.7


17 2884.8 + ∞ 2962.4


18 2751.1 + ∞ 2958.0


19 2044.1 2044.1 2044.1


20 2023.3 2023.3 2023.3


21 1913.3 + ∞ 2074.1


22 2249.4 2249.4 2249.4


23 3877.6 + ∞ 4133.8


24 1340.1 + ∞ 1421.6


25 3225.7 + ∞ 3258.5


_Mathematics_ **2024**, _12_, 2995 23 of 24


**N** _**[◦]**_ **Problem** **Dijkstra’s Algorithm** **Dijkstra’s Algorithm** **Conditional Weighting**
**Solution Cost** **Solution Cost** **Method Considering**
**Ignoring Constraints** **Considering Constraints** **Constraints**


26 2898.6 + ∞ 2954.3


27 426.0 + ∞ 1317.5


28 519.1 519.1 519.1


29 2282.8 + ∞ 2695.8


30 2071.3 + ∞ 2128.9


31 1838.7 1838.7 1838.7


32 2562.8 + ∞ 2782.2


33 1408.9 1408.9 1408.9


34 365.6 + ∞ 1266.3


35 1948.7 + ∞ 2055.0


36 3694.3 + ∞ 5595.6


37 951.5 + ∞ 2937.5


38 1988.0 + ∞ 1992.8


39 1294.4 1294.4 1294.4


40 2533.9 + ∞ 2603.4


41 2934.4 2934.4 2934.4


42 2945.9 2945.9 2945.9


43 2512.1 2512.1 2512.1


44 1635.1 1635.1 1635.1


45 477.9 477.9 477.9


46 1506.4 1506.4 1506.4


47 1762.6 + ∞ 1775.0


48 1380.4 + ∞ 2324.4


49 1729.8 + ∞ 2080.2


50 990.7 + ∞ 1192.2


Number of solution Not applicable 14 50


**References**


1. Wang, R.; Zhou, M.; Wang, J.; Gao, K. An Improved Discrete Jaya Algorithm for Shortest Path Problems in Transportation-Related
Processes. _Processes_ **2023**, _11_ [, 2447. [CrossRef]](http://doi.org/10.3390/pr11082447)
2. Wahhab, O.; Al-Araji, A.S. An Optimal Path Planning Algorithms for a Mobile Robot. _Iraqi J. Comput. Commun. Control Syst. Eng._
**2021**, _21_ [, 44–58. [CrossRef]](http://dx.doi.org/10.33103/uot.ijccce.21.2.4)
3. Rosyida, I.; Asih, T.S.N.; Waluya, S.; Sugiyanto. Fuzzy Shortest Path Approach for Determining Public Bus Route (Case study:
Route planning for “Trans Bantul bus” in Yogyakarta, Indonesia). _J. Discret. Math. Sci. Cryptogr._ **2021**, _24_ [, 557–577. [CrossRef]](http://dx.doi.org/10.1080/09720529.2021.1891692)
4. Priliana, C.Y.; Rosyida, I. The Ambulance Route Efficiency for Transporting Patients to Referral Hospitals Based on Distance and
Traffic Density Using the Floyd-Warshall Algorithm and Google Traffic Assistance. In Proceedings of the 4th International Seminar
on Science and Technology (ISST 2022), Palu, Indonesia, 2–3 November 2022; Atlantis Press: Amsterdam, The Netherlands, 2023;
[pp. 349–360. [CrossRef]](http://dx.doi.org/10.2991/978-94-6463-228-6_39)
5. Murrieta Mendoza, A.; Beuze, B.; Ternisien, L.; Botez, R.M. Branch & Bound-Based Algorithm for Aircraft VNAV Profile Reference
Trajectory Optimization. In Proceedings of the 15th AIAA Aviation Technology, Integration, and Operations Conference, Dallas,
[TX, USA, 22–26 June 2015; American Institute of Aeronautics and Astronautics: Reston, VA, USA. 2015. [CrossRef]](http://dx.doi.org/10.2514/6.2015-2280)
6. Murrieta-Mendoza, A.; Hamy, A.; Botez, R.M. Four- and Three-Dimensional Aircraft Reference Trajectory Optimization Inspired
by Ant Colony Optimization. _J. Aerosp. Inf. Syst._ **2017**, _14_ [, 597–616. [CrossRef]](http://dx.doi.org/10.2514/1.I010540)
7. Murrieta-Mendoza, A.; Botez, R.M.; Bunel, A. Four-Dimensional Aircraft En Route Optimization Algorithm using the Artificial
Bee Colony. _J. Aerosp. Inf. Syst._ **2018**, _15_ [, 307–334. [CrossRef]](http://dx.doi.org/10.2514/1.I010523)
8. Murrieta-Mendoza, A.; Romain, C.; Botez, R.M. 3D Cruise Trajectory Optimization Inspired by a Shortest Path Algorithm.
_Aerospace_ **2020**, _7_ [, 99. [CrossRef]](http://dx.doi.org/10.3390/aerospace7070099)


_Mathematics_ **2024**, _12_, 2995 24 of 24


9. Durand, A.; Toulet, M.; Ghazi, G.; Botez, R.M. An Innovative Approach to Aircraft Ground Trajectory Optimization using a
Bi-Directional A* Algorithm. In Proceedings of the Canadian Aeronautics and Space Institute (CASI) AERO23 Conference,
Ottawa, ON, Canada, 14–16 November 2023.
10. Dijkstra, E.W. A note on two problems in connexion with graphs. _Numer. Math._ **1959**, _1_ [, 269–271. [CrossRef]](http://dx.doi.org/10.1007/BF01386390)
11. Hart, P.E.; Nilsson, N.J.; Raphael, B. A Formal Basis for the Heuristic Determination of Minimum Cost Paths. _IEEE Trans. Syst._
_Sci. Cybern._ **1968**, _4_ [, 100–107. [CrossRef]](http://dx.doi.org/10.1109/TSSC.1968.300136)
12. Loui, R.P. Optimal paths in graphs with stochastic or multidimensional weights. _Commun. ACM_ **1983**, _26_ [, 670–676. [CrossRef]](http://dx.doi.org/10.1145/358172.358406)
13. Sivakumar, R.A.; Batta, R. The variance-constrained shortest path problem. _Transp. Sci._ **1994**, _28_ [, 309–316. [CrossRef]](http://dx.doi.org/10.1287/trsc.28.4.309)
14. Sen, S.; Pillai, R.; Joshi, S.; Rathi, A.K. A Mean-Variance Model for Route Guidance in Advanced Traveler Information Systems.
_Transp. Sci._ **2001**, _35_ [, 37–49. [CrossRef]](http://dx.doi.org/10.1287/trsc.35.1.37.10141)
15. Hu, H.; Sotirov, R. On solving the quadratic shortest path problem. _INFORMS J. Comput._ **2020**, _32_ [, 219–233. [CrossRef]](http://dx.doi.org/10.1287/ijoc.2018.0861)
16. Rostami, B.; Malucelli, F.; Frey, D.; Buchheim, C. On the Quadratic Shortest Path Problem. In Proceedings of the Experimental
[Algorithms, Paris, France, 29 June–1 July 2015; Springer: Berlin/Heidelberg, Germany, 2015; pp. 379–390. [CrossRef]](http://dx.doi.org/10.1007/978-3-319-20086-6_29)
17. Rostami, B.; Chassein, A.; Hopf, M.; Frey, D.; Buchheim, C.; Malucelli, F.; Goerigk, M. The Quadratic Shortest Path Problem:
Complexity, Approximability, and Solution Methods. _Eur. J. Oper. Res._ **2018**, _268_ [, 473–485. [CrossRef]](http://dx.doi.org/10.1016/j.ejor.2018.01.054)
18. Hu, H.; Sotirov, R. A Polynomial Time Algorithm for the Linearization Pproblem of the QSPP and its Applications. _arXiv_ **2018**,
arXiv:1802.02426.

19. Weiss, E.; Kaminka, G.A. A Generalization of the Shortest Path Problem to Graphs with Multiple Edge-Cost Estimates. In
Proceedings of the ECAI 2023, Kraków, Poland, 30 September–4 October 2023.
20. Turner, L.; Hamacher, H.W. On Universal Shortest Paths. In Proceedings of the Operations Research Proceedings 2010: Selected
Papers of the Annual International Conference of the German Operations Research Society, 1–3 September 2011; Springer:
[Berlin/Heidelberg, Germany, 2011; pp. 313–318. [CrossRef]](http://dx.doi.org/10.1007/978-3-642-20009-0_50)
21. Turner, L. Variants of the Shortest Path Problem. _Algorithmic Oper. Res._ **2011**, _6_, 91–104.
22. Jiang, S.; Feng, Z.; Zhang, X.; Wang, X.; Rao, G. A Multi-dimension Weighted Graph-Based Path Planning with Avoiding Hotspots.
In Proceedings of the Knowledge Graph and Semantic Computing: Semantic, Knowledge, and Linked Big Data, Singapore, 19–22
[September 2016; pp. 15–26. [CrossRef]](http://dx.doi.org/10.1007/978-981-10-3168-7_2)
23. Salzman, O.; Felner, A.; Hernández, C.; Zhang, H.; Chan, S.H.; Koenig, S. Heuristic-Search Approaches for the Multi-Objective
Shortest-Path Problem: Progress and Research Opportunities. In Proceedings of the Proceedings of the Thirty-Second International
[Joint Conference on Artificial Intelligence, Macao, China, 19–25 August 2023; pp. 6759–6768. [CrossRef]](http://dx.doi.org/10.24963/ijcai.2023/757)
24. Vidhya, K.; Saraswathi, A. A Novel Method for Finding the Shortest Path with Two Objectives Under Trapezoidal Intuitionistic
Fuzzy Arc Costs. _Int. J. Anal. Appl._ **2023**, _21_ [, 121–121. [CrossRef]](http://dx.doi.org/10.28924/2291-8639-21-2023-121)
25. Dodziuk, J. Difference Equations, Isoperimetric Inequality and Transience of Certain Random Walks. _Trans. Am. Math. Soc._ **1984**,
_284_ [, 787–794. [CrossRef]](http://dx.doi.org/10.1090/S0002-9947-1984-0743744-X)
26. Woess, W. _Random Walks on Infinite Graphs and Groups_ ; Cambridge Tracts in Mathematics, Cambridge University Press: Cambridge,
[UK, 2000. [CrossRef]](http://dx.doi.org/10.1017/CBO9780511470967)
27. McDonald, P.; Meyers, R. Diffusions on Graphs, Poisson Problems and Spectral Geometry. _Trans. Am. Math. Soc._ **2002**,
_354_ [, 5111–5136. [CrossRef]](http://dx.doi.org/10.1090/S0002-9947-02-02973-2)
28. Friedman, J.; Tillich, J.P. Calculus on Graphs. _arXiv_ **2004** [, arXiv:cs/0408028. [CrossRef]](https://doi.org/10.48550/arXiv.cs/0408028)
29. Friedman, J.; Tillich, J.P. Laplacian Eigenvalues and Distances Between Subsets of a Manifold. _J. Differ. Geom._ **2000**, _56_, 285–299.

[[CrossRef]](http://dx.doi.org/10.4310/jdg/1090347645)
30. Friedman, J.; Tillich, J.P. Wave Equations for Graphs and the Edge-Based Laplacian. _Pac. J. Math._ **2004**, _216_ [, 229–266. [CrossRef]](http://dx.doi.org/10.2140/pjm.2004.216.229)
31. Elmoataz, A.; Lezoray, O.; Bougleux, S. Nonlocal Discrete Regularization on Weighted Graphs: A Framework for Image and
Manifold Processing. _IEEE Trans. Image Process._ **2008**, _17_ [, 1047–1060. [CrossRef] [PubMed]](http://dx.doi.org/10.1109/TIP.2008.924284)
32. Gilboa, G.; Osher, S. Nonlocal Operators with Applications to Image Processing. _Multiscale Model. Simul._ **2009**, _7_, 1005–1028.

[[CrossRef]](http://dx.doi.org/10.1137/070698592)
33. Desquesnes, X.; Elmoataz, A.; Lézoray, O. Eikonal Equation Adaptation on Weighted Graphs: Fast Geometric Diffusion Process
for Local and Non-Local Image and Data Processing. _J. Math. Imaging Vis._ **2013**, _46_ [, 238–257. [CrossRef]](http://dx.doi.org/10.1007/s10851-012-0380-9)
34. Mahmood, F.; Shahid, N.; Skoglund, U.; Vandergheynst, P. Adaptive Graph-Based Total Variation for Tomographic Reconstructions. _IEEE Signal Process. Lett._ **2018**, _25_ [, 700–704. [CrossRef]](http://dx.doi.org/10.1109/LSP.2018.2816582)
35. Whitney, H. Congruent Graphs and the Connectivity of Graphs. _Am. J. Math._ **1992**, _54_ [, 150–168. [CrossRef]](http://dx.doi.org/10.2307/2371086)
36. Harary, F.; Norman, R.Z. Some Properties of Line Digraphs. _Rend. Del Circ. Mat. Palermo_ **1960**, _9_ [, 161–168. [CrossRef]](http://dx.doi.org/10.1007/BF02854581)
37. van Rooij, A.C.M.; Wilf, H.S. The Interchange Graph of a Finite Graph. _Acta Math. Acad. Sci. Hung._ **1965**, _16_ [, 263–269. [CrossRef]](http://dx.doi.org/10.1007/BF01904834)
38. Fredman, M.L.; Tarjan, R.E. Fibonacci heaps and their uses in improved network optimization algorithms. _J. ACM_ **1987**,
_34_ [, 596–615. [CrossRef]](http://dx.doi.org/10.1145/28869.28874)


**Disclaimer/Publisher’s Note:** The statements, opinions and data contained in all publications are solely those of the individual
author(s) and contributor(s) and not of MDPI and/or the editor(s). MDPI and/or the editor(s) disclaim responsibility for any injury to
people or property resulting from any ideas, methods, instructions or products referred to in the content.


