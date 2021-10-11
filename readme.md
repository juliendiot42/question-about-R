Readme
================

## Case 1

Let’s say I have a very complex function `f`. In order to have a cleaner
and more understandable code, I have created another function `f1` that
is called by this main function. These two function are defined in a
`.R` file named `functionDefinition.R`:

``` r
f1 <- function(x) { 
   x^2 
 } 
  
 f <- function(x) { 
   f1(x) + 1 
 } 
```

Now I want to save in a `.rds` file the function and another parameter
for later used. So I (naively) do:

``` r
createSetup <- function(funDefFile, y) {
  source(funDefFile)
  z <- paste(y, y) # some complex stuff
  list(param = z,
       fun = f)
}

mySetup <- createSetup('functionsDefinition.R', "toto")
saveRDS(mySetup, 'savedSetup-1.rds')
```

Then later in **a new R-session** I load my “setup” and call my
function:

``` r
mySetup <- readRDS("savedSetup-1.rds")
mySetup$fun(10)
```

**Question: What will happen?**

<details>
<summary>
Click to see the anwser
</summary>

``` sh
R -q --vanilla -e '
tryCatch({
mySetup <- readRDS("savedSetup-1.rds")
mySetup$fun(10)
}, error = function(err) {
  message(err)
})
'
```

    ## > 
    ## > tryCatch({
    ## + mySetup <- readRDS("savedSetup-1.rds")
    ## + mySetup$fun(10)
    ## + }, error = function(err) {
    ## +   message(err)
    ## + })
    ## could not find function "f1"> 
    ## > 
    ## >

**It raise an error.**

Indeed by doing this way, I saved in the `mySetup` list the definition
of `f` but not `f1` so when I load it back `f1` is not defined.

Note: by default the function `source` evaluate the given file in the
global environment.

</details>

## Case 2:

If I specify that the function `source` should evaluate the function
definition in the local environment, it should not change anything, I
still do not save (explicitly) `f1`:

``` r
createSetup_2 <- function(funDefFile, y) {
  source(funDefFile, environment())
  z <- paste(y, y) # some complex stuff
  list(param = z,
       fun = f)
}
```

``` r
mySetup <- createSetup_2('functionsDefinition.R', "toto")
saveRDS(mySetup, 'savedSetup-2.rds')
```

Again I load my new setup:

``` r
mySetup <- readRDS("savedSetup-2.rds")
mySetup$fun(10)
```

**Question: What will happen?**

<details>
<summary>
Click to see the anwser
</summary>

``` sh
R -q --vanilla -e '
tryCatch({
mySetup <- readRDS("savedSetup-2.rds")
mySetup$fun(10)
}, error = function(err) {
  message(err)
})
'
```

    ## > 
    ## > tryCatch({
    ## + mySetup <- readRDS("savedSetup-2.rds")
    ## + mySetup$fun(10)
    ## + }, error = function(err) {
    ## +   message(err)
    ## + })
    ## [1] 101
    ## > 
    ## > 
    ## >

**It works !**

Indeed, this code is similar to:

``` r
createFun <- function(y){
  function(x){
    x + y
  }
}

foo10 <- createFun(10)
foo42 <- createFun(42)
y <- 1

foo10(0)
```

    ## [1] 10

``` r
foo42(0)
```

    ## [1] 42

In this case, the functions `foo10` and `foo42` look for `y` in
different environments. (*in R the values of free variables are searched
for in the environment in which the function was defined*)

