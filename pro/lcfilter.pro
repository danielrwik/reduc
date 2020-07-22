pro lcfilter,indir,inobsid,inab,e1,e2,imname,intbin,usr=usr,excl=excl

dir=indir
obsid=inobsid
ab=inab
tbin=intbin

if not keyword_set(usr) then usr=0

cldir=dir+'/'+obsid+'/event_cl/'
if keyword_set(excl) then begin
    mask=intarr(1000,1000)
    mask[*,*]=1
    if not file_test(cldir+imname) then $
          stop,'LCFILTER: Image file '+cldir+imname+' does not exist'
    if not file_test(cldir+'excl.reg') then $
          stop,'LCFILTER: Exclude region file '+cldir+'excl.reg does not exist'
    excl=reg2mask(cldir+imname,cldir+'excl.reg')
    ii=where(excl gt 0.5)
    mask[ii]=0
endif else undefine,mask
if usr ne 1 then undefine,usr

reglc,cldir,obsid,mask,ab,e1,e2,tbin=tbin,usr=usr

end
