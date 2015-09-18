(in-package "ACL2")

(include-book "centaur/esim/defmodules" :dir :system)
(include-book "centaur/gl/gl" :dir :system)
(include-book "centaur/aig/g-aig-eval" :dir :system)
(include-book "centaur/esim/stv/stv-top" :dir :system)
(include-book "centaur/esim/stv/stv-debug" :dir :system)
(include-book "centaur/4v-sexpr/top" :dir :system)
(include-book "tools/plev-ccl" :dir :system)
(include-book "centaur/misc/memory-mgmt" :dir :system)
(include-book "misc/without-waterfall-parallelism" :dir :system)

(without-waterfall-parallelism
(def-gl-clause-processor my-glcp))

(plev)
(set-slow-alist-action :break)
(set-debugger-enable t)
(break-on-error t)

(value-triple (set-max-mem (* 3 (expt 2 30))))

;;  loading stuff for SAT
(include-book "centaur/gl/bfr-satlink" :dir :system)
(tshell-ensure)
(gl::gl-satlink-mode)
(gl::gl-bdd-mode)

;; loading config for glucose
(defun my-glucose-config ()
  (declare (xargs :guard t))
  (satlink::make-config :cmdline "glucose"
                        :verbose t
                        :mintime 1/2
                        :remove-temps t))
(defattach gl::gl-satlink-config my-glucose-config)


;; ---------------- END GENERAL BOOK LOADING ------------------------------


;; reading Verilog and extracting modules
(defmodules *translation*
  (vl2014::make-vl-loadconfig
   :start-files (list "core8.v")))


;; ----------------- END TEMPLATE----------------------------------------

; lookup the simplified version of "alu"
(defconst *ex8-vl*
  (vl2014::vl-find-module "ex8"
                          (vl2014::vl-design->mods
                           (vl2014::vl-translation->good *translation*))))

; extract the E module
(defconst *ex8*
  (vl2014::vl-module->esim *ex8-vl*))








;; STV for the opertions where the second value is in the register Rr
; Symbolic Test Vector for ex8 module
(defstv test-vector-ex8
  :mod *ex8*

  ;; phases:  0     1     2    3
  
  :inputs
  '(("clk"    0     ~ )
    ("rst"    1     1     0)
    ("ir[3:0]" reg_r)
    ("ir[7:4]" reg_d)
    ("ir[15:8]" opcode)
    ("abusin" ain)
    ("bbusin" bin)
    ("flg"    flg))

  :outputs
  '(("abus"   _     _     _     aout)
    ("bbus"   _     _     _     bout)
    ("alu"    _     _     _     op_alu)
    ("clrf"   _     _     _     clrf)
    ("irie"   _     irie1 _     irie2)
    ("raoe"   _     raoe1 _     raoe2)
    ("rboe"   _     rboe1 _     rboe2)
    ("sel"    _     sel1  _     sel2)
    ("sie"    _     sie1  _     sie2)
    ("rb"     _     _     _     rb))
  )

