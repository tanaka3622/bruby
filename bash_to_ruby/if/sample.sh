even = 0
odd = 0
i = 0

while i < 10 {
  if i % 2 == 0 {
    even = even + i
  } else {
    odd = odd + i
  }
  i = i + 1
}
even + odd

