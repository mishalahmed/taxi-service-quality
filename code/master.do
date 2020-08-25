cls
global code "D:/Dropbox/Research/Uber/Driver_level_analysis/code"
do $code/1a_drivers_yellow
do $code/1b_drivers_fhv
do $code/1c_drivers_append
do $code/2a_drivers_trunc
do $code/2b_drivers_trunc
* ./$code/3a_medallions_prep_for_stata
* not to be run since bash is not native to Windows installation
do $code/3b_medallions_clean
* ./$code/4a_complaints_prep_for_stata
* not to be run since bash is not native to Windows installation
do $code/4b_complaints_clean
do $code/4c_complaints_extract
do $code/5a_merge_all
do $code/5b_prep_for_analysis