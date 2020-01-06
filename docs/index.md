---
layout: default
title: Home
nav_order: 1
description: "APCSPLANG is a programming language inspired by the AP Computer Science Principles exam pseudocode."
permalink: /
---
# APCSPLANG
APCSPLANG is a programming language inspired by the pseudocode used on the AP Computer Science Principles exam, as seen on the [reference sheet](https://apcentral.collegeboard.org/pdf/ap-computer-science-principles-course-and-exam-description-0.pdf#page=126 "Course and Exam Description").

> **Note**: The name is in all caps to emulate the style of keywords such as `IF` and `REPEAT`

## Examples
### Hello world
```
DISPLAY("Hello, world")
```

### Fibonacci
```
fibonacci ← [1, 1]
REPEAT 98 TIMES {
  last ← LENGTH(fibonacci)
  APPEND(fibonacci, fibonacci[last] + fibonacci[last-1])
}

DISPLAY("First 100 fibonacci numbers:")
DISPLAY(fibonacci)
```
