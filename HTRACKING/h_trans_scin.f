      subroutine h_trans_scin(abort,errmsg)
*-------------------------------------------------------------------
* author: John Arrington
* created: 2/22/94
*
* h_trans_scin fills the hms_decoded_scin common block
* with track independant corrections and parameters
* needed for the drift chamber and tof analysis.
*
* modifications:
* $Log$
* Revision 1.11  1995/01/31 21:51:13  cdaq
* (JRA) Put hit in center of scint if only one tube fired
*
* Revision 1.10  1995/01/27  19:28:48  cdaq
* (JRA) Adjust start time cut to be hardwired for December 94 run.  Need a
*       better way to do this eventually.
*
* Revision 1.9  1995/01/18  16:28:08  cdaq
* (SAW) Catch negative ADC values in argument of square root
*
* Revision 1.8  1994/09/13  21:40:06  cdaq
* (JRA) remove obsolete code, fix check for 2 hits, fix hit position
*
* Revision 1.7  1994/08/19  03:41:21  cdaq
* (SAW) Remove a debugging statement that was left in (type *,fptime)
*
* Revision 1.6  1994/08/03  14:42:39  cdaq
* (JRA) Remove outliers from start time calculation
*
* Revision 1.5  1994/08/02  20:34:00  cdaq
* (JRA) Some hacks
*
* Revision 1.4  1994/07/27  19:25:56  cdaq
* ??
*
* Revision 1.3  1994/06/29  03:43:27  cdaq
* (JRA) Add call to h_strip_scin to get good hits from HSCIN_ALL arrays
*
* Revision 1.2  1994/04/13  18:03:14  cdaq
* (DFG) 4/6       Add call to h_fill_scin_raw_hist
* (DFG) 4/5       Move call to h_prt_raw_scin to h_dump_all_raw
* (DFG) 3/24      Add h_prt_scin_raw    raw bank dump routine
*                 Add h_prt_scin_dec    decoded print routine
*                 Add test for zero hits and skip all but initialization
*                 Commented out setting abort = .true.
*                 Add ABORT and errmsg to arguements
*
* Revision 1.1  1994/02/19  06:21:37  cdaq
* Initial revision
*
*--------------------------------------------------------

      implicit none

      include 'gen_data_structures.cmn'
      include 'hms_scin_parms.cmn'
      include 'hms_scin_tof.cmn'

      logical abort
      character*1024 errmsg
      character*20 here
      parameter (here = 'h_trans_scin')

      integer*4 ihit
      integer*4 time_num
      real*4 time_sum
      real*4 fptime
      real*4 scint_center
      real*4 hit_position
      real*4 dist_from_center
      real*4 pos_path, neg_path
      real*4 pos_ph(hmax_scin_hits)     !pulse height (channels)
      real*4 neg_ph(hmax_scin_hits)
      real*4 postime(hmax_scin_hits)
      real*4 negtime(hmax_scin_hits)

      save
      
      abort = .false.

**    Find scintillators with real hits (good TDC values)
      call h_strip_scin(abort,errmsg)
      if (abort) then
        call g_prepend(here,errmsg)
        return
      endif
      
**    Initialize track-independant quantaties.
      call h_tof_init(abort,errmsg)
      if (abort) then
        call g_prepend(here,errmsg)
        return
      endif

      hgood_start_time = .false.
      if( hscin_tot_hits .gt. 0)  then
** Histogram raw scin
        call h_fill_scin_raw_hist(abort,errmsg)
        if (abort) then
          call g_prepend(here,errmsg)
          return
        endif
      endif        
     
** Return if no valid hits.
      if( hscin_tot_hits .le. 0) return

        do ihit = 1 , hscin_tot_hits
          htwo_good_times(ihit) = .false.
        enddo

** Check for two good TDC values.
        do ihit = 1 , hscin_tot_hits
            if ((hscin_tdc_pos(ihit) .ge. hscin_tdc_min) .and.
     1      (hscin_tdc_pos(ihit) .le. hscin_tdc_max) .and.
     2      (hscin_tdc_neg(ihit) .ge. hscin_tdc_min) .and.
     3      (hscin_tdc_neg(ihit) .le. hscin_tdc_max)) then
              htwo_good_times(ihit) = .true.
            endif
        enddo                           !end of loop that finds tube setting time.