;ADC test
(stv-run (test-vector-ex8)
           `((opcode   . #b00011100)
             (reg_r . #b0010)
             (reg_d . #b0011)
             (ain  . 9)
             (bin  . 3)
             (flg  . #b1000)))


(stv-debug (test-vector-ex8)
           `((opcode   . #b00011100)
             (reg_r . #b0000)
             (reg_d . #b0000)
             (ain  . 0)
             (bin  . 0)
             (flg  . #b0000)))

;macro


(defmacro ex8-basic-result ()
  `(let* ((in-alist  (test-vector-ex8-autoins))
         (out-alist (stv-run (test-vector-ex8) in-alist))
         (res       out-alist))
     res))



(defmacro ex8-thm (name &key opcode_in spec (g-bindings
                                           '(test-vector-ex8-autobinds)))
  `(def-gl-thm ,name
     :hyp (and (test-vector-ex8-autohyps)
               (equal opcode ,opcode_in))
     :concl (equal (ex8-basic-result) ,spec)
     :g-bindings ,g-bindings))

;(defmacro ex8-thm (name &key opcode_in spec (g-bindings
;                                           '(test-vector-ex8-autobinds)))
;  `(def-gl-thm ,name
;     :hyp (and (test-vector-ex8-autohyps)
;               (equal opcode ,opcode_in))
;     :concl (b* ((impl (ex8-basic-result))
;                 (spec ,spec))
;                (cw "Spec: ~s0~%" (str::hexify (cdr (assoc 'OP_ALU spec))))
;                (equal impl spec))
;     :g-bindings ,g-bindings))



;; proove ADC
(defun adc-spec (ain bin flg reg_r)
 `((AOUT . ,ain)
       (BOUT . ,bin)
       (OP_ALU . ,(logapp 1 (logbit 3 flg) #b110))
       (CLRF . 15)
       (IRIE1 . #b1)
       (IRIE2 . #b0)
       (RAOE1 . #b0)
       (RAOE2 . #b1)
       (RBOE1 . #b0)
       (RBOE2 . #b1)
       (SEL1 . #b0)
       (SEL2 . #b1)
       (SIE1 . #b0)
       (SIE2 . #b1)
       (RB . ,reg_r)))



(ex8-thm proof-adc
         :opcode_in #b00011100
         :spec (adc-spec ain bin flg reg_r))

;; proove ADD
(defun add-spec (ain bin reg_r)
 `((AOUT . ,ain)
       (BOUT . ,bin)
       (OP_ALU . #b1100)
       (CLRF . 15)
       (IRIE1 . #b1)
       (IRIE2 . #b0)
       (RAOE1 . #b0)
       (RAOE2 . #b1)
       (RBOE1 . #b0)
       (RBOE2 . #b1)
       (SEL1 . #b0)
       (SEL2 . #b1)
       (SIE1 . #b0)
       (SIE2 . #b1)
       (RB . ,reg_r)))



(ex8-thm proof-add
         :opcode_in #b00001100
         :spec (add-spec ain bin reg_r))


;; proove AND
(defun and-spec (ain bin reg_r)
 `((AOUT . ,ain)
       (BOUT . ,bin)
       (OP_ALU . #b0000)
       (CLRF . #b1101)
       (IRIE1 . #b1)
       (IRIE2 . #b0)
       (RAOE1 . #b0)
       (RAOE2 . #b1)
       (RBOE1 . #b0)
       (RBOE2 . #b1)
       (SEL1 . #b0)
       (SEL2 . #b1)
       (SIE1 . #b0)
       (SIE2 . #b1)
       (RB . ,reg_r)))



(ex8-thm proof-and
         :opcode_in #b00100000
         :spec (and-spec ain bin reg_r))

;; STV for the opertions where the second value is in the register instruction code
; Symbolic Test Vector for ex8 module
(defstv test-vector-ex8-2
  :mod *ex8*

  ;; phases:  0     1     2    3
  
  :inputs
  '(("clk"    0     ~ )
    ("rst"    1     1     0)
    ("ir[3:0]" val_k0)
    ("ir[7:4]" reg_d)
    ("ir[11:8]" val_k1)
    ("ir[15:12]" opcode)
    ("abusin" ain)
    ("bbusin" bin)
    ("flg"    flg))

  :outputs
  '(("abus"   _     _     _     aout)
    ("bbus"   _     _     _     bout)
    ("alu"    _     _     _     op_alu)
    ("clrf"   _     _     _     clrf)
    ("irie"   _     irie1 _     irie2)
    ("raoe"   _     raoe1 _     raoe2)
    ("rboe"   _     rboe1 _     rboe2)
    ("sel"    _     sel1  _     sel2)
    ("sie"    _     sie1  _     sie2)
    ("rb"     _ ))
  )


;macro
(defmacro ex8-basic-result-2 ()
  `(let* ((in-alist  (test-vector-ex8-2-autoins))
         (out-alist (stv-run (test-vector-ex8-2) in-alist))
         (res       out-alist))
     res))



(defmacro ex8-thm-2 (name &key opcode_in spec (g-bindings
                                           '(test-vector-ex8-2-autobinds)))
  `(def-gl-thm ,name
     :hyp (and (test-vector-ex8-2-autohyps)
               (equal opcode ,opcode_in))
     :concl (equal (ex8-basic-result-2) ,spec)
     :g-bindings ,g-bindings))

;; proove ANDI
;; ANDI SPECIFICATION
(defun and-spec (ain val_k0 val_k1)
 `((AOUT . ,ain)
       (BOUT . ,(logapp 4 val_k0 val_k1)
       (OP_ALU . #b0000)
       (CLRF . #b1101)
       (IRIE1 . #b1)
       (IRIE2 . #b0)
       (RAOE1 . #b0)
       (RAOE2 . #b1)
       (RBOE1 . #b0)
       (RBOE2 . #b0)
       (SEL1 . #b0)
       (SEL2 . #b1)
       (SIE1 . #b0)
       (SIE2 . #b1)
       (RB . #b0)))

;; LDI SPECIFICATION
(defun ldi-spec (ain val_k0 val_k1)
 `((AOUT . ,ain)
       (BOUT . ,(logapp 4 val_k0 val_k1)
       (OP_ALU . #b1000)
       (CLRF . #b1111)
       (IRIE1 . #b1)
       (IRIE2 . #b0)
       (RAOE1 . #b0)
       (RAOE2 . #b1)
       (RBOE1 . #b0)
       (RBOE2 . #b0)
       (SEL1 . #b0)
       (SEL2 . #b1)
       (SIE1 . #b0)
       (SIE2 . #b0)
       (RB . #b0)))


(ex8-thm proof-and
         :opcode_in #b00100000
         :spec (and-spec ain bin reg_r))
