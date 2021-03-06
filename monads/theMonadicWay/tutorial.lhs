HaskellWiki
	

Haskell | Wiki community | Recent changes
Random page | Special pages
 
	

Not logged in
Log in | Help

Edit this page | Discuss this page | Page history | What links here | Related changes
The Monadic Way/Part I

< The Monadic Way

Categories: Tutorials | Monad

Note: this is the first part of The Monadic Way
Contents
[hide]

    * 1 An evaluation of Philip Wadler's "Monads for functional programming"
    * 2 A simple evaluator
          o 2.1 The basic evaluator
    * 3 Some output, please!
          o 3.1 The basic evaluator with output
    * 4 Let's go monadic
          o 4.1 Monadic evaluator with output
    * 5 What does bind bind?
    * 6 Some sugar, please!
          o 6.1 Monadic evaluator with output in do-notation
    * 7 Type and Newtype: What happened to our output?
    * 8 Errare monadicum est
          o 8.1 The basic evaluator, non monadic, with exception
          o 8.2 The basic evaluator, monadic, with exceptions
          o 8.3 Monadic evaluator with output and exceptions
    * 9 We need a state
          o 9.1 The basic evaluator, non monadic, with a counter
          o 9.2 The evaluator, monadic, with a counter
          o 9.3 The monadic evaluator with output and counter in do-notation
    * 10 If there's a state we need some discipline: Dealing with complexity
          o 10.1 Monadic evaluator with output, counter and exception, in do-notation
    * 11 Suggested readings
    * 12 Acknowledgments

[edit]
1 An evaluation of Philip Wadler's "Monads for functional programming"

This tutorial is a "translation" of Philip Wadler's "Monads for functional programming". (avail. from here)

I'm a Haskell newbie trying to grasp such a difficult concept as the one of Monad and monadic computation.

While "Yet Another Haskell Tutorial" gave me a good understanding of the type system when it comes to monads I find it almost unreadable.

But I had also Wadler's paper, and started reading it. Well, just wonderful! It explains how to create a monad!

So I decided to "translate it", in order to clarify to myself the topic. And I'm now sharing this translation ('not completed yet) with the hope it will be useful to someone else.

Moreover, this is a wiki, so please improve it. Specifically, please correct my poor English. I'm Italian, after all.

Note: The source of this page can be used as a literate Haskell file and can be run with ghci or hugs: So cut paste change and run (in emacs for instance) while reading it...
[edit]
2 A simple evaluator

Let's start with something simple: suppose we want to implement a new programming language. We just finished with Abelson and Sussman's Structure and Interpretation of Computer Programs and we want to test what we have learned.

Our programming language will be very simple: it will just compute the sum of two terms.

So we have just one primitive operation (Add) that takes two constants and calculates their sum.

Moreover we have just one kind of algebraic datatype: Con a, which is an Int.

For instance, something like:

 (Add (Con 5) (Con 6))

should yield:

 11

[edit]
2.1 The basic evaluator

We will implement our language with the help of a data type constructor such as:

> module TheMonadicWay where
> data Term = Con Int
>          | Add Term Term
>            deriving (Show)

After that we build our interpreter:

> eval :: Term -> Int
> eval (Con a) = a
> eval (Add a b) = eval a + eval b

That's it. Just an example:

 *TheMonadicWay> eval (Add (Con 5) (Con 6))
 11
 *TheMonadicWay>

Very very simple. The evaluator checks if its argument is of the form Con Int. When it is, the function just returns the Int.

If the argument is not of the form Con, but it is of the form Add Term Term, it evaluates the first Term and sums the result with the result of the evaluation of the second Term.

As you may understand, our evaluator uses some of the powerful features of Haskell type system. Instead of writing a parser that takes a string (the user input) and transforms that string into an expression to be evaluated, we use the two type constructors defined for our data type Term (Con and Add) to build the expression - such as (Add (Con 5) (Con 6)) - and to match the expression's elements in our "eval" function.
[edit]
3 Some output, please!

Now, that's fine, but we'd like to add some features, like providing some output, to show how the computation was carried out.

Well, but Haskell is a pure functional language, with no side effects, we were told.

Now we seem to be wanting to create a side effect of the computation, its output, and be able to stare at it...

If we had some global variable to store the output that would be simple...

But we can create the output and carry it along the computation, concatenating it with the old one, and present it at the end of the evaluation together with the evaluation of the expression given to our evaluator/interpreter!
[edit]
3.1 The basic evaluator with output

Simple and neat:

> type MOut a = (a, Output)
> type Output = String
> 
> formatLine :: Term -> Int -> Output
> formatLine t a = "eval (" ++ show t ++ ") <= " ++ show a ++ " - \n"                                                       
> 
> evalO :: Term -> MOut Int
> evalO (Con a) = (a, formatLine (Con a) a)
> evalO (Add t u) = ((a + b),(x ++ y ++ formatLine (Add t u) (a + b)))
>     where (a, x) = evalO t
>           (b, y) = evalO u

Now we have what we want. But we had to change our evaluator quite a bit.

First we added a function, formatLine, that takes an argument of type Term (the expression to be evaluated), one of type Int (the result of the evaluation of Term) and gives back an output of type Output (that is a synonym of String). This is just a helper function to format the string to output. Not very interesting at all.

The evaluator itself changed quite a lot! Now it has a different type signature: it takes an argument of type Term and produces a new type, we called it MOut, that is actually a compound pair of a variable type a (an Int in our evaluator) and a type Output, a string.

So our evaluator, now, will take a Term (the type of the expressions in our new programming language) and will produce a pair, composed of the result of the evaluation (an Int) and the Output, a string.

So far so good. But what's happening inside the evaluator?

The first part will just return a pair with the number evaluated ("a") and the output formatted by formatLine.

The second part does something more complicated: it returns a pair composed by 1. the result of the evaluation of the right Term summed to the result of the evaluation of the second Term 2. the output: the concatenation of the output produced by the evaluation of the right Term, the output produced by the evaluation of the left Term (each this evaluation returns a pair with the number and the output), and the formatted output of the evaluation.

Let's try it:

 *TheMonadicWay> evalO (Add (Con 5) (Con 6))
 (11,"eval (Con 5) <= 5 - eval (Con 6) <= 6 - eval (Add (Con 5) (Con 6)) <= 11 - ")
 *TheMonadicWay>

It works! Let's put the output this way:

 eval (Con 5) <= 5 - 
 eval (Con 6) <= 6 - 
 eval (Add (Con 5) (Con 6)) <= 11 -

Great! We are able to produce a side effect of our evaluation and present it at the end of the computation, after all.

Let's have a closer look at this expression:

evalO (Add t u) = ((a + b),(x ++ y ++ formatLine (Add t u) (a + b)))
     where (a, x) = evalO t
           (b, y) = evalO u

Why all that? The problem is that we need:

    * "a" and "b" to calculate their sum (a + b), that will be the first element of the compund pair rapresenting the type (MOut) our evaluator will return
    * "x and "y" (the output of each evaluation) to be concatenated with the ourput of formatLine by the expression (x ++ y ++ formatLine(...)): this will be the second element of the compound pair MOut, the string part. 

