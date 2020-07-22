pro reproc,dir,obsid

cldir=dir+'/'+obsid+'/event_cl'

spawn,'mv '+cldir+'/nu'+obsid+'*01_usrgti.fits '+dir+'/'+obsid+'/'
spawn,'mv '+cldir+' '+dir+'/'+obsid+'/event_defcl'

spawn,'$CALDB_AUXIL/run_pipe_usrgti_notstrict.sh '+dir+'/'+obsid+' A'
spawn,'$CALDB_AUXIL/run_pipe_usrgti_notstrict.sh '+dir+'/'+obsid+' B'

end
