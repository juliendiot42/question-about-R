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

Thank you very much.