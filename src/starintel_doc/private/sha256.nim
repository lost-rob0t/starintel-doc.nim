import std/[strutils]

const roundConstants: array[64, uint32] = [
  0x428a2f98'u32, 0x71374491'u32, 0xb5c0fbcf'u32, 0xe9b5dba5'u32,
  0x3956c25b'u32, 0x59f111f1'u32, 0x923f82a4'u32, 0xab1c5ed5'u32,
  0xd807aa98'u32, 0x12835b01'u32, 0x243185be'u32, 0x550c7dc3'u32,
  0x72be5d74'u32, 0x80deb1fe'u32, 0x9bdc06a7'u32, 0xc19bf174'u32,
  0xe49b69c1'u32, 0xefbe4786'u32, 0x0fc19dc6'u32, 0x240ca1cc'u32,
  0x2de92c6f'u32, 0x4a7484aa'u32, 0x5cb0a9dc'u32, 0x76f988da'u32,
  0x983e5152'u32, 0xa831c66d'u32, 0xb00327c8'u32, 0xbf597fc7'u32,
  0xc6e00bf3'u32, 0xd5a79147'u32, 0x06ca6351'u32, 0x14292967'u32,
  0x27b70a85'u32, 0x2e1b2138'u32, 0x4d2c6dfc'u32, 0x53380d13'u32,
  0x650a7354'u32, 0x766a0abb'u32, 0x81c2c92e'u32, 0x92722c85'u32,
  0xa2bfe8a1'u32, 0xa81a664b'u32, 0xc24b8b70'u32, 0xc76c51a3'u32,
  0xd192e819'u32, 0xd6990624'u32, 0xf40e3585'u32, 0x106aa070'u32,
  0x19a4c116'u32, 0x1e376c08'u32, 0x2748774c'u32, 0x34b0bcb5'u32,
  0x391c0cb3'u32, 0x4ed8aa4a'u32, 0x5b9cca4f'u32, 0x682e6ff3'u32,
  0x748f82ee'u32, 0x78a5636f'u32, 0x84c87814'u32, 0x8cc70208'u32,
  0x90befffa'u32, 0xa4506ceb'u32, 0xbef9a3f7'u32, 0xc67178f2'u32
]

proc rotateRight(value: uint32, count: int): uint32 =
  (value shr count) or (value shl (32 - count))

proc sha256Hex*(input: string): string =
  var bytes: seq[uint8]
  for character in input:
    bytes.add(uint8(character.ord))
  let bitLength = uint64(bytes.len) * 8'u64
  bytes.add(0x80'u8)
  while bytes.len mod 64 != 56:
    bytes.add(0'u8)
  for shift in countdown(56, 0, 8):
    bytes.add(uint8((bitLength shr shift) and 0xff'u64))

  var state: array[8, uint32] = [
    0x6a09e667'u32, 0xbb67ae85'u32, 0x3c6ef372'u32, 0xa54ff53a'u32,
    0x510e527f'u32, 0x9b05688c'u32, 0x1f83d9ab'u32, 0x5be0cd19'u32
  ]

  var offset = 0
  while offset < bytes.len:
    var words: array[64, uint32]
    for index in 0 ..< 16:
      let position = offset + index * 4
      words[index] = (uint32(bytes[position]) shl 24) or
        (uint32(bytes[position + 1]) shl 16) or
        (uint32(bytes[position + 2]) shl 8) or
        uint32(bytes[position + 3])
    for index in 16 ..< 64:
      let s0 = rotateRight(words[index - 15], 7) xor
        rotateRight(words[index - 15], 18) xor (words[index - 15] shr 3)
      let s1 = rotateRight(words[index - 2], 17) xor
        rotateRight(words[index - 2], 19) xor (words[index - 2] shr 10)
      words[index] = words[index - 16] + s0 + words[index - 7] + s1

    var a = state[0]
    var b = state[1]
    var c = state[2]
    var d = state[3]
    var e = state[4]
    var f = state[5]
    var g = state[6]
    var h = state[7]
    for index in 0 ..< 64:
      let sum1 = rotateRight(e, 6) xor rotateRight(e, 11) xor rotateRight(e, 25)
      let choose = (e and f) xor ((not e) and g)
      let temporary1 = h + sum1 + choose + roundConstants[index] + words[index]
      let sum0 = rotateRight(a, 2) xor rotateRight(a, 13) xor rotateRight(a, 22)
      let majority = (a and b) xor (a and c) xor (b and c)
      let temporary2 = sum0 + majority
      h = g
      g = f
      f = e
      e = d + temporary1
      d = c
      c = b
      b = a
      a = temporary1 + temporary2

    state[0] = state[0] + a
    state[1] = state[1] + b
    state[2] = state[2] + c
    state[3] = state[3] + d
    state[4] = state[4] + e
    state[5] = state[5] + f
    state[6] = state[6] + g
    state[7] = state[7] + h
    offset += 64

  for value in state:
    result.add(value.toHex(8).toLowerAscii)
