*=======================================================================
      subroutine h_cal(abort,errmsg)
*=======================================================================
*-
*-      Purpose: Computes the calorimeter particle ID quantities.
*-               Corrects the energy depositions for impact point 
*-               coordinate dependence.
*-
*-      Input Bank: HMS_TRACKS_CAL
*-
*-      Output Bank: HMS_TRACK_TESTS
*-
*-   Output: ABORT           - success or failure
*-         : err             - reason for failure, if any
*- 
*-      Created: 15 Mar 1994      Tsolak A. Amatuni
*
* $Log$
* Revision 1.6  1999/01/21 21:40:13  saw
* Extra shower counter tube modifications
*
* Revision 1.5  1998/12/17 22:02:38  saw
* Support extra set of tubes on HMS shower counter
*
* Revision 1.4  1995/05/22 19:39:04  cdaq
* (SAW) Split gen_data_data_structures into gen, hms, sos, and coin parts"
*
* Revision 1.3  1994/09/13  19:39:14  cdaq
* (JRA) Add preshower energy
*
* Revision 1.2  1994/04/12  21:24:55  cdaq
* (DFG) Put in real code and change name of print routine.
*
* Revision 1.1  1994/02/19  06:12:35  cdaq
* Initial revision
*
*--------------------------------------------------------
      implicit none
      save
*     
      logical abort
      character*(*) errmsg
      character*5 here
      parameter (here='H_CAL')
*
      integer*4 nt           !Detector track number
      integer*4 nc           !Calorimeter cluster number
      real*4 cor_pos     !Correction factor for X,Y dependenc.   ! Single  "POS_PMT"
*      real*4 cor         !Correction factor for X,Y dependenc.  !! For old version
      real*4 cor_neg     !Correction factor for X,Y dependenc.   ! Single  "NEG_PMT" 
      real*4 cor_two     !Correction factor for X,Y dependence.  ! "POS_PMT" + "NEG_PMT"  
      real*4 h_correct_cal_pos          !External function to compute "cor_pos". 
*      real*4 h_correct_cal              !External function to compute "cor" For old version.
      real*4 h_correct_cal_neg          !External function to compute "cor_neg"   
      real*4 h_correct_cal_two          !External function to compute "cor_two"

*
      include 'hms_data_structures.cmn'
      include 'hms_calorimeter.cmn'
*
      do nt=1,hntracks_fp
         htrack_e1_pos(nt)=0.      !  Only pos_pmt for layer "A"
         htrack_e1_neg(nt)=0.      !  Only_neg_pmt for layer "A"
*
         htrack_e2_pos(nt)=0.      !  Only_pos_pmt for layer "B"  
         htrack_e2_neg(nt)=0.      !  Only_neg_pmt for layer "B" 
*
         htrack_e1(nt)=0.
         htrack_e2(nt)=0.
         htrack_e3(nt)=0.
         htrack_e4(nt)=0.
         htrack_et(nt)=0.
         htrack_preshower_e(nt)=0.
      enddo
*
      call h_clusters_cal(abort,errmsg)
      if(abort) then
         call g_add_path(here,errmsg)
         return
      endif
*
      call h_tracks_cal(abort,errmsg)
      if(abort) then
         call g_add_path(here,errmsg)
         return
      endif
*
*      Return if there are no tracks found or none of the found
*      tracks matches a cluster in the calorimeter.
*
      if(hntracks_fp .le.0) go to 100   !Return
      if(hntracks_cal.le.0) go to 100   !Return
*
      do nt =1,hntracks_fp
         nc=hcluster_track(nt)

         if(nc.gt.0) then
           cor_pos=h_correct_cal_pos(htrack_xc(nt),htrack_yc(nt)) ! For single "pos_pmt"
*
*     cor=h_correct_cal(htrack_xc(nt),htrack_yc(nt))   ! For old version single "pos_pmt"
*
           cor_neg=h_correct_cal_neg(htrack_xc(nt),htrack_yc(nt)) ! For single "neg_pmt"
*
           cor_two=h_correct_cal_two(htrack_xc(nt),htrack_yc(nt)) ! For "pos_pmt"+"neg_pmt"
*
           hnblocks_cal(nt)=hcluster_size(nc)
*
*
**  "cor_two" also may be used for "htrack_e1" and "htrack_e2' as a mean correction 
*    factor when "POS_PMT" and "NEG_PMT" on use !!
*
*                  If "POS_PMT" + "NEG_PMT" then 
*
*            htrack_e1(nt)=cor_two*hcluster_e1(nc)          !!  For "POS_PMT"+"NEG_PMT"
*
           if(hcal_num_neg_columns.ge.1) then
             htrack_e1_pos(nt)=cor_pos*hcluster_e1_pos(nc) !!  For "A" layer "POS_PMT"    
             htrack_e1_neg(nt)=cor_neg*hcluster_e1_neg(nc) !!  For "A" layer "NEG_PMT"
             htrack_e1(nt)= htrack_e1_pos(nt)+htrack_e1_neg(nt) !!  For "A" layer "POS"+"NEG_PMT"
           else
             htrack_e1(nt)=cor_pos*hcluster_e1(nc) !!   IF ONLY "POS_PMT" in layer "A"                
           endif

           if(hcal_num_neg_columns.ge.2) then
             htrack_e2_pos(nt)=cor_pos*hcluster_e2_pos(nc) !!  For "B" layer "POS_PMT"    
             htrack_e2_neg(nt)=cor_neg*hcluster_e2_neg(nc) !!  For "B" layer "NEG_PMT"
             htrack_e2(nt)= htrack_e2_pos(nt)+htrack_e2_neg(nt) !!  For "B" layer "POS"+"NEG_PMT"
           else
             htrack_e2(nt)=cor_pos*hcluster_e2(nc) !!   IF ONLY "POS_PMT" in layer "B"
           endif

           if(hcal_num_neg_columns.ge.3) then
             print *,"Extra tubes on more than two layers not supported"
           endif
           htrack_e3(nt)=cor_pos*hcluster_e3(nc)  
           htrack_e4(nt)=cor_pos*hcluster_e4(nc)

 
           htrack_et(nt)=htrack_e1(nt)+htrack_e2(nt)+ htrack_e3(nt)
     $          +htrack_e4(nt) 
           if(hcal_num_neg_columns.ge.1) then
             htrack_preshower_e(nt)=cor_pos*hcluster_e1(nc)+cor_neg
     $            *hcluster_e1(nc) 
           else
             htrack_preshower_e(nt)=cor_pos*hcluster_e1(nc)  
           endif
*     
         endif                          !End ... if nc > 0
      enddo                             !End loop over detector tracks
*
  100 continue
      if(hdbg_tests_cal.gt.0) call h_prt_cal_tests
*
      return
      end
