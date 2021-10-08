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

    ## WARNING: ignoring environment value of R_HOME
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

    ## WARNING: ignoring environment value of R_HOME
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

But I don’t understand why…

</details>

## Case 3

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

    ## WARNING: ignoring environment value of R_HOME
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

## Case 4

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

    ## WARNING: ignoring environment value of R_HOME
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

It also work, but this would be expected because it should behave like
case 2.

</details>

## Other information

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
    ## [1] "72f4b07b84f85577940b9c026933d628"
    ## [1] "77deccbf7373ce64460330b9aa88f0d0"
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
    ## "ed79f3a45ace281a5131388fecbd4486" 
    ##                   savedSetup-2.rds 
    ## "d6d6cd0864cf8e63f43fcc39ec342457" 
    ##                   savedSetup-3.rds 
    ## "6d5471289e96c9ca87de08eb42206664" 
    ##                   savedSetup-4.rds 
    ## "cc21b281a90c9e334368aeb3da2ac850" 
    ## [1]  146  248 1767  248

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
    ##   ..- attr(*, "srcfile")=Classes 'srcfilecopy', 'srcfile' <environment: 0x556f9e27a390> 
    ## function (x)

``` r
all.equal(setup2, setup3)
all.equal(setup2, setup4)
```

    ## [1] TRUE
    ## [1] "Component \"fun\": Length mismatch: comparison on first 2 components"

``` r
all.equal(setup1, setup2)
```

    ##  [1] "Component \"fun\": Names: 5 string mismatches"                                
    ##  [2] "Component \"fun\": Length mismatch: comparison on first 5 components"         
    ##  [3] "Component \"fun\": Component 1: target, current do not match when deparsed"   
    ##  [4] "Component \"fun\": Component 2: target, current do not match when deparsed"   
    ##  [5] "Component \"fun\": Component 3: Modes of target, current: function, character"
    ##  [6] "Component \"fun\": Component 3: target, current do not match when deparsed"   
    ##  [7] "Component \"fun\": Component 3: 'current' is not an environment"              
    ##  [8] "Component \"fun\": Component 4: Modes of target, current: function, character"
    ##  [9] "Component \"fun\": Component 4: target, current do not match when deparsed"   
    ## [10] "Component \"fun\": Component 4: 'current' is not an environment"              
    ## [11] "Component \"fun\": Component 5: Modes of target, current: function, character"
    ## [12] "Component \"fun\": Component 5: target, current do not match when deparsed"   
    ## [13] "Component \"fun\": Component 5: 'current' is not an environment"

## Any help would be much appreciated

If someone reading this understand what is happening on “Case 2” I would
be very happy to know it. You can open [an issue in this
repo.](https://github.com/juliendiot42/question-about-R/issues).

Thank you very much.

# session info:

<details>
<summary style="margin-bottom: 10px;">
Session Information (click to expand)
</summary>
<!-- Place an empty line before the chunk ! -->

    ## 
    ## CPU: AMD Ryzen 5 3600X 6-Core Processor
    ## Memory total size: 32.7965 GB
    ## 
    ## 
    ## Session information:
    ## R version 4.1.1 (2021-08-10)
    ## Platform: x86_64-pc-linux-gnu (64-bit)
    ## Running under: Pop!_OS 21.04
    ## 
    ## Matrix products: default
    ## BLAS/LAPACK: /opt/OpenBLAS/lib/libopenblas_zenp-r0.3.17.so
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] compiler_4.1.1  magrittr_2.0.1  fastmap_1.1.0   tools_4.1.1    
    ##  [5] htmltools_0.5.2 yaml_2.2.1      stringi_1.7.4   rmarkdown_2.11 
    ##  [9] knitr_1.36      stringr_1.4.0   xfun_0.26       digest_0.6.28  
    ## [13] rlang_0.4.11    evaluate_0.14

</details>
