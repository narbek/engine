      subroutine h_tof_fit(abort,errmsg,trk)

*-------------------------------------------------------------------
* author: John Arrington
* created: 2/22/94
*
* h_tof_fit fits the velocity of the paritcle from the corrected
* times generated by h_tof.
*
* modifications:
* $Log$
* Revision 1.3  1994/07/08 19:42:31  cdaq
* (JRA) Change fit from velocity to beta.  Bad fits give beta=0
*
* Revision 1.2  1994/06/14  04:53:41  cdaq
* (DFG) Protect against divide by 0 in beta calc
*
* Revision 1.1  1994/04/13  16:29:15  cdaq
* Initial revision
*
*-------------------------------------------------------------------

      implicit none

      include 'gen_data_structures.cmn'
      include 'hms_scin_parms.cmn'
      include 'hms_scin_tof.cmn'

      logical abort
      character*1024 errmsg
      character*20 here
      parameter (here = 'h_tof_fit')
      
      real*4 sumw, sumt, sumz, sumzz, sumtz
      real*4 scin_weight
      real*4 tmp, t0 ,tmpdenom
      real*4 pathnorm
      integer*4 hit, trk
      save
      
      sumw = 0.
      sumt = 0.
      sumz = 0.
      sumzz = 0.
      sumtz = 0.

      do hit = 1 , hscin_tot_hits
         if (hgood_scin_time(hit)) then
            scin_weight = 1./hscin_sigma(hit)**2
            sumw = sumw + scin_weight
            sumt = sumt + scin_weight * hscin_time(hit)
            sumz = sumz + scin_weight * hscin_zpos(hit)
            sumzz = sumzz + scin_weight * hscin_zpos(hit)**2
            sumtz = sumtz + scin_weight * hscin_zpos(hit) *
     1           hscin_time(hit)
         endif
      enddo

* The formula for beta (and t0) come from taking chi-squared (as
* defined below), and differentiating  with respect to each
* of the fit paramters (beta and t0 for fit to z=beta*(t-t0)).
* Setting both of these derivatives to zero gives the minumum
* chisquared (since they are quadratic in beta and t0), and
* gives a solution for beta in terms of sums of z, t, and w.

      tmp = sumw*sumzz - sumz*sumz
      t0 = (sumt*sumzz - sumz*sumtz) / tmp
      tmpdenom = sumw*sumtz - sumz*sumt
      if(tmpdenom .gt. 1.e-15) then
         hbeta(trk) = tmp / tmpdenom        !velocity in cm/ns.
         hbeta(trk) = hbeta(trk) / 29.9979  !velocity/c
         hbeta_chisq(trk) = 0.
         do hit = 1 , hscin_tot_hits
            if (hgood_scin_time(hit)) then
               hbeta_chisq(trk) = hbeta_chisq(trk) + 
     1              (hscin_zpos(hit)/hbeta(trk) -
     1              (hscin_time(hit) - t0))**2 / hscin_sigma(hit)**2
            endif
         enddo

         pathnorm = 1 + hxp_fp(trk)**2 + hyp_fp(trk)**2
         hbeta(trk) = hbeta(trk) * pathnorm !take angle into account
      else
         hbeta(trk) = 0.               ! set unphysical beta
         hbeta_chisq(trk) = -100
      endif                             ! end if on denomimator = 0.

      return
      end