Moreover, according to this blog post: [How and why to return functions
in
R](https://www.r-bloggers.com/2015/04/how-and-why-to-return-functions-in-r/)
(section: *The nature of closure driven reference leaks*)

> In R when objects are serialized they save their lexical environment
> (and any parent environments) up until the global environment. The
> global environment is not saved in these situations. When a function
> is re-loaded it brings in new copies of its saved lexical environment
> chain and the top of this chain is altered to have a current
> environment as its parent. This is made clearer by the following two
> code examples:

> Example 1: R closure fails to durably bind items in the global
> environment (due to serialization hack).

``` r
f <- function() { print(x) }
x <- 5
f()
## [1] 5
saveRDS(f,file='f1.rds')
rm(list=ls())
f = readRDS('f1.rds')
f()
## Error in print(x) : object 'x' not found
```

> Example 2: R closure seems to bind items in intermediate lexical
> environments.

``` r
g <- function() {
  x <- 5
  function() {
    print(x)
  }
}
f <- g()
saveRDS(f,file='f2.rds')
rm(list=ls())
f = readRDS('f2.rds')
f()
## [1] 5
```

### Warning

Using such enclosure can make the function to store a lot of unnecessary
information depending where they had been defined:

(I have modify the function `f` to print all the variable it has access
to, except the global environment, see `functionDefinition_2.R`)

``` r
createSetup_x <- function(funDefFile, y) {
  
  source(funDefFile, environment())
  
  # next variables are not necessary for later and especially not for `f`
  tempVar_1 <- "a"
  tempVar_2 <- "b"
  tempVar_3 <- "c"
  
  z <- paste(y, tempVar_1, tempVar_2, tempVar_3) # some complex stuff
  list(param = z,
       fun = f)
}
```

``` r
mySetup <- createSetup_x("functionsDefinition_2.R", "toto")
saveRDS(mySetup, 'savedSetup-x.rds')
```

``` sh
R -q --vanilla -e '
tryCatch({
mySetup <- readRDS("savedSetup-x.rds")
mySetup$fun(10)
}, error = function(err) {
  message(err)
})
'
```

    ## > 
    ## > tryCatch({
    ## + mySetup <- readRDS("savedSetup-x.rds")
    ## + mySetup$fun(10)
    ## + }, error = function(err) {
    ## +   message(err)
    ## + })
    ## <environment: 0x558af660fed0>
    ## [1] "env" "x"  
    ## <environment: 0x558af65fee68>
    ## [1] "f"          "f1"         "funDefFile" "tempVar_1"  "tempVar_2" 
    ## [6] "tempVar_3"  "y"          "z"         
    ## [1] 101
    ## > 
    ## > 
    ## >

Here we can see that `f` had saved the values of `funDefFile`,
`tempVar_1`,`tempVar_2`, `tempVar_3`, `y` and `z`.

Indeed it had been defined in the function `createSetup_x` in which we
can find those variable.

We can avoid that by sourcing in an empty new environment:

``` r
createSetup_y <- function(funDefFile, y) {
  
  env <- new.env(parent = globalenv())
  source(funDefFile, env)
  
  # next variables are not necessary for later and especially not for `f`
  tempVar_1 <- "a"
  tempVar_2 <- "b"
  tempVar_3 <- "c"
  
  z <- paste(y, tempVar_1, tempVar_2, tempVar_3) # some complex stuff
  list(param = z,
       fun = env$f)
}
```

``` r
mySetup <- createSetup_y("functionsDefinition_2.R", "toto")
saveRDS(mySetup, 'savedSetup-y.rds')
```

``` sh
R -q --vanilla -e '
tryCatch({
mySetup <- readRDS("savedSetup-y.rds")
mySetup$fun(10)
}, error = function(err) {
  message(err)
})
'
```

    ## > 
    ## > tryCatch({
    ## + mySetup <- readRDS("savedSetup-y.rds")
    ## + mySetup$fun(10)
    ## + }, error = function(err) {
    ## +   message(err)
    ## + })
    ## <environment: 0x55eded2f3250>
    ## [1] "env" "x"  
    ## <environment: 0x55eded2e1e68>
    ## [1] "f"  "f1"
    ## [1] 101
    ## > 
    ## > 
    ## >

</details>

## Other similar cases

<details>
<summary>
Click to expand
</summary>

### Case 3

Now let’s get rid of the `source` function:

``` r
createSetup_3 <- function(funDefFile, y) {
  
  f1 <- function(x) { 
    x^2 
  } 
  
  f <- function(x) { 
    f1(x) + 1 
  } 
  
  z <- paste(y, y) # some complex stuff
  list(param = z,
       fun = f)
}
```

``` r
mySetup <- createSetup_3('functionsDefinition.R', "toto")
saveRDS(mySetup, 'savedSetup-3.rds')
```

Again I load my new setup:

``` r
mySetup <- readRDS("savedSetup-3.rds")
mySetup$fun(10)
```

**Question: What will happen?**

<details>
<summary>
Click to see the anwser
</summary>

``` sh
R -q --vanilla -e '
tryCatch({
mySetup <- readRDS("savedSetup-2.rds")
mySetup$fun(10)
}, error = function(err) {
  message(err)
})
'
```

    ## > 
    ## > tryCatch({
    ## + mySetup <- readRDS("savedSetup-2.rds")
    ## + mySetup$fun(10)
    ## + }, error = function(err) {
    ## +   message(err)
    ## + })
    ## [1] 101
    ## > 
    ## > 
    ## >

It also work, but this would be expected because it should behave like
case 2.

</details>

### Case 4

Now let’s source in a new environment:

``` r
createSetup_4 <- function(funDefFile, y) {
  env <- new.env()
  source(funDefFile, env)
  
  z <- paste(y, y) # some complex stuff
  list(param = z,
       fun = env$f)
}
```

``` r
mySetup <- createSetup_4('functionsDefinition.R', "toto")
saveRDS(mySetup, 'savedSetup-4.rds')
```

Again I load my new setup:

``` r
mySetup <- readRDS("savedSetup-4.rds")
mySetup$fun(10)
```

**Question: What will happen?**

<details>
<summary>
Click to see the anwser
</summary>

``` sh
R -q --vanilla -e '
tryCatch({
mySetup <- readRDS("savedSetup-4.rds")
mySetup$fun(10)
}, error = function(err) {
  message(err)
})
'
```

    ## > 
    ## > tryCatch({
    ## + mySetup <- readRDS("savedSetup-4.rds")
    ## + mySetup$fun(10)
    ## + }, error = function(err) {
    ## +   message(err)
    ## + })
    ## [1] 101
    ## > 
    ## > 
    ## >

It also works

</details>

### Other information

Let’s have a look on the objects’/setup files’ size and hash:

``` r
setup1 <- createSetup('functionsDefinition.R', "toto")
setup2 <- createSetup_2('functionsDefinition.R', "toto")
setup3 <- createSetup_3('functionsDefinition.R', "toto")
setup4 <- createSetup_4('functionsDefinition.R', "toto")

setup1_2 <- readRDS('savedSetup-1.rds')
setup2_2 <- readRDS('savedSetup-2.rds')
setup3_2 <- readRDS('savedSetup-3.rds')
setup4_2 <- readRDS('savedSetup-4.rds')

object.size(setup1)
object.size(setup1_2)

object.size(setup2)
object.size(setup2_2)

object.size(setup3)
object.size(setup3_2)

object.size(setup4)
object.size(setup4_2)
```

    ## 1368 bytes
    ## 1368 bytes
    ## 1368 bytes
    ## 1368 bytes
    ## 9992 bytes
    ## 5304 bytes
    ## 1368 bytes
    ## 1368 bytes

``` r
digest::digest(setup1)
digest::digest(setup1_2)
identical(setup1, setup1_2)
all.equal(setup1, setup1_2)

digest::digest(setup2)
digest::digest(setup2_2)
identical(setup2, setup2_2)
all.equal(setup2, setup2_2)


digest::digest(setup3)
digest::digest(setup3_2)
identical(setup3, setup3_2)
all.equal(setup3, setup3_2)

digest::digest(setup4)
digest::digest(setup4_2)
identical(setup4, setup4_2)
all.equal(setup4, setup4_2)
```

    ## [1] "424ce4d9012908990559a7c15110e04a"
    ## [1] "424ce4d9012908990559a7c15110e04a"
    ## [1] TRUE
    ## [1] TRUE
    ## [1] "210f7065526604412277d8ebe891f64c"
    ## [1] "fae1491a4efd38412f9c297e80035ae7"
    ## [1] FALSE
    ## [1] TRUE
    ## [1] "829e4f604fe0c7a02f42f2fdb9b64f10"
    ## [1] "3ad72750021c4586d6fdc7b85d050374"
    ## [1] FALSE
    ## [1] TRUE
    ## [1] "28691772934279dea7071795200982a1"
    ## [1] "18f2532a54122c3c1016a88e7e2082fa"
    ## [1] FALSE
    ## [1] TRUE

``` r
tools::md5sum('savedSetup-1.rds')
tools::md5sum('savedSetup-2.rds')
tools::md5sum('savedSetup-3.rds')
tools::md5sum('savedSetup-4.rds')

file.info(c('savedSetup-1.rds',
            'savedSetup-2.rds',
            'savedSetup-3.rds',
            'savedSetup-2.rds'))$size
```

    ##                   savedSetup-1.rds 
    ## "302fe17168ef4e8ec779092fd6fe711c" 
    ##                   savedSetup-2.rds 
    ## "ed22d0a1464c30544f68796ae600d93d" 
    ##                   savedSetup-3.rds 
    ## "7fd89ec79844fe92d55a8230382202f7" 
    ##                   savedSetup-4.rds 
    ## "b2038bbb0eb9a8d7b130c2db37e5d274" 
    ## [1]  145  248 1744  248

``` r
str(setup1$fun)
str(setup2$fun)
str(setup3$fun)
str(setup4$fun)
```

    ## function (x)  
    ## function (x)  
    ## function (x)  
    ##  - attr(*, "srcref")= 'srcref' int [1:8] 7 8 9 3 8 3 7 9
    ##   ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x555eccdb99a8> 
    ## function (x)

``` r
all.equal(setup2, setup3)
all.equal(setup2, setup4)
```

    ## [1] TRUE
    ## [1] TRUE

``` r
all.equal(setup1, setup2)
```

    ## [1] TRUE

</details>

# session info:

    ## 
    ## CPU: AMD Ryzen Threadripper 3990X 64-Core Processor
    ## Memory total size: 263.8572 GB
    ## 
    ## 
    ## Session information:
    ## R version 4.0.2 (2020-06-22)
    ## Platform: x86_64-pc-linux-gnu (64-bit)
    ## Running under: Ubuntu 20.04.3 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/local/lib/R/lib/libRblas.so
    ## LAPACK: /usr/local/lib/R/lib/libRlapack.so
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] compiler_4.0.2  magrittr_2.0.1  tools_4.0.2     htmltools_0.5.1
    ##  [5] yaml_2.2.1      stringi_1.5.3   rmarkdown_2.6   knitr_1.30     
    ##  [9] stringr_1.4.0   xfun_0.20       digest_0.6.27   rlang_0.4.10   
    ## [13] evaluate_0.14