**    Get corrected time/adc for each scintillator hit
        do ihit = 1 , hscin_tot_hits
          if (htwo_good_times(ihit)) then !both tubes fired

*     Correct time for everything except veloc. correction in order to
*     find hit location from difference in tdc.
            pos_ph(ihit) = float(hscin_adc_pos(ihit))
            postime(ihit) = hscin_tdc_pos(ihit) * hscin_tdc_to_time
            postime(ihit) = postime(ihit) - hscin_pos_phc_coeff(ihit) * 
     1           sqrt(max(0.,(pos_ph(ihit)/hscin_minph-1.)))
            postime(ihit) = postime(ihit) - hscin_pos_time_offset(ihit)

            neg_ph(ihit) = float(hscin_adc_neg(ihit))
            negtime(ihit) = hscin_tdc_neg(ihit) * hscin_tdc_to_time
            negtime(ihit) = negtime(ihit) - hscin_neg_phc_coeff(ihit) * 
     1           sqrt(max(0.,(neg_ph(ihit)/hscin_minph-1.)))
            negtime(ihit) = negtime(ihit) - hscin_neg_time_offset(ihit)

* Find hit position.  If postime larger, then hit was nearer negative side.
            dist_from_center = 0.5*(negtime(ihit) - postime(ihit))
     1           * hscin_vel_light(ihit)
            scint_center = (hscin_pos_coord(ihit)+hscin_neg_coord(ihit))
     $           /2.
            hit_position = scint_center + dist_from_center
            hscin_dec_hit_coord(ihit) = hit_position
            
*     Get corrected time.
            pos_path = abs(hscin_pos_coord(ihit) - hit_position)
            neg_path = abs(hscin_neg_coord(ihit) - hit_position)
            postime(ihit) = postime(ihit) - pos_path
     $           /hscin_vel_light(ihit)
            negtime(ihit) = negtime(ihit) - neg_path
     $           /hscin_vel_light(ihit)

            hscin_cor_time(ihit) = ( postime(ihit) + negtime(ihit) )/2.
ccc The following sometimes results in square roots of negative numbers
ccc Supposedly, no one uses this right now (SAW 1/17/95)
            if(neg_ph(ihit) .ge. 0.0 .and. pos_ph(ihit) .ge. 0.0) then
              hscin_cor_adc(ihit) = sqrt( neg_ph(ihit) * pos_ph(ihit))
            else
              hscin_cor_adc(ihit) = 0.0
            endif
          else                          !only 1 tube fired
            hscin_dec_hit_coord(ihit) = 0.
            hscin_cor_adc(ihit) = 0.
            hscin_cor_time(ihit) = 0.   !not a very good 'flag', but there is
                                        ! the logical htwo_good_hits.
          endif
        enddo                           !loop over hits to find ave time,adc.

* TEMPORARY START TIME CALCULATION.  ASSUME XP=YP=0 RADIANS.  PROJECT ALL
*     TIME VALUES TO FOCAL PLANE.  USE AVERAGE FOR START TIME.
        time_num = 0
        time_sum = 0.
        do ihit = 1 , hscin_tot_hits
          if (htwo_good_times(ihit)) then
            fptime  = hscin_cor_time(ihit) - hscin_zpos(ihit)/29.989
            if (abs(fptime-18.).le.10) then
              time_sum = time_sum + fptime
              time_num = time_num + 1
            endif
          endif
        enddo
        if (time_num.eq.0) then
          hgood_start_time = .false.
          hstart_time = 18.		!150 ns is a rough average of time dif between trig
                                        ! and wire firing.
        else
          hgood_start_time = .true.
          hstart_time = time_sum / float(time_num)
        endif


*     Dump decoded bank if hdebugprintscindec is set
      if( hdebugprintscindec .ne. 0) call h_prt_dec_scin(ABORT,errmsg)
      return
      end