So we need to separate the pairs produced by "evalO t" and "evalO u".

We do that within the where clause (remember: evalO now produces a value of type MOut Int, i.e. a pair of an Int and a String).

Then we use the single element, "extraded" within the where clause, to return a new MOut composed by

 ((a + b),(x ++ y ++ formatLine (Add t u) (a + b))).
  ------   -------------------------------------
   Int            Output = String

[edit]
4 Let's go monadic

Is there a more general way of doing so?

Let's analyze the evaluator from another perspective. From the type perspective.

We solved our problem by creating a new type, a pair of an Int (the result of the evaluation) and a String (the output of the process of evaluation).

The first part of the evaluator does nothing else but creating, from a value of type Int, an object of type MOut Int (Int,Output). It does so by creating a pair with that Int and some text produced by formatLine.

The second part evaluates the two Term(s) and "stores" the values thus produced in some variables to be use later to compute the output.

Let's focus on the "stores" action. The correct term should be "binds".

Take a function:

f x = x + x

"x" appears on both sides of the expression. We say that on the right side "x" is bound to the value of x given on the left side.

So

f 3

binds x to 3 for the evaluation of the expression "x + x".

Our evaluator binds "a" and "x" / "b" and "y" with the evaluation of "evalO t" and "evalO u" respectively.

Then "a","b","x" and "y" will be used in the evaluation of ((a+b),(x++y++formatLine)), that will produce a value of type MOut Int:

  ((a + b),(x ++ y ++ formatLine (Add t u) (a + b))).
   ------   -------------------------------------
    \ /          \                   /
    Int             Output = String
    ---------------------------------
                  \  /
                MOut Int             

The binding happens in the "where" clause:

where (a, x) = evalO t
      (b, y) = evalO u

We know that there is an ad hoc operator for binding variables to a value: lambda, or \.

Indeed f x = x + x is syntactic sugar for:

f = \x -> x + x

When we write f 3 we are actually binding "x" to 3 within what's next "->", that will be used (substituted) for evaluating f 3.

So we can try to abstract this phenomenon.
[edit]
4.1 Monadic evaluator with output

What we need is a function that takes our composed type MOut Int and a function in order to produce a new MOut Int, concatenating the output of the computation of the first with the output of the computation of the second.

This is what bindM does:

> bindM :: MOut a -> (a -> MOut b) -> MOut b
> bindM m f = (b, x ++ y)
>             where (a, x) = m
>                   (b, y) = f a

It takes:

    * "m": the compound type MOut Int carrying the result of an "eval Term",
    * a function "f". This function will take the Int ("a") extracted by the evaluation of "m" ((a,x)=m). This function will produce a new pair: a new Int produced by a new evaluation; some new output. 

bindM will return the new Int in pair with the concatenated outputs resulting from the evaluation of "m" and "f a".

As you see, we took the binding part out from evalO and put it in this new function.

So let's write the new version of the evaluator, that we will call evalM_1:

> evalM_1 :: Term -> MOut Int
> evalM_1 (Con a) = (a, formatLine (Con a) a)
> evalM_1 (Add t u) = bindM (evalM_1 t) (\a -> 
>                                      bindM (evalM_1 u) (\b -> 
>                                                         ((a + b), formatLine (Add t u) (a + b))
>                                                     )
>                                     )

Ugly, isn't it?

Let's start from the outside:

bindM (evalM_1 u) (\b -> ((a + b), formatLine (Add t u) (a + b)))

bindM takes the result of the evaluation "evalM_1 u", a type Mout Int, and a function. It will extract the Int from that type and use it to bind "b".

So in bindM (evalM_1 u) (\b ->) "b" will be bound to the value returned by evalM_1 u, and this bound variable will be available in what comes after "->" as a bound variable (not free).

