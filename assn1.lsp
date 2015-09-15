(include-book "intro")

(plev)

(set-slow-alist-action :break)
(set-debugger-enable t)
(break-on-error t)

(value-triple (set-max-mem (* 2 (expt 2 30))))

; EXERCISE 4

; translating the ALU design
(defmodules *translation3*
  (vl2014::make-vl-loadconfig
   :start-files (list "assn1.v")))

; lookup the simplified version of "alu"
(defconst *alu-vl3*
  (vl2014::vl-find-module "alu"
                          (vl2014::vl-design->mods
                           (vl2014::vl-translation->good *translation3*))))

; extract the E module
(defconst *alu3*
  (vl2014::vl-module->esim *alu-vl3*))

; writing a Symbolic Test Vector (STV)
(defstv test-vector3
  :mod *alu3*
  :inputs
  '(("a" a)
    ("b" b)
    ("alu_op" op))


  :outputs
  '(("c_out" c)
    ("z" z)
    ("v" v)
    ("n" n)
    ("r" res)))

; test it - only for us- REMOVE THIS
; a+1
(stv-run (test-vector3)
         '((a . 9)
           (b . 5)
           (op . 9)))
; a+b
(stv-run (test-vector3)
         '((a . 9)
           (b . 5)
           (op . 12)))
