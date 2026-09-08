///|
test "fib" {
  debug_inspect([0, 1, 2, 3, 4, 5].map(fib), content="[1, 1, 2, 3, 5, 8]")
}

///|
test "external dependency" {
  debug_inspect(encoded_message(), content="\"aGk=\"")
}
