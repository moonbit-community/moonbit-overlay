///|
pub fn fib(n : Int) -> Int64 {
  for i = 0, a = 0L, b = 1L; i < n; i = i + 1, a = b, b = a + b {

  } nobreak {
    b
  }
}

///|
pub fn encoded_message() -> String {
  @base64.std_encode2str([b'h', b'i'])
}