Then the outer part (bindM (evalM_1 t) (\a...) will bind "a" to the value returned "evalM_1 t", the result of the evaluatuion of the first Term. This value is needed to evaluate "((a+b), formatLine...) and produce our final MOut Int.

We can try to explain "bindM" in a different way by using more descriptive names.

As we have seen, "bindM" extracts the Int part from our type. The Int part will be used for further computations and the Output part will be concatenated. As a result we will have a new pair with a new Int and an accumulated Output.

The new version of "bindM":

> getIntFromType typeMOut doSomething = (newInt,oldOutput ++ newOutput)
>     where (oldInt,oldOutput) = typeMOut
>           (newInt,newOutput) = (doSomething oldInt)

As you can see it does the very same things that "bindM" does: it takes something of type MOut and a function to perform some computation with the Int part.

In the "where" clause, the old Int and the old output will be extracted from our type MOut (first line of the "where" clause).

A new Int and a new output will be extracted from evaluating (doSomething oldInt) in the second line.

Our function will return the new Int and the concatenated outputs.

We do not need to define our doSomething function, because it will be an anonymous function:

> evaluator (Con a) = (a, "output-")
> evaluator (Add t u) = 
>                getIntFromType (evaluator t) 
>                               (\firstInt -> getIntFromType (evaluator u) 
>                                                            (\secondInt -> ((firstInt + secondInt),("-newoutput"))))

As you can see we are feeding our "getIntFromType" with the evaluation of an expression ("evaluator t" and "evaluator u"). The second argument of "getIntFromType" is an anonymous function that takes the "oldInt" and does something with it.

So we have a series of nested anonymous functions. Their arguments ("\firstInt" and "\secondInt") will be used to produce the computation we need ("(firstInt + secondInt). Moreover "getIntFromType" will take care of concatenating the outputs.

This is the result:

 *TheMonadicWay> evaluator (Add (Con 5) (Con 6))
 (11,"output-output--newoutput")
 *TheMonadicWay> 

Going back to our "bindM", we can now use lambda notation to write our evaluator in a more convinient way:

> evalM_2 :: Term -> MOut Int
> evalM_2 (Con a) = (a, formatLine (Con a) a)
> evalM_2 (Add t u) = evalM_2 t `bindM` \a ->
>                     evalM_2 u `bindM` \b ->
>                     ((a + b), (formatLine (Add t u) (a + b)))

Now, look at the first part:

evalM_2 (Con a) = (a, formatLine (Con a) a)

We could use a more general way of creating some output.

We can create a function that takes an Int and returns the type MOut Int. We do that by pairing the received Int with an empty string "".

This will be a general way of creating an object with type MOut Int starting from an Int.

Or, more generaly, a function that takes something of a variable type a, and return an object of type MOut a, a coumpunt object made up of an element of type a, and one of type String.

There it is:

> mkM :: a -> MOut a
> mkM a = (a, "")

As you can see, this function will just push an Int and an empty string ("") inside our type MOut.

Then we need a method of inserting some text in our object of type MOut. So we will take a string and return it paired with a void element "()":

> outPut :: Output -> MOut ()
> outPut x = ((), x)

Very simple: we have a string "x" (Output) and create a pair with a () instead of an Int, and the output.

You can see this function as one that pushes a string, paired with a void int, inside our type MOut.

Now we can rewrite:

evalM_2 (Con a) = (a, formatLine (Con a) a)

using the bindM function:

evalM_2 (Con a) = outPut (formatLine (Con a) a) `bindM` \_ -> mkM a

First we create an object of type MOut with the Int part (). As you see bindM will not use it ("\_"), but will concatenate the String part with the result of mkM, which in turn is the empty string "".

In other words, first we insert the Output part (a string) in our MOut, and then we insert the Int paired with an empty string: "bindM" will not use the void int (the anonymous function will not use it's argument: "\_"), but will take care of concatenating the non empty string inserted by "outPut" with the empty one inserted by "mkM".

Let's rewrite the evaluator:

> evalM_3 :: Term -> MOut Int
> evalM_3 (Con a) = outPut (formatLine (Con a) a) `bindM` \_ -> 
>                   mkM a
> evalM_3 (Add t u) = evalM_3 t `bindM` \a ->
>                     evalM_3 u `bindM` \b ->
>                     outPut (formatLine (Add t u) (a + b)) `bindM` \_ -> 
>                     mkM (a + b)

Well, this is fine, definetly better then before, anyway.

Still we use `bindM` \_ -> that binds something we do not use (_). We could write a function for this specific case, when we concatenate computations without the need of binding variables for later uses. Let's call it `combineM`:

> combineM :: MOut a -> MOut b -> MOut b
> combineM m f = m `bindM` \_ -> f

This is just something that will allow us to write the evaluator in a more concise way.

So the new evaluator:

> evalM :: Term -> MOut Int
> evalM (Con a) = outPut (formatLine (Con a) a) `combineM` 
>                 mkM a
> evalM (Add t u) = evalM t `bindM` \a ->
>                   evalM u `bindM` \b ->
>                   outPut (formatLine (Add t u) (a + b)) `combineM` 
>                   mkM (a + b)

Let's put everything together (changing M into MO, so that this file will be still usable as a Literate Haskell file):

> type MO a = (a, Out)
> type Out = String
 
> mkMO :: a -> MO a
> mkMO a = (a, "")
 
> bindMO :: MO a -> (a -> MO b) -> MO b
> bindMO m f = (b, x ++ y)
>              where (a, x) = m
>                    (b, y) = f a
 
> combineMO :: MO a -> MO b -> MO b
> combineMO m f = m `bindM` \_ -> f
 
> outMO :: Out -> MO ()
> outMO x = ((), x)
 
> evalMO :: Term -> MO Int
> evalMO (Con a) = outMO (formatLine (Con a) a) `combineMO`
>                  mkMO a
> evalMO (Add t u) = evalMO t `bindMO` \a ->
>                    evalMO u `bindMO` \b ->
>                    outMO (formatLine (Add t u) (a + b)) `combineMO` 
>                    mkMO (a + b)

[edit]
5 What does bind bind?

The evaluator looks like:

evalM t >>= \a -> evalM u >>= \b -> outPut "something" >>= \_ -> mkM (a +b)

where >>= is bindMO, obviously.

Let's do some substitution, writing the type of their output of each function:

    * evalMO t => (a,Out) - where a is Int
    * evalMO u => (b,Out) - where b is the same of a, an Int, but with a different value
    * outMO Out = ((),Out)
    * mkMO (a+b) => ((a+b),Out) - where (a+b) is the same of a and b, but with a different value from either a and b 

B | (a,Out) >>= \a -> (b,Out) >>= \b -> ((),Out) >>= \_ >>= ((a + b), Out)---\
i |  V  V        V     V  V        V     V   V        ^       ^   ^    ^     |\
n |  |__|________^     |  |        ^     |   |        |       |   |    |     |  MOut Int <=> ((a+b), Out)
d |_____|__(++)__|_Out_|__|__(++)__V_Out_|___|___(++)_|_(++)__|___|____|_____|/
i |              |     |______(b)__|_____|_____(b)____|__(b)__|___|
n |              |_________(a)___________|____________|__(a)__|
g |                                      |_____()_____|


Clear, isn't it?

"bindMO" is just a function that takes care of gluing together, inside a data type, a sequence of computations!
[edit]
6 Some sugar, please!

Now our evaluator has been completely transformed into a monadic evaluator. That's what it is: a monad.

We have a function that constructs an object of type MO Int, formed by a pair: the result of the evaluation and the accumulated (concatenated) output.

The process of accumulation and the act of parting the MO Int into its component is buried into bindMO, now, that can also preserve some value for later uses.

So we have:

    * MO a type constructor for a type carrying a pair composed by an Int and a String;
    * bindMO, that gives a direction to the process of evaluation: it concatenates computations and captures some side effects we created (the direction is given by the changes in the Out part: there's a "before" when Out was something and there's a "later" when Out is something else).
    * mkMO lets us create an object of type MO Int starting from an Int. 

As you see this is all we need to create a monad. In other words monads arise from the type system and the lambda calculus. Everything else is just syntactic sugar.

So, let's have a look at that sugar: the famous do-notation!
[edit]
6.1 Monadic evaluator with output in do-notation

In order to be able to use the "do-notation" we need to define a new type and make it an instance of the Monad class. To make a new type an instance of the Monad class we will have to define the two methods of this class: (>>=) and "return".

This is not going to be difficult, because we already created these two methods: "bindM" and "mkM". Now we will have to rewrite them in order to reflect the fact that we are not going to use a type, for our evaluator, that is a synonymous of other types, as we did before. Indeed our MOut was defined with the "type" keyword. Now we will have to define a "real" new type with either "newtype" or "data". Since we are not going to need multiple constructors, we will use "newtype".

> newtype Eval_IO a = Eval_IO (a, O)
>     deriving (Show)
> type O = String

This is our new type: it will have a single type constructor, whose name is the same of the type name ("Eval_IO"). The type constructor takes a parameter ("a"), a variable type, and will build a type formed by a type "a" (an Int in our case) and a String (O is indeed synonymous of String).

We now need to define our "bind" function to reflect the fact that we are now using a "real" type, and, to unpack its content, we need to do pattern-matching we the type constructor "Eval_IO". Moreover, since we must return an Eval_IO type, we will use the type constructor also for building the new type with the new int and the concatenated output.

For the rest our "bind" function will be identical to the one we defined before.

We are going to use very descriptive names:

> getInt monad doSomething = Eval_IO (newInt,oldOutput ++ newOutput)
>     where Eval_IO (oldInt,oldOutput) = monad
>           Eval_IO (newInt,newOutput) = (doSomething oldInt)

As you can see, we are using Eval_IO to build the result of the computation to be returned by getInt: "Eval_IO (newInt,oldOutput ++ newOutput)". And we are using it to match the internal components of our type in the "where" clause.

We also need to create a function that, like mkO, will take an Int and, using the type constructor "Eval_IO", will create an object of type Eval_IO with that Int and an empty string:

> createEval_IO :: a -> Eval_IO a
> createEval_IO int = Eval_IO (int,"")

And, finally, we need a function that will insert, in our type, a string and a void ():

> print_IO :: O -> Eval_IO ()
> print_IO string = Eval_IO ((), string)

With these functions we could write our monadic evaluator without the "do-notation" like this:

> evalM_4 :: Term -> Eval_IO Int
> evalM_4 (Con a) = createEval_IO a
> evalM_4 (Add t u) = evalM_4 t `getInt` \a ->
>                     evalM_4 u `getInt` \b ->
>                     print_IO (formatLine (Add t u) (a + b)) `getInt` \_ ->
>                     createEval_IO (a + b)

It is very similar to the previous evaluator, as you can see. The only differences are related to the fact that we are now using a "real" type and not a type synonymous: this requires the use of the type constructor to match the type and its internal part (as we do in the "where" clause of our "bind" function: "getInt") or to build the type (as we do in the "bind" function to return the new Int with the concatenated output).

Running this evaluator will produce:

 *TheMonadicWay> evalM_4 (Add (Con 6) (Con 12))
 Eval_IO (18,"eval (Add (Con 6) (Con 12)) <= 18 - ")
 *TheMonadicWay> 

Now we have everything we need to declare our type, Eval_IO, as an instance of the Monad class:

> instance Monad Eval_IO where
>     return a = createEval_IO a
>     (>>=) m f = getInt m f

As you see we are just using our defined functions as methods for our instance of the Monad class.

This is all we need to do. Notice that we do not have to define the "combineM" function, for chaining computation, as we do with "getInt", without binding variables for later use within the series of nested anonymous functions (the "doSomething" part) that will form the "do" block.

This function comes for free by just defining our type as an instance of the Monad class. Indeed, if you look at the definition of the Monad class in the Prelude you see that "combineM", or (>>) is deduced by the definition of (>>=):

class Monad m where
    return :: a -> m a
    (>>=)  :: m a -> (a -> m b) -> m b
    (>>)   :: m a -> m b -> m b
    fail   :: String -> m a
 
    -- Minimal complete definition: (>>=), return
    p >> q  = p >>= \ _ -> q
    fail s  = error s

You can see that the "combineM"" method (or (>>)) is automatically derived by the "bindMO" (or >>=) method:

p >> q  = p >>= \ _ -> q

We can now write our evaluator using the do-notation:

 
> eval_IO :: Term -> Eval_IO Int
> eval_IO (Con a) = do print_IO (formatLine (Con a) a)
>                      return a
> eval_IO (Add t u) = do a <- eval_IO t
>                        b <- eval_IO u
>                        print_IO (formatLine (Add t u) (a + b))
>                        return (a + b)

As you can see the anonymous functions are gone. Instead we use this:

 a <- eval_IO t

This seems like an assignment, that cannot be possible in Haskell. In fact it is just the way our anonymous function's arguments is bound within a do block.

Even if it does not seem like a series of nested anonymous functions, this is what actually a do block is.

Our monad is defined by three elements:

    * a type, with its type constructor(s);
    * a bind method: it will bind an unwritten anonymous function's argument to the value of the Int part of our type, or more generally, of the variable type "a". It will also create a series of anonymous functions: a line for each function;
    * a "return" function, to insert, into out type, a value of type Int, or, more generally, a value of variable type "a". 

Additionally, we need a function to insert a string in our type, string that the derived "bind" (>>) will concatenate ignoring the void (), our "print_IO".

Within a do block we can thus perform only tree kinds of operations:

    * a computation that produces a new Int, packed inside our monad's type, to be extracted and bound to a variable (an anonymous function's argument really):
          o this operation requires a binding (">>= \varName ->"), translated into "varName <- computation"
          o example: a <- eval_IO t 
    * a computation that inserts a string into our monad, a string to be concatenated, without the need of binding a variable (an anonymous function's argument really):
          o this operation does not require a binding: it will be ">>= \_ ->", i.e. ">>", translated into a simple new line
          o example: print_IO (formatLine (Add t u) (a + b)) 
    * a computation that inserts an Int into our monad without the need of binding a variable (an anonymous function's argument really):
          o this operation is carried out by the return method (usually at the end of a do block, useless in the middle)
          o example return (a + b) 

To sum up, within a block, "do" will take care of creating and nesting, for us, all the needed anonymous functions so that bound variables will be available for later computations.

In this way we can emulate a direction of our computation, a "before" and an "after", even within a pure functional language. And we can use this possibility to create and accumulate side effects, like output.

Let's see the evaluator with output in action:

 *TheMonadicWay> eval_IO (Add (Con 6) (Add (Con 16) (Add (Con 20) (Con 12)))) 
  Eval_IO (54,"eval (Con 6) <= 6 - eval (Con 16) <= 16 - eval (Con 20) <= 20 - eval (Con 12) <= 12 - \
     eval (Add (Con 20) (Con 12)) <= 32 - eval (Add (Con 16) (Add (Con 20) (Con 12))) <= 48 - \
     eval (Add (Con 6) (Add (Con 16) (Add (Con 20) (Con 12)))) <= 54 - ")
 *TheMonadicWay> 

Let's format the output part:

 eval (Con 6) <= 6 
 eval (Con 16) <= 16 
 eval (Con 20) <= 20 
 eval (Con 12) <= 12 
 eval (Add (Con 20) (Con 12)) <= 32 
 eval (Add (Con 16) (Add (Con 20) (Con 12))) <= 48 
 eval (Add (Con 6) (Add (Con 16) (Add (Con 20) (Con 12)))) <= 54 

[edit]
7 Type and Newtype: What happened to our output?

Well, actually something happened to the output. Let's compare the output of evalMO (the monadic evaluator written without the do-notation) and eval_IO:

 *TheMonadicWay> evalMO (Con 6)
 (6,"eval (Con 6) <= 6 - ")
 *TheMonadicWay> eval_IO (Con 6)
 Eval_IO (6,"eval (Con 6) <= 6 - ")
 *TheMonadicWay>  

They look almost the same, but they are not the same: the output of eval_IO has the Eval_IO stuff. It must be related to the changes we had to do to our evaluator in order to use the do-conation, obviously.

We can now review some of our basic knowledge of Haskell's type system.

What's changed? First the type definition. We have now:

newtype Eval_IO a = Eval_IO (a, O)
      deriving (Show)

instead of

type MO a = (a, Out)

Now return a is the product of the application of the type constructor Eval_IO to the pair that are going to form our monad.

"return" takes an Int and inserts it into our monad. It will also insert an empty String "" that (>>=) or (>>) will then concatenate in the sequence of computations they glue together.

The same for (>>=). It will now return something constructed by Eval_IO:

    * "newInt", the result of the application of "doSomething" to "oldInt" (better, the binding of "oldInt" in "doSomething");
    * the concatenation of "oldOutput" (matched by Eval_IO (oldInt, oldOutput) with the evaluation of "monad" - "eval_IO t") and "newOutput", (matched by "Eval_IO(newInt,newOutput)" with the evaluation of "(doSomething monad)" - "eval_IO u"). 

That is to say: in the "where" clause, we are matching for the elements paired in a type Eval_IO: this is indeed the type of "monad" (corresponding to "eval_IO t" in the body of the evaluator) and "(doSomething monad)" (where "doSomething" correspond to the evaluation of "eval_IO u" within an anonymous function with \oldInt as its argument, argument bound to the result of the previous evaluation of "monad", that is to say "eval_IO t").

And so, "Eval_IO (oldInt,oldOutput) = monad" means: match "oldInt" and "oldOutput", paired in a type Eval_IO, and that are produced by the evaluation of "monad" (that is to say: "eval_IO t"). The same for Eval_IO (newInt,newOutput): match "newInt" and "newOutput" produced by the evaluation of "(doSomething monad)".

So the output of the evaluator is now not simply a pair made of and Int and a String. It is a specific type (Eval_IO) that happens to carry a pair of an Int and a String. But, if we want the Int and the string, we have to extract them from the Eval_IO type, as we do in the "where" clause: we unpack our type object (let's call it with its name: our monad!) and take out the Int and the String to feed the next function application and the output generation.

The same to insert something in our monad: if we want to create a pair of an Int and a String, pair of type Eval_IO, we now have to pack them together by using our type constructor, feeding it with a pair composed by and Int and a String. This is what we do with the "return" method of out monad and with "print_IO" function, where:

    * return insert into the monad an Int;
    * print_IO insert into the monad a String. 

So, why cannot we use the old type MO a = (a, Out) that did not required all this additional work (apart the need to specifically define (>>)?

Type MO is just a synonymous for (a,Out): the two can be substituted one for the other. That's it.

We did not have to pack "a" and "Out" together with a type constructor to have a new type MO.

As a consequence, we cannot use MO as an instance of Monad, and so, we cannot use with it the syntactic sugar we needed: the do-notation.

That is to say: a type created with the "type" keyword cannot be an instance of a class, and cannot inherits its methods (in our case (>>=, >> and return). And without those methods the do-notation is not usable.
[edit]
8 Errare monadicum est

Now that we have a basic understanding of what a monad is, and does, we will further explore it by making some changes to our evaluator.

In this section we will se how to handle exceptions in our monadic evaluator.

Suppose that we want to stop the execution of our monad if some conditions occurs. If our evaluator was to compute divisions, instead of sums, then we would like to stop the evaluator when a division by zero occurs, possibly producing some output, instead of the result of the evaluation of the expression, that explains what happened.

Basic error handling.

We will do so starting from the beginning once again...
[edit]
8.1 The basic evaluator, non monadic, with exception

We just take our basic evaluator, without any output, and write a method to stop execution if a condition occurs:

> data M a = Raise Exception
>          | Return a
>            deriving (Show)
> type Exception = String

Now, our monad is of datatype "M a" which can either be constructed with the "Raise" constructor, that takes a String (Exception is a synonymous of String), or by the "Return" constructor, that takes a variable type ("a"), an Int in our case.

> evalE :: Term -> M Int
> evalE (Con a) = Return a

If evalE matches a Con it will construct a type Return with, inside, the content of the Con.

> evalE (Add a b) = 
>     case evalE a of
>       Raise e -> Raise e
>       Return a ->
>           case evalE b of 
>             Raise e -> Raise e
>             Return b ->
>                 if (a+b) == 42
>                    then Raise "The Ultimate Answer Has Been Computed!! Now I'm tired!"
>                    else Return (a+b)

If evalE matches an Add it will check if evaluating the first part produces a "Raise" or a "Return": in the first case it will return a "Raise" whose content is the same received.

If instead the evaluation produces a value of a type matched by "Return", the evaluator will evaluate the second term of Add.

If this returns a "Raise", a "Raise" will be returned all the way up the recursion, otherwise the evaluator will check whether a condition for raising a "Raise" exists. If not, it will return a "Return" with the sum inside.

Test it with:

 evalE (Add (Con 10) (Add (Add (Con 20) (Con 10)) (Con 2)))


[edit]
8.2 The basic evaluator, monadic, with exceptions

In order to produce a monadic version of the previous evaluator, the one that raises exceptions, we just need to abstract out from the evaluator all that case analysis.

> data M1 a = Except Exception
>           | Ok {showM :: a }
>             deriving (Show)

The data type didn't change at all. Well, we changed the name of the Return type constructor (now Ok) so that this constructor can coexist with the previous one in the same Literate Haskell file.

 
> instance Monad M1 where
>     return a = Ok a
>     m >>= f = case m of
>                      Except e -> Except e
>                      Ok a -> f a

Binding operations are now very easy. Basically we check:

    * if the result of the evaluation of "m" produces an exception (first match: Except e ->...), in which case we return its content by constructing our M1 Int with the "Raise" constructor".
    * if the result of the evaluation of "m" is matched with the "Ok" constructor, we get its content and use it to bind the argument of "f" to its value. 

return a will just use the Ok type constructor for inserting "a" (in our case an Int) into M1 Int, the type of our monad.

> raise :: Exception -> M1 a
> raise e = Except e

This is just a helper function to construct our "M1 a" type with the Raise constructor. It takes a string and returns a type (M1 a) to be matched with the "Raise" constructor.

> eval_ME :: Term -> M1 Int
> eval_ME (Con a) = do return a
> eval_ME (Add t u) = do a <- eval_ME t
>                        b <- eval_ME u
>                        if (a+b) == 42
>                          then raise "The Ultimate Answer Has Been Computed!! Now I'm tired!"
>                          else return (a + b)

The evaluator itself is very simple. We bind "a" with the result of "eval_ME t", "b" with the result of "eval_ME u", and we check for a condition:

    * if the condition is met we raise an exception, that is to say: we return a value constructed with the "Raise" constructor. This value will be matched by ">>=" in the next recursion. And >>= will just return it all the way up the recursion.
    * if the condition is not met, we return a value constructed with the "Return" type constructor and go on with the recursion. 

Run with:

 eval_ME (Add (Con 10) (Add (Add (Con 20) (Con 10)) (Con 2)))

It is noteworthy the fact that in our datatype definition we used a label field with a label selector (we called it showM), even though it was not used in our code. We will use this methodology later on.

So, just to refresh your memory:

> data Person = Person {name :: String,
>                       age :: Int,
>                       hobby :: String
>                      } deriving (Show)
             
> andreaRossato = Person "Andrea" 37 "Haskell The Monadic Way"
> personName (Person a b c) = a

will produce:

 *TheMonadicWay> andreaRossato
 Person {name = "Andrea", age = 37, hobby = "Haskell The Monadic Way"}
 *TheMonadicWay> personName andreaRossato
 "Andrea"
 *TheMonadicWay> name andreaRossato
 "Andrea"
 *TheMonadicWay> age andreaRossato
 37
 *TheMonadicWay> hobby andreaRossato
 "Haskell The Monadic Way"
 *TheMonadicWay> 


[edit]
8.3 Monadic evaluator with output and exceptions

We will now try to combine the output-producing monadic evaluator with exception producing one.


> data M2 a = Ex Exception
>           | Done {unpack :: (a,O) }
>             deriving (Show)

Now we need a algebraic datatype with two constructors: one to produce a value type "M2 a" using "Ex String" and one for value type "M2 a" (Int in this case) using "Done a".

Note that we changed the name of the exception type constructor from "Raise" to "Ex" just to make the two coexist in the same literate Haskell file.

The constructor "Done a" is defined with a label selector: Done {unpack :: (a,O)} and is equivalent to Done (a,O).

The only difference is that, this way, we are also defining a method to retrieve the pair (a,O) (in our case "O" is a synonymous for String, whereas "a" is a variable type) from an object of type "Done a".

> instance Monad M2 where
>     return a = Done (a, "")
>     m >>= f = case m of
>                      Ex e -> Ex e
>                      Done (a, x) -> case (f a) of
>                                       Ex e1 -> Ex e1
>                                       Done (b, y) -> Done (b, x ++ y)

Now our binding operations gets more complicated by the fact that we have to concatenate the output, as we did before, and check for exceptions.

It is not possible to do has we did in the exception producing evaluator, where we could check just for "m" (remember the "m" in the first run stands for "eval t").

Since at the end we must return the output produced by the evaluation of "m" concatenated with the output produced by the evaluation of "f a" (where "a" is returned by "m", paired with "x" by "Done"), now we must check if we do have an output from "f a" produced by "Done".

Indeed, now, "f a" can also produce a value constructed by "Ex", and this value does not contain the pair as the value produced by "Done".

So, we evaluate "m":

    * if we match a value produced by type constructor "Ex" we return a value produced by type constructor "Ex" whose content is the one we extracted in the matching;
    * if we match a value produced by "Done" we match the pair it carries "(a,x)" and we analyze what "f a" returns:
          o if "f a" returns a value produced by "Ex" we extract the exception and we return it, constructing a value with "Ex"
          o if "f a" returns a value produced by "Done" we return "b" and the concatenated "x" and "y". 

And now the evaluator:

                       
> raise_IOE :: Exception -> M2 a
> raise_IOE e = Ex e

This is the function to insert an exception in our monad (M2): We take a String and produce a value applying the type constructor for exception "Ex" to its value.

> print_IOE :: O -> M2 ()
> print_IOE x = Done ((), x)

The function to produce output is the very same of the one of the output-producing monadic evaluator.

 
> eval_IOE :: Term -> M2 Int
> eval_IOE (Con a) = do print_IOE (formatLine (Con a) a)
>                       return a
> eval_IOE (Add t u) = do a <- eval_IOE t
>                         b <- eval_IOE u
>                         let out = formatLine (Add t u) (a + b)
>                         print_IOE out
>                         if (a+b) == 42
>                            then raise_IOE $ out ++ "The Ultimate Answer Has Been Computed!! Now I'm tired!"
>                            else return (a + b)

The evaluator procedure did not change very much from the one of the output-producing monadic evaluator.

We just added the case analysis to see if the condition for raising an exception is met.

Running with

 eval_IOE (Add (Con 10) (Add (Add (Con 20) (Con 10)) (Con 2)))

will produce

 Ex "eval (Add (Con 10) (Add (Add (Con 20) (Con 10)) (Con 2))) <= 42 - 
     The Ultimate Answer Has Been Computed!! Now I'm tired!"

Look at the let clause within the do-notation. We do not need to use the "let ... in" construction: since all bound variables remain bound within a do procedure (see here), we do not need the "in" to specify "where" the variable "out" will be bound in!
[edit]
9 We need a state

We will keep on adding complexity to our monadic evaluator and this time we will add a counter. We just want to count the number of iterations (the number of times "eval" will be called) needed to evaluate the expression.
[edit]
9.1 The basic evaluator, non monadic, with a counter

As before we will start by adding this feature to our basic evaluator.

A method to count the number of iterations, since the lack of assignment and destructive updates (such as for i=0;i<10;i++;), is to add an argument to our function, the initial state, number that in each call of the function will be increased and passed to the next function call.

And so, very simply:

> -- non monadic
> type St a = State -> (a, State)
> type State = Int
> evalNMS :: Term -> St Int
> evalNMS (Con a) x = (a, x + 1)
> evalNMS (Add t u) x = let (a, y) = evalNMS t x in
>                       let (b, z) = evalNMS u y in
>                       (a + b, z +1)

Now evalNMS takes two arguments: the expression of type Term and an State (which is a synonymous for Int), and will produce a pair (a,State), that is to say a pair with a variable type "a" and an Int.

The operations in the evaluator are very similar to the non monadic output producing evaluator.

We are now using the "let ... in" clause, instead of the "where", and we are increasing the counter "z" the comes from the evaluation of the second term, but the basic operation are the same:

    * we evaluate "evalNMS t x" where "x" is the initial state, and we match and bind the result in "let (a, y) ... in"
    * we evaluate "evalNMS u y", where "y" was bound to the value returned by the previous evaluation, and we match and bind the result in "let (b, z) ... in"
    * we return a pair formed by the sum of the result (a+b) and the state z increased by 1. 

Let's try it:

 *TheMonadicWay> evalNMS (Add (Con 10) (Add (Add (Con 20) (Con 10)) (Con 2))) 0
 (42,7)
 *TheMonadicWay> 

As you see we must pass to "evalNMS"the initial state of our counter: 0.

Look at the type signature of the function "evalNMS":

evalNMS :: Term -> St Int

From this signature you could argue that our function takes only one argument. But since our type St is defined with the "type" keyword, St can be substituted with what comes after the "=" sign. So, the real type signature of our function is:

evalNMS :: Term -> State -> (Int,State)

Just to refresh your memory:

> type IamAfunction a = (a -> a)
> newtype IamNotAfunction a = NF (a -> a)
> newtype IamNotAfunctionButYouCanUnPackAndRunMe a = F { unpackAndRun :: (a -> a) }
 
> a = \x -> x * x
 
> a1 :: IamAfunction Integer
> a1 = a
 
> a2 :: IamNotAfunction Integer
> a2 = NF a
 
> a3 :: IamNotAfunctionButYouCanUnPackAndRunMe Integer
> a3 = F a


 *TheMonadicWay> a 4
 16
 *TheMonadicWay> a1 4
 16
 *TheMonadicWay> a2 4
 
 <interactive>:1:0:
     The function `a2' is applied to one arguments,
     but its type `IamNotAfunction Int' has only 0
     In the definition of `it': it = a2 4
 *TheMonadicWay> a3 4
 
 <interactive>:1:0:
     The function `a3' is applied to one arguments,
     but its type `IamNotAfunctionButYouCanUnPackAndRunMe Int' has only 0
     In the definition of `it': it = a3 4
 *TheMonadicWay> unpackAndRun a3 4
 16
 *TheMonadicWay>

This means that "a1" is a partial application hidden by a type synonymous.

"a2" and "a3" are not function types. They are types that have a functional value.

Moreover, since we defined the type constructor of type "IamNotAfunctionButYouCanUnPackAndRunMe", F, with a label field, in that label field we defined a method (a label selector) to "extract" the function from the type "IamNotAfunctionButYouCanUnPackAndRunMe", and run it:

unpackAndRun a3 4

And what about "a2"? Is it lost forever?

Obviously not! We need to write a function that unpacks a type "IamNotAfunction", using its type constructor NF to match the internal function:

> unpackNF :: IamNotAfunction a -> a -> a
> unpackNF (NF f) = f

and run:

 *TheMonadicWay> unpackNF a2 4
 16
 *TheMonadicWay> 

As you see, "unpackNF" definition is a partial application: we specify one argument to get a function that gets another argument.

A label selector does the same thing.

Later we will see the importance of this distinction, quite obvious for haskell gurus, but not for us. Till now.
[edit]
9.2 The evaluator, monadic, with a counter

We will now rewrite our basic evaluator with the counter in do-notation.

As we have seen, in order to do so we need:

    * a new type that we must declare as an instance of the Monad class;
    * a function for binding method (>>=) and a function for the "return" method, for the instance declaration; 

Now our type will be holding a function that will take the initial state 0 as we did before.

In order to simplify the process of unpacking the monad each time to get the function, we will use a label sector:

> newtype MS a = MS { unpackMSandRun :: (State -> (a, State)) }

This is it: MS will be our type constructor for matching and for building our monad. "unpackMSandRun" will be the method to get the function out of the monad to feed it with the initial state of the counter, 0, to get our result.

Then we need the "return" function that, as we have seen does nothing but inserting into our monad an Integer:

> mkMS :: a -> MS a
> mkMS int = MS (\x -> (int, x))

"mkMS" will just take an Integer "a" and apply the MS type constructor to our anonymous function that takes an initial state and produces the final state "x" and the integer "a".

In other words, we are just creating our monad with inside an Integer.

Our binding function will be a bit more complicated then before. We must create a type that holds an anonymous function with elements to be extracted from our type and passed to the anonymous function that comes next:

> bindMS :: MS a -> (a -> MS b) -> MS b
> bindMS monad doNext = MS $ \initialState -> 
>                       let (oldInt, oldState) = unpackMSandRun monad initialState in
>                       let (newInt, newState) = unpackMSandRun (doNext oldInt) oldState in
>                       (newInt,newState)

So, we are creating an anonymous function that will take an initial state, 0, and return a "newInt" and "newState".

To do that we need to unpack and run our "monad" against the initialState in order to get the "oldInt" and the "oldState".

The "oldInt" will be passed to the "doNext" function (the next anonymous function in our do block) together with the "oldState" to get the "newInt" and the "newState".

We can now declare our type "MS" as an instance of the Monad class:

> instance Monad MS where
>     return a = mkMS a
>     (>>=) m f = bindMS m f

We now need a function to increase the counter in our monad from within a do block:

 
> incState :: MS ()
> incState = MS (\s -> ((), s + 1))

This is easier then it looks like. We use the type constructor MS to create a function that takes a state an returns a void integer () paired with the state increased by one. We do not need any binding, since we are just modifying the state, an integer, and, in our do block, we will insert this function before a new line, so that the non binding ">>" operator will be applied.

And now the evaluator:

> evalMS :: Term -> MS Int
> evalMS (Con a) = do incState
>                     mkMS a
> evalMS (Add t u) = do a <- evalMS t
>                       b <- evalMS u
>                       incState 
>                       return (a + b)

Very easy: we just added the "incState" function before returning the sum of the evaluation of the Terms of our expression.

Let's try it:

 *TheMonadicWay> unpackMSandRun (evalMS (Add (Con 6) (Add (Con 16) (Add (Con 20) (Con 12))))) 0
 (54,7)
 *TheMonadicWay> 

As you can see, adding a counter makes our binding operations a bit more complicated by the fact that we have an anonymous function within our monad. This means that we must recreate that anonymous function in each step of our do block. This makes "incState" and, as we are going to see in the next paragraph, the function to produce output a bit more complicated. Anyway we can handle this complexity quite well, for now.
[edit]
9.3 The monadic evaluator with output and counter in do-notation

Adding output to our evaluator is now quite easy. It's just a matter of adding a field to our type, where we are going to accumulate the output, and take care of extracting it in our bind function to concatenate the old one with the new one.

> newtype Eval_SIO a = Eval_SIO { unPackMSIOandRun :: State -> (a, State, Output) }

Now our monad contains an anonymous function that takes the initial state, 0, and will produce the final Integer, the final state and the concatenated output.

So, this is bind:

> bindMSIO monad doNext = 
>          Eval_SIO (\initialState ->
>                    let (oldInt, oldState, oldOutput) = unPackMSIOandRun monad initialState in
>                    let (newInt, newState, newOutput) = unPackMSIOandRun (doNext oldInt) oldState in
>                    (newInt, newState, oldOutput ++ newOutput))

And this is our "return":

> mkMSIO int = Eval_SIO (\s -> (int, s, ""))

Now we can declare our type, "Eval_SIO", as an instance of the Monad class:

> instance Monad Eval_SIO where
>     return a = mkMSIO a
>     (>>=) m f = bindMSIO m f

Now, the function to increment the counter will also insert an empty string "" in our monad: "bind" will take care of concatenating it with the old output:

> incSIOstate :: Eval_SIO () 
> incSIOstate = Eval_SIO (\s -> ((), s + 1, ""))

The function to insert some new output will just insert a string into our monad, together with a void Integer (). Since no binding will occur (>> will be applied), the () will not be taken into consideration within the anonymous functions automatically created for us within the do block:

> print_SIO :: Output -> Eval_SIO ()
> print_SIO x = Eval_SIO (\s -> ((),s, x))

And now the evaluator, that puts everything together. As you can see it did not change too much from the previous versions:

> eval_SIO :: Term -> Eval_SIO Int
> eval_SIO (Con a) = do incSIOstate
>                       print_SIO (formatLine (Con a) a)
>                       return a
> eval_SIO (Add t u) = do a <- eval_SIO t
>                         b <- eval_SIO u
>                         incSIOstate
>                         print_SIO (formatLine (Add t u) (a + b))
>                         return (a + b)

Running it will require unpacking the monad and feeding it with the initial state 0:

 unPackMSIOandRun (eval_SIO (Add (Con 6) (Add (Con 16) (Add (Con 20) (Con 12))))) 0
 *TheMonadicWay> unPackMSIOandRun (eval_SIO (Add (Con 6) (Add (Con 16) (Add (Con 20) (Con 12))))) 0
 (54,7,"eval (Con 6) <= 6 - eval (Con 16) <= 16 - 
        eval (Con 20) <= 20 - 
        eval (Con 12) <= 12 - 
        eval (Add (Con 20) (Con 12)) <= 32 - 
        eval (Add (Con 16) (Add (Con 20) (Con 12))) <= 48 - 
        eval (Add (Con 6) (Add (Con 16) (Add (Con 20) (Con 12)))) <= 54 - ")
 *TheMonadicWay> 

(I formatted the output).


[edit]
10 If there's a state we need some discipline: Dealing with complexity

(Text to be done yet: just a summary)

In order to increase the complexity of our monad now we will try to mix State (counter), Exceptions and Output.

This is an email I send to the haskell-cafe mailing list:

Now I'm trying to create a statefull evaluator, with output and
exception, but I'm facing a problem I seem not to be able to
conceptually solve.

Take the code below.
Now, in order to get it run (and try to debug) the Eval_SOI type has a
Raise constructor that produces the same type of SOIE. Suppose instead it
should be constructing something like Raise "something". 
Moreover, I wrote a second version of >>=, commented out.
This is just to help me illustrate to problem I'm facing.

Now, >>= is suppose to return Raise if "m" is matched against Raise
(second version commented out).
If "m" matches SOIE it must return a SOIE only if "f a" does not
returns a Raise (output must be concatenated).

I seem not to be able to find a way out. Moreover, I cannot understand
if a way out can be possibly found. Something suggests me it could be
related to that Raise "something".
But my feeling is that functional programming could be something out
of the reach of my mind... by the way, I teach Law, so perhaps you'll
forgive me...;-)

If you can help me to understand this problem all I can promise is
that I'll mention your help in the tutorial I'm trying to write on
"the monadic way"... that seems to lead me nowhere.

Thanks for your kind attention.

Andrea

This was the code:

data Eval_SOI a = Raise { unPackMSOIandRun :: State -> (a, State, Output) }
                | SOIE { unPackMSOIandRun :: State -> (a, State, Output) }
 
instance Monad Eval_SOI where
    return a = SOIE (\s -> (a, s, ""))
    m >>= f =  SOIE (\x ->
                       let (a, y, s1) = unPackMSOIandRun m x in
                       case f a of
                         SOIE nextRun -> let (b, z, s2) = nextRun y in  
                                         (b, z, s1 ++ s2)
                         Raise e1 -> e1 y  --only this happens
 
                      )
--     (>>=) m f =  case m of
--                    Raise e -> error "ciao" -- why this is not going to happen?
--                    SOIE a -> SOIE (\x ->
--                                    let (a, y, s1) = unPackMSOIandRun m x in
--                                    let (b, z, s2) = unPackMSOIandRun (f a) y in 
--                                    (b, z, s1 ++ s2))	   
 
 
incSOIstate :: Eval_SOI ()
incSOIstate = SOIE (\s -> ((), s + 1, ""))
 
print_SOI :: Output -> Eval_SOI ()
print_SOI x = SOIE (\s -> ((),s, x))
 
raise x e = Raise (\s -> (x,s,e))
 
eval_SOI :: Term -> Eval_SOI Int
eval_SOI (Con a) = do incSOIstate
                      print_SOI (formatLine (Con a) a)
                      return a
eval_SOI (Add t u) = do a <- eval_SOI t
                        b <- eval_SOI u
                        incSOIstate
                        print_SOI (formatLine (Add t u) (a + b))
                        if (a + b)  ==  42 
                          then raise (a+b) " = The Ultimate Answer!!"
                          else return (a + b)
 
runEval exp =  case eval_SOI exp of
                 Raise a -> a 0
                 SOIE p -> let (result, state, output) = p 0 in
                             (result,state,output)
 
 
 
--runEval (Add (Con 10) (Add (Con 28) (Add (Con 40) (Con 2)))) 

This code will produce

 eval (Con 10) <= 10 -
 eval (Con 28) <= 28 -
 eval (Con 40) <= 40 -
 eval (Con 2) <= 2 -  = The Ultimate Answer!!
 eval (Add (Con 28) (Add (Con 40) (Con 2))) <= 70 -
 eval (Add (Con 10) (Add (Con 28) (Add (Con 40) (Con 2)))) <= 80 -

The exception appears in the output, but executioon is not stopped.
[edit]
10.1 Monadic evaluator with output, counter and exception, in do-notation

Brian Hulley came up with this solution:

> -- thanks to  Brian Hulley
> data Result a
>    = Good a State Output
>    | Bad State Output Exception
>    deriving Show
 
> newtype Eval_SIOE a = SIOE {runSIOE :: State -> Result a}
 
> instance Monad Eval_SIOE where
>    return a = SIOE (\s -> Good a s "")
>    m >>= f = SIOE $ \x ->
>              case runSIOE m x of
>                Good a y o1 ->
>                    case runSIOE (f a) y of
>                      Good b z o2 -> Good b z (o1 ++ o2)
>                      Bad z o2 e -> Bad z (o1 ++ o2) e
>                Bad z o2 e -> Bad z o2 e
 
> raise_SIOE e = SIOE (\s -> Bad s "" e)
 
> incSIOEstate :: Eval_SIOE ()
> incSIOEstate = SIOE (\s -> Good () (s + 1) "")
 
> print_SIOE :: Output -> Eval_SIOE ()
> print_SIOE x = SIOE (\s -> Good () s  x)
 
 
> eval_SIOE :: Term -> Eval_SIOE Int
> eval_SIOE (Con a) = do incSIOEstate
>                        print_SIOE (formatLine (Con a) a)
>                        return a
> eval_SIOE (Add t u) = do a <- eval_SIOE t
>                          b <- eval_SIOE u
>                          incSIOEstate
>                          let out = formatLine (Add t u) (a + b)
>                          print_SIOE out
>                          if (a+b) == 42
>                            then raise_SIOE $ out ++ "The Ultimate Answer Has Been Computed!! Now I'm tired!"
>                            else return (a + b)
 
> runEval exp =  case runSIOE (eval_SIOE exp) 0 of
>                  Bad s o e -> "Error at iteration n. " ++ show s ++ 
>                               " - Output stack = " ++ o ++ 
>                               " - Exception = " ++ e
>                  Good a s o -> "Result = " ++ show a ++ 
>                                 " - Iterations = " ++ show s ++ " - Output = " ++ o

Run with runEval (Add (Con 18) (Add (Con 12) (Add (Con 10) (Con 2))))
[edit]
11 Suggested readings

    Cale Gibbard, Monads as containers 
    Jeff Newbern, All About Monads 
    IO inside 
    You Could Have Invented Monads! (And Maybe You Already Have.) by sigfpe 


[edit]
12 Acknowledgments

Thanks to Neil Mitchell, Daniel Fisher, Bulat Ziganzhin, Brian Hulley and Udo Stenzel for the invaluable help they gave, in the haskell-cafe mailing list, in understanding this topic.

I couldn't do it without their help.

Obviously errors are totally mine. But this is a wiki so, please, correct them!
- Andrea Rossato

Retrieved from "http://www.haskell.org/haskellwiki/The_Monadic_Way/Part_I"

This page has been accessed 1,917 times. This page was last modified 22:54, 24 July 2007. Recent content is available under a simple permissive license.

Recent content is available under a simple permissive license.
