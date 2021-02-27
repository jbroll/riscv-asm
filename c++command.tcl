 proc processargs {typesArray names cnames}  {
    upvar $typesArray types
    set body ""
    foreach x $names c $cnames {
        set t $types($x)
        switch -- $t {
            int - long - float - double - char* - Tcl_Obj* {
                append body "            $t $c;\n"
            }
            default {
                append body "            void* $c;\n"
            }
        }
    }
    set n 1
    foreach x $names c $cnames {
        set t $types($x)
        incr n
        switch -- $t {
            int {
                append body "            if (Tcl_GetIntFromObj(ip, objv\[$n], &$c) != TCL_OK)\n"
                append body "                return TCL_ERROR;\n"
            }
            long {
                append body "            if (Tcl_GetLongFromObj(ip, objv\[$n], &$c) != TCL_OK)\n"
                append body "                return TCL_ERROR;\n"
            }
            float {
                append body "            \{ double tmp;\n"
                append body "                if (Tcl_GetDoubleFromObj(ip, objv\[$n], &tmp) != TCL_OK)\n"
                append body "                   return TCL_ERROR;\n"
                append body "                $c = (float) tmp;\n"
                append body "            \}\n"
            }
            double {
                append body "            if (Tcl_GetDoubleFromObj(ip, objv\[$n], &$c) != TCL_OK)\n"
                append body "                return TCL_ERROR;\n"
            }
            char* {
                append body "            $c = Tcl_GetString(objv\[$n]);\n"
            }
            default {
                append body "            $c = objv\[$n];\n"
            }
        }
    }
    return $body 
 } 
 proc c++command {tclname class constructors methods} {
 #
 # Build the body of the function to define a new tcl command for the C++ class
    set helpline {}
    set classptr ptr_$tclname
    set comproc "    $class* $classptr;\n"
    append comproc "    switch (objc) \{\n"

    foreach adefs $constructors {
       array set types {}
        set names {}
        set cargs {}
        set cnames {}
        
        foreach {t n} $adefs {
            set types($n) $t
            lappend names $n
            lappend cnames _$n
            lappend cargs "$t $n"
        }
        lappend helpline "$tclname pathName [join $names { }]"      
        set nargs [llength $names]
        set ncargs [expr $nargs+2]
       append comproc "        case $ncargs: \{\n"
        
        if {$nargs == 0} {
            append comproc "            $classptr = new $class\();\n"
        } else  {
            append comproc [processargs types $names $cnames]
            append comproc "            $classptr = new $class\([join $cnames {, }]);\n"
         }
         append comproc "            break;\n"
         append comproc "        \}\n"

    }
    append comproc "        default: \{\n"
    append comproc "            Tcl_SetResult(ip, \"wrong # args: should be either [join $helpline { or }]\",TCL_STATIC);\n"
    append comproc "            return TCL_ERROR;\n"
    append comproc "        \}\n"
    append comproc "    \}\n"

    append comproc "    if ( $classptr == NULL ) \{\n"
    append comproc "        Tcl_SetResult(ip, \"Not enough memory to allocate a new $tclname\", TCL_STATIC);\n"
    append comproc "        return TCL_ERROR;\n"
    append comproc "    \}\n"


    append comproc "    Tcl_CreateObjCommand(ip, Tcl_GetString(objv\[1]), cmdproc_$tclname, (ClientData) $classptr, delproc_$tclname);\n"
    append comproc "    return TCL_OK;\n"
 #
 #  Build the body of the c function called when the object is deleted
 #
    set delproc "void delproc_$tclname\(ClientData cd) \{\n"
    append delproc "    if (cd != NULL)\n"
    append delproc "        delete ($class*) cd;\n"
    append delproc "\}\n"

 #
 # Build the body of the function that processes the tcl commands for the class
 #
    set cmdproc "int cmdproc_$tclname\(ClientData cd, Tcl_Interp* ip, int objc, Tcl_Obj *CONST objv\[]) \{\n"
    append cmdproc "    int index;\n"
    append cmdproc "    $class* $classptr = ($class*) cd;\n"

    set rtypes {}
    set tnames {}
    set mnames {}
    set adefs {}
    foreach method $methods {
        foreach {rt n a} $method {
            lappend rtypes $rt
            lappend tnames [lindex [split $n | ] 0]
            set tmp [lindex [split $n | ] 1]
            if { $tmp == ""}  {
                lappend mnames  [lindex [split $n | ] 0]
            } else {
                lappend mnames [lindex [split $n | ] 1]
            }
            lappend adefs $a
        }
    }
    append cmdproc "    const char* cmds\[]=\{\"[join $tnames {","}]\",NULL\};\n"
    append cmdproc "    if (objc<2) \{\n"
    append cmdproc "       Tcl_WrongNumArgs(ip, 1, objv, \"expecting pathName option\");\n"
    append cmdproc "       return TCL_ERROR;\n"
    append cmdproc "    \}\n\n"
    append cmdproc "    if (Tcl_GetIndexFromObj(ip, objv\[1], cmds, \"option\", TCL_EXACT, &index) != TCL_OK)\n"
    append cmdproc "        return TCL_ERROR;\n"
    append cmdproc "    switch (index) \{\n"

    set ndx 0
    foreach rtype $rtypes tname $tnames mname $mnames adef $adefs {
        array set types {}
        set names {}
        set cargs {}
        set cnames {}

        switch -- $rtype {
            ok      { set rtype2 "int" }
            string -
            dstring -
            vstring { set rtype2 "char*" }
            default { set rtype2 $rtype }
        }
      
        foreach {t n} $adef {
            set types($n) $t
            lappend names $n
            lappend cnames _$n
            lappend cargs "$t $n"
        }
        set helpline "$tname [join $names { }]"      
        set nargs [llength $names]
        set ncargs [expr $nargs+2]
       
        append cmdproc "        case $ndx: \{\n"
        append cmdproc "            if (objc==$ncargs) \{\n"
        append cmdproc  [processargs types $names $cnames]
        append cmdproc "                "
        if {$rtype != "void"} {
            append cmdproc "$rtype2 rv = "
        }
        append cmdproc "$classptr->$mname\([join $cnames {, }]);\n"
        append cmdproc "                "
        switch -- $rtype {
           void     { }
           ok { append cmdproc "return rv;" }
           int { append cmdproc "Tcl_SetIntObj(Tcl_GetObjResult(ip), rv);" }
           long { append cmdproc " Tcl_SetLongObj(Tcl_GetObjResult(ip), rv);" }
           float -
           double { append cmdproc "Tcl_SetDoubleObj(Tcl_GetObjResult(ip), rv);" }
           char* { append cmdproc "Tcl_SetResult(ip, rv, TCL_STATIC);" }
           string -
           dstring { append cmdproc "Tcl_SetResult(ip, rv, TCL_DYNAMIC);" }
           vstring { append cmdproc "Tcl_SetResult(ip, rv, TCL_VOLATILE);" }
           default  { append cmdproc "Tcl_SetObjResult(ip, rv); Tcl_DecrRefCount(rv);" }
        }
        append cmdproc "\n"
        append cmdproc "                "
        if {$rtype != "ok"} { append cmdproc "return TCL_OK;\n" }
 
        append cmdproc "            \} else \{\n"
        append cmdproc "               Tcl_WrongNumArgs(ip, 1, objv, \"$helpline\");\n"
        append cmdproc "               return TCL_ERROR;\n"
        append cmdproc "            \}\n"                
        append cmdproc "        \}\n"
        incr ndx
    }
    append cmdproc "    \}\n\}\n"
   

    critcl::ccode $delproc
    critcl::ccode $cmdproc
    critcl::ccommand $tclname {dummy ip objc objv} $comproc
 }
