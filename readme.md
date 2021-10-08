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

## Other information

Let’s have a look on the `setup`s size:

``` r
setup1 <- createSetup('functionsDefinition.R', "toto")
setup2 <- createSetup_2('functionsDefinition.R', "toto")
setup3 <- createSetup_3('functionsDefinition.R', "toto")

object.size(setup1)
object.size(setup2)
object.size(setup3)
```

    ## 1368 bytes
    ## 1368 bytes
    ## 9992 bytes

``` r
digest::digest(setup1)
digest::digest(setup2)
digest::digest(setup3)
```

    ## [1] "424ce4d9012908990559a7c15110e04a"
    ## [1] "210f7065526604412277d8ebe891f64c"
    ## [1] "aa6b62a55001f70942a0f8cce1d7fe42"

`setup2` and `setup3` are different

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
