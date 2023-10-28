.macro adbw src, val
  lda src
  adc val
  sta src
  bcc skip_carry
  inc src + 1
skip_carry:
.endmacro