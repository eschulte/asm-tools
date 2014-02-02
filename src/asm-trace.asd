(defsystem :asm-trace
  :description "Trace execution of GCC produced AT&T syntax assembler"
  :version "0.0.0"
  :author "Eric Schulte <schulte.eric@gmail.com>"
  :licence "GPL V3"
  :depends-on (alexandria metabang-bind curry-compose-reader-macros cl-ppcre)
  :components ((:file "asm-trace")))
