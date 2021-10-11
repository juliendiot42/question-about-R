f1 <- function(x) {
  x^2
}

f <- function(x) {
  # get all accessible variables
  env <- environment()
  while (!identical(env, globalenv())) {
    print(env)
    print(ls(envir = env))
    env <- parent.env(env)
  }

  f1(x) + 1
}
