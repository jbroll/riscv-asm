
proc ::critcl::c++command {tclname class constructors methods} {
    # Build the body of the function to define a new tcl command for
    # the C++ class
    set helpline {}
    set classptr ptr_$tclname
    set comproc "    $class* $classptr;\n"
    append comproc "    switch (objc) \{\n"

    if {![llength $constructors]} {
	set constructors {{}}
    }

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
	set nargs  [llength $names]
	set ncargs [expr {$nargs + 2}]
	append comproc "        case $ncargs: \{\n"

	if {!$nargs} {
	    append comproc "            $classptr = new $class\();\n"
	} else  {
	    append comproc [ProcessArgs types $names $cnames]
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
    foreach {rt n a} $methods {
	lappend rtypes $rt
	lappend tnames [lindex $n 0]
	set tmp [lindex $n 1]
	if {$tmp eq ""}  {
	    lappend mnames [lindex $n 0]
	} else {
	    lappend mnames [lindex $n 1]
	}
	lappend adefs $a
    }
    append cmdproc "    static const char* cmds\[]=\{\"[join $tnames {","}]\",NULL\};\n"
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
	set nargs  [llength $names]
	set ncargs [expr {$nargs + 2}]

	append cmdproc "        case $ndx: \{\n"
	append cmdproc "            if (objc==$ncargs) \{\n"
	append cmdproc  [ProcessArgs types $names $cnames]
	append cmdproc "                "
	if {$rtype ne "void"} {
	    append cmdproc "$rtype2 rv = "
	}
	append cmdproc "$classptr->$mname\([join $cnames {, }]);\n"
	append cmdproc "                "
	switch -- $rtype {
	    void     { }
	    ok   { append cmdproc "return rv;" }
	    int  { append cmdproc "Tcl_SetIntObj(Tcl_GetObjResult(ip), rv);" }
	    long { append cmdproc " Tcl_SetLongObj(Tcl_GetObjResult(ip), rv);" }
	    float -
	    double { append cmdproc "Tcl_SetDoubleObj(Tcl_GetObjResult(ip), rv);" }
	    char*  { append cmdproc "Tcl_SetResult(ip, rv, TCL_STATIC);" }
	    string -
	    dstring  { append cmdproc "Tcl_SetResult(ip, rv, TCL_DYNAMIC);" }
	    vstring  { append cmdproc "Tcl_SetResult(ip, rv, TCL_VOLATILE);" }
	    default  { append cmdproc "if (rv == NULL) \{ return TCL_ERROR ; \}\n  Tcl_SetObjResult(ip, rv); Tcl_DecrRefCount(rv);" }
	}
	append cmdproc "\n"
	append cmdproc "                "
	if {$rtype ne "ok"} { append cmdproc "return TCL_OK;\n" }

	append cmdproc "            \} else \{\n"
	append cmdproc "               Tcl_WrongNumArgs(ip, 1, objv, \"$helpline\");\n"
	append cmdproc "               return TCL_ERROR;\n"
	append cmdproc "            \}\n"
	append cmdproc "        \}\n"
	incr ndx
    }
    append cmdproc "    \}\n\}\n"

    # TODO: line pragma fix ?!
    ccode $delproc
    ccode $cmdproc

    puts $cmdproc
    puts $comproc

    # Force the new ccommand to be defined in the caller's namespace
    # instead of improperly in ::critcl.
    namespace eval [uplevel 1 namespace current] \
	[list critcl::ccommand $tclname {dummy ip objc objv} $comproc]

    return
}
