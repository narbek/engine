      SUBROUTINE C_reconstruction(ABORT,err)
*--------------------------------------------------------
*-       Prototype C analysis routine
*-
*-
*-   Purpose and Methods : reconstruction of HMS quantities 
*-
*-   Output: ABORT              - success or failure
*-         : err             - reason for failure, if any
*- 
*-   Created  8-Nov-1993   Kevin B. Beard, HU
*-   Modified 20-Nov-1993   KBB for new errors
*-    $Log$
*-    Revision 1.4  1995/05/11 15:48:15  cdaq
*-    (SAW) Add call to c_physics for coincidence variables
*-
* Revision 1.3  1994/06/17  03:16:29  cdaq
* (KBB) Remove not yet written warning
*
* Revision 1.2  1994/02/04  21:09:43  cdaq
* Fix indentation
*
c Revision 1.1  1994/02/04  21:08:21  cdaq
c Initial revision
c
*-
*- All standards are from "Proposal for Hall C Analysis Software
*- Vade Mecum, Draft 1.0" by D.F.Geesamn and S.Wood, 7 May 1993
*-
*--------------------------------------------------------
      IMPLICIT NONE
      SAVE
*
      character*16 here
      parameter (here= 'C_reconstruction')
*
      logical ABORT
      character*(*) err
*
      INCLUDE 'gen_data_structures.cmn'
      INCLUDE 'gen_constants.par'
      INCLUDE 'gen_units.par'
      INCLUDE 'coin_bypass_switches.cmn'
*
*--------------------------------------------------------
*
      ABORT= .FALSE.
      err = ' '
*
      if(cbypass_physics.eq.0) then
        call c_physics(abort,err)
        IF(ABORT) call G_add_path(here,err)
        return
      endif
*
*     Successful return
*
      abort = .false.
*
      RETURN
      END

